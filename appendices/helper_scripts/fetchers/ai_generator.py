"""Fetcher that generates structured quiz questions via OpenAI."""
import json
import os
import logging
import openai
from dotenv import load_dotenv
from .base import BaseFetcher

load_dotenv()
logger = logging.getLogger(__name__)

class IQGenerator(BaseFetcher):
    """Generate IQ-style question data in the repository JSON schema."""
    def __init__(self):
        """Initialize API credentials from the current environment."""
        openai.api_key = os.getenv("OPENAI_API_KEY")

    def fetch(self, amount: int = 10) -> list:
        """Request and normalize ``amount`` generated questions."""
        prompt = (
            f"Generate {amount} unique IQ questions as a JSON list. "
            "Format: [{'question': '...', 'answers': {'a': '...', 'b': '...', 'c': '...', 'd': '...'}, "
            "'correct_answer': 'a'}]"
        )
        try:
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.7
            )
            content = response.choices[0].message.content
            raw_data = json.loads(content)
            
            # Keep AI output consistent with the same schema used by all fetchers.
            return [
                {
                    "id": i, 
                    "correct_answer": item['correct_answer'], 
                    "en": {"question": item['question'], "answers": item['answers']}
                } 
                for i, item in enumerate(raw_data, 1)
            ]
        except Exception as e:
            logger.error(f"AI error: {e}")
            return []
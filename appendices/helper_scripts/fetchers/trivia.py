"""Fetcher for Open Trivia Database question payloads."""
import requests
import html
import random
import time
import logging
from .base import BaseFetcher

logger = logging.getLogger(__name__)

class TriviaFetcher(BaseFetcher):
    """Normalize OpenTDB responses into the project ``en`` schema."""
    URL = "https://opentdb.com/api.php"

    def fetch(self, amount: int = 50) -> list:
        """Fetch and normalize multiple-choice questions from OpenTDB."""
        params = {"amount": amount, "type": "multiple"}
        try:
            response = requests.get(self.URL, params=params, timeout=10)
            data = response.json()
            
            results = []
            for idx, item in enumerate(data.get('results', []), 1):
                # Unescape entities before answer shuffling so displayed text is clean.
                correct = html.unescape(item['correct_answer'])
                options = [html.unescape(a) for a in item['incorrect_answers']] + [correct]
                random.shuffle(options)
                
                # Map shuffled answers to stable single-letter keys (a, b, c, ...).
                opt_map = {chr(97+i): val for i, val in enumerate(options)}
                ans_key = next(k for k, v in opt_map.items() if v == correct)

                results.append({
                    "id": idx,
                    "correct_answer": ans_key,
                    "en": {
                        "question": html.unescape(item['question']),
                        "answers": opt_map
                    }
                })
            return results
        except Exception as e:
            logger.error(f"Trivia error: {e}")
            return []
"""
Translation engine with multiprocessing isolation and recursive structure handling.
"""
import time
import random
import logging
from multiprocessing import Process, Pipe
from deep_translator import GoogleTranslator
from .utils import mask_placeholders, restore_placeholders

logger = logging.getLogger(__name__)

class TranslationEngine:
    """
    A robust translator that manages Google Translate API calls across multiple processes.
    """

    def __init__(self, max_retries: int = 5, timeout: int = 10):
        self.max_retries = max_retries
        self.timeout = timeout
        self.cache = {}

    @staticmethod
    def _translate_worker(text: str, lang: str, conn):
        """Worker function for isolated process execution."""
        try:
            masked, phs = mask_placeholders(text)
            translator = GoogleTranslator(source='auto', target=lang)
            translated = translator.translate(masked)
            final = restore_placeholders(translated, phs)
            conn.send((final, None))
        except Exception as e:
            conn.send((None, str(e)))
        finally:
            conn.close()

    def translate_text(self, text: str, lang: str) -> str:
        """
        Translates a single string with process-level isolation and retry logic.
        """
        if not text or (isinstance(text, str) and text.isdigit()):
            return text
            
        key = (text, lang)
        if key in self.cache:
            return self.cache[key]

        for attempt in range(self.max_retries):
            parent_conn, child_conn = Pipe()
            p = Process(target=self._translate_worker, args=(text, lang, child_conn))
            p.start()
            
            p.join(self.timeout)
            if p.is_alive():
                p.terminate()
                p.join()
                logger.warning(f"Timeout translating to {lang} (Attempt {attempt+1})")
            elif parent_conn.poll():
                result, error = parent_conn.recv()
                if not error and result:
                    self.cache[key] = result
                    return result
            
            time.sleep(attempt * 1.5 + random.uniform(0.5, 1.0))
            
        return text

    def translate_recursive(self, data: any, lang: str) -> any:
        """
        Walks through dictionaries and lists to translate every string found.
        """
        if isinstance(data, dict):
            return {k: self.translate_recursive(v, lang) for k, v in data.items()}
        elif isinstance(data, list):
            return [self.translate_recursive(item, lang) for item in data]
        elif isinstance(data, str):
            return self.translate_text(data, lang)
        return data
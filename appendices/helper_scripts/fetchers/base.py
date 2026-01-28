"""
Abstract base class for all content fetchers.
"""
from abc import ABC, abstractmethod

class BaseFetcher(ABC):
    """
    Standard interface for fetching data.
    """
    @abstractmethod
    def fetch(self, amount: int):
        """
        Fetches 'amount' records and returns a list of standardized dicts.
        """
        pass
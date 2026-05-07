"""Abstract contracts for content fetchers."""
from abc import ABC, abstractmethod

class BaseFetcher(ABC):
    """Common interface that all content providers must implement."""
    @abstractmethod
    def fetch(self, amount: int):
        """Return ``amount`` normalized records in the project schema."""
        pass
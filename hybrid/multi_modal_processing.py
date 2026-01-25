from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Callable, Dict, List


@dataclass
class ModalData:
    """
    Data container for a specific modality.

    Attributes
    ----------
    modality : str
        Type of modality (e.g., "text", "audio", "image").
    data : Any
        The raw data associated with the modality.
    """
    modality: str
    data: Any


class MultiModalProcessor:
    """
    Simple processor that routes inputs to registered modality-specific handlers.
    """
    def __init__(self) -> None:
        self.handlers: Dict[str, Callable[[Any], Any]] = {}

    def register_handler(self, modality: str, handler: Callable[[Any], Any]) -> None:
        """
        Register a function to handle a specific modality.
        """
        self.handlers[modality] = handler

    def process(self, inputs: List[ModalData]) -> Dict[str, Any]:
        """
        Process a list of `ModalData` objects and return a dict of results keyed by modality.
        """
        results: Dict[str, Any] = {}
        for item in inputs:
            handler = self.handlers.get(item.modality)
            if handler:
                results[item.modality] = handler(item.data)
        return results


if __name__ == "__main__":
    processor = MultiModalProcessor()
    processor.register_handler("text", lambda s: s.upper())
    processor.register_handler("number", lambda n: n * 2)

    sample_inputs = [ModalData("text", "hello"), ModalData("number", 3)]
    print(processor.process(sample_inputs))

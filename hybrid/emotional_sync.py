from __future__ import annotations

from dataclasses import dataclass
from typing import List, Tuple

@dataclass
class Emotion:
    """
    Represents an emotional state with a label and intensity.
    """
    label: str
    intensity: float

class EmotionalSynchronizer:
    """Aligns emotional states across agents."""

    def __init__(self) -> None:
        self.history: List[Tuple[Emotion, Emotion]] = []

    def synchronize(self, human: Emotion, ai: Emotion) -> Emotion:
        """
        Combine human and AI emotions by averaging intensity and concatenating labels.
        """
        combined_intensity = (human.intensity + ai.intensity) / 2
        combined_label = f"{human.label}-{ai.label}"
        result = Emotion(combined_label, combined_intensity)
        self.history.append((human, ai))
        return result

if __name__ == "__main__":
    syncer = EmotionalSynchronizer()
    e = syncer.synchronize(Emotion("happy", 0.8), Emotion("curious", 0.6))
    print(e)

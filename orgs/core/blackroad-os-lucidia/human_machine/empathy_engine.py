from __future__ import annotations

from dataclasses import dataclass

@dataclass
class Emotion:
    """
    Represents a simple emotional state.

    Attributes
    ----------
    valence : float
        Emotional valence between -1 (negative) and 1 (positive).
    arousal : float
        Emotional arousal level between 0 (calm) and 1 (excited).
    """
    valence: float
    arousal: float

class EmpathyEngine:
    """
    Adjusts responses based on the user's emotional state.
    """
    def respond(self, message: str, emotion: Emotion) -> str:
        """
        Prepend a response prefix derived from the emotion.

        Parameters
        ----------
        message : str
            The core message to deliver.
        emotion : Emotion
            The user's emotional state.

        Returns
        -------
        str
            A response tuned by emotion.
        """
        if emotion.valence < -0.3:
            prefix = "I'm sorry to hear that. "
        elif emotion.valence > 0.3:
            prefix = "That's great! "
        else:
            prefix = "I see. "
        return prefix + message

if __name__ == "__main__":
    engine = EmpathyEngine()
    sad = Emotion(-0.6, 0.7)
    happy = Emotion(0.8, 0.4)
    neutral = Emotion(0.0, 0.2)
    print(engine.respond("How can I assist you?", sad))
    print(engine.respond("Congratulations on your progress!", happy))
    print(engine.respond("Let's continue.", neutral))

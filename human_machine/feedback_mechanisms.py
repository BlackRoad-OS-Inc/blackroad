from __future__ import annotations

from dataclasses import dataclass
from typing import List, Optional


@dataclass
class Feedback:
    """Represents a piece of user feedback with an optional numeric rating.

    Attributes
    ----------
    user_id : str
        Identifier of the user providing feedback.
    message : str
        The textual content of the feedback.
    rating : Optional[int]
        Optional numeric rating (e.g., 1–5) associated with the feedback.
    """
    user_id: str
    message: str
    rating: Optional[int] = None


class FeedbackManager:
    """
    Collects and processes feedback from users.

    This manager stores feedback entries and can compute simple statistics
    over them.
    """

    def __init__(self) -> None:
        self._feedback: List[Feedback] = []

    def submit(self, feedback: Feedback) -> None:
        """Submit new feedback."""
        self._feedback.append(feedback)

    def average_rating(self) -> Optional[float]:
        """Compute the average rating across all feedback that has a rating."""
        ratings = [f.rating for f in self._feedback if f.rating is not None]
        if ratings:
            return sum(ratings) / len(ratings)
        return None

    def messages(self) -> List[str]:
        """Return a list of all feedback messages."""
        return [f.message for f in self._feedback]


if __name__ == "__main__":
    mgr = FeedbackManager()
    mgr.submit(Feedback(user_id="u1", message="Great job!", rating=5))
    mgr.submit(Feedback(user_id="u2", message="Could be better.", rating=3))
    mgr.submit(Feedback(user_id="u3", message="Loved the experience!"))

    print("Average rating:", mgr.average_rating())
    print("Messages:", mgr.messages())

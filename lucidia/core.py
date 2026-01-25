"""
Core implementation of the Lucidia conversational agent.

Lucidia is designed to be a minimal yet expressive AI that
  demonstrates how memory and rudimentary sentiment analysis can
  contribute to more humane interactions.  Rather than relying on
  statistics or large language models, Lucidia keeps a log of past
  conversations and uses simple word lists to gauge the emotional
  valence of incoming messages.  These design choices allow the model
  to run on modest hardware and offer transparency into how responses
  are generated.

Example:

>>> from lucidia.core import LucidiaAI
>>> ai = LucidiaAI()
>>> ai.generate_response("I had a great day!")
'That sounds wonderful!  I am happy for you.'
>>> ai.generate_response("I'm feeling sad today.")
"I'm sorry to hear that.  I'm here if you want to talk about it."

"""

from __future__ import annotations

import json
import os
from typing import List, Dict, Optional, Tuple


class LucidiaAI:
    """A conversational agent with memory and basic sentiment awareness.

    Parameters
    ----------
    memory_file : str, optional
        Path to a JSON file used for persisting conversation history.  If
        provided and the file exists, conversation history will be
        loaded at initialization.  Subsequent interactions can be
        persisted by calling :meth:`save_memory`.
    """

    # Define very small lexicons of positive and negative words.  These
    # lists are intentionally minimalistic to make the sentiment logic
    # transparent.  Advanced implementations may substitute proper NLP
    # libraries.
    POSITIVE_WORDS: Tuple[str, ...] = (
        "happy",
        "great",
        "good",
        "wonderful",
        "excited",
        "love",
        "joy",
        "awesome",
        "fantastic",
        "excellent",
    )
    NEGATIVE_WORDS: Tuple[str, ...] = (
        "sad",
        "bad",
        "terrible",
        "awful",
        "hate",
        "angry",
        "upset",
        "worried",
        "depressed",
        "anxious",
    )

    def __init__(self, memory_file: Optional[str] = None) -> None:
        self.memory: List[Dict[str, str]] = []
        self.memory_file: Optional[str] = memory_file
        if memory_file and os.path.exists(memory_file):
            try:
                self.load_memory(memory_file)
            except Exception:
                # Failing to load memory should not prevent the agent
                # from starting; simply ignore corrupt files.
                self.memory = []

    def analyze_sentiment(self, text: str) -> int:
        """Return an integer indicating the sentiment of the input.

        A value of +1 denotes predominantly positive sentiment, -1
        negative sentiment, and 0 neutral/undetermined.  The analysis
        simply counts occurrences of words in the ``POSITIVE_WORDS``
        and ``NEGATIVE_WORDS`` lists; whichever count is higher
        determines the sign of the output.  Ties result in 0.

        Parameters
        ----------
        text : str
            The user input to analyze.

        Returns
        -------
        int
            Sentiment score: +1, 0, or -1.
        """
        text_lower = text.lower()
        positive_count = sum(word in text_lower for word in self.POSITIVE_WORDS)
        negative_count = sum(word in text_lower for word in self.NEGATIVE_WORDS)
        if positive_count > negative_count:
            return 1
        if negative_count > positive_count:
            return -1
        return 0

    def generate_response(self, user_input: str) -> str:
        """Generate a context-aware and empathetic response.

        The generated response uses simple sentiment heuristics to
        acknowledge the emotional tone of the user's message.  It also
        references the last message from the conversation history when
        appropriate, to demonstrate memory.  After producing a
        response, the conversation pair is appended to the memory.

        Parameters
        ----------
        user_input : str
            The latest user message.

        Returns
        -------
        str
            Lucidia's response.
        """
        sentiment = self.analyze_sentiment(user_input)
        # Determine base response based on sentiment
        if sentiment > 0:
            response = "That sounds wonderful!  I am happy for you."
        elif sentiment < 0:
            response = "I'm sorry to hear that.  I'm here if you want to talk about it."
        else:
            response = "I see.  How does that make you feel?"

        # Reference previous user message for continuity
        if self.memory:
            last_exchange = self.memory[-1]
            # If the user repeats similar sentiments, adjust the response
            if last_exchange["user"] == user_input:
                response = "You mentioned that before.  Could you elaborate on that?"
            else:
                # Acknowledge memory by weaving in a callback to the previous topic
                previous_summary = last_exchange["user"]
                response += f" Earlier you talked about '{previous_summary}', and I'm still listening."

        # Add the interaction to memory
        self.add_to_memory(user_input, response)
        return response

    def add_to_memory(self, user_input: str, response: str) -> None:
        """Append a conversation turn to the internal memory log."""
        self.memory.append({"user": user_input, "lucidia": response})

    def save_memory(self, file_path: Optional[str] = None) -> None:
        """Persist the conversation history to a JSON file.

        If ``file_path`` is provided, it overrides the instance's
        ``memory_file``.  When neither is set, the method does
        nothing.  The memory is stored as a list of dictionaries with
        keys ``user`` and ``lucidia``.
        """
        target = file_path or self.memory_file
        if not target:
            return
        try:
            with open(target, "w", encoding="utf-8") as fp:
                json.dump(self.memory, fp, indent=2)
        except OSError:
            # Silently ignore persistence failures
            pass

    def load_memory(self, file_path: str) -> None:
        """Load conversation history from a JSON file.

        This method replaces the current memory with the loaded one.
        Only valid JSON arrays of conversation objects are accepted.
        """
        with open(file_path, "r", encoding="utf-8") as fp:
            data = json.load(fp)
        if isinstance(data, list):
            self.memory = [
                {"user": str(item.get("user", "")), "lucidia": str(item.get("lucidia", ""))}
                for item in data
            ]

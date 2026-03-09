"""RoadSearch Analyzer Base - Core Text Analysis Components.

Provides base classes for the text analysis pipeline including
tokenizers, filters, and analyzers.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from enum import Enum, auto
from typing import Any, Dict, Generator, Iterator, List, Optional, Tuple

logger = logging.getLogger(__name__)


class TokenType(Enum):
    """Token type classification."""

    WORD = auto()
    NUMBER = auto()
    PUNCTUATION = auto()
    WHITESPACE = auto()
    SYMBOL = auto()
    EMAIL = auto()
    URL = auto()
    HASHTAG = auto()
    MENTION = auto()
    EMOJI = auto()
    CJK = auto()  # Chinese/Japanese/Korean
    ALPHANUM = auto()


@dataclass
class Token:
    """A token in the analysis stream.

    Attributes:
        text: Token text
        position: Position in original text
        start_offset: Start character offset
        end_offset: End character offset
        token_type: Type classification
        position_increment: Position increment
        payload: Custom payload data
    """

    text: str
    position: int = 0
    start_offset: int = 0
    end_offset: int = 0
    token_type: TokenType = TokenType.WORD
    position_increment: int = 1
    payload: Optional[bytes] = None

    def __repr__(self) -> str:
        return f"Token({self.text!r}, pos={self.position}, type={self.token_type.name})"

    def clone(self) -> "Token":
        """Create a copy of this token."""
        return Token(
            text=self.text,
            position=self.position,
            start_offset=self.start_offset,
            end_offset=self.end_offset,
            token_type=self.token_type,
            position_increment=self.position_increment,
            payload=self.payload,
        )

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            "text": self.text,
            "position": self.position,
            "start_offset": self.start_offset,
            "end_offset": self.end_offset,
            "token_type": self.token_type.name,
            "position_increment": self.position_increment,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Token":
        """Create from dictionary."""
        return cls(
            text=data["text"],
            position=data.get("position", 0),
            start_offset=data.get("start_offset", 0),
            end_offset=data.get("end_offset", 0),
            token_type=TokenType[data.get("token_type", "WORD")],
            position_increment=data.get("position_increment", 1),
        )


class TokenStream:
    """A stream of tokens.

    Provides iteration and manipulation of token sequences.
    """

    def __init__(self, tokens: Optional[List[Token]] = None):
        """Initialize token stream.

        Args:
            tokens: Initial tokens
        """
        self._tokens: List[Token] = tokens or []
        self._position = 0

    def add(self, token: Token) -> None:
        """Add token to stream."""
        self._tokens.append(token)

    def reset(self) -> None:
        """Reset stream to beginning."""
        self._position = 0

    def next_token(self) -> Optional[Token]:
        """Get next token."""
        if self._position < len(self._tokens):
            token = self._tokens[self._position]
            self._position += 1
            return token
        return None

    def peek(self) -> Optional[Token]:
        """Peek at next token without advancing."""
        if self._position < len(self._tokens):
            return self._tokens[self._position]
        return None

    def has_next(self) -> bool:
        """Check if more tokens available."""
        return self._position < len(self._tokens)

    def __iter__(self) -> Iterator[Token]:
        """Iterate over tokens."""
        return iter(self._tokens)

    def __len__(self) -> int:
        """Get token count."""
        return len(self._tokens)

    def __getitem__(self, index: int) -> Token:
        """Get token by index."""
        return self._tokens[index]

    def to_list(self) -> List[Token]:
        """Convert to list of tokens."""
        return list(self._tokens)

    def get_texts(self) -> List[str]:
        """Get list of token texts."""
        return [t.text for t in self._tokens]

    def filter(self, predicate: callable) -> "TokenStream":
        """Filter tokens by predicate.

        Args:
            predicate: Function that returns True to keep token

        Returns:
            New filtered TokenStream
        """
        return TokenStream([t for t in self._tokens if predicate(t)])

    def map(self, func: callable) -> "TokenStream":
        """Map function over tokens.

        Args:
            func: Function to apply to each token

        Returns:
            New mapped TokenStream
        """
        return TokenStream([func(t) for t in self._tokens])


class CharacterFilter(ABC):
    """Filters characters before tokenization.

    Character filters transform the input text before tokenization.
    """

    @abstractmethod
    def filter(self, text: str) -> str:
        """Filter input text.

        Args:
            text: Input text

        Returns:
            Filtered text
        """
        pass


class HTMLCharacterFilter(CharacterFilter):
    """Strips HTML tags from text."""

    def __init__(self, escaped: bool = True):
        """Initialize filter.

        Args:
            escaped: Unescape HTML entities
        """
        self.escaped = escaped

    def filter(self, text: str) -> str:
        """Strip HTML tags."""
        import re
        import html

        # Remove HTML tags
        text = re.sub(r"<[^>]+>", " ", text)

        # Unescape entities
        if self.escaped:
            text = html.unescape(text)

        return text


class MappingCharacterFilter(CharacterFilter):
    """Maps characters based on mapping table."""

    def __init__(self, mappings: Dict[str, str]):
        """Initialize filter.

        Args:
            mappings: Character mapping table
        """
        self.mappings = mappings

    def filter(self, text: str) -> str:
        """Apply character mappings."""
        for old, new in self.mappings.items():
            text = text.replace(old, new)
        return text


class PatternReplaceCharacterFilter(CharacterFilter):
    """Replaces patterns using regex."""

    def __init__(self, pattern: str, replacement: str):
        """Initialize filter.

        Args:
            pattern: Regex pattern
            replacement: Replacement string
        """
        import re
        self.pattern = re.compile(pattern)
        self.replacement = replacement

    def filter(self, text: str) -> str:
        """Apply pattern replacement."""
        return self.pattern.sub(self.replacement, text)


class Analyzer(ABC):
    """Base class for text analyzers.

    An analyzer combines character filters, a tokenizer, and token
    filters into a complete text analysis pipeline.
    """

    def __init__(
        self,
        char_filters: Optional[List[CharacterFilter]] = None,
        tokenizer: Optional["Tokenizer"] = None,
        token_filters: Optional[List["TokenFilter"]] = None,
    ):
        """Initialize analyzer.

        Args:
            char_filters: Character filters to apply
            tokenizer: Tokenizer to use
            token_filters: Token filters to apply
        """
        self._char_filters = char_filters or []
        self._tokenizer = tokenizer
        self._token_filters = token_filters or []

    def analyze(self, text: str) -> TokenStream:
        """Analyze text into tokens.

        Args:
            text: Input text

        Returns:
            Token stream
        """
        # Apply character filters
        for char_filter in self._char_filters:
            text = char_filter.filter(text)

        # Tokenize
        if self._tokenizer:
            stream = self._tokenizer.tokenize(text)
        else:
            stream = self._default_tokenize(text)

        # Apply token filters
        for token_filter in self._token_filters:
            stream = token_filter.filter(stream)

        return stream

    def _default_tokenize(self, text: str) -> TokenStream:
        """Default tokenization (whitespace split)."""
        tokens = []
        position = 0
        start = 0

        for i, char in enumerate(text):
            if char.isspace():
                if start < i:
                    token_text = text[start:i]
                    tokens.append(Token(
                        text=token_text,
                        position=position,
                        start_offset=start,
                        end_offset=i,
                    ))
                    position += 1
                start = i + 1

        # Last token
        if start < len(text):
            tokens.append(Token(
                text=text[start:],
                position=position,
                start_offset=start,
                end_offset=len(text),
            ))

        return TokenStream(tokens)

    def get_terms(self, text: str) -> List[str]:
        """Get analyzed terms from text.

        Args:
            text: Input text

        Returns:
            List of term strings
        """
        stream = self.analyze(text)
        return stream.get_texts()

    def get_tokens_with_positions(
        self,
        text: str,
    ) -> List[Tuple[str, int, int]]:
        """Get tokens with positions.

        Args:
            text: Input text

        Returns:
            List of (term, position, offset) tuples
        """
        stream = self.analyze(text)
        return [(t.text, t.position, t.start_offset) for t in stream]


class Tokenizer(ABC):
    """Base class for tokenizers.

    Tokenizers break text into tokens based on various strategies.
    """

    @abstractmethod
    def tokenize(self, text: str) -> TokenStream:
        """Tokenize text.

        Args:
            text: Input text

        Returns:
            Token stream
        """
        pass


class TokenFilter(ABC):
    """Base class for token filters.

    Token filters transform, remove, or add tokens in the stream.
    """

    @abstractmethod
    def filter(self, stream: TokenStream) -> TokenStream:
        """Filter token stream.

        Args:
            stream: Input token stream

        Returns:
            Filtered token stream
        """
        pass


class AnalyzerRegistry:
    """Registry for analyzer instances.

    Provides lookup of analyzers by name.
    """

    _instance: Optional["AnalyzerRegistry"] = None

    def __new__(cls) -> "AnalyzerRegistry":
        """Singleton pattern."""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._analyzers = {}
        return cls._instance

    def register(self, name: str, analyzer: Analyzer) -> None:
        """Register an analyzer.

        Args:
            name: Analyzer name
            analyzer: Analyzer instance
        """
        self._analyzers[name] = analyzer

    def get(self, name: str) -> Optional[Analyzer]:
        """Get analyzer by name.

        Args:
            name: Analyzer name

        Returns:
            Analyzer or None
        """
        return self._analyzers.get(name)

    def list_analyzers(self) -> List[str]:
        """List registered analyzer names."""
        return list(self._analyzers.keys())


# Global registry instance
_registry = AnalyzerRegistry()


def register_analyzer(name: str) -> callable:
    """Decorator to register an analyzer.

    Args:
        name: Analyzer name

    Returns:
        Decorator function
    """
    def decorator(cls: type) -> type:
        _registry.register(name, cls())
        return cls
    return decorator


def get_analyzer(name: str) -> Optional[Analyzer]:
    """Get analyzer by name.

    Args:
        name: Analyzer name

    Returns:
        Analyzer or None
    """
    return _registry.get(name)


__all__ = [
    "Analyzer",
    "Token",
    "TokenType",
    "TokenStream",
    "Tokenizer",
    "TokenFilter",
    "CharacterFilter",
    "HTMLCharacterFilter",
    "MappingCharacterFilter",
    "PatternReplaceCharacterFilter",
    "AnalyzerRegistry",
    "register_analyzer",
    "get_analyzer",
]

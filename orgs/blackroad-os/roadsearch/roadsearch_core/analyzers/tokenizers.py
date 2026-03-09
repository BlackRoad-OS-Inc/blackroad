"""RoadSearch Tokenizers - Text Tokenization Strategies.

Various tokenization strategies for breaking text into tokens.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import re
import unicodedata
from typing import List, Optional, Pattern

from roadsearch_core.analyzers.base import (
    Tokenizer,
    Token,
    TokenStream,
    TokenType,
)


class StandardTokenizer(Tokenizer):
    """Standard tokenizer based on Unicode text segmentation.

    Breaks text on whitespace and punctuation while preserving
    emails, URLs, and other special patterns.
    """

    # Pattern for word characters
    WORD_PATTERN = re.compile(
        r"""
        (?:
            # Email addresses
            [a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}
            |
            # URLs
            (?:https?://)?(?:www\.)?[a-zA-Z0-9][a-zA-Z0-9-]*\.[a-zA-Z]{2,}(?:/[^\s]*)?
            |
            # Contractions
            \w+(?:'\w+)?
            |
            # Numbers with decimals
            \d+(?:\.\d+)?
            |
            # CJK characters
            [\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff]
            |
            # Alphanumeric
            [a-zA-Z0-9]+
        )
        """,
        re.VERBOSE | re.UNICODE,
    )

    EMAIL_PATTERN = re.compile(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}")
    URL_PATTERN = re.compile(r"(?:https?://)?(?:www\.)?[a-zA-Z0-9][a-zA-Z0-9-]*\.[a-zA-Z]{2,}(?:/[^\s]*)?")

    def __init__(self, max_token_length: int = 255):
        """Initialize tokenizer.

        Args:
            max_token_length: Maximum token length
        """
        self.max_token_length = max_token_length

    def tokenize(self, text: str) -> TokenStream:
        """Tokenize text."""
        tokens = []
        position = 0

        for match in self.WORD_PATTERN.finditer(text):
            token_text = match.group()

            # Skip tokens that are too long
            if len(token_text) > self.max_token_length:
                continue

            # Determine token type
            token_type = self._classify_token(token_text)

            tokens.append(Token(
                text=token_text,
                position=position,
                start_offset=match.start(),
                end_offset=match.end(),
                token_type=token_type,
            ))
            position += 1

        return TokenStream(tokens)

    def _classify_token(self, text: str) -> TokenType:
        """Classify token type."""
        if self.EMAIL_PATTERN.fullmatch(text):
            return TokenType.EMAIL
        if self.URL_PATTERN.fullmatch(text):
            return TokenType.URL
        if text.startswith("#"):
            return TokenType.HASHTAG
        if text.startswith("@"):
            return TokenType.MENTION
        if text.isdigit() or re.match(r"^\d+\.\d+$", text):
            return TokenType.NUMBER
        if any("\u4e00" <= c <= "\u9fff" for c in text):
            return TokenType.CJK
        return TokenType.WORD


class WhitespaceTokenizer(Tokenizer):
    """Simple whitespace tokenizer.

    Splits text on whitespace only, preserving punctuation.
    """

    def tokenize(self, text: str) -> TokenStream:
        """Tokenize text on whitespace."""
        tokens = []
        position = 0
        start = 0
        in_token = False

        for i, char in enumerate(text):
            if char.isspace():
                if in_token:
                    tokens.append(Token(
                        text=text[start:i],
                        position=position,
                        start_offset=start,
                        end_offset=i,
                    ))
                    position += 1
                    in_token = False
            else:
                if not in_token:
                    start = i
                    in_token = True

        # Last token
        if in_token:
            tokens.append(Token(
                text=text[start:],
                position=position,
                start_offset=start,
                end_offset=len(text),
            ))

        return TokenStream(tokens)


class LetterTokenizer(Tokenizer):
    """Letter tokenizer.

    Splits on non-letter characters, producing only letter tokens.
    """

    def tokenize(self, text: str) -> TokenStream:
        """Tokenize text on non-letters."""
        tokens = []
        position = 0
        start = 0
        in_token = False

        for i, char in enumerate(text):
            if char.isalpha():
                if not in_token:
                    start = i
                    in_token = True
            else:
                if in_token:
                    tokens.append(Token(
                        text=text[start:i],
                        position=position,
                        start_offset=start,
                        end_offset=i,
                    ))
                    position += 1
                    in_token = False

        # Last token
        if in_token:
            tokens.append(Token(
                text=text[start:],
                position=position,
                start_offset=start,
                end_offset=len(text),
            ))

        return TokenStream(tokens)


class PatternTokenizer(Tokenizer):
    """Pattern-based tokenizer.

    Uses a regex pattern to split or match tokens.
    """

    def __init__(
        self,
        pattern: str,
        group: int = 0,
        split: bool = False,
    ):
        """Initialize tokenizer.

        Args:
            pattern: Regex pattern
            group: Capture group to use
            split: True to split on pattern, False to match pattern
        """
        self.pattern = re.compile(pattern)
        self.group = group
        self.split = split

    def tokenize(self, text: str) -> TokenStream:
        """Tokenize text using pattern."""
        tokens = []
        position = 0

        if self.split:
            # Split on pattern
            parts = self.pattern.split(text)
            offset = 0
            for part in parts:
                if part:
                    tokens.append(Token(
                        text=part,
                        position=position,
                        start_offset=offset,
                        end_offset=offset + len(part),
                    ))
                    position += 1
                offset += len(part)
        else:
            # Match pattern
            for match in self.pattern.finditer(text):
                try:
                    token_text = match.group(self.group)
                except IndexError:
                    token_text = match.group(0)

                tokens.append(Token(
                    text=token_text,
                    position=position,
                    start_offset=match.start(self.group if self.group else 0),
                    end_offset=match.end(self.group if self.group else 0),
                ))
                position += 1

        return TokenStream(tokens)


class NGramTokenizer(Tokenizer):
    """N-gram tokenizer.

    Produces character n-grams from text.
    """

    def __init__(
        self,
        min_gram: int = 1,
        max_gram: int = 2,
    ):
        """Initialize tokenizer.

        Args:
            min_gram: Minimum n-gram size
            max_gram: Maximum n-gram size
        """
        self.min_gram = min_gram
        self.max_gram = max_gram

    def tokenize(self, text: str) -> TokenStream:
        """Tokenize text into n-grams."""
        tokens = []
        position = 0

        for i in range(len(text)):
            for n in range(self.min_gram, self.max_gram + 1):
                if i + n <= len(text):
                    ngram = text[i:i + n]
                    tokens.append(Token(
                        text=ngram,
                        position=position,
                        start_offset=i,
                        end_offset=i + n,
                    ))
                    position += 1

        return TokenStream(tokens)


class EdgeNGramTokenizer(Tokenizer):
    """Edge n-gram tokenizer.

    Produces n-grams from the beginning of words.
    """

    def __init__(
        self,
        min_gram: int = 1,
        max_gram: int = 10,
    ):
        """Initialize tokenizer.

        Args:
            min_gram: Minimum n-gram size
            max_gram: Maximum n-gram size
        """
        self.min_gram = min_gram
        self.max_gram = max_gram
        self._word_tokenizer = WhitespaceTokenizer()

    def tokenize(self, text: str) -> TokenStream:
        """Tokenize text into edge n-grams."""
        tokens = []
        position = 0

        # First split into words
        word_stream = self._word_tokenizer.tokenize(text)

        for word_token in word_stream:
            word = word_token.text
            for n in range(self.min_gram, min(self.max_gram + 1, len(word) + 1)):
                ngram = word[:n]
                tokens.append(Token(
                    text=ngram,
                    position=position,
                    start_offset=word_token.start_offset,
                    end_offset=word_token.start_offset + n,
                ))
                position += 1

        return TokenStream(tokens)


class PathTokenizer(Tokenizer):
    """File path tokenizer.

    Tokenizes file paths into components.
    """

    def __init__(self, delimiter: str = "/", reverse: bool = False):
        """Initialize tokenizer.

        Args:
            delimiter: Path delimiter
            reverse: Reverse path order
        """
        self.delimiter = delimiter
        self.reverse = reverse

    def tokenize(self, text: str) -> TokenStream:
        """Tokenize path."""
        tokens = []
        parts = text.split(self.delimiter)

        if self.reverse:
            parts = parts[::-1]

        offset = 0
        for position, part in enumerate(parts):
            if part:
                tokens.append(Token(
                    text=part,
                    position=position,
                    start_offset=offset,
                    end_offset=offset + len(part),
                ))
            offset += len(part) + len(self.delimiter)

        return TokenStream(tokens)


class UnicodeTokenizer(Tokenizer):
    """Unicode-aware tokenizer using ICU boundaries.

    Uses Unicode text segmentation rules for proper handling
    of international text.
    """

    def __init__(self, locale: str = "en"):
        """Initialize tokenizer.

        Args:
            locale: Locale for tokenization rules
        """
        self.locale = locale

    def tokenize(self, text: str) -> TokenStream:
        """Tokenize using Unicode rules."""
        tokens = []
        position = 0
        start = 0
        in_word = False

        for i, char in enumerate(text):
            cat = unicodedata.category(char)

            # Word characters: Letters, Numbers, Marks
            is_word_char = cat.startswith(("L", "N", "M"))

            if is_word_char:
                if not in_word:
                    start = i
                    in_word = True
            else:
                if in_word:
                    tokens.append(Token(
                        text=text[start:i],
                        position=position,
                        start_offset=start,
                        end_offset=i,
                    ))
                    position += 1
                    in_word = False

        # Last word
        if in_word:
            tokens.append(Token(
                text=text[start:],
                position=position,
                start_offset=start,
                end_offset=len(text),
            ))

        return TokenStream(tokens)


__all__ = [
    "Tokenizer",
    "StandardTokenizer",
    "WhitespaceTokenizer",
    "LetterTokenizer",
    "PatternTokenizer",
    "NGramTokenizer",
    "EdgeNGramTokenizer",
    "PathTokenizer",
    "UnicodeTokenizer",
]

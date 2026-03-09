"""RoadSearch Standard Analyzers - Pre-configured Analyzers.

Common analyzer configurations for typical use cases.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

from typing import List, Optional, Set

from roadsearch_core.analyzers.base import (
    Analyzer,
    CharacterFilter,
    HTMLCharacterFilter,
    TokenStream,
    register_analyzer,
)
from roadsearch_core.analyzers.tokenizers import (
    StandardTokenizer,
    WhitespaceTokenizer,
    LetterTokenizer,
)
from roadsearch_core.analyzers.filters import (
    LowercaseFilter,
    StopwordFilter,
    StemmerFilter,
    ASCIIFoldingFilter,
)


@register_analyzer("standard")
class StandardAnalyzer(Analyzer):
    """Standard analyzer for general text.

    Uses standard tokenization with lowercase and stopword removal.
    """

    def __init__(
        self,
        stopwords: Optional[Set[str]] = None,
        max_token_length: int = 255,
    ):
        """Initialize standard analyzer.

        Args:
            stopwords: Custom stopword set
            max_token_length: Maximum token length
        """
        super().__init__(
            tokenizer=StandardTokenizer(max_token_length=max_token_length),
            token_filters=[
                LowercaseFilter(),
                StopwordFilter(stopwords=stopwords),
            ],
        )


@register_analyzer("simple")
class SimpleAnalyzer(Analyzer):
    """Simple analyzer with letter tokenization.

    Breaks on non-letters and lowercases.
    """

    def __init__(self):
        """Initialize simple analyzer."""
        super().__init__(
            tokenizer=LetterTokenizer(),
            token_filters=[
                LowercaseFilter(),
            ],
        )


@register_analyzer("whitespace")
class WhitespaceAnalyzer(Analyzer):
    """Whitespace analyzer.

    Splits only on whitespace, preserves case and punctuation.
    """

    def __init__(self):
        """Initialize whitespace analyzer."""
        super().__init__(
            tokenizer=WhitespaceTokenizer(),
        )


@register_analyzer("keyword")
class KeywordAnalyzer(Analyzer):
    """Keyword analyzer.

    Treats entire input as a single token. Useful for exact matching.
    """

    def analyze(self, text: str) -> TokenStream:
        """Return input as single token."""
        from roadsearch_core.analyzers.base import Token
        return TokenStream([Token(
            text=text,
            position=0,
            start_offset=0,
            end_offset=len(text),
        )])


@register_analyzer("stop")
class StopAnalyzer(Analyzer):
    """Stop analyzer.

    Simple analyzer with stopword removal.
    """

    def __init__(self, stopwords: Optional[Set[str]] = None):
        """Initialize stop analyzer.

        Args:
            stopwords: Custom stopword set
        """
        super().__init__(
            tokenizer=LetterTokenizer(),
            token_filters=[
                LowercaseFilter(),
                StopwordFilter(stopwords=stopwords),
            ],
        )


@register_analyzer("snowball")
class SnowballAnalyzer(Analyzer):
    """Snowball analyzer with stemming.

    Standard analyzer with Porter stemmer for better recall.
    """

    def __init__(
        self,
        language: str = "english",
        stopwords: Optional[Set[str]] = None,
    ):
        """Initialize snowball analyzer.

        Args:
            language: Stemmer language
            stopwords: Custom stopword set
        """
        super().__init__(
            tokenizer=StandardTokenizer(),
            token_filters=[
                LowercaseFilter(),
                StopwordFilter(stopwords=stopwords),
                StemmerFilter(language=language),
            ],
        )


@register_analyzer("html")
class HTMLAnalyzer(Analyzer):
    """HTML analyzer.

    Strips HTML tags before analysis.
    """

    def __init__(
        self,
        stopwords: Optional[Set[str]] = None,
    ):
        """Initialize HTML analyzer.

        Args:
            stopwords: Custom stopword set
        """
        super().__init__(
            char_filters=[HTMLCharacterFilter()],
            tokenizer=StandardTokenizer(),
            token_filters=[
                LowercaseFilter(),
                StopwordFilter(stopwords=stopwords),
            ],
        )


@register_analyzer("folding")
class FoldingAnalyzer(Analyzer):
    """Folding analyzer with ASCII conversion.

    Converts accented characters to ASCII for accent-insensitive search.
    """

    def __init__(
        self,
        stopwords: Optional[Set[str]] = None,
    ):
        """Initialize folding analyzer.

        Args:
            stopwords: Custom stopword set
        """
        super().__init__(
            tokenizer=StandardTokenizer(),
            token_filters=[
                LowercaseFilter(),
                ASCIIFoldingFilter(),
                StopwordFilter(stopwords=stopwords),
            ],
        )


@register_analyzer("fingerprint")
class FingerprintAnalyzer(Analyzer):
    """Fingerprint analyzer.

    Produces a consistent fingerprint for duplicate detection.
    Lowercases, removes punctuation, sorts tokens alphabetically.
    """

    def analyze(self, text: str) -> TokenStream:
        """Produce fingerprint token."""
        from roadsearch_core.analyzers.base import Token

        # Tokenize
        standard = StandardAnalyzer()
        stream = standard.analyze(text)

        # Get unique sorted terms
        terms = sorted(set(t.text for t in stream))
        fingerprint = " ".join(terms)

        return TokenStream([Token(
            text=fingerprint,
            position=0,
            start_offset=0,
            end_offset=len(fingerprint),
        )])


class LanguageAnalyzer(Analyzer):
    """Base class for language-specific analyzers."""

    # Language-specific stopwords
    STOPWORDS = {
        "english": StopwordFilter.DEFAULT_STOPWORDS,
        "spanish": frozenset([
            "de", "la", "que", "el", "en", "y", "a", "los", "se", "del",
            "las", "un", "por", "con", "no", "una", "su", "para", "es", "al",
        ]),
        "french": frozenset([
            "le", "de", "la", "et", "les", "des", "en", "un", "du", "une",
            "que", "est", "pour", "qui", "dans", "ce", "il", "sur", "son", "ne",
        ]),
        "german": frozenset([
            "der", "die", "und", "in", "den", "von", "zu", "das", "mit", "sich",
            "des", "auf", "für", "ist", "im", "dem", "nicht", "ein", "eine", "als",
        ]),
    }

    def __init__(self, language: str = "english"):
        """Initialize language analyzer.

        Args:
            language: Language code
        """
        self.language = language
        stopwords = self.STOPWORDS.get(language, set())

        super().__init__(
            tokenizer=StandardTokenizer(),
            token_filters=[
                LowercaseFilter(),
                StopwordFilter(stopwords=stopwords),
                StemmerFilter(language=language),
            ],
        )


@register_analyzer("english")
class EnglishAnalyzer(LanguageAnalyzer):
    """English language analyzer."""

    def __init__(self):
        """Initialize English analyzer."""
        super().__init__(language="english")


@register_analyzer("spanish")
class SpanishAnalyzer(LanguageAnalyzer):
    """Spanish language analyzer."""

    def __init__(self):
        """Initialize Spanish analyzer."""
        super().__init__(language="spanish")


@register_analyzer("french")
class FrenchAnalyzer(LanguageAnalyzer):
    """French language analyzer."""

    def __init__(self):
        """Initialize French analyzer."""
        super().__init__(language="french")


@register_analyzer("german")
class GermanAnalyzer(LanguageAnalyzer):
    """German language analyzer."""

    def __init__(self):
        """Initialize German analyzer."""
        super().__init__(language="german")


__all__ = [
    "StandardAnalyzer",
    "SimpleAnalyzer",
    "WhitespaceAnalyzer",
    "KeywordAnalyzer",
    "StopAnalyzer",
    "SnowballAnalyzer",
    "HTMLAnalyzer",
    "FoldingAnalyzer",
    "FingerprintAnalyzer",
    "LanguageAnalyzer",
    "EnglishAnalyzer",
    "SpanishAnalyzer",
    "FrenchAnalyzer",
    "GermanAnalyzer",
]

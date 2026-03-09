"""RoadSearch Token Filters - Token Transformation Pipeline.

Various filters for transforming, removing, or adding tokens.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import re
from typing import Dict, List, Optional, Set

from roadsearch_core.analyzers.base import (
    TokenFilter,
    Token,
    TokenStream,
    TokenType,
)


class LowercaseFilter(TokenFilter):
    """Converts tokens to lowercase."""

    def filter(self, stream: TokenStream) -> TokenStream:
        """Convert all tokens to lowercase."""
        tokens = []
        for token in stream:
            new_token = token.clone()
            new_token.text = token.text.lower()
            tokens.append(new_token)
        return TokenStream(tokens)


class UppercaseFilter(TokenFilter):
    """Converts tokens to uppercase."""

    def filter(self, stream: TokenStream) -> TokenStream:
        """Convert all tokens to uppercase."""
        tokens = []
        for token in stream:
            new_token = token.clone()
            new_token.text = token.text.upper()
            tokens.append(new_token)
        return TokenStream(tokens)


class StopwordFilter(TokenFilter):
    """Removes common stopwords.

    Stopwords are common words that don't carry significant meaning
    and can be removed to improve search performance.
    """

    # Default English stopwords
    DEFAULT_STOPWORDS = frozenset([
        "a", "an", "and", "are", "as", "at", "be", "but", "by",
        "for", "if", "in", "into", "is", "it", "no", "not", "of",
        "on", "or", "such", "that", "the", "their", "then", "there",
        "these", "they", "this", "to", "was", "will", "with",
    ])

    def __init__(
        self,
        stopwords: Optional[Set[str]] = None,
        ignore_case: bool = True,
    ):
        """Initialize filter.

        Args:
            stopwords: Custom stopword set
            ignore_case: Case-insensitive matching
        """
        self.stopwords = stopwords or self.DEFAULT_STOPWORDS
        self.ignore_case = ignore_case

        if ignore_case:
            self.stopwords = frozenset(w.lower() for w in self.stopwords)

    def filter(self, stream: TokenStream) -> TokenStream:
        """Remove stopwords from stream."""
        tokens = []
        for token in stream:
            check_text = token.text.lower() if self.ignore_case else token.text
            if check_text not in self.stopwords:
                tokens.append(token)
        return TokenStream(tokens)


class StemmerFilter(TokenFilter):
    """Applies stemming to tokens.

    Reduces words to their base form (stem).
    """

    def __init__(self, language: str = "english"):
        """Initialize filter.

        Args:
            language: Stemmer language
        """
        self.language = language
        self._suffixes = self._get_suffixes(language)

    def _get_suffixes(self, language: str) -> List[str]:
        """Get suffix patterns for language."""
        if language == "english":
            return [
                "ational", "tional", "enci", "anci", "izer",
                "isation", "ization", "ation", "ator", "alism",
                "iveness", "fulness", "ousness", "aliti", "iviti",
                "biliti", "alli", "entli", "eli", "ousli",
                "ment", "ness", "ance", "ence", "able", "ible",
                "ant", "ent", "ism", "ate", "iti", "ous",
                "ive", "ize", "ing", "ion", "ful", "ess",
                "ly", "al", "er", "or", "ed", "en", "s",
            ]
        return []

    def filter(self, stream: TokenStream) -> TokenStream:
        """Apply stemming to tokens."""
        tokens = []
        for token in stream:
            new_token = token.clone()
            new_token.text = self._stem(token.text)
            tokens.append(new_token)
        return TokenStream(tokens)

    def _stem(self, word: str) -> str:
        """Simple suffix-stripping stemmer."""
        if len(word) <= 3:
            return word

        word_lower = word.lower()
        for suffix in self._suffixes:
            if word_lower.endswith(suffix):
                stem = word_lower[:-len(suffix)]
                if len(stem) >= 2:
                    return stem

        return word_lower


class SynonymFilter(TokenFilter):
    """Expands tokens with synonyms.

    Adds synonym tokens at same position for synonym matching.
    """

    def __init__(
        self,
        synonyms: Dict[str, List[str]],
        expand: bool = True,
        ignore_case: bool = True,
    ):
        """Initialize filter.

        Args:
            synonyms: Mapping of word -> synonyms
            expand: Add original and synonyms (vs. replace)
            ignore_case: Case-insensitive matching
        """
        self.expand = expand
        self.ignore_case = ignore_case

        if ignore_case:
            self.synonyms = {
                k.lower(): [s.lower() for s in v]
                for k, v in synonyms.items()
            }
        else:
            self.synonyms = synonyms

    def filter(self, stream: TokenStream) -> TokenStream:
        """Expand tokens with synonyms."""
        tokens = []

        for token in stream:
            lookup_text = token.text.lower() if self.ignore_case else token.text

            if lookup_text in self.synonyms:
                if self.expand:
                    # Add original token
                    tokens.append(token)

                # Add synonym tokens
                for synonym in self.synonyms[lookup_text]:
                    syn_token = token.clone()
                    syn_token.text = synonym
                    syn_token.position_increment = 0  # Same position
                    tokens.append(syn_token)
            else:
                tokens.append(token)

        return TokenStream(tokens)


class NGramFilter(TokenFilter):
    """Creates n-grams from tokens.

    Produces character n-grams from each token.
    """

    def __init__(
        self,
        min_gram: int = 1,
        max_gram: int = 2,
    ):
        """Initialize filter.

        Args:
            min_gram: Minimum n-gram size
            max_gram: Maximum n-gram size
        """
        self.min_gram = min_gram
        self.max_gram = max_gram

    def filter(self, stream: TokenStream) -> TokenStream:
        """Create n-grams from tokens."""
        tokens = []

        for token in stream:
            text = token.text
            for n in range(self.min_gram, self.max_gram + 1):
                for i in range(len(text) - n + 1):
                    ngram = text[i:i + n]
                    ngram_token = token.clone()
                    ngram_token.text = ngram
                    ngram_token.start_offset = token.start_offset + i
                    ngram_token.end_offset = token.start_offset + i + n
                    tokens.append(ngram_token)

        return TokenStream(tokens)


class EdgeNGramFilter(TokenFilter):
    """Creates edge n-grams from tokens.

    Produces n-grams from the beginning of each token.
    """

    def __init__(
        self,
        min_gram: int = 1,
        max_gram: int = 10,
        side: str = "front",
    ):
        """Initialize filter.

        Args:
            min_gram: Minimum n-gram size
            max_gram: Maximum n-gram size
            side: "front" or "back"
        """
        self.min_gram = min_gram
        self.max_gram = max_gram
        self.side = side

    def filter(self, stream: TokenStream) -> TokenStream:
        """Create edge n-grams from tokens."""
        tokens = []

        for token in stream:
            text = token.text
            for n in range(self.min_gram, min(self.max_gram + 1, len(text) + 1)):
                if self.side == "front":
                    ngram = text[:n]
                    offset_start = token.start_offset
                    offset_end = token.start_offset + n
                else:
                    ngram = text[-n:]
                    offset_start = token.end_offset - n
                    offset_end = token.end_offset

                ngram_token = token.clone()
                ngram_token.text = ngram
                ngram_token.start_offset = offset_start
                ngram_token.end_offset = offset_end
                tokens.append(ngram_token)

        return TokenStream(tokens)


class LengthFilter(TokenFilter):
    """Filters tokens by length."""

    def __init__(self, min_length: int = 1, max_length: int = 255):
        """Initialize filter.

        Args:
            min_length: Minimum token length
            max_length: Maximum token length
        """
        self.min_length = min_length
        self.max_length = max_length

    def filter(self, stream: TokenStream) -> TokenStream:
        """Filter tokens by length."""
        return TokenStream([
            t for t in stream
            if self.min_length <= len(t.text) <= self.max_length
        ])


class TrimFilter(TokenFilter):
    """Trims whitespace from tokens."""

    def filter(self, stream: TokenStream) -> TokenStream:
        """Trim whitespace from tokens."""
        tokens = []
        for token in stream:
            trimmed = token.text.strip()
            if trimmed:
                new_token = token.clone()
                new_token.text = trimmed
                tokens.append(new_token)
        return TokenStream(tokens)


class PatternReplaceFilter(TokenFilter):
    """Replaces patterns in tokens using regex."""

    def __init__(
        self,
        pattern: str,
        replacement: str,
        all_occurrences: bool = True,
    ):
        """Initialize filter.

        Args:
            pattern: Regex pattern
            replacement: Replacement string
            all_occurrences: Replace all or first only
        """
        self.pattern = re.compile(pattern)
        self.replacement = replacement
        self.all_occurrences = all_occurrences

    def filter(self, stream: TokenStream) -> TokenStream:
        """Apply pattern replacement to tokens."""
        tokens = []
        for token in stream:
            new_token = token.clone()
            if self.all_occurrences:
                new_token.text = self.pattern.sub(self.replacement, token.text)
            else:
                new_token.text = self.pattern.sub(self.replacement, token.text, count=1)
            tokens.append(new_token)
        return TokenStream(tokens)


class ASCIIFoldingFilter(TokenFilter):
    """Converts Unicode characters to ASCII equivalents.

    Useful for accent-insensitive search.
    """

    # Common mappings
    MAPPINGS = {
        "à": "a", "á": "a", "â": "a", "ã": "a", "ä": "a", "å": "a",
        "è": "e", "é": "e", "ê": "e", "ë": "e",
        "ì": "i", "í": "i", "î": "i", "ï": "i",
        "ò": "o", "ó": "o", "ô": "o", "õ": "o", "ö": "o",
        "ù": "u", "ú": "u", "û": "u", "ü": "u",
        "ñ": "n", "ç": "c", "ß": "ss",
    }

    def __init__(self, preserve_original: bool = False):
        """Initialize filter.

        Args:
            preserve_original: Keep original token too
        """
        self.preserve_original = preserve_original

    def filter(self, stream: TokenStream) -> TokenStream:
        """Convert to ASCII."""
        import unicodedata

        tokens = []
        for token in stream:
            if self.preserve_original:
                tokens.append(token)

            # Normalize and fold
            text = token.text
            folded = []
            changed = False

            for char in text:
                if char in self.MAPPINGS:
                    folded.append(self.MAPPINGS[char])
                    changed = True
                elif ord(char) > 127:
                    # Use Unicode normalization
                    normalized = unicodedata.normalize("NFD", char)
                    ascii_char = "".join(c for c in normalized if ord(c) < 128)
                    if ascii_char:
                        folded.append(ascii_char)
                        changed = True
                    else:
                        folded.append(char)
                else:
                    folded.append(char)

            if changed or not self.preserve_original:
                new_token = token.clone()
                new_token.text = "".join(folded)
                if changed and self.preserve_original:
                    new_token.position_increment = 0
                tokens.append(new_token)

        return TokenStream(tokens)


class ElisionFilter(TokenFilter):
    """Removes elisions (contractions with apostrophes).

    For example: "l'école" -> "école"
    """

    def __init__(self, elisions: Optional[Set[str]] = None):
        """Initialize filter.

        Args:
            elisions: Set of elision prefixes
        """
        self.elisions = elisions or {"l", "d", "j", "n", "m", "t", "s", "c", "qu"}

    def filter(self, stream: TokenStream) -> TokenStream:
        """Remove elisions from tokens."""
        tokens = []
        for token in stream:
            text = token.text
            for elision in self.elisions:
                prefix = elision + "'"
                if text.lower().startswith(prefix):
                    new_token = token.clone()
                    new_token.text = text[len(prefix):]
                    tokens.append(new_token)
                    break
            else:
                tokens.append(token)
        return TokenStream(tokens)


class ShingleFilter(TokenFilter):
    """Creates word shingles (phrases).

    Combines adjacent tokens into phrases.
    """

    def __init__(
        self,
        min_shingle_size: int = 2,
        max_shingle_size: int = 2,
        output_unigrams: bool = True,
        token_separator: str = " ",
    ):
        """Initialize filter.

        Args:
            min_shingle_size: Minimum shingle size
            max_shingle_size: Maximum shingle size
            output_unigrams: Include original tokens
            token_separator: Separator between tokens
        """
        self.min_shingle_size = min_shingle_size
        self.max_shingle_size = max_shingle_size
        self.output_unigrams = output_unigrams
        self.token_separator = token_separator

    def filter(self, stream: TokenStream) -> TokenStream:
        """Create shingles from tokens."""
        token_list = list(stream)
        tokens = []

        for i, token in enumerate(token_list):
            if self.output_unigrams:
                tokens.append(token)

            # Create shingles
            for size in range(self.min_shingle_size, self.max_shingle_size + 1):
                if i + size <= len(token_list):
                    shingle_tokens = token_list[i:i + size]
                    shingle_text = self.token_separator.join(
                        t.text for t in shingle_tokens
                    )

                    shingle_token = token.clone()
                    shingle_token.text = shingle_text
                    shingle_token.end_offset = shingle_tokens[-1].end_offset
                    if not self.output_unigrams or i > 0:
                        shingle_token.position_increment = 0
                    tokens.append(shingle_token)

        return TokenStream(tokens)


class KeywordMarkerFilter(TokenFilter):
    """Marks tokens as keywords to prevent further processing.

    Marked tokens will be skipped by stemming and other filters.
    """

    def __init__(self, keywords: Set[str], ignore_case: bool = True):
        """Initialize filter.

        Args:
            keywords: Set of keyword terms
            ignore_case: Case-insensitive matching
        """
        self.ignore_case = ignore_case
        if ignore_case:
            self.keywords = frozenset(k.lower() for k in keywords)
        else:
            self.keywords = frozenset(keywords)

    def filter(self, stream: TokenStream) -> TokenStream:
        """Mark keywords."""
        tokens = []
        for token in stream:
            check_text = token.text.lower() if self.ignore_case else token.text
            new_token = token.clone()
            if check_text in self.keywords:
                new_token.payload = b"keyword"  # Mark as keyword
            tokens.append(new_token)
        return TokenStream(tokens)


class TypeTokenFilter(TokenFilter):
    """Filters tokens by type."""

    def __init__(
        self,
        types: Set[TokenType],
        use_whitelist: bool = True,
    ):
        """Initialize filter.

        Args:
            types: Token types to keep/remove
            use_whitelist: True to keep types, False to remove
        """
        self.types = types
        self.use_whitelist = use_whitelist

    def filter(self, stream: TokenStream) -> TokenStream:
        """Filter tokens by type."""
        if self.use_whitelist:
            return TokenStream([t for t in stream if t.token_type in self.types])
        else:
            return TokenStream([t for t in stream if t.token_type not in self.types])


__all__ = [
    "TokenFilter",
    "LowercaseFilter",
    "UppercaseFilter",
    "StopwordFilter",
    "StemmerFilter",
    "SynonymFilter",
    "NGramFilter",
    "EdgeNGramFilter",
    "LengthFilter",
    "TrimFilter",
    "PatternReplaceFilter",
    "ASCIIFoldingFilter",
    "ElisionFilter",
    "ShingleFilter",
    "KeywordMarkerFilter",
    "TypeTokenFilter",
]

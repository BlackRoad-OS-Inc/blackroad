"""RoadSearch Query Parser - Query DSL Parsing.

Parses query strings into structured query trees for execution.
Supports boolean operators, phrases, wildcards, fuzzy matching, and more.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import re
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Dict, List, Optional, Set, Tuple, Union

logger = logging.getLogger(__name__)


class BooleanOperator(Enum):
    """Boolean query operators."""

    AND = "AND"
    OR = "OR"
    NOT = "NOT"


class QueryType(Enum):
    """Query type enumeration."""

    TERM = auto()
    PHRASE = auto()
    BOOLEAN = auto()
    RANGE = auto()
    WILDCARD = auto()
    FUZZY = auto()
    PREFIX = auto()
    REGEX = auto()
    EXISTS = auto()
    MATCH_ALL = auto()
    MATCH_NONE = auto()


@dataclass
class QueryNode(ABC):
    """Abstract base class for query nodes.

    All query types inherit from this class.
    """

    query_type: QueryType = field(init=False)
    boost: float = 1.0
    field: Optional[str] = None

    @abstractmethod
    def to_string(self) -> str:
        """Convert to query string representation."""
        pass

    @abstractmethod
    def get_terms(self) -> List[str]:
        """Get all terms in this query."""
        pass

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary representation."""
        return {
            "type": self.query_type.name,
            "boost": self.boost,
            "field": self.field,
        }


@dataclass
class TermQuery(QueryNode):
    """Single term query.

    Matches documents containing the specified term.
    """

    term: str = ""

    def __post_init__(self):
        self.query_type = QueryType.TERM

    def to_string(self) -> str:
        """Convert to query string."""
        result = self.term
        if self.field:
            result = f"{self.field}:{result}"
        if self.boost != 1.0:
            result = f"{result}^{self.boost}"
        return result

    def get_terms(self) -> List[str]:
        """Get terms."""
        return [self.term]

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            **super().to_dict(),
            "term": self.term,
        }


@dataclass
class PhraseQuery(QueryNode):
    """Phrase query.

    Matches documents containing exact phrase (terms in order).
    """

    terms: List[str] = field(default_factory=list)
    slop: int = 0  # Maximum distance between terms

    def __post_init__(self):
        self.query_type = QueryType.PHRASE

    def to_string(self) -> str:
        """Convert to query string."""
        phrase = " ".join(self.terms)
        result = f'"{phrase}"'
        if self.slop > 0:
            result = f"{result}~{self.slop}"
        if self.field:
            result = f"{self.field}:{result}"
        if self.boost != 1.0:
            result = f"{result}^{self.boost}"
        return result

    def get_terms(self) -> List[str]:
        """Get terms."""
        return list(self.terms)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            **super().to_dict(),
            "terms": self.terms,
            "slop": self.slop,
        }


@dataclass
class BooleanQuery(QueryNode):
    """Boolean query combining multiple clauses.

    Combines multiple queries with AND, OR, NOT operators.
    """

    must: List[QueryNode] = field(default_factory=list)  # AND
    should: List[QueryNode] = field(default_factory=list)  # OR
    must_not: List[QueryNode] = field(default_factory=list)  # NOT
    minimum_should_match: int = 1

    def __post_init__(self):
        self.query_type = QueryType.BOOLEAN

    def add_must(self, query: QueryNode) -> None:
        """Add a MUST clause."""
        self.must.append(query)

    def add_should(self, query: QueryNode) -> None:
        """Add a SHOULD clause."""
        self.should.append(query)

    def add_must_not(self, query: QueryNode) -> None:
        """Add a MUST NOT clause."""
        self.must_not.append(query)

    def to_string(self) -> str:
        """Convert to query string."""
        parts = []

        for clause in self.must:
            parts.append(f"+{clause.to_string()}")

        for clause in self.should:
            parts.append(clause.to_string())

        for clause in self.must_not:
            parts.append(f"-{clause.to_string()}")

        result = " ".join(parts)
        if self.boost != 1.0:
            result = f"({result})^{self.boost}"
        return result

    def get_terms(self) -> List[str]:
        """Get all terms."""
        terms = []
        for clause in self.must + self.should + self.must_not:
            terms.extend(clause.get_terms())
        return terms

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            **super().to_dict(),
            "must": [c.to_dict() for c in self.must],
            "should": [c.to_dict() for c in self.should],
            "must_not": [c.to_dict() for c in self.must_not],
            "minimum_should_match": self.minimum_should_match,
        }


@dataclass
class RangeQuery(QueryNode):
    """Range query for numeric/date fields.

    Matches documents with field values in specified range.
    """

    gte: Optional[Union[int, float, str, datetime]] = None  # Greater than or equal
    gt: Optional[Union[int, float, str, datetime]] = None  # Greater than
    lte: Optional[Union[int, float, str, datetime]] = None  # Less than or equal
    lt: Optional[Union[int, float, str, datetime]] = None  # Less than
    include_lower: bool = True
    include_upper: bool = True

    def __post_init__(self):
        self.query_type = QueryType.RANGE

    def to_string(self) -> str:
        """Convert to query string."""
        lower = "*"
        upper = "*"

        if self.gte is not None:
            lower = str(self.gte)
        elif self.gt is not None:
            lower = str(self.gt)

        if self.lte is not None:
            upper = str(self.lte)
        elif self.lt is not None:
            upper = str(self.lt)

        lower_bracket = "[" if self.include_lower else "{"
        upper_bracket = "]" if self.include_upper else "}"

        result = f"{lower_bracket}{lower} TO {upper}{upper_bracket}"
        if self.field:
            result = f"{self.field}:{result}"
        return result

    def get_terms(self) -> List[str]:
        """Get terms (ranges have no terms)."""
        return []

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            **super().to_dict(),
            "gte": str(self.gte) if self.gte else None,
            "gt": str(self.gt) if self.gt else None,
            "lte": str(self.lte) if self.lte else None,
            "lt": str(self.lt) if self.lt else None,
        }


@dataclass
class WildcardQuery(QueryNode):
    """Wildcard query.

    Supports * (any characters) and ? (single character).
    """

    pattern: str = ""

    def __post_init__(self):
        self.query_type = QueryType.WILDCARD

    def to_string(self) -> str:
        """Convert to query string."""
        result = self.pattern
        if self.field:
            result = f"{self.field}:{result}"
        return result

    def get_terms(self) -> List[str]:
        """Get base term (without wildcards)."""
        base = self.pattern.replace("*", "").replace("?", "")
        return [base] if base else []

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            **super().to_dict(),
            "pattern": self.pattern,
        }


@dataclass
class FuzzyQuery(QueryNode):
    """Fuzzy query using edit distance.

    Matches terms within specified edit distance.
    """

    term: str = ""
    fuzziness: int = 2  # Maximum edit distance
    prefix_length: int = 0  # Required matching prefix

    def __post_init__(self):
        self.query_type = QueryType.FUZZY

    def to_string(self) -> str:
        """Convert to query string."""
        result = f"{self.term}~{self.fuzziness}"
        if self.field:
            result = f"{self.field}:{result}"
        return result

    def get_terms(self) -> List[str]:
        """Get terms."""
        return [self.term]

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            **super().to_dict(),
            "term": self.term,
            "fuzziness": self.fuzziness,
            "prefix_length": self.prefix_length,
        }


@dataclass
class PrefixQuery(QueryNode):
    """Prefix query.

    Matches terms starting with specified prefix.
    """

    prefix: str = ""

    def __post_init__(self):
        self.query_type = QueryType.PREFIX

    def to_string(self) -> str:
        """Convert to query string."""
        result = f"{self.prefix}*"
        if self.field:
            result = f"{self.field}:{result}"
        return result

    def get_terms(self) -> List[str]:
        """Get terms."""
        return [self.prefix]

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            **super().to_dict(),
            "prefix": self.prefix,
        }


@dataclass
class RegexQuery(QueryNode):
    """Regular expression query.

    Matches terms matching the regex pattern.
    """

    pattern: str = ""
    flags: int = 0

    def __post_init__(self):
        self.query_type = QueryType.REGEX

    def to_string(self) -> str:
        """Convert to query string."""
        result = f"/{self.pattern}/"
        if self.field:
            result = f"{self.field}:{result}"
        return result

    def get_terms(self) -> List[str]:
        """Get terms (regex has no fixed terms)."""
        return []

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            **super().to_dict(),
            "pattern": self.pattern,
            "flags": self.flags,
        }


@dataclass
class ExistsQuery(QueryNode):
    """Exists query.

    Matches documents where field exists and has value.
    """

    def __post_init__(self):
        self.query_type = QueryType.EXISTS

    def to_string(self) -> str:
        """Convert to query string."""
        return f"_exists_:{self.field}"

    def get_terms(self) -> List[str]:
        """Get terms (exists has no terms)."""
        return []


@dataclass
class MatchAllQuery(QueryNode):
    """Match all documents query."""

    def __post_init__(self):
        self.query_type = QueryType.MATCH_ALL

    def to_string(self) -> str:
        """Convert to query string."""
        return "*:*"

    def get_terms(self) -> List[str]:
        """Get terms (match all has no terms)."""
        return []


@dataclass
class MatchNoneQuery(QueryNode):
    """Match no documents query."""

    def __post_init__(self):
        self.query_type = QueryType.MATCH_NONE

    def to_string(self) -> str:
        """Convert to query string."""
        return "-*:*"

    def get_terms(self) -> List[str]:
        """Get terms (match none has no terms)."""
        return []


@dataclass
class ParsedQuery:
    """Result of query parsing.

    Attributes:
        root: Root query node
        original: Original query string
        fields: Fields referenced in query
        terms: All terms in query
        has_boolean: Uses boolean operators
        has_phrase: Contains phrase queries
        has_wildcard: Contains wildcard queries
        has_fuzzy: Contains fuzzy queries
    """

    root: QueryNode
    original: str = ""
    fields: Set[str] = field(default_factory=set)
    terms: List[str] = field(default_factory=list)
    has_boolean: bool = False
    has_phrase: bool = False
    has_wildcard: bool = False
    has_fuzzy: bool = False
    parse_errors: List[str] = field(default_factory=list)

    def __post_init__(self):
        """Extract metadata from root query."""
        self.terms = self.root.get_terms()
        self._analyze_query(self.root)

    def _analyze_query(self, node: QueryNode) -> None:
        """Analyze query structure."""
        if node.field:
            self.fields.add(node.field)

        if isinstance(node, BooleanQuery):
            self.has_boolean = True
            for child in node.must + node.should + node.must_not:
                self._analyze_query(child)
        elif isinstance(node, PhraseQuery):
            self.has_phrase = True
        elif isinstance(node, WildcardQuery):
            self.has_wildcard = True
        elif isinstance(node, FuzzyQuery):
            self.has_fuzzy = True

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            "original": self.original,
            "root": self.root.to_dict(),
            "fields": list(self.fields),
            "terms": self.terms,
            "has_boolean": self.has_boolean,
            "has_phrase": self.has_phrase,
            "has_wildcard": self.has_wildcard,
            "has_fuzzy": self.has_fuzzy,
            "parse_errors": self.parse_errors,
        }


class Token:
    """Lexer token."""

    def __init__(
        self,
        token_type: str,
        value: str,
        position: int,
    ):
        """Initialize token.

        Args:
            token_type: Token type
            value: Token value
            position: Position in input
        """
        self.type = token_type
        self.value = value
        self.position = position

    def __repr__(self) -> str:
        return f"Token({self.type}, {self.value!r})"


class QueryLexer:
    """Lexer for query strings.

    Tokenizes query strings for parsing.
    """

    # Token patterns
    PATTERNS = [
        ("WHITESPACE", r"\s+"),
        ("AND", r"\bAND\b|\&\&"),
        ("OR", r"\bOR\b|\|\|"),
        ("NOT", r"\bNOT\b|\!"),
        ("LPAREN", r"\("),
        ("RPAREN", r"\)"),
        ("LBRACKET", r"\["),
        ("RBRACKET", r"\]"),
        ("LBRACE", r"\{"),
        ("RBRACE", r"\}"),
        ("COLON", r":"),
        ("CARET", r"\^"),
        ("TILDE", r"~"),
        ("PLUS", r"\+"),
        ("MINUS", r"-"),
        ("TO", r"\bTO\b"),
        ("STAR", r"\*"),
        ("QUESTION", r"\?"),
        ("PHRASE", r'"[^"]*"'),
        ("REGEX", r"/[^/]+/"),
        ("TERM", r"[^\s\(\)\[\]\{\}:^~+\-\"\*\?/]+"),
    ]

    def __init__(self):
        """Initialize lexer."""
        # Compile patterns
        self._patterns = [
            (name, re.compile(pattern))
            for name, pattern in self.PATTERNS
        ]

    def tokenize(self, query: str) -> List[Token]:
        """Tokenize query string.

        Args:
            query: Query string

        Returns:
            List of tokens
        """
        tokens = []
        position = 0

        while position < len(query):
            matched = False

            for token_type, pattern in self._patterns:
                match = pattern.match(query, position)
                if match:
                    value = match.group(0)
                    if token_type != "WHITESPACE":  # Skip whitespace
                        tokens.append(Token(token_type, value, position))
                    position = match.end()
                    matched = True
                    break

            if not matched:
                # Skip unknown character
                logger.warning(f"Unknown character at position {position}: {query[position]}")
                position += 1

        return tokens


class QueryParser:
    """Parser for query strings.

    Parses query DSL into structured query trees.

    Query DSL Syntax:
    - term: Single word search
    - "phrase": Exact phrase search
    - field:term: Search in specific field
    - term1 AND term2: Both terms required
    - term1 OR term2: Either term
    - NOT term: Exclude term
    - term~2: Fuzzy search (edit distance)
    - term*: Prefix search
    - te?m: Wildcard search
    - [a TO z]: Range search
    - term^2: Boost term importance
    """

    def __init__(
        self,
        default_field: str = "_all",
        default_operator: BooleanOperator = BooleanOperator.OR,
        allow_leading_wildcard: bool = False,
        fuzzy_prefix_length: int = 0,
        phrase_slop: int = 0,
    ):
        """Initialize parser.

        Args:
            default_field: Default search field
            default_operator: Default boolean operator
            allow_leading_wildcard: Allow wildcards at start
            fuzzy_prefix_length: Required prefix for fuzzy
            phrase_slop: Default phrase slop
        """
        self.default_field = default_field
        self.default_operator = default_operator
        self.allow_leading_wildcard = allow_leading_wildcard
        self.fuzzy_prefix_length = fuzzy_prefix_length
        self.phrase_slop = phrase_slop

        self._lexer = QueryLexer()
        self._tokens: List[Token] = []
        self._position = 0
        self._errors: List[str] = []

    def parse(self, query: str) -> ParsedQuery:
        """Parse query string.

        Args:
            query: Query string

        Returns:
            Parsed query
        """
        if not query or query.strip() == "*":
            return ParsedQuery(
                root=MatchAllQuery(),
                original=query,
            )

        self._tokens = self._lexer.tokenize(query)
        self._position = 0
        self._errors = []

        try:
            root = self._parse_expression()
        except Exception as e:
            logger.error(f"Query parse error: {e}")
            self._errors.append(str(e))
            # Fall back to simple term query
            root = TermQuery(term=query, field=self.default_field)

        return ParsedQuery(
            root=root,
            original=query,
            parse_errors=self._errors,
        )

    def _current_token(self) -> Optional[Token]:
        """Get current token."""
        if self._position < len(self._tokens):
            return self._tokens[self._position]
        return None

    def _peek_token(self, offset: int = 1) -> Optional[Token]:
        """Peek at token ahead."""
        pos = self._position + offset
        if pos < len(self._tokens):
            return self._tokens[pos]
        return None

    def _advance(self) -> Optional[Token]:
        """Advance to next token."""
        token = self._current_token()
        self._position += 1
        return token

    def _expect(self, token_type: str) -> Token:
        """Expect specific token type."""
        token = self._current_token()
        if not token or token.type != token_type:
            raise ValueError(f"Expected {token_type}, got {token}")
        return self._advance()

    def _parse_expression(self) -> QueryNode:
        """Parse a query expression."""
        return self._parse_or_expression()

    def _parse_or_expression(self) -> QueryNode:
        """Parse OR expression."""
        left = self._parse_and_expression()

        while self._current_token() and self._current_token().type == "OR":
            self._advance()  # Consume OR
            right = self._parse_and_expression()

            if isinstance(left, BooleanQuery) and left.must == [] and left.must_not == []:
                left.add_should(right)
            else:
                bool_query = BooleanQuery()
                bool_query.add_should(left)
                bool_query.add_should(right)
                left = bool_query

        return left

    def _parse_and_expression(self) -> QueryNode:
        """Parse AND expression."""
        left = self._parse_not_expression()

        while self._current_token() and self._current_token().type == "AND":
            self._advance()  # Consume AND
            right = self._parse_not_expression()

            if isinstance(left, BooleanQuery):
                left.add_must(right)
            else:
                bool_query = BooleanQuery()
                bool_query.add_must(left)
                bool_query.add_must(right)
                left = bool_query

        return left

    def _parse_not_expression(self) -> QueryNode:
        """Parse NOT expression."""
        if self._current_token() and self._current_token().type == "NOT":
            self._advance()  # Consume NOT
            operand = self._parse_clause()

            bool_query = BooleanQuery()
            bool_query.add_must_not(operand)
            bool_query.add_must(MatchAllQuery())  # Match all except NOT terms
            return bool_query

        return self._parse_clause()

    def _parse_clause(self) -> QueryNode:
        """Parse a single clause."""
        token = self._current_token()
        if not token:
            return MatchAllQuery()

        # Handle modifiers
        boost = 1.0
        required = False
        prohibited = False

        if token.type == "PLUS":
            self._advance()
            required = True
            token = self._current_token()
        elif token.type == "MINUS":
            self._advance()
            prohibited = True
            token = self._current_token()

        if not token:
            return MatchAllQuery()

        # Handle parentheses
        if token.type == "LPAREN":
            self._advance()
            query = self._parse_expression()
            if self._current_token() and self._current_token().type == "RPAREN":
                self._advance()
            return query

        # Parse primary
        query = self._parse_primary()

        # Handle boost
        if self._current_token() and self._current_token().type == "CARET":
            self._advance()
            boost_token = self._current_token()
            if boost_token and boost_token.type == "TERM":
                try:
                    boost = float(boost_token.value)
                    self._advance()
                except ValueError:
                    pass
            query.boost = boost

        # Wrap in boolean if required/prohibited
        if required or prohibited:
            bool_query = BooleanQuery()
            if required:
                bool_query.add_must(query)
            else:
                bool_query.add_must_not(query)
                bool_query.add_must(MatchAllQuery())
            return bool_query

        return query

    def _parse_primary(self) -> QueryNode:
        """Parse primary query (term, phrase, etc.)."""
        token = self._current_token()
        if not token:
            return MatchAllQuery()

        # Handle phrase
        if token.type == "PHRASE":
            self._advance()
            phrase_text = token.value[1:-1]  # Remove quotes
            terms = phrase_text.split()

            query = PhraseQuery(terms=terms, slop=self.phrase_slop)

            # Check for slop
            if self._current_token() and self._current_token().type == "TILDE":
                self._advance()
                slop_token = self._current_token()
                if slop_token and slop_token.type == "TERM":
                    try:
                        query.slop = int(slop_token.value)
                        self._advance()
                    except ValueError:
                        pass

            return query

        # Handle regex
        if token.type == "REGEX":
            self._advance()
            pattern = token.value[1:-1]  # Remove slashes
            return RegexQuery(pattern=pattern)

        # Handle range
        if token.type == "LBRACKET" or token.type == "LBRACE":
            return self._parse_range()

        # Handle field:value or term
        if token.type == "TERM":
            term_value = token.value
            self._advance()

            # Check for field prefix
            field = self.default_field
            if self._current_token() and self._current_token().type == "COLON":
                self._advance()
                field = term_value
                next_token = self._current_token()

                if next_token:
                    if next_token.type == "PHRASE":
                        self._advance()
                        phrase_text = next_token.value[1:-1]
                        query = PhraseQuery(terms=phrase_text.split(), field=field)
                        return query
                    elif next_token.type == "LBRACKET" or next_token.type == "LBRACE":
                        query = self._parse_range()
                        query.field = field
                        return query
                    elif next_token.type == "TERM":
                        term_value = next_token.value
                        self._advance()
                    elif next_token.type == "STAR":
                        term_value = "*"
                        self._advance()
                    else:
                        term_value = ""

            # Check for wildcards
            if "*" in term_value or "?" in term_value:
                if not self.allow_leading_wildcard and term_value.startswith(("*", "?")):
                    self._errors.append("Leading wildcard not allowed")
                return WildcardQuery(pattern=term_value, field=field)

            # Check for fuzzy
            if self._current_token() and self._current_token().type == "TILDE":
                self._advance()
                fuzziness = 2
                fuzzy_token = self._current_token()
                if fuzzy_token and fuzzy_token.type == "TERM":
                    try:
                        fuzziness = int(fuzzy_token.value)
                        self._advance()
                    except ValueError:
                        pass
                return FuzzyQuery(
                    term=term_value,
                    field=field,
                    fuzziness=fuzziness,
                    prefix_length=self.fuzzy_prefix_length,
                )

            # Regular term
            return TermQuery(term=term_value, field=field)

        # Handle standalone star
        if token.type == "STAR":
            self._advance()
            return MatchAllQuery()

        # Unknown token
        self._advance()
        return TermQuery(term=token.value, field=self.default_field)

    def _parse_range(self) -> RangeQuery:
        """Parse range query."""
        token = self._current_token()
        include_lower = token.type == "LBRACKET"
        self._advance()

        # Get lower bound
        lower = None
        if self._current_token() and self._current_token().type != "TO":
            if self._current_token().type == "STAR":
                self._advance()
            else:
                lower_token = self._advance()
                if lower_token:
                    lower = lower_token.value

        # Expect TO
        if self._current_token() and self._current_token().type == "TO":
            self._advance()

        # Get upper bound
        upper = None
        if self._current_token() and self._current_token().type not in ("RBRACKET", "RBRACE"):
            if self._current_token().type == "STAR":
                self._advance()
            else:
                upper_token = self._advance()
                if upper_token:
                    upper = upper_token.value

        # Expect closing bracket
        include_upper = True
        if self._current_token():
            include_upper = self._current_token().type == "RBRACKET"
            self._advance()

        query = RangeQuery(include_lower=include_lower, include_upper=include_upper)

        if lower:
            if include_lower:
                query.gte = lower
            else:
                query.gt = lower

        if upper:
            if include_upper:
                query.lte = upper
            else:
                query.lt = upper

        return query


__all__ = [
    "QueryParser",
    "ParsedQuery",
    "QueryNode",
    "BooleanQuery",
    "TermQuery",
    "PhraseQuery",
    "RangeQuery",
    "WildcardQuery",
    "FuzzyQuery",
    "PrefixQuery",
    "RegexQuery",
    "ExistsQuery",
    "MatchAllQuery",
    "MatchNoneQuery",
    "BooleanOperator",
    "QueryType",
    "QueryLexer",
    "Token",
]

"""
RoadTemplate - Template Engine for BlackRoad
Template rendering with variables, conditionals, loops, and inheritance.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Tuple
import html
import json
import logging
import re
import threading

logger = logging.getLogger(__name__)


class TemplateError(Exception):
    """Template error."""
    pass


class TokenType(str, Enum):
    """Token types."""
    TEXT = "text"
    VARIABLE = "variable"
    BLOCK_START = "block_start"
    BLOCK_END = "block_end"
    COMMENT = "comment"


@dataclass
class Token:
    """A template token."""
    type: TokenType
    value: str
    line: int = 0


@dataclass
class TemplateNode:
    """Base template node."""
    pass


@dataclass
class TextNode(TemplateNode):
    """Text node."""
    content: str


@dataclass
class VariableNode(TemplateNode):
    """Variable node."""
    name: str
    filters: List[str] = field(default_factory=list)


@dataclass
class BlockNode(TemplateNode):
    """Block node (if, for, etc)."""
    block_type: str
    expression: str
    children: List[TemplateNode] = field(default_factory=list)
    else_children: List[TemplateNode] = field(default_factory=list)


class TemplateLexer:
    """Tokenize template strings."""

    VARIABLE_START = "{{"
    VARIABLE_END = "}}"
    BLOCK_START = "{%"
    BLOCK_END = "%}"
    COMMENT_START = "{#"
    COMMENT_END = "#}"

    def __init__(self, template: str):
        self.template = template
        self.pos = 0
        self.line = 1

    def tokenize(self) -> List[Token]:
        """Tokenize the template."""
        tokens = []

        while self.pos < len(self.template):
            if self.template[self.pos:].startswith(self.COMMENT_START):
                self._skip_comment()
            elif self.template[self.pos:].startswith(self.VARIABLE_START):
                tokens.append(self._read_variable())
            elif self.template[self.pos:].startswith(self.BLOCK_START):
                tokens.append(self._read_block())
            else:
                tokens.append(self._read_text())

        return tokens

    def _read_text(self) -> Token:
        """Read text content."""
        start = self.pos
        while self.pos < len(self.template):
            if any(self.template[self.pos:].startswith(s) for s in
                   [self.VARIABLE_START, self.BLOCK_START, self.COMMENT_START]):
                break
            if self.template[self.pos] == '\n':
                self.line += 1
            self.pos += 1

        return Token(TokenType.TEXT, self.template[start:self.pos], self.line)

    def _read_variable(self) -> Token:
        """Read variable expression."""
        self.pos += len(self.VARIABLE_START)
        start = self.pos

        while self.pos < len(self.template):
            if self.template[self.pos:].startswith(self.VARIABLE_END):
                value = self.template[start:self.pos].strip()
                self.pos += len(self.VARIABLE_END)
                return Token(TokenType.VARIABLE, value, self.line)
            self.pos += 1

        raise TemplateError(f"Unclosed variable at line {self.line}")

    def _read_block(self) -> Token:
        """Read block tag."""
        self.pos += len(self.BLOCK_START)
        start = self.pos

        while self.pos < len(self.template):
            if self.template[self.pos:].startswith(self.BLOCK_END):
                value = self.template[start:self.pos].strip()
                self.pos += len(self.BLOCK_END)

                if value.startswith("end"):
                    return Token(TokenType.BLOCK_END, value, self.line)
                return Token(TokenType.BLOCK_START, value, self.line)
            self.pos += 1

        raise TemplateError(f"Unclosed block at line {self.line}")

    def _skip_comment(self) -> None:
        """Skip comment."""
        self.pos += len(self.COMMENT_START)
        while self.pos < len(self.template):
            if self.template[self.pos:].startswith(self.COMMENT_END):
                self.pos += len(self.COMMENT_END)
                return
            if self.template[self.pos] == '\n':
                self.line += 1
            self.pos += 1


class TemplateParser:
    """Parse tokens into AST."""

    def __init__(self, tokens: List[Token]):
        self.tokens = tokens
        self.pos = 0

    def parse(self) -> List[TemplateNode]:
        """Parse tokens into nodes."""
        return self._parse_nodes()

    def _parse_nodes(self, end_tags: Set[str] = None) -> List[TemplateNode]:
        """Parse a sequence of nodes."""
        end_tags = end_tags or set()
        nodes = []

        while self.pos < len(self.tokens):
            token = self.tokens[self.pos]

            if token.type == TokenType.BLOCK_END:
                if token.value in end_tags:
                    return nodes
                self.pos += 1
                continue

            if token.type == TokenType.TEXT:
                nodes.append(TextNode(content=token.value))
                self.pos += 1

            elif token.type == TokenType.VARIABLE:
                nodes.append(self._parse_variable(token))
                self.pos += 1

            elif token.type == TokenType.BLOCK_START:
                nodes.append(self._parse_block(token))

            else:
                self.pos += 1

        return nodes

    def _parse_variable(self, token: Token) -> VariableNode:
        """Parse variable with filters."""
        parts = token.value.split("|")
        name = parts[0].strip()
        filters = [f.strip() for f in parts[1:]]
        return VariableNode(name=name, filters=filters)

    def _parse_block(self, token: Token) -> BlockNode:
        """Parse a block tag."""
        self.pos += 1
        parts = token.value.split(None, 1)
        block_type = parts[0]
        expression = parts[1] if len(parts) > 1 else ""

        if block_type == "if":
            return self._parse_if(expression)
        elif block_type == "for":
            return self._parse_for(expression)
        elif block_type == "block":
            return self._parse_named_block(expression)
        else:
            return BlockNode(block_type=block_type, expression=expression)

    def _parse_if(self, expression: str) -> BlockNode:
        """Parse if block."""
        node = BlockNode(block_type="if", expression=expression)
        node.children = self._parse_nodes({"endif", "else", "elif"})

        while self.pos < len(self.tokens):
            token = self.tokens[self.pos]
            if token.type == TokenType.BLOCK_END:
                if token.value == "endif":
                    self.pos += 1
                    break
                elif token.value == "else":
                    self.pos += 1
                    node.else_children = self._parse_nodes({"endif"})
                elif token.value.startswith("elif"):
                    # Handle elif as nested if in else
                    pass
            self.pos += 1

        return node

    def _parse_for(self, expression: str) -> BlockNode:
        """Parse for loop."""
        node = BlockNode(block_type="for", expression=expression)
        node.children = self._parse_nodes({"endfor", "else"})

        while self.pos < len(self.tokens):
            token = self.tokens[self.pos]
            if token.type == TokenType.BLOCK_END:
                if token.value == "endfor":
                    self.pos += 1
                    break
                elif token.value == "else":
                    self.pos += 1
                    node.else_children = self._parse_nodes({"endfor"})
            self.pos += 1

        return node

    def _parse_named_block(self, name: str) -> BlockNode:
        """Parse named block for inheritance."""
        node = BlockNode(block_type="block", expression=name)
        node.children = self._parse_nodes({"endblock"})

        if self.pos < len(self.tokens):
            self.pos += 1

        return node


class TemplateContext:
    """Template rendering context."""

    def __init__(self, data: Dict[str, Any] = None):
        self.stack: List[Dict[str, Any]] = [data or {}]

    def push(self, data: Dict[str, Any]) -> None:
        """Push new scope."""
        self.stack.append(data)

    def pop(self) -> None:
        """Pop scope."""
        if len(self.stack) > 1:
            self.stack.pop()

    def get(self, name: str) -> Any:
        """Get variable from context."""
        parts = name.split(".")

        # Search stack from top to bottom
        for scope in reversed(self.stack):
            value = scope
            try:
                for part in parts:
                    if isinstance(value, dict):
                        value = value.get(part)
                    elif hasattr(value, part):
                        value = getattr(value, part)
                    else:
                        value = None
                        break
                if value is not None:
                    return value
            except (KeyError, AttributeError, TypeError):
                continue

        return None

    def set(self, name: str, value: Any) -> None:
        """Set variable in current scope."""
        self.stack[-1][name] = value


class TemplateFilters:
    """Built-in template filters."""

    @staticmethod
    def escape(value: Any) -> str:
        """HTML escape."""
        return html.escape(str(value))

    @staticmethod
    def upper(value: Any) -> str:
        """Uppercase."""
        return str(value).upper()

    @staticmethod
    def lower(value: Any) -> str:
        """Lowercase."""
        return str(value).lower()

    @staticmethod
    def title(value: Any) -> str:
        """Title case."""
        return str(value).title()

    @staticmethod
    def trim(value: Any) -> str:
        """Trim whitespace."""
        return str(value).strip()

    @staticmethod
    def default(value: Any, default_value: str = "") -> str:
        """Default value if None/empty."""
        return str(value) if value else default_value

    @staticmethod
    def length(value: Any) -> int:
        """Get length."""
        return len(value) if value else 0

    @staticmethod
    def join(value: List, separator: str = ", ") -> str:
        """Join list."""
        return separator.join(str(v) for v in value)

    @staticmethod
    def first(value: List) -> Any:
        """Get first item."""
        return value[0] if value else None

    @staticmethod
    def last(value: List) -> Any:
        """Get last item."""
        return value[-1] if value else None

    @staticmethod
    def json(value: Any) -> str:
        """JSON encode."""
        return json.dumps(value)

    @staticmethod
    def date(value: datetime, fmt: str = "%Y-%m-%d") -> str:
        """Format date."""
        if isinstance(value, datetime):
            return value.strftime(fmt)
        return str(value)


class TemplateRenderer:
    """Render template AST."""

    def __init__(self):
        self.filters: Dict[str, Callable] = {
            "escape": TemplateFilters.escape,
            "e": TemplateFilters.escape,
            "upper": TemplateFilters.upper,
            "lower": TemplateFilters.lower,
            "title": TemplateFilters.title,
            "trim": TemplateFilters.trim,
            "default": TemplateFilters.default,
            "length": TemplateFilters.length,
            "join": TemplateFilters.join,
            "first": TemplateFilters.first,
            "last": TemplateFilters.last,
            "json": TemplateFilters.json,
            "date": TemplateFilters.date
        }

    def add_filter(self, name: str, fn: Callable) -> None:
        """Add custom filter."""
        self.filters[name] = fn

    def render(self, nodes: List[TemplateNode], context: TemplateContext) -> str:
        """Render nodes to string."""
        output = []

        for node in nodes:
            if isinstance(node, TextNode):
                output.append(node.content)
            elif isinstance(node, VariableNode):
                output.append(self._render_variable(node, context))
            elif isinstance(node, BlockNode):
                output.append(self._render_block(node, context))

        return "".join(output)

    def _render_variable(self, node: VariableNode, context: TemplateContext) -> str:
        """Render a variable."""
        value = context.get(node.name)

        for filter_name in node.filters:
            filter_fn = self.filters.get(filter_name)
            if filter_fn:
                value = filter_fn(value)

        return str(value) if value is not None else ""

    def _render_block(self, node: BlockNode, context: TemplateContext) -> str:
        """Render a block."""
        if node.block_type == "if":
            return self._render_if(node, context)
        elif node.block_type == "for":
            return self._render_for(node, context)
        elif node.block_type == "block":
            return self.render(node.children, context)
        return ""

    def _render_if(self, node: BlockNode, context: TemplateContext) -> str:
        """Render if block."""
        condition = self._evaluate_condition(node.expression, context)

        if condition:
            return self.render(node.children, context)
        elif node.else_children:
            return self.render(node.else_children, context)
        return ""

    def _evaluate_condition(self, expression: str, context: TemplateContext) -> bool:
        """Evaluate a condition expression."""
        # Simple evaluation - in production use a proper expression parser
        parts = expression.split()

        if len(parts) == 1:
            value = context.get(parts[0])
            return bool(value)

        if len(parts) == 3:
            left = context.get(parts[0]) or parts[0]
            op = parts[1]
            right = context.get(parts[2]) or parts[2]

            # Strip quotes from string literals
            if isinstance(right, str) and right.startswith('"') and right.endswith('"'):
                right = right[1:-1]

            if op == "==":
                return left == right
            elif op == "!=":
                return left != right
            elif op == ">":
                return left > right
            elif op == "<":
                return left < right
            elif op == ">=":
                return left >= right
            elif op == "<=":
                return left <= right

        return bool(context.get(expression))

    def _render_for(self, node: BlockNode, context: TemplateContext) -> str:
        """Render for loop."""
        # Parse expression: "item in items"
        match = re.match(r'(\w+)\s+in\s+(\w+)', node.expression)
        if not match:
            return ""

        var_name = match.group(1)
        iterable_name = match.group(2)
        iterable = context.get(iterable_name)

        if not iterable:
            return self.render(node.else_children, context) if node.else_children else ""

        output = []
        for i, item in enumerate(iterable):
            context.push({
                var_name: item,
                "loop": {
                    "index": i + 1,
                    "index0": i,
                    "first": i == 0,
                    "last": i == len(iterable) - 1,
                    "length": len(iterable)
                }
            })
            output.append(self.render(node.children, context))
            context.pop()

        return "".join(output)


class Template:
    """A compiled template."""

    def __init__(self, source: str, name: str = None):
        self.source = source
        self.name = name or "template"
        self.nodes: List[TemplateNode] = []
        self._compile()

    def _compile(self) -> None:
        """Compile the template."""
        lexer = TemplateLexer(self.source)
        tokens = lexer.tokenize()
        parser = TemplateParser(tokens)
        self.nodes = parser.parse()

    def render(self, data: Dict[str, Any] = None, renderer: TemplateRenderer = None) -> str:
        """Render the template."""
        renderer = renderer or TemplateRenderer()
        context = TemplateContext(data or {})
        return renderer.render(self.nodes, context)


class TemplateLoader:
    """Load templates from various sources."""

    def __init__(self, search_paths: List[str] = None):
        self.search_paths = search_paths or ["."]
        self.cache: Dict[str, Template] = {}
        self._lock = threading.Lock()

    def load(self, name: str) -> Template:
        """Load a template by name."""
        with self._lock:
            if name in self.cache:
                return self.cache[name]

        # In production, search file system
        # For now, return None
        raise TemplateError(f"Template not found: {name}")

    def from_string(self, source: str, name: str = None) -> Template:
        """Create template from string."""
        template = Template(source, name)
        if name:
            with self._lock:
                self.cache[name] = template
        return template


class TemplateEngine:
    """High-level template engine."""

    def __init__(self):
        self.loader = TemplateLoader()
        self.renderer = TemplateRenderer()
        self.globals: Dict[str, Any] = {}

    def add_global(self, name: str, value: Any) -> None:
        """Add global variable."""
        self.globals[name] = value

    def add_filter(self, name: str, fn: Callable) -> None:
        """Add custom filter."""
        self.renderer.add_filter(name, fn)

    def render_string(self, source: str, data: Dict[str, Any] = None) -> str:
        """Render template string."""
        template = self.loader.from_string(source)
        merged_data = {**self.globals, **(data or {})}
        return template.render(merged_data, self.renderer)

    def render(self, template_name: str, data: Dict[str, Any] = None) -> str:
        """Render named template."""
        template = self.loader.load(template_name)
        merged_data = {**self.globals, **(data or {})}
        return template.render(merged_data, self.renderer)


# Example usage
def example_usage():
    """Example template usage."""
    engine = TemplateEngine()

    # Add global
    engine.add_global("site_name", "BlackRoad")

    # Simple variable
    result = engine.render_string("Hello, {{ name }}!", {"name": "World"})
    print(result)

    # Filters
    result = engine.render_string(
        "{{ message | upper | trim }}",
        {"message": "  hello world  "}
    )
    print(result)

    # Conditionals
    template = """
{% if user.admin %}
Welcome, Admin {{ user.name }}!
{% else %}
Welcome, {{ user.name }}!
{% endif %}
"""
    result = engine.render_string(template, {"user": {"name": "Alice", "admin": True}})
    print(result.strip())

    # Loops
    template = """
<ul>
{% for item in items %}
<li>{{ loop.index }}. {{ item.name }} - ${{ item.price }}</li>
{% endfor %}
</ul>
"""
    result = engine.render_string(template, {
        "items": [
            {"name": "Widget", "price": 9.99},
            {"name": "Gadget", "price": 19.99}
        ]
    })
    print(result)

    # Nested access
    result = engine.render_string(
        "{{ user.profile.email }}",
        {"user": {"profile": {"email": "test@example.com"}}}
    )
    print(result)


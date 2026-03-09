# blackroad-xml-parser

**BlackRoad XML Parser** — parse, validate, XPath query, transform to JSON, and diff XML/RSS/Atom documents.

## Features

- 📄 **Multi-format parsing** — XML, RSS 2.0, Atom feeds with auto-detection
- 🔍 **XPath queries** — ElementTree-based queries with result history
- ✅ **Schema validation** — rules: required_element, attribute_required, text_pattern, max_occurrences
- 🔄 **JSON transformation** — structured tree, flattened rows, RSS/Atom feed normalization
- ↔️ **Document diffing** — tree-level diff showing added/removed/modified elements
- 🔖 **Namespace extraction** — automatic xmlns prefix/URI mapping
- 💾 **SQLite persistence** — 4-table schema for docs, rules, XPath history, transforms
- 🎨 **ANSI CLI** — 6 subcommands with color output

## Install

```bash
pip install pytest pytest-cov
```

## Usage

```bash
# Parse documents
python src/xml_parser.py parse '<catalog><book id="1"><title>Test</title></book></catalog>' --name catalog
python src/xml_parser.py parse feed.rss --file --name my-feed

# XPath queries
python src/xml_parser.py xpath catalog ".//book"
python src/xml_parser.py xpath catalog ".//title" --limit 10

# Transform to JSON
python src/xml_parser.py transform catalog --output catalog.json
python src/xml_parser.py transform my-feed  # auto-detects RSS/Atom

# Schema validation
python src/xml_parser.py validate catalog

# Diff two documents
python src/xml_parser.py diff catalog catalog-v2 --verbose

# List all documents
python src/xml_parser.py list
```

## Testing

```bash
pytest tests/ -v --cov=src --cov-report=term-missing
```

## License

Proprietary — BlackRoad OS, Inc.

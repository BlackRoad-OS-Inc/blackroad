"""Tests for BlackRoad XML Parser."""
import os
import sys
import json
import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))
from xml_parser import XMLDB, XMLParser, DiffResult


SAMPLE_XML = """<?xml version="1.0"?>
<catalog>
    <book id="bk101" lang="en">
        <author>Gambardella, Matthew</author>
        <title>XML Developer's Guide</title>
        <genre>Computer</genre>
        <price>44.95</price>
        <publish_date>2000-10-01</publish_date>
    </book>
    <book id="bk102" lang="fr">
        <author>Ralls, Kim</author>
        <title>Midnight Rain</title>
        <genre>Fantasy</genre>
        <price>5.95</price>
        <publish_date>2000-12-16</publish_date>
    </book>
</catalog>"""

RSS_XML = """<?xml version="1.0"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <link>https://example.com</link>
    <description>Test RSS feed</description>
    <item>
      <title>Item 1</title>
      <link>https://example.com/1</link>
      <description>First item</description>
      <guid>item-1</guid>
    </item>
    <item>
      <title>Item 2</title>
      <link>https://example.com/2</link>
      <description>Second item</description>
    </item>
  </channel>
</rss>"""


@pytest.fixture
def parser(tmp_path):
    db = XMLDB(db_path=str(tmp_path / "test_xml.db"))
    return XMLParser(db)


def test_parse_xml(parser):
    doc = parser.parse(SAMPLE_XML, name="catalog")
    assert doc.name == "catalog"
    assert doc.doc_type == "xml"
    assert doc.element_count > 0
    assert doc.depth >= 2


def test_parse_rss(parser):
    doc = parser.parse(RSS_XML, name="test-rss")
    assert doc.doc_type == "rss"
    assert doc.element_count > 0


def test_parse_invalid_xml(parser):
    with pytest.raises(ValueError, match="XML parse error"):
        parser.parse("<broken><xml>", name="bad")


def test_xpath_query(parser):
    doc = parser.parse(SAMPLE_XML, name="xpath-test")
    result = parser.xpath_query(doc.id, ".//book")
    assert result.match_count == 2
    assert result.matches[0]["tag"] == "book"


def test_xpath_with_filter(parser):
    doc = parser.parse(SAMPLE_XML, name="xpath-filter")
    result = parser.xpath_query(doc.id, ".//title")
    assert result.match_count == 2


def test_transform_to_json_xml(parser):
    doc = parser.parse(SAMPLE_XML, name="transform-xml")
    result = parser.transform_to_json(doc.id)
    assert result.format_out == "json"
    assert isinstance(result.content, dict)
    assert result.content["tag"] == "catalog"


def test_transform_rss(parser):
    doc = parser.parse(RSS_XML, name="transform-rss")
    result = parser.transform_to_json(doc.id)
    assert result.content["type"] == "rss"
    assert result.content["title"] == "Test Feed"
    assert result.content["item_count"] == 2
    assert len(result.content["items"]) == 2


def test_schema_validation(parser):
    doc = parser.parse(SAMPLE_XML, name="validate-xml")
    parser.add_schema_rule("has-catalog", "required_element", ".", "exists")
    parser.add_schema_rule("has-books", "required_element", ".//book", "exists")
    parser.add_schema_rule("no-video", "required_element", ".//video", "exists",
                           required=False)
    result = parser.validate_schema(doc.id)
    assert "violations" in result
    assert "rules_checked" in result


def test_diff_identical_documents(parser):
    doc_a = parser.parse(SAMPLE_XML, name="diff-a")
    doc_b = parser.parse(SAMPLE_XML, name="diff-b")
    result = parser.diff_documents(doc_a.id, doc_b.id)
    assert len(result.added) == 0
    assert len(result.removed) == 0
    assert len(result.modified) == 0


def test_diff_different_documents(parser):
    xml_b = SAMPLE_XML.replace("44.95", "49.99").replace("XML Developer's Guide", "Advanced XML")
    doc_a = parser.parse(SAMPLE_XML, name="orig")
    doc_b = parser.parse(xml_b, name="modified")
    result = parser.diff_documents(doc_a.id, doc_b.id)
    assert result.total_changes > 0
    assert isinstance(result.modified, list)


def test_flatten_transform(parser):
    doc = parser.parse(SAMPLE_XML, name="flat-xml")
    result = parser.transform_to_json(doc.id, flatten=True)
    assert isinstance(result.content, list)
    assert all("tag" in item for item in result.content)


def test_list_documents(parser):
    parser.parse(SAMPLE_XML, name="list-test-1")
    parser.parse(RSS_XML, name="list-test-2")
    docs = parser.list_documents()
    names = [d["name"] for d in docs]
    assert "list-test-1" in names
    assert "list-test-2" in names

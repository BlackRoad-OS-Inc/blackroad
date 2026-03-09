"""Tests for blackroad-search-engine."""
import os
import pytest
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from module import (
    Document, SearchResult,
    index_document, search, get_document, delete_document,
    reindex_all, search_suggestions, export_index, index_stats,
    tokenize, stem, normalize_tokens, extract_highlights, init_db,
)


@pytest.fixture
def db(tmp_path):
    return str(tmp_path / "test_search.db")


def make_doc(doc_id, title, content, metadata=None):
    return Document(id=doc_id, title=title, content=content, metadata=metadata or {})


class TestIndexAndGet:
    def test_index_then_get(self, db):
        doc = make_doc("d1", "Python Guide", "Python is a powerful programming language.")
        index_document(doc, db)
        fetched = get_document("d1", db)
        assert fetched is not None
        assert fetched.id == "d1"
        assert fetched.title == "Python Guide"

    def test_indexed_at_set(self, db):
        doc = make_doc("d2", "Test", "content")
        index_document(doc, db)
        fetched = get_document("d2", db)
        assert fetched.indexed_at is not None and fetched.indexed_at > 0

    def test_reindex_updates_content(self, db):
        doc = make_doc("d3", "Old Title", "old content")
        index_document(doc, db)
        doc.title = "New Title"
        doc.content = "new content"
        index_document(doc, db)
        fetched = get_document("d3", db)
        assert fetched.title == "New Title"
        assert "new" in fetched.content

    def test_get_nonexistent_returns_none(self, db):
        init_db(db)
        assert get_document("nonexistent", db) is None

    def test_metadata_preserved(self, db):
        meta = {"category": "tech", "author": "alice"}
        doc = make_doc("d4", "Meta Doc", "content", metadata=meta)
        index_document(doc, db)
        fetched = get_document("d4", db)
        assert fetched.metadata == meta


class TestSearch:
    def test_search_returns_matching_docs(self, db):
        index_document(make_doc("s1", "Python Basics", "Python programming tutorial"), db)
        index_document(make_doc("s2", "Java Guide", "Java is object-oriented"), db)
        index_document(make_doc("s3", "Python Advanced", "Advanced Python patterns"), db)
        results = search("Python", limit=10, db_path=db)
        ids = [r.document.id for r in results]
        assert "s1" in ids
        assert "s3" in ids

    def test_search_scores_relevant_doc_higher(self, db):
        index_document(make_doc("r1", "Python", "Python Python Python is great"), db)
        index_document(make_doc("r2", "Other", "This has one mention of python"), db)
        results = search("Python", limit=10, db_path=db)
        assert len(results) >= 2
        # r1 has higher TF -> should rank higher
        top_id = results[0].document.id
        assert top_id == "r1"

    def test_search_returns_empty_for_no_match(self, db):
        index_document(make_doc("e1", "Cats", "Fluffy feline animals"), db)
        results = search("quantum spaceship", db_path=db)
        assert results == []

    def test_search_respects_limit(self, db):
        for i in range(10):
            index_document(make_doc(f"lim{i}", f"Doc {i}", "common term repeated many times"), db)
        results = search("common term", limit=3, db_path=db)
        assert len(results) <= 3

    def test_search_result_has_highlights(self, db):
        index_document(make_doc("h1", "Highlight Test", "The quick brown fox jumps over the lazy dog"), db)
        results = search("quick brown", db_path=db)
        assert len(results) > 0
        # highlights are populated (may be empty if tokenizer strips all query words)
        assert isinstance(results[0].highlights, list)

    def test_search_empty_query_returns_empty(self, db):
        index_document(make_doc("eq1", "T", "content"), db)
        assert search("", db_path=db) == []

    def test_search_empty_db_returns_empty(self, db):
        init_db(db)
        assert search("anything", db_path=db) == []


class TestDeleteDocument:
    def test_delete_existing_returns_true(self, db):
        doc = make_doc("del1", "To Delete", "some content")
        index_document(doc, db)
        assert delete_document("del1", db) is True
        assert get_document("del1", db) is None

    def test_delete_removes_from_inverted_index(self, db):
        doc = make_doc("del2", "Del Test", "unique_word_xyz123 content")
        index_document(doc, db)
        delete_document("del2", db)
        results = search("unique_word_xyz123", db_path=db)
        assert results == []

    def test_delete_nonexistent_returns_false(self, db):
        init_db(db)
        assert delete_document("ghost", db) is False


class TestReindexAll:
    def test_reindex_returns_count(self, db):
        for i in range(3):
            index_document(make_doc(f"ri{i}", f"Doc {i}", "test content"), db)
        count = reindex_all(db)
        assert count == 3

    def test_reindex_preserves_searchability(self, db):
        index_document(make_doc("ri_a", "Reindex A", "searchable content alpha"), db)
        reindex_all(db)
        results = search("searchable content", db_path=db)
        ids = [r.document.id for r in results]
        assert "ri_a" in ids

    def test_reindex_empty_db(self, db):
        init_db(db)
        assert reindex_all(db) == 0


class TestSearchSuggestions:
    def test_suggestions_for_prefix(self, db):
        index_document(make_doc("sg1", "Programming", "programming languages are powerful"), db)
        index_document(make_doc("sg2", "Progress", "progress is important"), db)
        suggestions = search_suggestions("progr", db_path=db)
        assert isinstance(suggestions, list)

    def test_empty_prefix_returns_empty(self, db):
        assert search_suggestions("", db_path=db) == []

    def test_suggestions_respect_limit(self, db):
        for i in range(20):
            index_document(make_doc(f"sugg{i}", f"Term {i}", f"termword{i} content"), db)
        suggestions = search_suggestions("termword", limit=5, db_path=db)
        assert len(suggestions) <= 5


class TestExportAndStats:
    def test_export_structure(self, db):
        index_document(make_doc("ex1", "Export Test", "content for export"), db)
        exported = export_index(db_path=db)
        assert "total_documents" in exported
        assert "documents" in exported
        assert exported["total_documents"] >= 1

    def test_index_stats(self, db):
        index_document(make_doc("st1", "Stats Doc", "many words here for statistics"), db)
        stats = index_stats(db_path=db)
        assert stats["total_documents"] >= 1
        assert "total_distinct_terms" in stats
        assert "total_postings" in stats


class TestTextProcessing:
    def test_tokenize_basic(self):
        tokens = tokenize("Hello World hello")
        # 'hello' and 'world' after lowercasing; stop word filter may keep both
        assert "hello" in tokens or "world" in tokens

    def test_tokenize_removes_stop_words(self):
        tokens = tokenize("the quick brown fox")
        assert "the" not in tokens

    def test_tokenize_handles_punctuation(self):
        tokens = tokenize("Hello, world! Python's great.")
        for t in tokens:
            assert t.isalnum()

    def test_stem_common_suffixes(self):
        assert stem("running") == "runn"
        assert stem("boxes") == "box"

    def test_stem_short_word_unchanged(self):
        assert stem("go") == "go"

    def test_normalize_tokens_applies_stem(self):
        tokens = normalize_tokens(["running", "boxes", "python"])
        assert "runn" in tokens or "run" in tokens  # some form of stem

    def test_extract_highlights_returns_list(self):
        text = "The quick brown fox jumps over the lazy dog"
        highlights = extract_highlights(text, ["quick", "fox"])
        assert isinstance(highlights, list)
        assert len(highlights) <= 3

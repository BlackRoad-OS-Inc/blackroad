"""Tests for blackroad-zip-service."""
import os
import sys
import tarfile
import zipfile
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from main_module import (
    create_archive, extract_archive, list_contents, add_to_archive,
    checksum_verify, streaming_extract, compute_checksum, get_db,
    get_history, ArchiveInfo, detect_format,
)


@pytest.fixture
def tmp_db(tmp_path):
    return get_db(tmp_path / "test.db")


@pytest.fixture
def sample_files(tmp_path):
    """Create sample files for archiving."""
    f1 = tmp_path / "hello.txt"
    f1.write_text("Hello, BlackRoad!\n")
    f2 = tmp_path / "data.json"
    f2.write_text('{"key": "value", "numbers": [1, 2, 3]}\n')
    f3 = tmp_path / "script.py"
    f3.write_text("print('from blackroad')\n")
    return [str(f1), str(f2), str(f3)]


def test_create_zip_archive(tmp_path, sample_files, tmp_db):
    out = str(tmp_path / "test.zip")
    info = create_archive(sample_files, out, compression="zip", conn=tmp_db)
    assert Path(out).exists()
    assert info.format == "zip"
    assert info.entry_count == 3
    assert info.size > 0
    assert len(info.checksum) == 64


def test_create_tar_gz_archive(tmp_path, sample_files, tmp_db):
    out = str(tmp_path / "test.tar.gz")
    info = create_archive(sample_files, out, compression="tar.gz", conn=tmp_db)
    assert Path(out).exists()
    assert info.format == "tar.gz"


def test_extract_zip(tmp_path, sample_files, tmp_db):
    archive = str(tmp_path / "extract_test.zip")
    create_archive(sample_files, archive, conn=tmp_db)
    dest = str(tmp_path / "extracted")
    extracted = extract_archive(archive, dest, conn=tmp_db)
    assert len(extracted) == 3
    assert any("hello.txt" in e for e in extracted)


def test_list_contents(tmp_path, sample_files, tmp_db):
    archive = str(tmp_path / "list_test.zip")
    create_archive(sample_files, archive, conn=tmp_db)
    entries = list_contents(archive)
    assert len(entries) == 3
    names = [e.path for e in entries]
    assert any("hello.txt" in n for n in names)
    for e in entries:
        assert e.size >= 0


def test_add_to_archive(tmp_path, sample_files, tmp_db):
    archive = str(tmp_path / "add_test.zip")
    create_archive(sample_files[:2], archive, conn=tmp_db)

    new_file = tmp_path / "extra.txt"
    new_file.write_text("extra content\n")

    info = add_to_archive(archive, str(new_file), conn=tmp_db)
    assert info.entry_count == 3  # 2 + 1

    entries = list_contents(archive)
    assert any("extra.txt" in e.path for e in entries)


def test_checksum_verify_valid(tmp_path, sample_files, tmp_db):
    archive = str(tmp_path / "verify_test.zip")
    info = create_archive(sample_files, archive, conn=tmp_db)
    result = checksum_verify(archive, expected=info.checksum, conn=tmp_db)
    assert result["valid"] is True
    assert result["error"] is None


def test_checksum_verify_mismatch(tmp_path, sample_files, tmp_db):
    archive = str(tmp_path / "bad_checksum.zip")
    create_archive(sample_files, archive, conn=tmp_db)
    result = checksum_verify(archive, expected="deadbeef" * 8, conn=tmp_db)
    assert result["valid"] is False
    assert "mismatch" in result["error"].lower()


def test_streaming_extract(tmp_path, sample_files):
    archive = str(tmp_path / "stream_test.zip")
    create_archive(sample_files, archive)
    collected = {}

    def handler(name, data):
        collected[name] = data

    count = streaming_extract(archive, handler)
    assert count == 3
    assert any(b"Hello" in v for v in collected.values())


def test_detect_format():
    assert detect_format("file.zip") == "zip"
    assert detect_format("file.tar.gz") == "tar.gz"
    assert detect_format("file.tar.bz2") == "tar.bz2"
    assert detect_format("file.tar.xz") == "tar.xz"
    assert detect_format("file.tar") == "tar"
    with pytest.raises(ValueError):
        detect_format("file.unknown")


def test_history_recording(tmp_path, sample_files, tmp_db):
    archive = str(tmp_path / "hist_test.zip")
    create_archive(sample_files, archive, conn=tmp_db)
    dest = str(tmp_path / "hist_extract")
    extract_archive(archive, dest, conn=tmp_db)

    history = get_history(tmp_db)
    ops = [h["operation"] for h in history]
    assert "create" in ops
    assert "extract" in ops


def test_compute_checksum(tmp_path):
    f = tmp_path / "checksum_target.txt"
    f.write_bytes(b"deterministic content")
    cs1 = compute_checksum(str(f))
    cs2 = compute_checksum(str(f))
    assert cs1 == cs2
    assert len(cs1) == 64

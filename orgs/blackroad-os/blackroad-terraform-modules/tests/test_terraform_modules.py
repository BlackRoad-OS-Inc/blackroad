"""
Tests for BlackRoad Terraform Module Registry
"""
import pytest
import tempfile
from pathlib import Path
from unittest.mock import patch

# Use a temp DB for every test
@pytest.fixture(autouse=True)
def tmp_registry(tmp_path):
    db = tmp_path / "test.db"
    with patch("terraform_modules.DB_PATH", db):
        yield db


# Import after patching so the module uses the temp path
@pytest.fixture
def registry(tmp_path):
    db = tmp_path / "registry.db"
    from terraform_modules import TerraformRegistry
    return TerraformRegistry(db_path=db)


@pytest.fixture
def sample_vars():
    from terraform_modules import TerraformVariable
    return [
        TerraformVariable("name", "string", "Instance name"),
        TerraformVariable("ami_id", "string", "AMI ID"),
        TerraformVariable("instance_type", "string", "Type", default="t3.micro", required=False),
    ]


@pytest.fixture
def sample_outputs():
    from terraform_modules import TerraformOutput
    return [
        TerraformOutput("instance_id", "EC2 Instance ID", "aws_instance.main.id"),
    ]


SIMPLE_HCL = '''resource "aws_instance" "${var.name}" {
  ami           = "${var.ami_id}"
  instance_type = "${var.instance_type}"
}'''


# ── 1. Registration ───────────────────────────────────────────

def test_register_module_returns_module(registry, sample_vars, sample_outputs):
    mod = registry.register_module(
        "test_ec2", "aws", "aws_instance",
        SIMPLE_HCL, sample_vars, sample_outputs,
        description="Test EC2",
    )
    assert mod.name == "test_ec2"
    assert mod.provider == "aws"
    assert mod.version == "1.0.0"
    assert mod.id is not None


def test_register_module_custom_version(registry, sample_vars, sample_outputs):
    mod = registry.register_module(
        "test_ec2_v2", "aws", "aws_instance",
        SIMPLE_HCL, sample_vars, sample_outputs,
        version="2.5.1",
    )
    assert mod.version == "2.5.1"


def test_register_invalid_provider_raises(registry, sample_vars):
    with pytest.raises(ValueError, match="Unknown provider"):
        registry.register_module(
            "bad_mod", "oracle", "some_resource",
            SIMPLE_HCL, sample_vars, [],
        )


def test_register_module_persisted(registry, sample_vars, sample_outputs):
    mod = registry.register_module(
        "persist_test", "aws", "aws_instance",
        SIMPLE_HCL, sample_vars, sample_outputs,
    )
    retrieved = registry.get_module(mod.id)
    assert retrieved.name == "persist_test"


# ── 2. HCL Generation ────────────────────────────────────────

def test_generate_tf_substitutes_vars(registry, sample_vars, sample_outputs):
    registry.register_module(
        "gen_test", "aws", "aws_instance",
        SIMPLE_HCL, sample_vars, sample_outputs,
    )
    result = registry.generate_tf("gen_test", {"name": "my-server", "ami_id": "ami-123"})
    assert "my-server" in result
    assert "ami-123" in result
    assert "t3.micro" in result  # default used


def test_generate_tf_missing_required_raises(registry, sample_vars, sample_outputs):
    registry.register_module(
        "req_test", "aws", "aws_instance",
        SIMPLE_HCL, sample_vars, sample_outputs,
    )
    with pytest.raises(ValueError, match="Missing required variables"):
        registry.generate_tf("req_test", {"name": "x"})  # ami_id missing


def test_generate_tf_increments_download_count(registry, sample_vars, sample_outputs):
    mod = registry.register_module(
        "dl_test", "aws", "aws_instance",
        SIMPLE_HCL, sample_vars, sample_outputs,
    )
    assert mod.download_count == 0
    registry.generate_tf("dl_test", {"name": "x", "ami_id": "ami-999"})
    updated = registry.get_module("dl_test")
    assert updated.download_count == 1


# ── 3. Validation ─────────────────────────────────────────────

def test_validate_valid_hcl(registry):
    result = registry.validate_hcl(SIMPLE_HCL)
    assert result.valid is True
    assert result.errors == []


def test_validate_unbalanced_braces(registry):
    result = registry.validate_hcl('resource "aws_instance" "x" { ami = "y"')
    assert result.valid is False
    assert any("braces" in e for e in result.errors)


def test_validate_unbalanced_brackets(registry):
    result = registry.validate_hcl('resource "aws_s3_bucket" "b" {\n  tags = [\n}')
    assert result.valid is False
    assert any("bracket" in e for e in result.errors)


def test_validate_empty_hcl(registry):
    result = registry.validate_hcl("")
    assert result.valid is False
    assert any("empty" in e for e in result.errors)


def test_validate_suspicious_interpolation_warning(registry):
    hcl = 'resource "null_resource" "x" {\n  triggers = { val = "${something.weird}" }\n}'
    result = registry.validate_hcl(hcl)
    assert any("Suspicious" in w for w in result.warnings)


# ── 4. Listing & Filtering ───────────────────────────────────

def test_list_modules_returns_seeded(registry):
    mods = registry.list_modules()
    assert len(mods) >= 8


def test_list_modules_filter_by_provider(registry):
    mods = registry.list_modules(provider_filter="aws")
    assert all(m.provider == "aws" for m in mods)
    assert len(mods) >= 4


def test_list_modules_filter_by_resource_type(registry):
    mods = registry.list_modules(resource_type_filter="aws_instance")
    assert all(m.resource_type == "aws_instance" for m in mods)


# ── 5. Plan Export ───────────────────────────────────────────

def test_export_plan_contains_module_name(registry):
    plan = registry.export_plan("aws_s3_bucket", {"bucket_name": "my-bucket"})
    assert "aws_s3_bucket" in plan
    assert "my-bucket" in plan


def test_export_plan_contains_plan_header(registry):
    plan = registry.export_plan("aws_vpc", {"name": "test-vpc"})
    assert "Terraform Plan Export" in plan
    assert "aws" in plan


# ── 6. Search ────────────────────────────────────────────────

def test_search_by_provider_name(registry):
    results = registry.search("kubernetes")
    assert any("kubernetes" in m.provider for m in results)


def test_search_by_description(registry):
    results = registry.search("bucket")
    assert len(results) >= 2


def test_search_no_results(registry):
    results = registry.search("zzznomatchzzz")
    assert results == []


# ── 7. Docs Generation ───────────────────────────────────────

def test_generate_docs_contains_variables_section(registry):
    docs = registry.generate_docs("aws_ec2_instance")
    assert "## Variables" in docs
    assert "ami_id" in docs


def test_generate_docs_contains_outputs_section(registry):
    docs = registry.generate_docs("aws_ec2_instance")
    assert "## Outputs" in docs


def test_generate_docs_contains_hcl_template(registry):
    docs = registry.generate_docs("aws_s3_bucket")
    assert "```hcl" in docs


# ── 8. Stats ─────────────────────────────────────────────────

def test_get_stats_structure(registry):
    stats = registry.get_stats()
    assert "total_modules" in stats
    assert "by_provider" in stats
    assert "most_downloaded" in stats
    assert stats["total_modules"] >= 8


def test_get_stats_provider_counts(registry):
    stats = registry.get_stats()
    assert stats["by_provider"].get("aws", 0) >= 4


# ── 9. Delete ────────────────────────────────────────────────

def test_delete_module(registry, sample_vars, sample_outputs):
    mod = registry.register_module(
        "to_delete", "null", "null_resource",
        'resource "null_resource" "x" {}',
        sample_vars, sample_outputs,
    )
    assert registry.delete_module(mod.id) is True
    with pytest.raises(KeyError):
        registry.get_module(mod.id)


def test_delete_nonexistent_module(registry):
    assert registry.delete_module("nonexistent-id") is False


# ── 10. Bump version ─────────────────────────────────────────

def test_bump_version_patch():
    from terraform_modules import TerraformModule
    m = TerraformModule("id", "test", "aws", "res", "1.2.3", "", "")
    assert m.bump_version("patch") == "1.2.4"


def test_bump_version_minor():
    from terraform_modules import TerraformModule
    m = TerraformModule("id", "test", "aws", "res", "1.2.3", "", "")
    assert m.bump_version("minor") == "1.3.0"


def test_bump_version_major():
    from terraform_modules import TerraformModule
    m = TerraformModule("id", "test", "aws", "res", "1.2.3", "", "")
    assert m.bump_version("major") == "2.0.0"

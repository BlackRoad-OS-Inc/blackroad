# 🏗️ BlackRoad Terraform Module Registry

[![CI](https://github.com/BlackRoad-OS/blackroad-terraform-modules/actions/workflows/ci.yml/badge.svg)](https://github.com/BlackRoad-OS/blackroad-terraform-modules/actions/workflows/ci.yml)
[![Python](https://img.shields.io/badge/python-3.10%2B-blue)](https://www.python.org/)
[![License](https://img.shields.io/badge/license-Proprietary-red)](./LICENSE)
[![Modules](https://img.shields.io/badge/built--in%20modules-8-green)](#built-in-modules)
[![Providers](https://img.shields.io/badge/providers-aws%20%7C%20gcp%20%7C%20kubernetes-orange)](#built-in-modules)

> Production-grade Python registry for managing, generating, and validating Terraform modules.
> Store modules in SQLite, render HCL templates with variable substitution, validate syntax,
> export plans, and generate markdown documentation — all from the CLI or Python API.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 📦 **Module Registry** | Register and version Terraform modules in a local SQLite database |
| 🔧 **HCL Generation** | Render HCL templates with `${var.name}` substitution and default merging |
| ✅ **Validation** | Static analysis of HCL: brace balance, resource syntax, interpolation checks |
| 📋 **Plan Export** | Human-readable Terraform plan showing resources to be created |
| 📚 **Docs Generator** | Auto-generate Markdown docs from module metadata |
| 🔍 **Search** | Full-text search across name, description, provider, and tags |
| 📊 **Statistics** | Module counts by provider, most-downloaded leaderboard |
| 🎨 **Rich CLI** | Beautiful terminal output with tables, syntax highlighting, and panels |

---

## 📦 Built-in Modules

| Name | Provider | Resource Type | Version | Tags |
|------|----------|---------------|---------|------|
| `aws_ec2_instance` | `aws` | `aws_instance` | 2.1.0 | compute, vm |
| `aws_s3_bucket` | `aws` | `aws_s3_bucket` | 3.0.1 | storage |
| `aws_rds_instance` | `aws` | `aws_db_instance` | 1.4.2 | database |
| `aws_vpc` | `aws` | `aws_vpc` | 2.0.0 | networking |
| `gcp_gce_instance` | `gcp` | `google_compute_instance` | 1.2.0 | compute, vm |
| `gcp_gcs_bucket` | `gcp` | `google_storage_bucket` | 1.1.0 | storage |
| `kubernetes_deployment` | `kubernetes` | `kubernetes_deployment` | 1.3.0 | k8s, container |
| `kubernetes_service` | `kubernetes` | `kubernetes_service` | 1.1.0 | k8s, networking |

All 8 modules are seeded automatically on first run.

---

## 🚀 Quick Start

```bash
# Install dependencies
pip install typer rich

# List all built-in modules
python terraform_modules.py list

# Generate HCL for an EC2 instance
python terraform_modules.py generate aws_ec2_instance \
  --var name=my-server \
  --var ami_id=ami-0abcdef1234567890 \
  --var instance_type=t3.small

# Validate an HCL file
python terraform_modules.py validate path/to/main.tf

# Show module documentation
python terraform_modules.py docs aws_s3_bucket

# Search for storage-related modules
python terraform_modules.py search storage

# Registry statistics
python terraform_modules.py stats
```

---

## 📖 CLI Reference

### `list`
```
python terraform_modules.py list [--provider PROVIDER] [--resource RESOURCE]
```
List all registered modules, optionally filtered by provider or resource type.

### `register`
```
python terraform_modules.py register NAME PROVIDER RESOURCE_TYPE TEMPLATE_FILE \
  [--description DESC] [--version VERSION]
```
Register a new module from an HCL template file.

### `generate`
```
python terraform_modules.py generate MODULE_NAME_OR_ID \
  --var key=value [--var key2=value2 ...] [--out output.tf]
```
Render a module's HCL template with variable substitution.

### `validate`
```
python terraform_modules.py validate TEMPLATE_FILE
```
Validate HCL syntax with static analysis.

### `plan`
```
python terraform_modules.py plan MODULE_NAME_OR_ID --var key=value [...]
```
Export a human-readable Terraform plan.

### `search`
```
python terraform_modules.py search QUERY
```
Search modules by name, description, provider, or tags.

### `docs`
```
python terraform_modules.py docs MODULE_NAME_OR_ID
```
Generate and display Markdown documentation for a module.

### `stats`
```
python terraform_modules.py stats
```
Display registry statistics: module counts and download leaderboard.

---

## 🐍 Python API

```python
from terraform_modules import (
    TerraformRegistry,
    TerraformVariable,
    TerraformOutput,
    TerraformExample,
)

registry = TerraformRegistry()

# List all modules
modules = registry.list_modules()

# Filter by provider
aws_modules = registry.list_modules(provider_filter="aws")

# Generate HCL
hcl = registry.generate_tf("aws_s3_bucket", {
    "bucket_name": "my-unique-bucket-name-2024",
    "environment": "production",
})
print(hcl)

# Validate HCL
result = registry.validate_hcl(hcl)
print(result)  # Valid: True

# Export plan
plan = registry.export_plan("aws_ec2_instance", {
    "name":          "web-prod",
    "ami_id":        "ami-0abcdef1234567890",
    "instance_type": "t3.medium",
    "subnet_id":     "subnet-12345678",
})
print(plan)

# Generate docs
docs = registry.generate_docs("aws_rds_instance")
print(docs)

# Register a custom module
mod = registry.register_module(
    name="my_custom_bucket",
    provider="aws",
    resource_type="aws_s3_bucket",
    hcl_template='''resource "aws_s3_bucket" "${var.name}" {
  bucket = "${var.name}"
}''',
    variables=[
        TerraformVariable("name", "string", "Bucket name"),
    ],
    outputs=[
        TerraformOutput("arn", "Bucket ARN", "aws_s3_bucket.${var.name}.arn"),
    ],
    description="My custom S3 bucket module",
    version="1.0.0",
)
print(f"Registered: {mod.id}")

# Search
results = registry.search("kubernetes")

# Statistics
stats = registry.get_stats()
print(stats["total_modules"])       # e.g. 9
print(stats["by_provider"])         # {"aws": 4, "gcp": 2, ...}

# Delete
registry.delete_module("my_custom_bucket")
```

---

## 📐 HCL Template Format

Templates use `${var.name}` placeholders that are replaced during generation:

```hcl
resource "aws_instance" "${var.name}" {
  ami           = "${var.ami_id}"
  instance_type = "${var.instance_type}"

  tags = {
    Name        = "${var.name}"
    Environment = "${var.environment}"
  }

  root_block_device {
    volume_size = ${var.root_volume_size}
    encrypted   = true
  }
}
```

**Rules:**
- Use `${var.<name>}` for string/interpolated values
- Use `${var.<name>}` (no quotes) for number/bool attributes
- Variables with `required=True` and no `default` must be supplied at generation time
- All other variables fall back to their `default` value

---

## ✅ Validation Rules

The `validate_hcl()` method performs these checks:

| Check | Severity | Description |
|-------|----------|-------------|
| Balanced `{ }` | **Error** | Every opening brace must have a closing brace |
| Balanced `[ ]` | **Error** | Every opening bracket must have a closing bracket |
| Balanced `( )` | **Error** | Every opening parenthesis must have a closing one |
| Resource block labels | **Error** | `resource` blocks must have two string labels |
| Empty template | **Error** | Template must not be empty |
| No block found | **Warning** | Template has no `resource`/`data`/`module` block |
| Unknown interpolation | **Warning** | `${something.*}` — not `var.`, `local.`, `module.`, `data.` |
| Escaped dollar | **Warning** | `$${` is only needed for literal `$` in strings |

---

## 🗄️ Database

Modules are stored in a SQLite database at `~/.blackroad/terraform-modules.db`.
The schema is auto-created on first run.

```
~/.blackroad/
└── terraform-modules.db   # SQLite module registry
```

To reset the registry: `rm ~/.blackroad/terraform-modules.db`

---

## 🧪 Running Tests

```bash
pip install pytest pytest-cov typer rich
pytest tests/ -v --cov=terraform_modules --cov-report=term-missing
```

Expected: **30+ tests passing** across registration, generation, validation, listing, plan export, search, docs, stats, and delete.

---

## 📁 Project Structure

```
blackroad-terraform-modules/
├── terraform_modules.py          # Core implementation (400+ lines)
├── tests/
│   └── test_terraform_modules.py # 30+ pytest tests
├── .github/
│   └── workflows/
│       └── ci.yml                # CI: lint + test matrix
└── README.md
```

---

## 🔒 License

Proprietary — © BlackRoad OS, Inc. All rights reserved.  
See [SECURITY.md](./SECURITY.md) for vulnerability disclosure policy.

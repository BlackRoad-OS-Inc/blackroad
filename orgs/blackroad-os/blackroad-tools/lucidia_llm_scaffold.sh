#!/usr/bin/env bash
set -euo pipefail

# Create project scaffolding for Lucidia LLM
mkdir -p datasets/lucidia
mkdir -p models
mkdir -p checkpoints
mkdir -p outputs
mkdir -p scripts
mkdir -p rag/index
mkdir -p serving/jetson
mkdir -p .github/workflows

# Initialize empty dataset files
:> datasets/lucidia/train.jsonl
:> datasets/lucidia/val.jsonl

echo "Lucidia scaffold created."

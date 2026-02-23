#!/usr/bin/env python3
"""
BlackRoad Apple OpenELM-270M Fine-Tuning Pipeline
==================================================
LoRA fine-tuning on GSM-Symbolic math reasoning dataset.
Optimized for Raspberry Pi 5 (8GB RAM, CPU-only).

Usage:
    python3 apple-finetune-270m.py                    # Full training
    python3 apple-finetune-270m.py --epochs 1         # Quick test
    python3 apple-finetune-270m.py --eval-only        # Evaluate existing
    python3 apple-finetune-270m.py --export-gguf      # Export to GGUF
"""

import os
import sys
import json
import time
import argparse
import logging
from pathlib import Path

# ── Paths ───────────────────────────────────────────────────────────────
MODEL_PATH = os.path.expanduser("~/models/apple/openelm/270M-Instruct")
DATASET_PATH = os.path.expanduser("~/datasets/apple/gsm-symbolic")
OUTPUT_DIR = os.path.expanduser("~/models/apple/openelm/270M-math-lora")
MERGED_DIR = os.path.expanduser("~/models/apple/openelm/270M-math-merged")
GGUF_DIR = os.path.expanduser("~/models/apple/gguf")

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("blackroad-finetune")


def install_deps():
    """Install required packages if missing."""
    required = ["peft", "trl", "bitsandbytes"]
    missing = []
    for pkg in required:
        try:
            __import__(pkg)
        except ImportError:
            missing.append(pkg)

    if missing:
        logger.info(f"Installing: {', '.join(missing)}")
        import subprocess
        subprocess.check_call([
            sys.executable, "-m", "pip", "install",
            "--break-system-packages", "--quiet"
        ] + missing)
        logger.info("Dependencies installed")


def format_dataset(tokenizer, max_length=512, train_split=0.9):
    """Format GSM-Symbolic into instruction-tuning format."""
    from datasets import load_from_disk

    logger.info(f"Loading dataset from {DATASET_PATH}")
    ds = load_from_disk(DATASET_PATH)

    def format_example(example):
        """Convert to chat/instruction format."""
        prompt = (
            f"<|system|>\n"
            f"You are a math tutor. Solve step by step.\n"
            f"<|user|>\n"
            f"{example['question']}\n"
            f"<|assistant|>\n"
            f"{example['answer']}"
        )
        return {"text": prompt}

    logger.info(f"Formatting {len(ds)} examples...")
    ds = ds.map(format_example, remove_columns=ds.column_names)

    # Tokenize
    def tokenize(examples):
        tokens = tokenizer(
            examples["text"],
            truncation=True,
            max_length=max_length,
            padding="max_length",
        )
        tokens["labels"] = tokens["input_ids"].copy()
        return tokens

    logger.info("Tokenizing...")
    tokenized = ds.map(tokenize, batched=True, remove_columns=["text"])

    # Split
    split_idx = int(len(tokenized) * train_split)
    train_ds = tokenized.select(range(split_idx))
    eval_ds = tokenized.select(range(split_idx, len(tokenized)))

    logger.info(f"Train: {len(train_ds)} | Eval: {len(eval_ds)}")
    return train_ds, eval_ds


def setup_lora(model):
    """Apply LoRA adapters to the model."""
    from peft import LoraConfig, get_peft_model, TaskType

    # Target the attention projection layers in OpenELM
    # OpenELM uses qkv_proj and out_proj in its attention layers
    lora_config = LoraConfig(
        task_type=TaskType.CAUSAL_LM,
        r=8,                        # Low rank for Pi memory constraints
        lora_alpha=16,              # Scaling factor
        lora_dropout=0.05,
        target_modules=["qkv_proj", "out_proj"],  # OpenELM attention layers
        bias="none",
    )

    model = get_peft_model(model, lora_config)

    # Print trainable params
    trainable = sum(p.numel() for p in model.parameters() if p.requires_grad)
    total = sum(p.numel() for p in model.parameters())
    pct = 100 * trainable / total
    logger.info(f"Trainable: {trainable:,} / {total:,} ({pct:.2f}%)")

    return model


def train(args):
    """Main training loop."""
    import torch
    from transformers import AutoModelForCausalLM, AutoTokenizer, TrainingArguments, Trainer

    # ── Load tokenizer ──────────────────────────────────────────────
    logger.info("Loading tokenizer (Llama-2 tokenizer for OpenELM)...")
    # OpenELM uses the Llama tokenizer
    tokenizer = AutoTokenizer.from_pretrained(
        "NousResearch/Llama-2-7b-hf",
        trust_remote_code=True,
    )
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    # ── Load model ──────────────────────────────────────────────────
    logger.info(f"Loading model from {MODEL_PATH}...")
    model = AutoModelForCausalLM.from_pretrained(
        MODEL_PATH,
        trust_remote_code=True,
    )
    model = model.float()  # Ensure float32 for CPU training
    model.config.use_cache = False  # Disable KV cache for training

    # ── Apply LoRA ──────────────────────────────────────────────────
    logger.info("Applying LoRA adapters...")
    model = setup_lora(model)

    # ── Format dataset ──────────────────────────────────────────────
    train_ds, eval_ds = format_dataset(tokenizer, max_length=args.max_length)

    # ── Training args (optimized for Pi 5) ──────────────────────────
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    training_args = TrainingArguments(
        output_dir=OUTPUT_DIR,
        num_train_epochs=args.epochs,
        per_device_train_batch_size=1,       # Minimal for 8GB RAM
        per_device_eval_batch_size=1,
        gradient_accumulation_steps=8,        # Effective batch = 8
        learning_rate=2e-4,
        weight_decay=0.01,
        warmup_steps=50,
        lr_scheduler_type="cosine",
        logging_steps=10,
        eval_strategy="steps",
        eval_steps=100,
        save_strategy="steps",
        save_steps=200,
        save_total_limit=3,                   # Keep disk usage low
        fp16=False,                           # CPU doesn't support fp16
        bf16=False,
        dataloader_num_workers=0,             # Pi has limited cores
        optim="adamw_torch",
        report_to="none",                     # No wandb/mlflow
        max_grad_norm=1.0,
        seed=42,
        remove_unused_columns=False,
    )

    # ── Trainer ─────────────────────────────────────────────────────
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_ds,
        eval_dataset=eval_ds,
        processing_class=tokenizer,
    )

    # ── Train ───────────────────────────────────────────────────────
    logger.info("Starting training...")
    logger.info(f"  Epochs: {args.epochs}")
    logger.info(f"  Batch size: 1 (effective: 8 with grad accum)")
    logger.info(f"  Train samples: {len(train_ds)}")
    logger.info(f"  Steps/epoch: {len(train_ds) // 8}")
    logger.info(f"  Total steps: {len(train_ds) // 8 * args.epochs}")

    start = time.time()
    result = trainer.train()
    elapsed = time.time() - start

    logger.info(f"Training complete in {elapsed/3600:.1f}h")
    logger.info(f"  Loss: {result.training_loss:.4f}")

    # Save LoRA adapter
    model.save_pretrained(OUTPUT_DIR)
    tokenizer.save_pretrained(OUTPUT_DIR)
    logger.info(f"LoRA adapter saved to {OUTPUT_DIR}")

    # Save training stats
    stats = {
        "model": "apple/OpenELM-270M-Instruct",
        "dataset": "apple/GSM-Symbolic",
        "train_samples": len(train_ds),
        "eval_samples": len(eval_ds),
        "epochs": args.epochs,
        "training_loss": result.training_loss,
        "training_time_hours": elapsed / 3600,
        "lora_r": 8,
        "lora_alpha": 16,
        "effective_batch_size": 8,
        "max_length": args.max_length,
    }
    with open(os.path.join(OUTPUT_DIR, "training_stats.json"), "w") as f:
        json.dump(stats, f, indent=2)
    logger.info(f"Stats saved to {OUTPUT_DIR}/training_stats.json")

    return result


def evaluate(args):
    """Evaluate the fine-tuned model."""
    import torch
    from transformers import AutoModelForCausalLM, AutoTokenizer
    from peft import PeftModel

    logger.info("Loading base model...")
    tokenizer = AutoTokenizer.from_pretrained(
        "NousResearch/Llama-2-7b-hf",
        trust_remote_code=True,
    )
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    base_model = AutoModelForCausalLM.from_pretrained(
        MODEL_PATH,
        trust_remote_code=True,
    )

    logger.info(f"Loading LoRA adapter from {OUTPUT_DIR}...")
    model = PeftModel.from_pretrained(base_model, OUTPUT_DIR)
    model.eval()

    # Test prompts
    test_questions = [
        "If a store sells 15 apples at $2 each and 8 oranges at $3 each, what is the total revenue?",
        "A train travels 120 miles in 2 hours. What is its average speed in miles per hour?",
        "Sarah has 48 cookies and wants to share them equally among 6 friends. How many cookies does each friend get?",
    ]

    logger.info("\n=== Evaluation ===")
    for q in test_questions:
        prompt = f"<|system|>\nYou are a math tutor. Solve step by step.\n<|user|>\n{q}\n<|assistant|>\n"
        inputs = tokenizer(prompt, return_tensors="pt")

        with torch.no_grad():
            outputs = model.generate(
                **inputs,
                max_new_tokens=200,
                do_sample=False,
                temperature=1.0,
            )

        response = tokenizer.decode(outputs[0], skip_special_tokens=True)
        # Extract just the assistant response
        if "<|assistant|>" in response:
            response = response.split("<|assistant|>")[-1].strip()

        print(f"\nQ: {q}")
        print(f"A: {response[:300]}")
        print("-" * 60)


def merge_and_export(args):
    """Merge LoRA weights and export to GGUF for Ollama."""
    import torch
    from transformers import AutoModelForCausalLM, AutoTokenizer
    from peft import PeftModel

    logger.info("Loading base model + LoRA adapter for merge...")

    tokenizer = AutoTokenizer.from_pretrained(
        "NousResearch/Llama-2-7b-hf",
        trust_remote_code=True,
    )
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    base_model = AutoModelForCausalLM.from_pretrained(
        MODEL_PATH,
        trust_remote_code=True,
    )

    model = PeftModel.from_pretrained(base_model, OUTPUT_DIR)
    logger.info("Merging LoRA weights into base model...")
    model = model.merge_and_unload()

    os.makedirs(MERGED_DIR, exist_ok=True)
    model.save_pretrained(MERGED_DIR)
    tokenizer.save_pretrained(MERGED_DIR)
    logger.info(f"Merged model saved to {MERGED_DIR}")

    # Copy OpenELM custom code files needed for loading
    import shutil
    for fname in ["configuration_openelm.py", "modeling_openelm.py", "generate_openelm.py"]:
        src = os.path.join(MODEL_PATH, fname)
        if os.path.exists(src):
            shutil.copy2(src, MERGED_DIR)
            logger.info(f"Copied {fname}")

    logger.info(f"\nMerged model at: {MERGED_DIR}")
    logger.info("To convert to GGUF, use llama.cpp's convert script:")
    logger.info(f"  python3 convert_hf_to_gguf.py {MERGED_DIR} --outfile {GGUF_DIR}/OpenELM-270M-math.gguf --outtype q4_k_m")
    logger.info("\nThen register with Ollama:")
    logger.info(f"  echo 'FROM {GGUF_DIR}/OpenELM-270M-math.gguf' > /tmp/Modelfile")
    logger.info("  ollama create blackroad-math-270m -f /tmp/Modelfile")


def main():
    parser = argparse.ArgumentParser(description="BlackRoad OpenELM-270M Fine-Tuning")
    parser.add_argument("--epochs", type=int, default=3, help="Training epochs (default: 3)")
    parser.add_argument("--max-length", type=int, default=384, help="Max sequence length (default: 384)")
    parser.add_argument("--eval-only", action="store_true", help="Only evaluate existing model")
    parser.add_argument("--export-gguf", action="store_true", help="Merge LoRA and export")
    args = parser.parse_args()

    print("\n" + "=" * 60)
    print("  BlackRoad × Apple OpenELM-270M Fine-Tuning Pipeline")
    print("  Model: apple/OpenELM-270M-Instruct")
    print("  Dataset: apple/GSM-Symbolic (5000 math problems)")
    print("  Method: LoRA (r=8, alpha=16)")
    print("  Device: Cecilia Pi 5 (CPU, 8GB RAM)")
    print("=" * 60 + "\n")

    install_deps()

    if args.eval_only:
        evaluate(args)
    elif args.export_gguf:
        merge_and_export(args)
    else:
        train(args)
        logger.info("\nTraining complete! Next steps:")
        logger.info("  1. Evaluate: python3 apple-finetune-270m.py --eval-only")
        logger.info("  2. Export:   python3 apple-finetune-270m.py --export-gguf")


if __name__ == "__main__":
    main()

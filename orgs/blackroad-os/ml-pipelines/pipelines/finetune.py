from transformers import AutoModelForCausalLM, AutoTokenizer, TrainingArguments
from peft import LoraConfig, get_peft_model
from datasets import load_dataset

def finetune(
    base_model: str,
    dataset_path: str,
    output_dir: str,
    epochs: int = 3
):
    # Load model with QLoRA
    model = AutoModelForCausalLM.from_pretrained(
        base_model,
        load_in_4bit=True,
        device_map="auto"
    )
    
    # Configure LoRA
    lora_config = LoraConfig(
        r=16,
        lora_alpha=32,
        target_modules=["q_proj", "v_proj"],
        lora_dropout=0.05
    )
    model = get_peft_model(model, lora_config)
    
    # Load dataset
    dataset = load_dataset("json", data_files=dataset_path)
    
    # Training
    args = TrainingArguments(
        output_dir=output_dir,
        num_train_epochs=epochs,
        per_device_train_batch_size=4,
        gradient_accumulation_steps=4,
        learning_rate=2e-4
    )
    
    return model, args

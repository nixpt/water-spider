from datasets import Dataset
from tokenizers import Tokenizer, models
from transformers import LlamaConfig, LlamaForCausalLM, PreTrainedTokenizerFast
from trl import SFTConfig, SFTTrainer

tokenizer = Tokenizer(models.WordLevel(
    vocab={"[UNK]": 0, "[PAD]": 1, "[EOS]": 2}, unk_token="[UNK]"))
processing = PreTrainedTokenizerFast(
    tokenizer_object=tokenizer, pad_token="[PAD]", eos_token="[EOS]")
model = LlamaForCausalLM(LlamaConfig(
    vocab_size=128, hidden_size=32, intermediate_size=64,
    num_hidden_layers=1, num_attention_heads=4, num_key_value_heads=4,
))
rows = [[1, 2, 3, 4, 5, 6, 7, 8], [8, 7, 6, 5, 4, 3, 2, 1]]
args = SFTConfig(
    output_dir="/tmp/water-spider-train-smoke", max_steps=1,
    per_device_train_batch_size=1, use_cpu=True, max_length=8,
    report_to=[], logging_steps=1, save_strategy="no",
)
SFTTrainer(
    model=model, args=args, processing_class=processing,
    train_dataset=Dataset.from_dict({"input_ids": rows, "labels": rows}),
).train()
print("TRL SFTTrainer 1-step CPU smoke: PASS")

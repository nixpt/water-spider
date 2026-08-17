import inspect

import causal_conv1d
import fla
import torch
from transformers.models.qwen3_5 import modeling_qwen3_5

assert torch.__version__.startswith("2.9.1"), torch.__version__
assert fla.__version__ == "0.5.1", fla.__version__
assert causal_conv1d.__version__.startswith("1.6.2"), causal_conv1d.__version__
src = inspect.getsource(modeling_qwen3_5.Qwen3_5GatedDeltaNet)
assert "chunk_gated_delta_rule" in src or "fused_recurrent" in src
print("training imports: PASS")
print("torch", torch.__version__, "cuda", torch.version.cuda)
print("fla fast path: ACTIVE (Qwen3.5 GDN fused implementation present)")

# Local AI Reverse Engineering: Qwen 27B + Hermes + REA (on a 24GB GPU)

![GPU](https://img.shields.io/badge/Tested%20on-RTX%203090%2024GB-76b900?style=for-the-badge&logo=nvidia&logoColor=white)
![Model](https://img.shields.io/badge/Model-Qwen3.8--27B%20Q4__K__M-06b6d4?style=for-the-badge)
![Agent](https://img.shields.io/badge/Agent-Hermes-8b5cf6?style=for-the-badge)
![Toolkit](https://img.shields.io/badge/Toolkit-REA%20(Reverse%20Engineer%20Anything)-f59e0b?style=for-the-badge)
![Engine](https://img.shields.io/badge/Engine-llama.cpp-000000?style=for-the-badge)
![Cloud](https://img.shields.io/badge/Cloud-Not%20Required-red?style=for-the-badge)
![API](https://img.shields.io/badge/API-OpenAI%20Compatible-black?style=for-the-badge)

Set up a **local AI that reverse engineers software** — a stripped binary, no source code — running the **Qwen 27B** model on a single consumer GPU, driven by the **Hermes** agent with the **REA** toolkit. This repo has the exact **prompts** and **configs** from the video. Nothing leaves your machine.

> Use this only on binaries you own, or ones you have clear permission to inspect. Many licenses forbid reverse engineering, and the laws vary by country.

[![Subscribe](https://img.shields.io/badge/Subscribe-NetworkCoder-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/@NetworkCoder?sub_confirmation=1)

⭐ If this helped, **star the repo** so more people can find it.

## Hardware

| Spec | |
|---|---|
| GPU | RTX 3090 · 24 GB |
| Model | Qwen3.8-27B · Q4_K_M (~17.4 GB) |
| Context | 128K · q8_0 KV cache · single slot |
| VRAM | ~21.3 GB, reserved up front, flat all session |
| Engine | llama.cpp (OpenAI-compatible server) |
| Agent | Hermes · toolkit: REA (Ghidra-backed) |

## The stack

Four pieces, bottom to top:

1. **GPU** — a 24 GB card holds the model and the full context window.
2. **llama.cpp** — runs the quantized model and serves an OpenAI-compatible API.
3. **Hermes** — the agent; decides what to do next and calls tools.
4. **REA** (*reverse engineer anything*) — gives the agent Ghidra-backed tools to open and analyze a binary.

## Setup

**Before you start**

| Need | Why |
|---|---|
| llama.cpp built with CUDA | provides `llama-server` |
| `Qwen3.8-27B-Q4_K_M.gguf` | the weights, ~17.4 GB |
| Node + Ghidra + Java | for the REA toolkit |

**1. Start the model server** ([`config/llama-server.sh`](config/llama-server.sh))
```bash
./llama-server \
  -m Qwen3.8-27B-Q4_K_M.gguf \
  -c 131072 \
  -ctk q8_0 -ctv q8_0 \
  -np 1 \
  -ngl 99 \
  --host 127.0.0.1 --port 8081
```
| Flag | What it does |
|---|---|
| `-c 131072` | 128K context — room to read the whole binary |
| `-ctk q8_0 -ctv q8_0` | 8-bit KV cache — roughly halves context memory |
| `-np 1` | single slot — one agent gets all 128K |
| `-ngl 99` | offload all layers to the GPU |

**2. Install Hermes and point it at the server** ([`config/hermes-setup.md`](config/hermes-setup.md))
```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash   # Linux / macOS / WSL2
hermes model        # → Custom endpoint → http://127.0.0.1:8081/v1
```
The endpoint block on its own is [`config/hermes-server.json`](config/hermes-server.json):
```json
{
  "provider": "custom",
  "base_url": "http://127.0.0.1:8081/v1",
  "api_key": "local",
  "model": "Qwen3.8-27B-Q4_K_M"
}
```

**3. Install the REA toolkit** ([`config/rea-setup.md`](config/rea-setup.md))
```bash
npx rea-agents setup     # installs the toolkit + Ghidra bridge (needs Ghidra, Java, Node)
npx rea-agents doctor    # should report all green
```

**4. Run the agent** in your working folder and paste one of the prompts below — or feed a prompt
file straight in:
```bash
hermes chat --query-file prompts/01-save-hack.txt
```

## The prompts

Paste as-is. Point the paths at your own binaries.

**Challenge 1 — save hack** ([`prompts/01-save-hack.txt`](prompts/01-save-hack.txt))
```text
/workspace/targets/dungeon is a stripped terminal game called Dungeon Quest.
I don't have its source code. My save file is /workspace/work/save.dat.
Use REA to reverse engineer the save file format, then write
/workspace/work/save_edit.py, which sets my gold to 999,999 in an existing save.
Don't modify the game binary. Success means the unmodified game loads the edited
save and I can buy the Legendary Sword. Explain each part of the format, with evidence.
```

**Challenge 2 — license keygen** ([`prompts/02-keygen.txt`](prompts/02-keygen.txt))
```text
The file /workspace/targets/notepro is a stripped notes app. The FREE edition is
limited to 3 notes, and a license key unlocks PRO. I don't have its source code.
Use REA to find out exactly how license keys are validated, then write
/workspace/work/keygen.py, which prints 5 new valid keys. Don't modify the binary.
Success means all 5 keys unlock PRO in the unmodified app. Explain every check, with evidence.
```

> Tip: start the prompt with a word (e.g. *"The file `/workspace/targets/notepro`…"*) so the agent reads the path as normal text, not as an attached file.

## Tips

- **One slot, full context.** `-np 1` gives a single agent the entire 128K window — better than splitting it.
- **Let REA load tools on demand.** `tool_search` pulls in only the tool needed, so ~207 tools cost about +2K context, not +150K.
- **Fresh session per target.** Start a new agent session for each binary.

## Which GPUs?

NVIDIA RTX 30-series or newer. **24 GB is the sweet spot** for the 27B model at 128K context with an 8-bit KV cache. Smaller cards work with less context or a smaller quant.

## Related — the 125B-on-One-GPU series

| Part | Repo |
|:---:|---|
| 1 | [Run a 125B model on one GPU (Strata + Qwen 3.8 Flash-Next)](https://github.com/network-tocoder/Run-a-125B-AI-Model-on-One-GPU-Strata-Qwen3.8-Flash-Next) |
| 2 | [Free local AI coding agent — 125B on 16GB (Strata + opencode)](https://github.com/network-tocoder/free-local-ai-coding-agent-125b-on-16gb-gpu-strata-opencode) |
| 3 | [125B local AI on a 12GB GPU (Strata + Pi 1.0)](https://github.com/network-tocoder/125B-Local-AI-on-a-12GB-GPU-Strata-Pi-1.0-Coding-Agent) |

## Files

| File | What's in it |
|---|---|
| [`config/llama-server.sh`](config/llama-server.sh) | The exact llama.cpp flags used in the video |
| [`config/hermes-setup.md`](config/hermes-setup.md) | Installing Hermes and pointing it at your local endpoint |
| [`config/hermes-server.json`](config/hermes-server.json) | The endpoint block on its own, ready to copy |
| [`config/rea-setup.md`](config/rea-setup.md) | REA + Ghidra, and how the tool list stays small |
| [`prompts/01-save-hack.txt`](prompts/01-save-hack.txt) | Challenge 1 — recover a save-file format, write the editor |
| [`prompts/02-keygen.txt`](prompts/02-keygen.txt) | Challenge 2 — find how license keys are validated, write the keygen |

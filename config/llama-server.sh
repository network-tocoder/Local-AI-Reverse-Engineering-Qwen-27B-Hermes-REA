#!/usr/bin/env bash
# Start llama.cpp with Qwen3.8-27B (Q4_K_M, ~17.4 GB) on a 24 GB card.
# 128K context, 8-bit KV cache, single slot — one agent gets the whole window.
./llama-server \
  -m Qwen3.8-27B-Q4_K_M.gguf \
  -c 131072 \
  -ctk q8_0 -ctv q8_0 \
  -np 1 \
  -ngl 99 \
  --host 127.0.0.1 --port 8081

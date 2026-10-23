# Hermes — agent setup

Hermes is the agent that drives the whole run: it decides what to do next and calls the tools.
It talks to your **local** llama.cpp server — no account, no API key, nothing leaves the machine.

## Install

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash   # Linux / macOS / WSL2
```

Windows (native, PowerShell):

```powershell
iex (irm https://hermes-agent.nousresearch.com/install.ps1)
```

Reload your shell and check it resolved:

```bash
source ~/.bashrc      # or ~/.zshrc
hermes --version
```

## Point it at the local model

Run the wizard once:

```bash
hermes model
```

| Prompt | Answer |
|---|---|
| Select provider | **Custom endpoint (enter URL manually)** |
| Base URL | `http://127.0.0.1:8081/v1` |
| API key | `local` |
| Model | `Qwen3.8-27B-Q4_K_M` |
| Context length | press Enter — it auto-detects from the server |

Headless alternative, no wizard:

```bash
hermes config set model.provider custom
hermes config set model.base_url http://127.0.0.1:8081/v1
hermes config set model.default Qwen3.8-27B-Q4_K_M
```

The same endpoint block is in [`config/hermes-server.json`](hermes-server.json), ready to copy:

```json
{
  "provider": "custom",
  "base_url": "http://127.0.0.1:8081/v1",
  "api_key": "local",
  "model": "Qwen3.8-27B-Q4_K_M"
}
```

## Verify

```bash
hermes -z "Reply exactly HERMES_OK"
```

You should get `HERMES_OK`. If you don't, the endpoint isn't up — check the llama.cpp server is
listening and that it lists your model:

```bash
curl http://127.0.0.1:8081/v1/models
```

## Run a prompt file

```bash
hermes chat --query-file prompts/01-save-hack.txt
# or straight from stdin
hermes chat --query-file - < prompts/01-save-hack.txt
```

## Useful commands

| Command | What it does |
|---|---|
| `hermes` | interactive session |
| `hermes model` | pick provider + model (run outside a session) |
| `hermes tools` | configure which tools are enabled |
| `hermes doctor` | diagnose install and config problems |
| `hermes update` | upgrade |

## A note on tool count

REA registers ~207 tools. Hermes pulls them in **on demand** through `tool_search`, so the whole
toolkit costs about +2K tokens of context instead of +150K — see [`rea-setup.md`](rea-setup.md).
Don't disable them up front; measure first.

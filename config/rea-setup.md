# REA (Reverse Engineer Anything) — toolkit setup

REA gives the agent its tools (Ghidra-backed binary analysis). It needs three things underneath it:

| Component | Why |
|---|---|
| Ghidra  | the reverse-engineering suite the tools call |
| Java    | Ghidra runs on it |
| Node    | installs and runs the REA toolkit |

## Wire it up
```bash
npx rea-agents setup     # installs the toolkit + Ghidra bridge
npx rea-agents doctor    # verifies Ghidra, the agent, and the REA toolkit
```
`doctor` should report all green before you start.

## How the agent sees it
REA registers ~207 tools, but they are **not** all loaded into context. Hermes uses
`tool_search` to pull in only the tool it needs, the moment it needs it — so the whole
toolkit costs about +2K tokens of context instead of +150K.

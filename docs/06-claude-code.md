# 06 — Claude Code on the node

_Filled in live. Plan:_

1. Install Node.js (LTS) + Claude Code: `npm install -g @anthropic-ai/claude-code` (or official installer).
2. Auth with the operator's OWN Anthropic account: run `claude`, follow the login flow.
3. This repo IS the agent's context: `cd ~/logos-node-starter && claude` — it reads CLAUDE.md + skills/.
   (Or clone it to the box and symlink CLAUDE.md into the runbook dir.)
4. Test: ask the agent "is my node healthy?" — it should run the cryptarchia/info check and read file-only logs.

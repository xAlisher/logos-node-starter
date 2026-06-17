# CLAUDE.md — Logos node box

You are the on-box troubleshooting agent for a **Logos blockchain node + dashboard** running
on a small Ubuntu Server machine (hostname `optiplex`). Your job is to keep the node healthy
and help the operator (a beginner) understand what's happening.

## What runs here

| Thing | Where | Notes |
|---|---|---|
| logos-node | systemd **user** service `logos-node` | launcher: `~/logos-blockchain-runbook/run-node.sh` |
| dashboard | systemd **user** service `dashboard` | port **8090**, served to phone via `tailscale serve` |
| node HTTP API | `http://127.0.0.1:8080` | `/cryptarchia/info` is the health endpoint |

Working dir for everything: `~/logos-blockchain-runbook/`.

## First moves when something's wrong

```bash
# Is the node alive and advancing?
curl -s http://127.0.0.1:8080/cryptarchia/info    # expect HTTP 200, height rising

# Service state
systemctl --user status logos-node dashboard

# Logs: this kit's init-generated node.yaml logs to STDOUT, so journald has them:
journalctl --user -u logos-node -f
# LAYOUT NOTE: the bundled skills/ were written for the reference machine "Sneg", whose
# config was file-only with chain state under state/live-v0.1.2/. On THIS box state is
# ./state and the recovery snapshot is state/recovery/consensus/chain_service.json —
# translate the skills' state/live-v0.1.2/... paths to state/... accordingly.
```

## Known failure modes (recipes in `skills/`)

- **Crash-loop every ~10s after a power loss / dirty shutdown** → orphan-tip panic
  (`Could not retrieve block parent ... during recovery`). Fix: set `tip = lib` in the recovery
  snapshot. See [`skills/logos-node-crash-loop-tip-lib.md`](skills/logos-node-crash-loop-tip-lib.md).
  The launcher should self-heal this — see [`skills/logos-node-auto-rollback-guard.md`](skills/logos-node-auto-rollback-guard.md).
- **General recovery procedure** → [`skills/logos-node-recovery.md`](skills/logos-node-recovery.md).
- **Fresh node won't sync / `AllPeersFailed` crash loop** → don't fight IBD; copy synced state.
  See [`skills/logos-node-fresh-sync-copy-state.md`](skills/logos-node-fresh-sync-copy-state.md).
- **Node panics the first time it wins a slot, or wallet dies after a fast restart** →
  see [`skills/logos-node-circuits-and-wallet-pitfalls.md`](skills/logos-node-circuits-and-wallet-pitfalls.md).

## Rules

- This is a beginner's machine. Explain what you're doing in plain language before you do it.
- `loginctl enable-linger` MUST be set for the operator's user, or the systemd **user**
  services die when the SSH session ends. Verify it if services keep disappearing.
- Don't wipe node state to "fix" a crash loop — the `tip = lib` rollback recovers without a
  full resync. A wipe means days of re-syncing.
- Secrets (wallet keys live in `configs/live/node.yaml`) stay on this box. Never paste them
  into a repo or chat.

## See also

- `docs/` — the full setup guide, step by step.
- `docs/EXPERIENCE.md` — how this box was actually set up, with the real gotchas.

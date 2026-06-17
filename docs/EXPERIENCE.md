# The experiment — experience log

An honest, real-time record of setting up this node. Not a polished tutorial — the
actual play-by-play, including what bit us. The polished steps live in the other `docs/`.

## Who & what

- **Operator:** a 14-year-old, first server build, guided by a Claude Code agent.
- **Machine:** Dell Optiplex 3050 (SFF) — i5-7500 @ 3.4 GHz, 8 GB RAM, 500 GB SSD. Came with
  a licensed Windows 10 (wiped). Boots fast, healthy diagnostics, minor case scratches.
- **Goal:** a Logos node + dashboard, reachable from his phone, that he can troubleshoot with
  an on-box agent.
- **Date started:** 2026-06-17.

## Decisions made up front

- **Node + dashboard only** — no LLM/GPU/media stack (unlike the reference machine "Sneg").
- **Hostname:** `optiplex`.
- **His own wallet** — an independent identity on the Logos network, not a mirror of the mentor's.
- **Repo:** new standalone public repo (this one), meant to be shared with others.
- **Claude Code auth:** his own Anthropic account.
- **Reused from prior experience (Sneg):** the exact node + circuits binaries are copied over
  Tailscale rather than re-downloaded, so we start from a known-good build.

## Log

### Phase 0 — planning
- Pulled the Sneg setup history (post-install checklist, node migration, recovery skills) as the
  blueprint. Found the node + ZK-circuit tarballs already present and x86-64 — same arch as the
  Optiplex — so they can be copied directly.
- Scaffolded this repo and bundled the node-troubleshooting skills before the install even began.

### Phase 1 — Ubuntu install
- _(to be filled as it happens)_

---

## Takeaways (filled at the end)

_Main outtake report goes here once the node is live and synced._

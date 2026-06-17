#!/usr/bin/env bash
# Portable logos-node launcher with built-in dirty-shutdown self-heal.
# Drop this in ~/logos-blockchain-runbook/run-node.sh (the systemd unit ExecStart points here).
# Auto-detects paths from its own location — no hardcoded /home/<user>.
set -euo pipefail

RUNBOOK="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$RUNBOOK"

# --- locate artifacts (version-agnostic: picks whatever circuits dir is present) ---
NODE_BIN="$RUNBOOK/artifacts/node/logos-blockchain-node"
CIRCUITS_DIR="$(ls -d "$RUNBOOK"/artifacts/circuits/logos-blockchain-circuits-* 2>/dev/null | head -1)"
CONFIG="$RUNBOOK/configs/live/node.yaml"

STATE="$RUNBOOK/state/live-v0.1.2"
LOGDIR="$STATE/logs"
RECOVERY="$STATE/recovery/consensus/chain_service.json"

# --- self-heal: dirty-shutdown orphan-tip crash loop (upstream logos #2569) ---
# With systemd Restart=always, a corrupt boot self-heals in one cycle: first launch panics
# -> systemd restarts -> guard sees panic in the (file-only) log tail -> rolls tip = lib.
guard_recovery() {
  [ -d "$LOGDIR" ] || return 0
  [ -f "$RECOVERY" ] || return 0
  local latest; latest=$(ls -t "$LOGDIR" 2>/dev/null | head -1) || return 0
  [ -n "$latest" ] || return 0
  tail -n 60 "$LOGDIR/$latest" | grep -qa "Could not retrieve block parent.*during recovery" || return 0
  echo "[run-node] recovery panic detected — evaluating auto-rollback"   # -> journald
  python3 - "$RECOVERY" <<'PY'
import json, os, shutil, sys
p = sys.argv[1]
try: d = json.load(open(p))
except Exception as e: print(f"[run-node] cannot parse ({e}); manual fix"); sys.exit(0)
if d.get("tip") == d.get("lib"): print("[run-node] tip already == lib"); sys.exit(0)
if d.get("storage_blocks_to_remove") != []: print("[run-node] unexpected state; manual fix"); sys.exit(0)
shutil.copy2(p, p + ".bak.autorollback")
d["tip"] = d["lib"]; json.dump(d, open(p+".tmp","w")); os.replace(p+".tmp", p)
print("[run-node] auto-rollback applied")
PY
}
guard_recovery

export LOGOS_BLOCKCHAIN_CIRCUITS="$CIRCUITS_DIR"
exec "$NODE_BIN" "$CONFIG"

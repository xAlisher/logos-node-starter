---
id: logos-node-auto-rollback-guard
title: Self-heal logos-node dirty-shutdown crash loop with a pre-start guard in the launcher
phase: recovery
type: pattern
severity: high
severity_reason: Without it, every dirty shutdown needs a manual recovery edit or the node crash-loops indefinitely
machines: ["sneg"]
distro: "ubuntu-24.04"
kernel: ""
source: extracted-local
last_used: "2026-06-16"
created: "2026-06-16"
status: active
---

## Problem

logos-node crash-loops after every dirty shutdown (orphan tip, upstream #2569 — see
`logos-node-crash-loop-tip-lib`). Manually editing the recovery snapshot each time is not
sustainable. Automate the `tip = lib` fix as a guard the launcher runs before each start.

## Recipe

Add `guard_recovery` to `~/logos-blockchain-runbook/run-node.sh`, called before launching
the node. With systemd `Restart=always`, a dirty boot self-heals in one restart cycle:
first launch panics → systemd restarts → guard sees the panic in the log tail → rolls
`tip = lib` → node recovers and re-syncs `(lib, head]`.

```bash
guard_recovery() {
  [ -d "$LOGDIR" ] || return 0          # state/live-v0.1.2/logs
  [ -f "$RECOVERY" ] || return 0        # state/live-v0.1.2/recovery/consensus/chain_service.json
  local latest; latest=$(ls -t "$LOGDIR" 2>/dev/null | head -1) || return 0
  [ -n "$latest" ] || return 0
  tail -n 60 "$LOGDIR/$latest" | grep -qa "Could not retrieve block parent.*during recovery" || return 0
  echo "[run-node] recovery panic detected — evaluating auto-rollback"   # echo -> journald
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
```

## Why

Three design rules that matter, learned the hard way:
- **Trigger on the panic-in-log signal, NOT on `tip != lib`.** A healthy syncing node
  normally has tip ahead of lib, so keying off `tip != lib` would clobber good state on
  every restart. The panic in the (file-only) recovery log is the only reliable pre-start
  signal — the node dies before the API binds, so nothing is queryable over HTTP.
- **Idempotent** — once `tip == lib` it never fires again, so deeper corruption fails
  loudly for manual intervention instead of silently looping rollbacks.
- **Conservative** — bails without mutating on unparseable JSON or unexpected
  `storage_blocks_to_remove`. `echo` lands in journald (the node's own tracing is file-only).

## See also

- logos-node-crash-loop-tip-lib (the manual fix this automates)

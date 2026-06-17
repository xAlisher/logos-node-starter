#!/usr/bin/env bash
# Portable logos-node launcher. Drop in ~/logos-blockchain-runbook/run-node.sh
# (the systemd unit's ExecStart points here). Auto-detects paths from its own
# location — no hardcoded /home/<user> and no hardcoded circuits version.
#
# This is the plain, verified launcher. For power-loss resilience, add the
# dirty-shutdown self-heal guard described in
# ../skills/logos-node-auto-rollback-guard.md (adapt its state/recovery path to
# your config's base_folder before relying on it).
set -euo pipefail

RUNBOOK="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$RUNBOOK"

# find the circuits dir; fail loudly if missing (don't start the node blind to its circuits).
# NOTE: assigning separately, not `export VAR=$(...)`, so a failed glob still trips `set -e`.
CIRC_DIR="$(ls -d "$RUNBOOK"/artifacts/circuits/logos-blockchain-circuits-* 2>/dev/null | head -1)"
[ -n "$CIRC_DIR" ] && [ -d "$CIRC_DIR" ] || {
  echo "[run-node] circuits not found in $RUNBOOK/artifacts/circuits — run scripts/fetch-artifacts.sh" >&2
  exit 1
}
export LOGOS_BLOCKCHAIN_CIRCUITS="$CIRC_DIR"
exec "$RUNBOOK/artifacts/node/logos-blockchain-node" "$RUNBOOK/configs/live/node.yaml"

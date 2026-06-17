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

export LOGOS_BLOCKCHAIN_CIRCUITS="$(ls -d "$RUNBOOK"/artifacts/circuits/logos-blockchain-circuits-* | head -1)"
exec "$RUNBOOK/artifacts/node/logos-blockchain-node" "$RUNBOOK/configs/live/node.yaml"

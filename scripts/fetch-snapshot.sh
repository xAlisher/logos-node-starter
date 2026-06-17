#!/usr/bin/env bash
# Download a synced chain snapshot (db + recovery) and drop it into the node's
# state/, so a fresh node skips the unreliable from-scratch Initial Block Download
# and comes up Online in seconds. Verifies SHA256. Plain curl, no GitHub CLI.
#
# IMPORTANT: stop the node first (this replaces its chain state):
#   systemctl --user stop logos-node
#
# Usage:  scripts/fetch-snapshot.sh [runbook-dir]   (default: ~/logos-blockchain-runbook)
set -euo pipefail

REL="https://github.com/xAlisher/logos-node-starter/releases/download/chain-snapshot-latest"
SNAP="chain-snapshot.tar.gz"
RUNBOOK="${1:-$HOME/logos-blockchain-runbook}"

# refuse to clobber a running node
if systemctl --user is-active --quiet logos-node 2>/dev/null; then
  echo "✋ logos-node is running. Stop it first:  systemctl --user stop logos-node"; exit 1
fi

cd "$RUNBOOK"
echo "↓ chain snapshot (~300-400 MB)..."
curl -fL --retry 3 -o "/tmp/$SNAP" "$REL/$SNAP"
curl -fsSL --retry 3 -o "/tmp/snap-SHA256SUMS.txt" "$REL/SHA256SUMS.txt"

echo "↪ verifying checksum..."
( cd /tmp && sha256sum -c snap-SHA256SUMS.txt )

echo "↪ installing into state/ (replacing db + recovery)..."
mkdir -p state
rm -rf state/db state/recovery
tar xzf "/tmp/$SNAP" -C state          # extracts db/ and recovery/
rm -f "/tmp/$SNAP" /tmp/snap-SHA256SUMS.txt

echo "✅ snapshot installed. Start the node:  systemctl --user start logos-node"
echo "   then watch it reach Online:  curl -s http://127.0.0.1:8080/cryptarchia/info"

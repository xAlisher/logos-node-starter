#!/usr/bin/env bash
# MAINTAINER script — regenerate and publish the chain snapshot to the
# `chain-snapshot-latest` GitHub Release, so fresh nodes can fetch a recent
# synced state. Run from a machine that has `gh` (authenticated) and SSH access
# to a healthy, synced node on the canonical chain.
#
# Usage:  scripts/publish-snapshot.sh <ssh-target-of-synced-node> [owner/repo]
# Example: scripts/publish-snapshot.sh optiplex
#
# Good for a cron (e.g. weekly) on a maintainer box.
set -euo pipefail

NODE="${1:?usage: publish-snapshot.sh <ssh-target> [owner/repo]}"
REPO="${2:-xAlisher/logos-node-starter}"
TAG="chain-snapshot-latest"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

echo "→ creating consistent snapshot on $NODE (brief node stop)..."
ssh "$NODE" 'export XDG_RUNTIME_DIR=/run/user/$(id -u)
  systemctl --user stop logos-node
  cd ~/logos-blockchain-runbook/state && tar czf /tmp/chain-snapshot.tar.gz db recovery
  systemctl --user start logos-node'

rsync -a "$NODE:/tmp/chain-snapshot.tar.gz" "$TMP/chain-snapshot.tar.gz"
ssh "$NODE" 'rm -f /tmp/chain-snapshot.tar.gz'
( cd "$TMP" && sha256sum chain-snapshot.tar.gz > SHA256SUMS.txt )

echo "→ publishing to $REPO ($TAG)..."
if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  gh release upload "$TAG" "$TMP/chain-snapshot.tar.gz" "$TMP/SHA256SUMS.txt" --repo "$REPO" --clobber
else
  gh release create "$TAG" --repo "$REPO" --title "Chain snapshot (rolling latest)" \
    --notes "Latest db+recovery snapshot for fast fresh-node sync. Pulled by scripts/fetch-snapshot.sh. Regenerate with scripts/publish-snapshot.sh." \
    "$TMP/chain-snapshot.tar.gz" "$TMP/SHA256SUMS.txt"
fi
echo "✅ snapshot published $(date -u +%FT%TZ) ($(du -h "$TMP/chain-snapshot.tar.gz" | cut -f1))"

#!/usr/bin/env bash
# Download the Logos node binary + ZK circuits (linux-x86_64) from the OFFICIAL
# Logos release, verifying SHA256, into the runbook's artifacts/. No GitHub CLI
# needed — plain curl.
#
# We pin version 0.1.2 and verify against checksums we tested against. To move to
# a newer node, bump VERSION/CIRCUITS + the two SHA256 values (get them from the
# upstream release: https://github.com/logos-blockchain/logos-blockchain/releases).
#
# Usage:  scripts/fetch-artifacts.sh [runbook-dir]   (default: ~/logos-blockchain-runbook)
set -euo pipefail

VERSION="0.1.2"
CIRCUITS="v0.4.2"
REL="https://github.com/logos-blockchain/logos-blockchain/releases/download/${VERSION}"
NODE_TGZ="logos-blockchain-node-linux-x86_64-${VERSION}.tar.gz"
CIRC_TGZ="logos-blockchain-circuits-${CIRCUITS}-linux-x86_64.tar.gz"
NODE_SHA="6c0aaf2e2d732dfe4b46a649f9e3e96e66f5ba36bff436325da26c99b4fa3ed8"
CIRC_SHA="e9131ffac8b08a80e1a7152b34fdd5d5c52674d4cb396e8162131ca5dd7c858d"

RUNBOOK="${1:-$HOME/logos-blockchain-runbook}"
cd "$RUNBOOK"
mkdir -p artifacts/node artifacts/circuits
cd artifacts

echo "↓ node binary (official Logos ${VERSION})..."
curl -fL --retry 3 -o "$NODE_TGZ" "$REL/$NODE_TGZ"
echo "$NODE_SHA  $NODE_TGZ" | sha256sum -c -

echo "↓ circuits ${CIRCUITS} (official)..."
curl -fL --retry 3 -o "$CIRC_TGZ" "$REL/$CIRC_TGZ"
echo "$CIRC_SHA  $CIRC_TGZ" | sha256sum -c -

echo "↪ extracting..."
tar xzf "$NODE_TGZ" -C node          # tarball holds the bare 'logos-blockchain-node'
tar xzf "$CIRC_TGZ" -C circuits      # tarball holds 'logos-blockchain-circuits-v0.4.2-linux-x86_64/'
chmod +x node/logos-blockchain-node
rm -f "$NODE_TGZ" "$CIRC_TGZ"

echo "✅ artifacts ready (from official Logos release, checksum-verified):"
echo "   node:     $(ls node/)"
echo "   circuits: $(ls -d circuits/logos-blockchain-circuits-*)"

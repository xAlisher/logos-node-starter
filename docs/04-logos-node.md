# 04 — The Logos node

**Who:** the mentor, over SSH. The longest phase. Working dir on the node:
`~/logos-blockchain-runbook`.

## 1. Get the code + the binaries

The runbook/dashboard code is public; the node binary + ZK circuits are release artifacts
(x86-64) that live *outside* git.

```bash
git clone --depth 1 https://github.com/xAlisher/logos-node-dashboard.git ~/logos-blockchain-runbook
cd ~/logos-blockchain-runbook
mkdir -p artifacts/node artifacts/circuits configs/live
```

Fetch the node binary + circuits straight from the **official Logos release** (pinned to 0.1.2,
checksum-verified):

```bash
# clone this starter repo somewhere too, then:
~/logos-node-starter/scripts/fetch-artifacts.sh
# downloads from github.com/logos-blockchain/logos-blockchain/releases/0.1.2,
# verifies SHA256, extracts into artifacts/node + artifacts/circuits.
```

This lands `artifacts/node/logos-blockchain-node` and
`artifacts/circuits/logos-blockchain-circuits-v0.4.2-linux-x86_64/` (containing `poc pol poq prover
verifier VERSION zksign`). If you already have a machine with them, `rsync` works too.

## 2. Mint the operator's OWN identity

The binary generates a fresh config with brand-new keys — its own `node_key`, `funding_pk`
(wallet), and consensus keys. Pass the testnet's bootstrap peers and the HTTP listen address:

```bash
./artifacts/node/logos-blockchain-node init \
  -p /ip4/65.109.51.37/udp/3000/quic-v1/p2p/12D3KooWFrouXfmrR4nsLMtE7wu15DoMJ6VtoUtHinREZCvbWHar \
     /ip4/65.109.51.37/udp/3001/quic-v1/p2p/12D3KooWJRGau8M1rjT7R5e4YYsgdFhsMX35nRDtMwCDjxQkXAHz \
     /ip4/65.109.51.37/udp/3002/quic-v1/p2p/12D3KooWQXJavMDTRscjauFSgVAB1VLB6Rzpy2uY5SU9Tk7927tb \
     /ip4/65.109.51.37/udp/3003/quic-v1/p2p/12D3KooWSQc7CcGtvWDPF1yCbBthFnQjprfCVHmfmNDUrSmqQsU1 \
  -o configs/live/node.yaml --http-addr 0.0.0.0:8080
./artifacts/node/logos-blockchain-node --check-config configs/live/node.yaml   # → "Configs are valid!"
```

Note the operator's wallet key: `grep funding_pk configs/live/node.yaml`. **This is their identity
— keep `node.yaml` private (it holds secret keys); never commit it.**

## 3. Circuits + launcher + service

```bash
# circuits where the node looks when it wins a slot
ln -sfn ~/logos-blockchain-runbook/artifacts/circuits/logos-blockchain-circuits-v0.4.2-linux-x86_64 \
        ~/.logos-blockchain-circuits

# launcher (see ../scripts/run-node.sh) → ~/logos-blockchain-runbook/run-node.sh, chmod +x
# systemd USER service (see ../systemd/logos-node.service) → ~/.config/systemd/user/logos-node.service
sudo loginctl enable-linger $USER        # ← REQUIRED, or the service dies on logout
systemctl --user daemon-reload
systemctl --user enable --now logos-node
```

## 4. Sync the chain — the real wall, and the reliable fix

A fresh node must do an **Initial Block Download (IBD)**. On a large testnet (this one was ~288k
blocks) IBD from the public bootstrap host is **unreliable**: it serves a chunk, drops the stream
(`sending stopped by peer`), and the node exits with `Initial Block Download failed:
AllPeersFailed`, then crash-loops (each restart re-replays all stored blocks). We confirmed this is
not fixed merely by adding one more peer.

**The reliable fix: copy the synced chain DB from a healthy node** (only valid if it's on the
canonical chain). You copy *chain data*, but keep *your own* `node.yaml` (your own `node_key`), so
there's no p2p identity collision:

```bash
# stop both nodes for a consistent RocksDB snapshot
ssh <synced-node> 'systemctl --user stop logos-node'
systemctl --user stop logos-node            # on the new node
rm -rf ~/logos-blockchain-runbook/state/* ~/logos-blockchain-runbook/db/*

# stream chain data node-to-node (skip logs + backups). Mind the base_folder mapping:
#   source uses base_folder ./state/live-v0.1.2 ; this node uses ./state
ssh <synced-node> 'cd ~/logos-blockchain-runbook/state/live-v0.1.2 && tar c --exclude=logs --exclude="*.bak*" .' \
  | (cd ~/logos-blockchain-runbook/state && tar x)

ssh <synced-node> 'systemctl --user start logos-node'   # restart the donor immediately
systemctl --user start logos-node                       # start ours
```

Only `db/` + `recovery/` are needed (~600 MB); the recovery snapshot lets the node **jump straight
to the tip** — Online in seconds, no full replay. A wallet-key mismatch in the copied state is
harmless; the node syncs regardless.

> No healthy node to copy from? You're stuck with public IBD — add several *diverse,
> currently-active* peers (not all one host) and expect a slow, flaky first sync.

## 5. Verify

```bash
curl -s http://127.0.0.1:8080/cryptarchia/info     # mode should reach "Online", height tracking the tip
systemctl --user show logos-node -p NRestarts --value   # 0 = stable
```

**Logs:** this config logs to **stdout**, so `journalctl --user -u logos-node -f` works (nice).
(Some setups are file-only — then read `state/.../logs/` directly.)

→ continue with [`05-dashboard.md`](05-dashboard.md).

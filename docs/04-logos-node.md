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

## 2. Mint the operator's OWN identity (IBD disabled)

The binary generates a fresh config with brand-new keys — its own `node_key`, `funding_pk`
(wallet), and consensus keys. Pass the testnet's bootstrap peers as **plain multiaddrs — no
`/p2p/<peerid>`** — and the HTTP listen address:

```bash
./artifacts/node/logos-blockchain-node init \
  -p /ip4/65.109.51.37/udp/3000/quic-v1 \
     /ip4/65.109.51.37/udp/3001/quic-v1 \
     /ip4/65.109.51.37/udp/3002/quic-v1 \
     /ip4/65.109.51.37/udp/3003/quic-v1 \
  -o configs/live/node.yaml --http-addr 127.0.0.1:8080
./artifacts/node/logos-blockchain-node --check-config configs/live/node.yaml   # → "Configs are valid!"
```

> **⚠️ Leave the `/p2p/<peerid>` OFF.** Per the Logos devs, the peerids are exactly what enable
> **IBD** (the bulk Initial Block Download) — and IBD has been failing on this testnet since
> ~mid-May. Multiaddrs *with* peerids → IBD on (broken, `AllPeersFailed` crash loop); *without* →
> IBD off, and the node syncs via normal online sync. The official v0.1.2 release notes correctly use
> this peerless form — we originally tripped by copying an *older community runbook* config whose
> multiaddrs still included peerids. Confirm it's off:
> `grep -A1 "ibd:" configs/live/node.yaml` → should read `peers: []`.

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

## 4. Sync the chain

Because IBD is disabled (step 2), the node connects to the bootstrap peers and **syncs the chain via
normal online sync** — skipping the broken bulk download entirely. Just start it (step 3) and let it
run; mode goes `Bootstrapping` → `Online` with height climbing.

A fresh online sync can take a while. **To be Online in seconds instead, install a synced chain
snapshot** (optional speed-up):

```bash
systemctl --user stop logos-node
~/logos-node-starter/scripts/fetch-snapshot.sh    # downloads + checksum-verifies, installs into state/
systemctl --user start logos-node
```

(See the README's trust/freshness note on what the snapshot trusts. If you already run your own
synced node, you can instead copy its `state/db` + `state/recovery`, keeping your own `node.yaml`.)

> **Why this changed:** the original build used the **peerid** form (IBD on) and hit `AllPeersFailed`
> crash-loops — see [`EXPERIENCE.md`](EXPERIENCE.md) and upstream
> [logos #2967](https://github.com/logos-blockchain/logos-blockchain/issues/2967). Peerless `init`
> (IBD off) is the upstream-recommended fix.

## 5. Verify

```bash
curl -s http://127.0.0.1:8080/cryptarchia/info     # mode should reach "Online", height tracking the tip
systemctl --user show logos-node -p NRestarts --value   # 0 = stable
```

**Logs:** this config logs to **stdout**, so `journalctl --user -u logos-node -f` works (nice).
(Some setups are file-only — then read `state/.../logs/` directly.)

→ continue with [`05-dashboard.md`](05-dashboard.md).

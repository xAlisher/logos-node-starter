# 04 — Logos node

_Filled in live. Plan:_

1. Clone the runbook/dashboard repo to `~/logos-blockchain-runbook`.
2. Copy known-good node + circuits binaries (x86-64) over Tailscale from the reference machine,
   OR fetch the matching release. (artifacts/node/ + artifacts/circuits/)
3. Generate the operator's OWN wallet/keys → fresh `configs/live/node.yaml`
   (node_key + funding_pk + consensus keys). This is his independent identity.
4. Symlink circuits to `~/.logos-blockchain-circuits` (node looks there when it wins a slot).
5. Drop in the portable `run-node.sh` (see ../scripts/run-node.sh) with the self-heal guard.
6. Install systemd user unit (../systemd/logos-node.service), `loginctl enable-linger`, enable+start.
7. Verify: `curl -s http://127.0.0.1:8080/cryptarchia/info` → height rising.

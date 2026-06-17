# 05 — Dashboard + phone access

**Who:** the mentor, over SSH. ~5 minutes. The payoff: the operator sees their node from their
phone.

## 1. Run the dashboard as a service

The dashboard ships in the runbook repo (`dashboard/`) and is **pure Python stdlib — no pip
install needed**. `dashboard/run.sh` auto-derives the wallet key from `node.yaml` (`funding_pk`).

Install the systemd **user** unit (see [`../systemd/dashboard.service`](../systemd/dashboard.service))
to `~/.config/systemd/user/dashboard.service`, then:

```bash
systemctl --user daemon-reload
systemctl --user enable --now dashboard
curl -s http://127.0.0.1:8090/ | grep -i '<title>'      # → "Logos Node Status"
curl -s http://127.0.0.1:8090/api/status                # → live node info (proxied)
```

Key env in the unit: `HOST=0.0.0.0`, `PORT=8090`, `ZONE_CHANNEL=<operator>`,
`NODE_LOG_DIR=%h/logos-blockchain-runbook` (where this config writes logs).

## 2. Publish it to the tailnet (private)

```bash
sudo tailscale serve --bg 8090
sudo tailscale serve status        # shows: https://<host>.<tailnet>.ts.net → 127.0.0.1:8090
```

This gives a URL like **`https://optiplex.tail8ce139.ts.net/`**, reachable **only inside your
tailnet** (not the public internet — that would be `tailscale funnel`, which we deliberately don't
use). Tailscale provisions the HTTPS cert automatically.

## 3. Verify, then hand the URL to the operator

```bash
# from any other tailnet device:
curl -s https://<host>.<tailnet>.ts.net/api/status     # confirms end-to-end reachability
```

On the operator's **phone** (Tailscale app ON, signed into the shared tailnet — see `03`): open the
URL in any browser. They should see their node's height, `Online` status, peers, and wallet.

→ continue with [`06-claude-code.md`](06-claude-code.md).

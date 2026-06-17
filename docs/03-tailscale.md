# 03 — Tailscale

_Filled in live. Outline:_

1. Install: `curl -fsSL https://tailscale.com/install.sh | sh`
2. Join the tailnet: `sudo tailscale up` → open the URL it prints, authorize on the mentor's account.
3. Note the Tailscale IP: `tailscale ip -4`
4. Now reachable from anywhere as `ssh <user>@<tailscale-ip>` (or by magicDNS name `optiplex`).

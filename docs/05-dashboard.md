# 05 — Dashboard + phone access

_Filled in live. Plan:_

1. Dashboard ships in the runbook repo (`dashboard/`). Python deps via venv.
2. systemd user unit (../systemd/dashboard.service) → serves 0.0.0.0:8090, wallet key auto-derived.
3. Expose to phone over Tailscale: `tailscale serve --bg 8090`
   → gives an https://optiplex.<tailnet>.ts.net URL openable from his phone (phone joined to tailnet).
4. Verify on the phone.

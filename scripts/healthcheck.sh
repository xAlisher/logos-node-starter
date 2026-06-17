#!/usr/bin/env bash
# Run ON the node. Prints a green/red summary so you KNOW it all worked.
# Usage:  scripts/healthcheck.sh
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
ok(){ echo "  ✅ $1"; }; warn(){ echo "  ⏳ $1"; }; bad(){ echo "  ❌ $1"; }

echo "── Logos node healthcheck ──"

info=$(curl -s --max-time 5 http://127.0.0.1:8080/cryptarchia/info 2>/dev/null)
if [ -n "$info" ]; then
  read -r mode h < <(echo "$info" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d['mode'],d['height'])" 2>/dev/null)
  if [ "$mode" = "Online" ]; then ok "node Online (height $h)"; else warn "node mode=$mode height=$h (still syncing)"; fi
else
  bad "node API not responding on :8080"
fi

for s in logos-node dashboard; do
  st=$(systemctl --user is-active "$s" 2>/dev/null)
  [ "$st" = active ] && ok "service $s: active" || bad "service $s: $st"
done

if loginctl show-user "$USER" -p Linger 2>/dev/null | grep -qi yes; then
  ok "linger enabled (services survive logout)"
else
  bad "linger NOT set — run: sudo loginctl enable-linger $USER"
fi

curl -s --max-time 5 http://127.0.0.1:8090/ 2>/dev/null | grep -qi logos \
  && ok "dashboard serving on :8090" || bad "dashboard not serving on :8090"

if command -v tailscale >/dev/null && tailscale status >/dev/null 2>&1; then
  ok "tailscale up ($(tailscale ip -4 2>/dev/null | head -1)) — dashboard URL: https://$(tailscale status --json 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);print(d['Self']['DNSName'].rstrip('.'))" 2>/dev/null)/"
else
  bad "tailscale not up"
fi
echo "────────────────────────────"

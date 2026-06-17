# 02 — Base setup (over SSH)

_Filled in live during the build. Outline:_

1. First SSH in: `ssh <user>@<ip>` (keys imported during install — no password).
2. Passwordless sudo (optional, convenience): `echo "<user> ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/<user>`
3. Timezone: `sudo timedatectl set-timezone Europe/Madrid`
4. Update: `sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y`
5. Essentials: `sudo apt install -y tmux git curl python3 python3-venv`
6. Confirm hostname is `optiplex`: `hostnamectl` (set with `sudo hostnamectl set-hostname optiplex` if not).

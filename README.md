# logos-node-starter

**This repo lets you install and run a Logos node on a cheap PC** — with remote access to it over
Tailscale (from your phone or any machine) and a **dashboard showing your node's status**.

It was compiled from the real experience of a **14-year-old boy installing Ubuntu Server and
configuring a Logos node for the first time in his life**. The machine was bought second-hand on
Wallapop: <https://es.wallapop.com/item/ordenador-dell-optiplex-3050-ssd-500gb-i5-1266524228>.
**Hardware weaker than that config has not been tested by this repo's maintainers.**

👉 **Point your AI agent at this repo and follow the instructions** (see [`SETUP-AGENT.md`](SETUP-AGENT.md)).
If any step feels complex or hard to understand, please **[file an issue](../../issues)** — that
feedback is how the guide gets smoother for the next person.

## ✅ Before you start — make sure you have

> - [ ] **A machine that meets the requirements** — x86-64, **≥4 GB RAM, ≥120 GB disk** (tested on a
>       Dell Optiplex 3050 / i5-7500 / 8 GB / 500 GB SSD; weaker is untested).
> - [ ] **A USB stick (≥8 GB)** flashed with **Ubuntu Server 24.04 LTS**
>       — [download the ISO](https://ubuntu.com/download/server), then flash it with
>       [balenaEtcher](https://etcher.balena.io/) (easiest, Win/Mac/Linux) or
>       [Rufus](https://rufus.ie/) (Windows). The stick gets erased.
> - [ ] **An Ethernet cable** from the machine to your router (wired is simpler than WiFi).
> - [ ] **A GitHub account** — the installer imports your SSH keys from it so you can log in without
>       passwords. No keys yet? `ssh-keygen -t ed25519`, then add the `.pub` to GitHub → SSH keys.
> - [ ] **A Tailscale account** (Google/Apple/GitHub login is fine), *or* an invite to someone's
>       existing tailnet — for remote + phone access.
> - [ ] **An on-box AI helper** *(optional)* — an Anthropic account for **Claude Code** (Phase 06),
>       *or any comparable coding agent, local or cloud,* that can read this repo's `CLAUDE.md` +
>       `skills/`. Only if you want the machine to help troubleshoot itself.
> - [ ] **About one evening**, and the OK to **erase whatever is currently on the machine**.

Full details in [`docs/00-before-you-start.md`](docs/00-before-you-start.md).

## What you get

- A minimal headless **Ubuntu Server** box, reachable by SSH.
- A **Logos node** under systemd (survives reboots), synced and Online.
- A **dashboard** of node status, served privately to your **phone** over Tailscale.
- Optionally, an **on-box AI helper** (Claude Code, or any comparable local/cloud agent), primed
  with this node's setup so it can help you troubleshoot in plain language.

## Dependencies

You install these along the way (the guide and scripts handle each):

| Dependency | Role | Where |
|---|---|---|
| **Ubuntu Server 24.04 LTS** | the OS | `docs/01` |
| **git, curl, python3** | basics (dashboard is pure-stdlib Python) | `docs/02` |
| **tmux** | long jobs survive SSH disconnects; share a live session | `docs/02` |
| **tailscale** | private remote access + phone dashboard | `docs/03` |
| **logos-node-dashboard** | the node + dashboard code (the "runbook") | `docs/04` |
| **logos-blockchain-node + ZK circuits** | the node binary + proving circuits (official Logos release, checksum-verified) | `scripts/fetch-artifacts.sh` |
| **systemd (user services) + linger** | keep node & dashboard running across reboots | `docs/04`, `docs/05` |
| **Claude Code** *(optional)* | on-box troubleshooting agent | `docs/06` |

## Hardware target

Tested on the machine below. **Anything weaker is untested** — expect to do some debugging:

| Part | Spec (tested) |
|---|---|
| Machine | Dell Optiplex 3050 (SFF) — bought on Wallapop |
| CPU | Intel Core i5-7500 @ 3.4 GHz (4c) |
| RAM | 8 GB |
| Disk | 500 GB SSD |
| GPU | none needed — this is a node, not an LLM box |

## Do it with an agent (recommended)

The original build was smooth because a beginner had a live AI agent guiding every step. **You can
have the same.** Read [`SETUP-AGENT.md`](SETUP-AGENT.md) and point Claude Code (or any agent) at
this repo — it will size up your experience and hardware, then walk you through, one step at a time.

## The guide, in order

0. [`docs/00-before-you-start.md`](docs/00-before-you-start.md) — shopping list + accounts + install USB
1. [`docs/01-ubuntu-install.md`](docs/01-ubuntu-install.md) — install minimal Ubuntu Server (you, at the machine)
2. [`docs/02-base-setup.md`](docs/02-base-setup.md) — hostname, sudo, updates, tmux (over SSH)
3. [`docs/03-tailscale.md`](docs/03-tailscale.md) — join your tailnet, reach it from anywhere
4. [`docs/04-logos-node.md`](docs/04-logos-node.md) — install + run the node (your own wallet)
5. [`docs/05-dashboard.md`](docs/05-dashboard.md) — dashboard + phone access via Tailscale
6. [`docs/06-claude-code.md`](docs/06-claude-code.md) — Claude Code + the skills bundle

…and [`docs/EXPERIENCE.md`](docs/EXPERIENCE.md) — the honest play-by-play of the original build.

## Helper scripts

| Script | What it does |
|---|---|
| [`scripts/fetch-artifacts.sh`](scripts/fetch-artifacts.sh) | download node binary + circuits from the **official Logos release** (checksum-verified) |
| [`scripts/fetch-snapshot.sh`](scripts/fetch-snapshot.sh) | install a synced chain snapshot so you skip the unreliable from-scratch sync |
| [`scripts/run-node.sh`](scripts/run-node.sh) | the node launcher (used by the systemd unit) |
| [`scripts/healthcheck.sh`](scripts/healthcheck.sh) | one command that confirms node Online, dashboard up, services healthy |
| [`scripts/publish-snapshot.sh`](scripts/publish-snapshot.sh) | maintainer: regenerate + publish the chain snapshot release |

## Skills — the self-troubleshooting kit

[`skills/`](skills/) holds recipes distilled from **months of running a node on the Logos testnet**
(plus this build). [`CLAUDE.md`](CLAUDE.md) wires them into Claude Code so the on-box agent knows
your exact setup and how to fix it:

- [`logos-node-fresh-sync-copy-state`](skills/logos-node-fresh-sync-copy-state.md) — fresh-node IBD
  fails (`AllPeersFailed`); bring it Online by copying synced state. Includes the peer-ID-from-key trick.
- [`logos-node-circuits-and-wallet-pitfalls`](skills/logos-node-circuits-and-wallet-pitfalls.md) —
  node panics the first time it wins a slot (circuits symlink); wallet dies after a fast restart.
- [`logos-node-crash-loop-tip-lib`](skills/logos-node-crash-loop-tip-lib.md) — dirty-shutdown
  crash loop; recover with `tip = lib` (not a wipe).
- [`logos-node-auto-rollback-guard`](skills/logos-node-auto-rollback-guard.md) — self-heal that
  crash loop automatically from the launcher.
- [`logos-node-recovery`](skills/logos-node-recovery.md) — the general recovery procedure.

## The hardest part, up front

The node's **first sync** is the wall. On a large testnet, from-scratch Initial Block Download is
unreliable. The fast, reliable path is `scripts/fetch-snapshot.sh` (or copying state from your own
trusted synced node). Everything else went smoothly.

### About the chain snapshot (trust & freshness)

- **Trust:** the snapshot is checksum-verified for **integrity** (exact bytes we published), but a
  checksum can't prove it's the *canonical* chain — you're trusting that we keep the source node on
  it. The checksum lives in the same release as the snapshot, so it guards against corruption, not a
  compromised release host — a planned hardening is to **sign** it with a public key shipped in this
  repo. Prefer your own trusted node's state if you have one.
- **Freshness:** it's a point-in-time copy; a restoring node catches the remaining gap via normal
  live gossip (only *bulk* from-scratch sync is the broken part). Maintainers refresh it with
  `scripts/publish-snapshot.sh`.

## Support trio

Three things make remote help painless: **SSH** (get in), **Tailscale** (reach it from anywhere),
**tmux** (long jobs survive disconnects; share a live session). All three are set up early.

---

*Not affiliated with Logos. Community setup guide. Hardware below the tested config is untested.*

# logos-node-starter

A reproducible, beginner-friendly guide to running a **Logos blockchain node + dashboard**
on a cheap second-hand x86 PC, accessible from your phone over Tailscale — and with
**Claude Code installed on the box itself** so you can troubleshoot the node by talking to an agent.

> Born from a real experiment: a 14-year-old setting up his first server (a Dell Optiplex 3050,
> i5-7500, 8 GB RAM, 500 GB SSD) with agent guidance. See [`docs/EXPERIENCE.md`](docs/EXPERIENCE.md)
> for the honest play-by-play — what worked, what bit us, and how long it took.

## What you end up with

- A minimal **Ubuntu Server** machine, headless, reachable by SSH.
- A **Logos node** running under systemd (survives reboots), syncing the chain.
- A **dashboard** showing node status, served to your phone via a private Tailscale URL.
- **Claude Code** on the node with a bundled set of node-troubleshooting skills, so the
  machine can largely diagnose itself.

## Hardware target

Anything x86-64 with ≥4 GB RAM and ≥120 GB disk works. This guide was tested on:

| Part | Spec |
|---|---|
| Machine | Dell Optiplex 3050 (SFF) |
| CPU | Intel Core i5-7500 @ 3.4 GHz (4c) |
| RAM | 8 GB |
| Disk | 500 GB SSD |
| GPU | none needed — this is a node, not an LLM box |

## The guide, in order

1. [`docs/01-ubuntu-install.md`](docs/01-ubuntu-install.md) — install minimal Ubuntu Server (you, at the machine)
2. [`docs/02-base-setup.md`](docs/02-base-setup.md) — hostname, sudo, updates, tmux (over SSH)
3. [`docs/03-tailscale.md`](docs/03-tailscale.md) — join your tailnet, reach it from anywhere
4. [`docs/04-logos-node.md`](docs/04-logos-node.md) — install + run the node (own wallet)
5. [`docs/05-dashboard.md`](docs/05-dashboard.md) — dashboard + phone access via Tailscale
6. [`docs/06-claude-code.md`](docs/06-claude-code.md) — Claude Code + the skills bundle

## The self-troubleshooting kit

[`skills/`](skills/) holds battle-tested recipes for the failure modes this node actually hits
(dirty-shutdown crash loops, recovery rollbacks, log locations). [`CLAUDE.md`](CLAUDE.md) wires
them into Claude Code so the agent on the box knows your exact setup.

## Support trio

Three things make remote help painless: **SSH** (get in), **Tailscale** (reach it from anywhere),
**tmux** (long jobs survive disconnects; you can share a live session). All three are set up early.

---

*Not affiliated with Logos. This is a community setup guide.*

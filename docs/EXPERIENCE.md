# The experiment — experience log

An honest, real-time record of setting up this node. Not a polished tutorial — the
actual play-by-play, including what bit us. The polished steps live in the other `docs/`.

## Who & what

- **Operator:** a 14-year-old, first server build, guided by a Claude Code agent.
- **Machine:** Dell Optiplex 3050 (SFF) — i5-7500 @ 3.4 GHz, 8 GB RAM, 500 GB SSD. Came with
  a licensed Windows 10 (wiped). Boots fast, healthy diagnostics, minor case scratches.
- **Goal:** a Logos node + dashboard, reachable from his phone, that he can troubleshoot with
  an on-box agent.
- **Date started:** 2026-06-17.

## Decisions made up front

- **Node + dashboard only** — no LLM/GPU/media stack (unlike the reference machine "Sneg").
- **Hostname:** `optiplex`.
- **His own wallet** — an independent identity on the Logos network, not a mirror of the mentor's.
- **Repo:** new standalone public repo (this one), meant to be shared with others.
- **Claude Code auth:** his own Anthropic account.
- **Reused from prior experience (Sneg):** the exact node + circuits binaries are copied over
  Tailscale rather than re-downloaded, so we start from a known-good build.

## Log

### Phase 0 — planning
- Pulled the Sneg setup history (post-install checklist, node migration, recovery skills) as the
  blueprint. Found the node + ZK-circuit tarballs already present and x86-64 — same arch as the
  Optiplex — so they can be copied directly.
- Scaffolded this repo and bundled the node-troubleshooting skills before the install even began.

### Phase 4 — Logos node bring-up + the IBD wall (in progress)
- Copied known-good x86_64 node binary (44 MB) + ZK circuits (52 MB) from the mentor machine
  over the LAN. Confirmed `logos-blockchain-node init` mints a **fresh independent identity**
  (its own `node_key`, `funding_pk`, consensus keys). Dariy's wallet pubkey:
  `bfbfdcb0e006bd8b8f140195737ce0d83b77eb025bf09940bc4cfaa9090e0e0f`.
- Wired it up: portable `run-node.sh`, systemd **user** service, `loginctl enable-linger` so it
  survives logout/reboot. Node starts, API answers, height climbs (1000 → ~18k). 🎉
- **Then it hit a wall.** The node **crash-loops on a clean exit (code 0)**, not a panic:
  ```
  No peers synced successfully during IBD
  Initial Block Download failed: AllPeersFailed. Initiating grace[period]
  ```
  Each restart it re-replays ALL stored blocks ("N/N blocks applied during initialization",
  N growing 1000→18k→20k) — so the init replay gets slower every cycle while never reaching the
  live tip (Sneg is at height ~288,744).
- **Diagnosis dug out so far:**
  - The 4 public bootstrap peers are all on ONE host (`65.109.51.37`, ports 3000-3003). They
    serve ~18k blocks then drop the stream ("sending stopped by peer: error 0"). One host can't
    reliably serve a full ~288k-block sync from scratch.
  - Added the mentor's healthy `Online` node (Sneg) as a 5th peer over Tailscale. **Neat trick
    that worked:** the node never logs its own peer ID, but a libp2p peer ID is a deterministic
    function of `node_key` — derived it in Python (ed25519 → protobuf → identity-multihash →
    base58) and the node connected to Sneg with NO "unexpected peer ID" error, confirming the
    derivation. Method is reusable.
  - **But IBD still fails even with Sneg connected** — internal `BlockProvider(RecvError(()))`
    (a download task's channel drops mid-batch) → AllPeersFailed. So it's not just peer supply.
- **Open question blocking the clean fix:** is this testnet's IBD-from-scratch simply
  unreliable now (the runbook precedent *copied* state rather than resyncing), and/or is Sneg on
  the minority fork from the earlier incident? Next candidate fixes: (a) copy synced chain state
  from Sneg, (b) add several diverse currently-active peers (harvest their multiaddrs from Sneg's
  logs) instead of one host.
- **RESOLVED — copied synced state from Sneg.** Mentor confirmed Sneg is on the canonical chain,
  so we cloned its chain DB instead of fighting IBD:
  - Only `db` (303M) + `recovery` (290M) were needed — skipped 1.6 GB of logs and `.bak` dirs.
  - Streamed it **node-to-node with tar piped through SSH** (Sneg → mentor box → optiplex), so
    nothing touched intermediate disk. Stopped both nodes for a consistent RocksDB snapshot;
    **Sneg was down only 13 seconds.**
  - Path mapping mattered: Sneg's `base_folder: ./state/live-v0.1.2` vs optiplex's `./state` —
    extracted Sneg's `live-v0.1.2/*` straight into optiplex's `./state/`.
  - optiplex kept its OWN `node_key` (from config, not state) so no p2p identity collision.
  - **Result: optiplex reached `mode=Online` in seconds** (the recovery snapshot lets it jump to
    the tip — no full replay) and tracks the live tip in lockstep with Sneg (both at 288,793).
    0 restarts. The wallet-key mismatch (Sneg's wallet data vs Dariy's `funding_pk`) caused no
    problem — node syncs fine.
  - **Monitoring gotcha (~4 min lost):** thought Sneg hadn't recovered because I polled its API on
    `:8085` (per old docs) — it actually answers on `:8080`, healthy the whole time. Confirm ports
    empirically, don't trust stale docs.

### Phase 5 — Dashboard + phone access (DONE)
- Dashboard runs as a systemd user service on `:8090`; `dashboard/run.sh` auto-derives the wallet
  key from `node.yaml`. Needs ZERO pip packages (pure stdlib).
- Exposed to phone with `sudo tailscale serve --bg 8090` → **https://optiplex.tail8ce139.ts.net/**
  (tailnet-only, not public internet). Verified reachable end-to-end from another tailnet device,
  showing live height/mode. Dariy's iPhone (on the tailnet) opens it directly.

### Phase 1 — Ubuntu install (DONE)
- Dariy drove the whole install at the keyboard. Smooth. Notable moments:
  - Booting the USB: F12 → "UEFI: Kingston DataTraveler". Kernel boot text scrolling worried
    him ("I see some code running") — worth telling first-timers that's normal.
  - **Storage gotcha confirmed live:** unchecked "Set up this disk as an LVM group" → root `/`
    came out **475G** (whole disk) instead of the ~100G LVM cap. Verified by reading the `/`
    partition size off the summary screen before confirming. Good teachable checkpoint.
  - **⭐ The ONE moment a human was needed (mentor's direct observation):** the Dell shipped with
    Windows across **several partitions** (recovery / EFI / data), and the 14-yo wasn't sure how
    to reclaim them all into one usable disk — it took some menu-diving to consolidate the SSD.
    Choosing **"Use an entire disk"** is what wipes every existing partition and hands you the
    whole drive, but that wasn't obvious to a first-timer staring at a pre-partitioned disk.
    **Every other step he did solo, tinkering directly with the agent.** This is the headline
    finding: for a motivated teenager, agent-guided server setup is essentially self-service
    except at the one genuinely destructive, irreversible decision (repartitioning the disk),
    where a human gut-check is reassuring.
  - SSH step: installed OpenSSH + imported GitHub identity `xAlisher` + allowed password auth.
  - Hostname `optiplex`, username `dar`. Resulting box: Ubuntu 24.04.4, kernel 6.8.0-124,
    i5-7500 (4c), 7.6 GB RAM, 475 GB free, x86_64.

### Connecting from the mentor machine — two real snags
- **WiFi client isolation:** Wild was on WiFi (`192.168.1.50`), optiplex on wired. The router
  blocked client-to-client traffic — couldn't even ping the box (or the other server). Fix:
  plugged Wild into the **wired** network (got `192.168.1.100`, wired route preferred). Ping
  worked instantly. Lesson: on isolating home routers, put the mentor machine on the same wire,
  or pivot to Tailscale-from-console.
- **Stale SSH host key:** `192.168.1.47` had been used by a different machine before, so SSH
  refused with "REMOTE HOST IDENTIFICATION HAS CHANGED". Expected on a fresh install reusing a
  DHCP address. Fix: `ssh-keygen -R 192.168.1.47` then reconnect. (Not an attack — just IP reuse.)

### Tailscale phone access (done early, in parallel) — a real gotcha worth teaching
- Goal: get Dariy's phone onto the family tailnet so he can open the dashboard later.
- **Trap we hit:** signing the Tailscale app into a *fresh* Google account
  (a brand-new personal Google account) does NOT join an existing tailnet — Tailscale silently creates a
  brand-new **separate** tailnet owned by that account. The phone showed "VPN on" and looked
  connected, but it was sitting on its own empty tailnet. From Wild, `tailscale status` showed
  nothing new, and the netmap's user list only knew the two existing accounts.
- **Old-phone wrinkle:** the emailed invite-accept *web page* wouldn't render on his older iPhone
  browser. Fix = don't accept on the phone browser; the app's native "Sign in with Google" works,
  and the actual tailnet join happens by accepting the **invite** (admin console → Invite users),
  not by app login alone.
- **How to verify from any machine on the tailnet** (not just the admin console):
  ```bash
  tailscale status --json | python3 -c "import json,sys; \
    [print(v['LoginName']) for v in json.load(sys.stdin)['User'].values()]"
  ```
  Once his account appeared in that user list and `iphone-11-pro-max  <his-account>@`
  showed up in `tailscale status`, he was truly in.
- Lesson for the tutorial: **"VPN on" ≠ "on the right tailnet."** Always confirm the account
  shows up as a tailnet member from a second device, not just by trusting the phone's toggle.

### Phase 6 — Claude Code on the node (installed; login pending)
- Installed Claude Code (native installer → `~/.local/bin/claude`, v2.1.179) and added it to PATH.
- Cloned this repo to the box as the agent's context: `~/logos-node-starter/` (its `CLAUDE.md`
  describes the exact node layout, ports, file-only-log trap, and the recovery skills).
- **Login deferred to next day** — it's an interactive OAuth flow tied to Dariy's own Anthropic
  account, so he does it himself (`cd ~/logos-node-starter && claude` → log in with his account).
  Note: pasting the auth code is easier over SSH from a desktop than at the bare console.

---

## Main outtake report

**What happened, in one line:** a 14-year-old wiped Windows off a €100 second-hand Dell and
stood up a real, Online Logos blockchain node + phone-accessible dashboard in a single evening,
needing an adult exactly **once**.

### The headline finding
Agent-guided infrastructure setup is, for a motivated teenager, **near self-service**. Across the
entire build the only point a human was pulled in was the **disk repartitioning** step — the
machine had a pre-existing multi-partition Windows install and it wasn't obvious to a first-timer
that "Use an entire disk" reclaims it all. That fits a clean rule: *let a human gut-check the one
irreversible, destructive decision (erasing the disk); everything else the kid + agent handled
together.* He physically drove the install; the agent drove everything else over SSH.

### What "done" looks like
- Ubuntu Server 24.04 on the Optiplex (i5-7500 / 8 GB / 475 GB), headless, key-only SSH.
- Logos node `mode=Online`, in lockstep with the mentor node, as a **fresh independent identity**
  (its own keys/wallet), surviving reboots via a systemd user service + linger.
- Dashboard at a private `https://<host>.<tailnet>.ts.net/` URL, working on his phone.
- Claude Code on the box with node-specific context (login tomorrow).

### The snags that became the best teaching moments
1. **Disk:** existing OS = multiple partitions. "Use an entire disk" + **uncheck LVM** → full
   475 GB single partition. (The one human-assist moment.)
2. **Mentor can't reach the box:** home router did **WiFi client isolation** — wire the mentor
   machine (or pivot to Tailscale-from-console).
3. **Tailscale:** signing a *fresh* Google account into the app makes its **own** tailnet —
   "VPN on" ≠ "on the right tailnet." You must **accept the invite** to join an existing one, and
   verify membership from a second device.
4. **Node sync is the real wall:** IBD-from-scratch on a ~288k-block testnet fails
   (`AllPeersFailed`) when the only bootstrap host drops mid-download. The reliable fix is to
   **copy the synced chain DB from a healthy node** (`db` + `recovery`, ~600 MB), streamed
   node-to-node over SSH, keeping your *own* `node_key`. Node was Online in seconds afterward.
5. **Reusable trick:** a libp2p peer ID is derivable from `node_key` (ed25519 → protobuf →
   identity-multihash → base58) — handy when a node never logs its own ID.
6. **Ops discipline:** confirm service ports empirically (Sneg answers on `:8080`, not the `:8085`
   in old notes) — a stale port cost ~4 minutes of false "it's down" panic.

### For others copying this setup
Most of the guide is fully general. The **one** part that needs a friend: the fast sync path
assumes you can copy state from an already-synced node. Without one, you're at the mercy of public
IBD, which on this testnet is currently unreliable from a single host — add several diverse,
currently-active peers and expect a slow, flaky first sync.

### Still open (next session)
- Dariy logs Claude Code into his account.
- Optional hardening: port the dirty-shutdown **auto-rollback guard** into this box's `run-node.sh`
  (adapted to its `./state` layout) so a power loss self-heals without manual recovery.

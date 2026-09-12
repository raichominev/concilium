# Building an isolated guest for the Kimi seat

> **Scope, stated up front.** This is *one* deployment, written for **VMware Workstation Pro on a
> Windows host** with an **Ubuntu 24.04 guest**. It is not the only approach and not a
> recommendation over the alternatives — a Linux container, podman/Docker, any other hypervisor, a
> cloud instance, or simply a separate OS account with ACLs will all get you the same property.
> Paths, addresses, adapter names and package managers are specific to each machine; treat the
> commands as a worked example to adapt, not a script to paste.

## Why bother

The Kimi seat has no OS sandbox (pitfalls #20), and on the CLI transport its headless print mode
auto-approves every tool call by construction. On machines with a live repository sitting beside
the review copy, every round wandered out of its sandbox and into that repository. The point of a
guest is not to *confine* the agent — you cannot, from inside — but to make wandering worthless:
if the guest holds the payload and nothing else, "it reads everything it can reach" stops being a
problem. That is a much cheaper property to guarantee than containment.

⚠ **"Holds the payload and nothing else" is a property you must keep re-establishing — revert to
snapshot between campaigns, not just between runs.** Measured 2026-08-20: a careful per-run harness
(fresh empty cwd per run, every result pulled off the box and deleted before the next one started)
still left the guest dirty, because the agent CLIs keep their **own transcript stores** under
`~/.cursor/projects/` and `~/.claude/projects/`, outside any working directory you clean — so a
later run of the same CLI can reach an earlier one's whole conversation. The previous campaign's
packets and answers were also still sitting in the home directory. Per-run hygiene inside a guest
you never reverted is theatre; the snapshot is the boundary.

## Two ways to get the guest

**A — prebuilt appliance.** The image used here was an Ubuntu 24.04 VMware `.ova` from
**osboxes.org**, distributed via **SourceForge**. Fastest path, and it imports in one command.
Weigh the trade: a third-party appliance contains whatever the packager put in it, and this guest
exists specifically to hold an agent that reads whatever it can reach. Every osboxes image also
ships with the same published default credentials (`osboxes` / `osboxes.org`, root likewise) —
change them before anything listens on a port.

```bash
ovftool --lax --allowExtraConfig --name=concilium-kimi <downloaded>.ova <target-dir>
```

**B — from scratch.** Slower by roughly ten minutes and removes the provenance question entirely.
Download the **Ubuntu Server** netinst ISO from ubuntu.com, create a VM in Workstation (Linux →
Ubuntu 64-bit), attach the ISO, and run a minimal install: no desktop, no snap extras, and the
only task selected is OpenSSH server if you want host access. Server rather than Desktop — the
CLI is a terminal program and a GUI is dead weight in a guest you revert constantly.

Either way, verify the ISO/OVA checksum against the publisher's before you boot it.

## Sizing

2 vCPU, 4 GB RAM, thin-provisioned disk. The prebuilt appliance already shipped at exactly this.
Actual consumption after install and one review payload was ~6 GB regardless of the nominal disk
size, because thin provisioning only grows as used. NAT networking is required — the model is
remote, so you cannot isolate the network, only the filesystem.

## Isolation settings

The host↔guest convenience channels are the thing to close. In `VM → Settings`:

- **Options → Guest Isolation** — uncheck *Enable drag and drop* and *Enable copy and paste*
- **Hardware → Display** — uncheck *Accelerate 3D graphics*
- Remove the USB controller, and add no shared folders

⚠ **Set these in the GUI, not by editing the `.vmx`.** Workstation owns these keys and rewrites
them when it powers a VM on: hand-edited `isolation.tools.copy.disable`,
`isolation.tools.paste.disable` and `isolation.tools.dnd.disable` were silently dropped on the
next power cycle, while the shared-folder keys survived. Verify after a boot, not before.

⚠ Unchecking 3D **removes** `mks.enable3d` rather than setting it `FALSE`, so its absence is not
evidence either way. Confirm from the running VM's `vmware.log`, which states
`SVGA3dCaps: Disabling 3d support` when it is genuinely off.

Note that VMware Tools being present means the clipboard channels are live unless disabled — this
is not belt-and-braces.

## Guest setup

Run the agent as an unprivileged account with **no sudo**. On the CLI transport this matters more
than usual: print mode auto-approves tool calls, so an agent running as root can rewrite the OS,
install packages, or edit the code it is reviewing.

```bash
sudo adduser --disabled-password --gecos "" concilium
```

`--disabled-password` means the account cannot be logged into; you enter it with
`sudo -u concilium -i`, which authenticates *you* and then switches. No password is ever needed.

Relocate the agent's state before first login, so credentials land where you intend:

```bash
sudo install -d -o concilium -g concilium /var/lib/concilium
echo 'export KIMI_CODE_HOME=/var/lib/concilium' | sudo tee -a /home/concilium/.profile
```

Install and authenticate **as that user**:

```bash
sudo -u concilium -i bash -lc 'curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash'
sudo -u concilium -i          # then: kimi → /login → device-code OAuth
```

⚠ **The PATH gotcha.** The installer places the binary in `~/.kimi-code/bin` regardless of
`KIMI_CODE_HOME` (which relocates only the state) and writes that PATH into `.bashrc` — which
non-interactive SSH never sources, so every automated call fails with "command not found" while an
interactive login works fine. Put it in `.profile` instead:

```bash
printf '%s\n' 'export PATH="$HOME/.kimi-code/bin:$PATH"' >> ~/.profile
```

Verify in the environment automation will actually use, not in your terminal:

```bash
sudo -u concilium -i bash -lc 'id; command -v kimi; echo "$KIMI_CODE_HOME"; ls /var/lib/concilium'
```

`id` must show no `sudo` or `adm`; the state directory must be non-empty after login.

## Host access

Key-only SSH keeps the account passwordless while remaining drivable:

```bash
sudo apt install -y openssh-server
sudo install -d -m700 -o concilium -g concilium /home/concilium/.ssh
# install your host public key, then:
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

⚠ **Make `authorized_keys` root-owned**, or the agent — which runs as `concilium` — can rewrite
the file that authorizes your access:

```bash
sudo chown root:root /home/concilium/.ssh/authorized_keys
sudo chmod 644 /home/concilium/.ssh/authorized_keys
```

sshd accepts a root-owned `authorized_keys` under StrictModes. On Ubuntu 24.04, `ssh.service` may
report *disabled* while `ssh.socket` is enabled — socket activation, which is fine; check the
socket, not the service.

**Pin the address on the host, not in the guest.** A guest-side static IP is rolled back by every
snapshot revert; a DHCP reservation is not. Add to the hypervisor's DHCP config (elevated) a
reservation keyed to the VM's MAC, then restart the DHCP service. Without it the address is
sticky but not guaranteed — leases expire and another VM can take it.

## Snapshot

Shut down first and snapshot **cold**: no memory image, a much smaller file, and reverts land in a
clean boot rather than a resumed session. Name it for what it *contains* — `clean+authed+ssh`
beats `fresh_install`, because the distinguishing property is that the OAuth session and your key
are already inside.

⚠ A VMware snapshot captures the `.vmx` as well as the disk. If you fix a setting after taking a
snapshot, retake it, or the next revert silently restores the broken configuration.

## Per-round workflow

Copy the payload in, run, copy the blocks out, revert. The revert is the mechanism: it returns the
guest to a state containing only what you chose to put there.

```bash
scp -r ./payload concilium@<guest>:~/payload
ssh concilium@<guest> 'MODEL=<flagship-alias> SANDBOX_FROM=$HOME/payload \
  ~/concilium/scripts/concilium-review-kimi.sh claim "<claim>"'
```

Set `MODEL` explicitly — the CLI's built-in default is not the flagship (setup.md), and nothing in
the output announces which model answered.

## What this buys, and what it does not

It does **not** confine the agent: it still reads anything the guest account can read. What it
buys is that there is nothing else in the guest to read, and that any damage is undone by a
revert. Measured: the one round that stayed inside its sandbox was the one run in a guest holding
the payload and nothing else — though the simpler explanation is that there was nowhere
interesting to go, which is precisely the property being engineered.

Anything that must never reach the provider should not be in the guest at all.

---

## This installation — inventoried 2026-09-12

Local facts, not general guidance. **The guest is not just the kimi seat's home — it is where every
non-codex seat actually lives**, and nothing below exists on the Windows host.

| | |
|---|---|
| SSH alias | `concilium-kimi` → `192.168.8.132`, user `concilium`, key `~/.ssh/concilium-kimi` |
| VM files | `G:\vm\concilium-kimi\concilium-kimi.vmx` (VMware Workstation) |
| Control | `"C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe" -T ws start <vmx> nogui` |
| Snapshots | `Snapshot3`, `Snapshot4`, `Snapshot5` (latest 2026-08-26) |
| Guest | Ubuntu, kernel 7.0.0-30-generic, user `concilium` (uid 1001, **no sudo**, no `adm`) |

**Seats present in the guest, and their transports:**

| Seat | Binary | Note |
|---|---|---|
| kimi | `~/.kimi-code/bin/kimi` | CLI transport, model `kimi-code/k3` |
| grok | `~/.local/bin/cursor-agent` | authenticated; `cursor-agent status` confirms the account |
| gemini | `~/.local/bin/agy` | Antigravity CLI, `gemini-3.1-pro-high` |
| glm · deepseek · qwen | `~/.local/bin/claude` | Claude Code as an Anthropic-compatible transport |
| opus · fable | same | present for lineage comparisons |

**Where the compat tokens live.** `ZAI_TOKEN`, `DEEPSEEK_TOKEN` and `QWEN_TOKEN` are exported from
the guest's `~/.profile` and **exist nowhere on the host**. A host-side check of those variables
reports them unset, which means "not on the host", not "not configured" — do not conclude from a
host check that these seats are unavailable.

⚠ `~/.profile` is sourced by a **login** shell. `ssh host 'cmd'` is not one, so the tokens and the
PATH are both absent. Always wrap: `ssh host 'bash -lc "…"'`.

**Two runners already in the guest**, and they are the reference implementations:

- `~/guest-run3.sh <seat> <arm> <replicate>` — one blind arm, any of
  `kimi | grok | opus | fable | glm | gemini | glmcursor | deepseek | qwen`. Each Anthropic-family
  seat gets its own `CLAUDE_CONFIG_DIR` so two seats can never read each other's transcripts. It
  runs in a **fresh empty cwd** and passes the packet as the prompt.
- `~/smoke-seat.sh <deepseek|qwen|glm>` — one-shot liveness check. Reads the token inside the
  script so it never reaches a command line, `ps`, or an ssh argument vector.

**`guest-run3.sh` suits a self-contained text packet, not a task that must read files.** Its empty
cwd is the point for adjudication packets and the wrong thing when the seat has to inspect a tree.
For a file-reading round, run the same seat dispatch with cwd set to the payload directory instead.

**Launching: detach inside the guest.** `ssh host '<runner>'` backgrounded from the Windows side
dies with the connection and leaves a zero-byte output and no process — observed 2026-09-12. Use
`ssh -n host 'bash -lc "setsid nohup <runner> … > log 2>&1 < /dev/null & disown"'` and poll.

### Two seat traps measured here, both silent

1. **`agy -p` denies every tool call by default.** A file-reading task returns **zero bytes with
   exit 0**, and the only trace is `permission check failed for command "pwd": user denied
   permission`. `scripts/concilium-review-agy.sh:92` does not pass an approval flag, so that
   wrapper works for text-only claims and silently returns nothing the moment the seat needs to
   read anything. The flag is `--dangerously-skip-permissions` — acceptable **in the guest**,
   which is what the guest is for.
2. **`agy --print-timeout` defaults to 5m** and truncates a long round without saying so. Raise it
   explicitly; an outer `timeout` does not substitute for it.

# AGENTS.md

Dendritic NixOS flake (flake-parts + import-tree): every file under `modules/`
is automatically a module. Eight hosts, one tree.

## Layout

| Path | What it is |
|---|---|
| `modules/hosts/<name>/` | Per-host config: `dn-workstation`, `dn-cscc` (NVIDIA desktops), `dn-notebook` (nix-darwin Mac), `dn-server`, `dn-cc` (servers), `dn-gcp`, `generic*` |
| `modules/configurations/` | How hosts are assembled (nixos.nix / darwin.nix) |
| `modules/nixosModules/` | Reusable module bundles (base, pc, server) |
| `modules/users/<name>/` | Per-user home-manager config |
| `modules/*.nix` (top level) | Feature modules — anything you add under `modules/` is auto-imported |
| `patches/` | Local patches applied to inputs |
| `scripts/` | Flake packages |
| `.sops.yaml` | sops-nix secrets (age recipients = host SSH keys) — never commit plaintext secrets |

## Conventions

- VCS is **jj**, not git (both installed; remotes: codeberg + forgejo).
  Commit identity is set per-remote via git includeIf hasconfig — don't override.
- Feature changes go in a new `modules/<feature>.nix` or extend an existing
  feature module; host-specific overrides go in `modules/hosts/<host>/`.
- `nixpkgs` is unstable; a pinned `nixpkgs-mesa` input exists only for the
  NVIDIA/EGL black-screen issue (modules/hardware.nix) — don't reuse it casually.
- Secrets: `sops edit <file>`; deployment keys are the hosts' SSH keys.

## Verify

```sh
./verify.sh            # targeted eval of every host (fast, catches eval errors)
nix flake check        # NOTE: currently fails on a KNOWN pre-existing issue
                       # (stylix option missing in homeManager check module) —
                       # unrelated eval errors hidden behind it still need fixing
```

After config changes, deploy with `rebuild` (= `nh os switch . -H "$(hostname)"`)
on the target host. Do not deploy as part of a change unless asked.

## Per-task context

Project skills under Pi memory cover common tasks: stalwart mail pipeline,
Alloy/Loki/Tempo, matrix-pi-bot, umbriel keybinds/window rules, fcitx5,
vpnctl, CVE side-input pinning. Search project memory before spelunking.

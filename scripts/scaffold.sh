#!/usr/bin/env bash
# Scaffold a new user or host module for this flake.
#
# Usage:
#   scripts/scaffold.sh user <name> [--email EMAIL] [--darwin]
#   scripts/scaffold.sh host <hostname> [--kind nixos|darwin] [--arch ARCH]
#                        [--user NAME]... [--profile NAME]... [--org NAME]
#                        [--hardware-config PATH] [--generate-hardware]
#
# Anything not given on the command line is prompted for interactively.
# Available profiles/users/orgs are discovered by scanning modules/, so the
# menus stay in sync with the repo as it grows.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULES_DIR="$REPO_ROOT/modules"
HOSTS_DIR="$MODULES_DIR/hosts"
USERS_DIR="$MODULES_DIR/users"
ORGS_DIR="$MODULES_DIR/organizations"

die() {
  echo "error: $*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  scripts/scaffold.sh user <name> [--email EMAIL] [--darwin]
  scripts/scaffold.sh host <hostname> [--kind nixos|darwin] [--arch ARCH]
                       [--user NAME]... [--profile NAME]... [--org NAME]
                       [--hardware-config PATH] [--generate-hardware]

Anything not given on the command line is prompted for interactively.

Examples:
  scripts/scaffold.sh user alice
  scripts/scaffold.sh host dn-newbox --kind nixos \
      --user danny --profile pc --profile vpn --generate-hardware
EOF
}

confirm() {
  local reply
  read -r -p "$1 [y/N] " reply || true
  [[ "$reply" =~ ^[Yy]$ ]]
}

prompt_default() {
  local __resultvar=$1 prompt=$2 default=${3:-}
  local input
  if [[ -n "$default" ]]; then
    read -r -p "$prompt [$default]: " input || true
    input=${input:-$default}
  else
    read -r -p "$prompt: " input || true
  fi
  printf -v "$__resultvar" '%s' "$input"
}

# Populates the global SELECTED array from a numbered menu. Free-text names
# (not just numbers) are passed through as-is, so unlisted/future profiles
# can still be typed in.
SELECTED=()
select_multi() {
  local prompt=$1
  shift
  local -a opts=("$@")
  echo "$prompt"
  local i
  for i in "${!opts[@]}"; do
    printf '  %2d) %s\n' "$((i + 1))" "${opts[$i]}"
  done
  local -a picks
  read -r -p "> " -a picks || true
  SELECTED=()
  local p
  for p in "${picks[@]:-}"; do
    [[ -z "$p" ]] && continue
    if [[ "$p" =~ ^[0-9]+$ ]] && ((p >= 1 && p <= ${#opts[@]})); then
      SELECTED+=("${opts[$((p - 1))]}")
    else
      SELECTED+=("$p")
    fi
  done
}

discover_dirs() {
  local dir=$1
  [[ -d "$dir" ]] || return 0
  find "$dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

# Finds top-level profile names already defined as flake.modules.<kind>.<name>
# by scanning the tree, so the menu never drifts from what actually exists.
discover_profiles() {
  local kind=$1
  grep -rhoE "flake\.modules\.${kind}\.[A-Za-z0-9_-]+" "$MODULES_DIR" 2>/dev/null |
    sed -E "s/^flake\.modules\.${kind}\.//" | sort -u
}

# ---------------------------------------------------------------------------
# user
# ---------------------------------------------------------------------------
cmd_user() {
  local name="" email="" want_darwin=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --email)
      email="$2"
      shift 2
      ;;
    --darwin)
      want_darwin="y"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "unknown flag: $1" ;;
    *)
      if [[ -z "$name" ]]; then
        name="$1"
      else
        die "unexpected argument: $1"
      fi
      shift
      ;;
    esac
  done

  [[ -n "$name" ]] || prompt_default name "User name (unix username)" ""
  [[ -n "$name" ]] || die "user name is required"
  [[ "$name" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "invalid username: $name"

  local dir="$USERS_DIR/$name"
  [[ -e "$dir" ]] && die "modules/users/$name already exists"

  if [[ -z "$email" ]]; then
    local default_domain
    default_domain=$(grep -hoE '@[A-Za-z0-9.-]+' "$USERS_DIR"/*/meta.nix 2>/dev/null | sort | uniq -c | sort -rn | awk 'NR==1{print $2}')
    prompt_default email "Email" "${name}${default_domain}"
  fi

  if [[ -z "$want_darwin" ]]; then
    if confirm "Also generate a nix-darwin wrapper for this user?"; then
      want_darwin="y"
    else
      want_darwin="n"
    fi
  fi

  mkdir -p "$dir"

  cat >"$dir/meta.nix" <<EOF
{ ... }:
{
  flake.modules.generic.${name} = args: {
    my.user = {
      name = "${name}";
      email = "${email}";
    };
  };
}
EOF

  cat >"$dir/nixos.nix" <<EOF
{ config, ... }:
{
  flake.modules.nixos.${name}.imports = [ config.flake.modules.generic.${name} ];
}
EOF

  if [[ "$want_darwin" == "y" ]]; then
    cat >"$dir/darwin.nix" <<EOF
{ config, ... }:
{
  flake.modules.darwin.${name}.imports = [ config.flake.modules.generic.${name} ];
}
EOF
  fi

  echo
  echo "Created modules/users/${name}/ ($(ls "$dir" | paste -sd, -))."
  echo "Reference it from a host's imports.nix as: nixos.${name}$([[ $want_darwin == y ]] && echo " / darwin.${name}")."
  echo "See modules/users/danny/ for optional extras (ssh keys, git, home-manager, secrets.yaml, ...)."
}

# ---------------------------------------------------------------------------
# host
# ---------------------------------------------------------------------------
cmd_host() {
  local hostname="" kind="" arch="" org="" hw_file="" gen_hw="n"
  local -a users=() profiles=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --kind)
      kind="$2"
      shift 2
      ;;
    --arch)
      arch="$2"
      shift 2
      ;;
    --user)
      users+=("$2")
      shift 2
      ;;
    --profile)
      profiles+=("$2")
      shift 2
      ;;
    --org)
      org="$2"
      shift 2
      ;;
    --hardware-config)
      hw_file="$2"
      shift 2
      ;;
    --generate-hardware)
      gen_hw="y"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "unknown flag: $1" ;;
    *)
      if [[ -z "$hostname" ]]; then
        hostname="$1"
      else
        die "unexpected argument: $1"
      fi
      shift
      ;;
    esac
  done

  [[ -n "$hostname" ]] || prompt_default hostname "Hostname" ""
  [[ -n "$hostname" ]] || die "hostname is required"
  [[ "$hostname" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "invalid hostname: $hostname"

  local dir="$HOSTS_DIR/$hostname"
  [[ -e "$dir" ]] && die "modules/hosts/$hostname already exists"

  if [[ -z "$kind" ]]; then
    select_multi "Configuration kind:" "nixos" "darwin"
    kind="${SELECTED[0]:-nixos}"
  fi
  [[ "$kind" == "nixos" || "$kind" == "darwin" ]] || die "--kind must be nixos or darwin"

  if [[ -z "$arch" ]]; then
    if [[ "$kind" == "darwin" ]]; then
      arch="aarch64-darwin"
    else
      select_multi "Target system architecture:" "x86_64-linux" "aarch64-linux"
      arch="${SELECTED[0]:-x86_64-linux}"
    fi
  fi

  if [[ ${#profiles[@]} -eq 0 ]]; then
    local -a available_profiles=()
    mapfile -t available_profiles < <(discover_profiles "$kind")
    if [[ ${#available_profiles[@]} -gt 0 ]]; then
      select_multi "Select top-level profile(s) to import (e.g. pc, server, gui, vpn):" "${available_profiles[@]}"
      profiles=("${SELECTED[@]}")
    fi
  fi

  if [[ ${#users[@]} -eq 0 ]]; then
    local -a available_users=()
    mapfile -t available_users < <(discover_dirs "$USERS_DIR")
    if [[ ${#available_users[@]} -eq 0 ]]; then
      echo "(no users found under modules/users/ yet — run '$0 user <name>' first if needed)"
    else
      select_multi "Select user(s) to enable on this host:" "${available_users[@]}"
      users=("${SELECTED[@]}")
    fi
  fi

  if [[ -z "$org" ]]; then
    local -a available_orgs=()
    mapfile -t available_orgs < <(discover_dirs "$ORGS_DIR")
    if [[ ${#available_orgs[@]} -eq 1 ]]; then
      org="${available_orgs[0]}"
    elif [[ ${#available_orgs[@]} -gt 1 ]]; then
      select_multi "Select organization module:" "${available_orgs[@]}"
      org="${SELECTED[0]:-}"
    fi
  fi

  mkdir -p "$dir"

  cat >"$dir/hostname.nix" <<EOF
{
  configurations.${kind}.${hostname}.module = {
    networking.hostName = "${hostname}";
  };
}
EOF

  cat >"$dir/system.nix" <<EOF
{
  configurations.${kind}.${hostname}.system = "${arch}";
}
EOF

  local -a import_lines=()
  local p u
  for p in "${profiles[@]:-}"; do
    [[ -n "$p" ]] && import_lines+=("${kind}.${p}")
  done
  for u in "${users[@]:-}"; do
    [[ -n "$u" ]] && import_lines+=("${kind}.${u}")
  done
  [[ -n "$org" ]] && import_lines+=("generic.${org}")

  {
    echo "{ config, ... }:"
    echo "{"
    echo "  configurations.${kind}.${hostname}.module = {"
    echo "    imports = with config.flake.modules; ["
    local l
    for l in "${import_lines[@]:-}"; do
      [[ -n "$l" ]] && echo "      ${l}"
    done
    echo "    ];"
    echo "  };"
    echo "}"
  } >"$dir/imports.nix"

  echo
  echo "Created modules/hosts/${hostname}/{hostname,system,imports}.nix"

  if [[ "$kind" == "nixos" ]]; then
    generate_hardware "$hostname" "$kind" "$dir" "$hw_file" "$gen_hw"
  fi

  echo
  echo "Next steps:"
  echo "  - Review modules/hosts/${hostname}/imports.nix and add any extra profiles/services."
  if [[ "$kind" == "nixos" ]]; then
    echo "  - If this host needs secrets: generate an age key for it, add it to .sops.yaml,"
    echo "    then create modules/hosts/${hostname}/secret.yaml (see modules/hosts/dn-server for an example)."
  fi
  echo "  - Run your formatter/pre-commit hooks (nixfmt) to tidy up generated files."
  echo "  - Build with: nix build .#${kind}Configurations.${hostname}.config.system.build.toplevel"
}

# Runs (or reuses) `nixos-generate-config --show-hardware-config` and splits
# its output the way existing hosts are laid out: fileSystems/swapDevices go
# to filesystem.nix, everything else (imports, boot.*, hardware.cpu.*, ...)
# goes to hardware.nix.
generate_hardware() {
  local hostname="$1" kind="$2" dir="$3" hw_file="$4" gen_hw="$5"
  local raw="" tmp=""

  if [[ -n "$hw_file" ]]; then
    [[ -f "$hw_file" ]] || die "hardware config file not found: $hw_file"
    raw="$hw_file"
  elif [[ "$gen_hw" == "y" ]]; then
    command -v nixos-generate-config >/dev/null 2>&1 || die "nixos-generate-config not found in PATH"
    if [[ "$(hostname 2>/dev/null || true)" != "$hostname" ]]; then
      confirm "This machine's hostname isn't '${hostname}'. Run nixos-generate-config here anyway?" ||
        {
          echo "Skipped hardware generation."
          return 0
        }
    fi
    tmp=$(mktemp)
    nixos-generate-config --show-hardware-config >"$tmp"
    raw="$tmp"
  else
    if confirm "Generate hardware.nix/filesystem.nix by running nixos-generate-config on THIS machine now?"; then
      generate_hardware "$hostname" "$kind" "$dir" "" "y"
      return
    fi
    echo "Skipping hardware config. On the target machine, run:"
    echo "    nixos-generate-config --show-hardware-config > hardware-configuration.nix"
    echo "then re-run:"
    echo "    $0 host ${hostname} --hardware-config <path-to-hardware-configuration.nix>"
    return 0
  fi

  split_hardware_config "$raw" "$hostname" "$kind" "$dir"
  if [[ -n "$tmp" ]]; then
    rm -f "$tmp"
  fi
}

split_hardware_config() {
  local raw="$1" hostname="$2" kind="$3" dir="$4"

  # Drop the "do not modify" comment banner and the function header line,
  # then drop the outer (unindented) braces, leaving just the body.
  local body
  body=$(grep -v '^#' "$raw" | grep -vE '^\{ .*\}: *$' | sed -E '/^\{[[:space:]]*$/d; /^\}[[:space:]]*$/d')

  local fs_blocks hw_blocks
  fs_blocks=$(printf '%s\n' "$body" | awk 'BEGIN{RS="";ORS="\n\n"} /^[ \t]*(fileSystems\.|swapDevices)/')
  hw_blocks=$(printf '%s\n' "$body" | awk 'BEGIN{RS="";ORS="\n\n"} !/^[ \t]*(fileSystems\.|swapDevices)/')

  {
    echo "{"
    echo "  configurations.${kind}.${hostname}.module ="
    echo "    { modulesPath, lib, config, ... }:"
    echo "    {"
    printf '%s\n' "$hw_blocks"
    echo "    };"
    echo "}"
  } >"$dir/hardware.nix"

  if [[ -n "$(tr -d '[:space:]' <<<"$fs_blocks")" ]]; then
    {
      echo "{"
      echo "  configurations.${kind}.${hostname}.module = {"
      printf '%s\n' "$fs_blocks"
      echo "  };"
      echo "}"
    } >"$dir/filesystem.nix"
  fi

  echo "Generated modules/hosts/${hostname}/hardware.nix$([[ -s "$dir/filesystem.nix" ]] 2>/dev/null && echo " and filesystem.nix")."
  echo "Double-check device UUIDs/labels — filesystems on real disks are worth pinning to by-label like existing hosts do."
}

main() {
  local cmd="${1:-}"
  [[ $# -gt 0 ]] && shift
  case "$cmd" in
  user) cmd_user "$@" ;;
  host) cmd_host "$@" ;;
  -h | --help | help | "") usage ;;
  *) die "unknown command: '$cmd' (expected 'user' or 'host')" ;;
  esac
}

main "$@"

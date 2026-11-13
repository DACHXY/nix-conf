{ config, ... }:
let
  # ─────────────────────────────────────────────────────────────────────────
  #  The only thing you have to change.
  #  Everything else (desktop, editor, gaming, containers, AI tooling) is
  #  inherited from the same modules dn-cscc uses.
  # ─────────────────────────────────────────────────────────────────────────
  username = "user";
  email = "user@example.com";
  # ─────────────────────────────────────────────────────────────────────────
in
{
  configurations.nixos.generic-desktop.module = {
    imports = with config.flake.modules; [
      nixos.pc # base + GUI (noctalia; niri + umbriel sessions)
      nixos.vpn # netbird
      nixos.nvf # neovim
      nixos.gaming
      nixos.virtualisation # libvirt / podman
      nixos.incus
      nixos.punktfunk
      nixos.docker-registry
      nixos.audio-rtp # no-op unless this hostName is in modules/audio-rtp.nix
      generic.dnywe
      generic.ai

      # Deliberately not imported (dn-cscc has them, they all need a secret
      # or danny's personal setup):
      #   nixos.danny / nixos.danny-gui  – hardcodes user "danny"
      #   nixos.danny-acme               – Cloudflare API token (sops)
      #   nixos.danny-ai                 – OpenSearch MCP credentials (sops)
      #   nixos.matrix-pi-bot            – Matrix bot token (sops)
      # Add your own sops secrets and set my.secrets.enable = true to get them.
    ];

    my = {
      user = {
        name = username;
        inherit email;
      };

      # No /var/lib/sops-nix/key.txt on this machine -> do not declare any
      # sops secrets, so activation never waits for a missing age key.
      secrets.enable = false;
    };

    # Umbriel is the desktop here (nixos.umbriel is pulled in by noctalia and
    # provides the keybinds/session), which is also the greeter's global default.
    # Niri stays selectable in the session list.

    # Log in on the greeter (or console) with this, then run `passwd`.
    users.users.${username}.initialPassword = "nixos";
  };
}

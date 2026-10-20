{ inputs, ... }:
let
  # Shared host wiring for the desktop and the headless-server profiles.
  host =
    { config, ... }:
    {
      imports = [ inputs.punktfunk.nixosModules.default ];

      services.punktfunk.host = {
        enable = true;
        openFirewall = true;
        users = [ config.my.user.name ];
        settings = {
          PUNKTFUNK_MGMT_BIND = "0.0.0.0:47990";
          PUNKTFUNK_COMPOSITOR = "gamescope";
          PUNKTFUNK_GAMESCOPE_WSI_DISABLE = "1";
          # Workaround: gamescope hands the host a LINEAR NV12 dmabuf, and the
          # NV12 zero-copy import repeats the frame horizontally on NVIDIA
          # (2560x1664 came out as 10 tiles 256px apart). The pitch guard that
          # would catch this only fires on Intel (pf-capture consume.rs
          # linear_pitch_rounds), so force the packed-RGB negotiation instead.
          PUNKTFUNK_PIPEWIRE_NV12 = "0";
        };
      };

      networking.firewall.allowedTCPPorts = [
        47990
      ];
    };
in
{
  # Desktop/login host: the host binds to the desktop session's lifetime, so a
  # compositor restart takes it down and it reconnects to the new compositor.
  flake.modules.nixos.punktfunk =
    { ... }:
    {
      imports = [ host ];

      services.punktfunk.host.desktopSession = true;

      # Native punktfunk/1 client + headless `punktfunk` CLI on this box.
      services.punktfunk.client.enable = true;
    };

  # Login-less gamescope appliance (dn-server): start with the user manager at
  # boot (linger is already on for this user) instead of graphical-session.target,
  # which a greetd/gamescope session never reaches. No client — it only streams out.
  flake.modules.nixos.punktfunk-server =
    { pkgs, ... }:
    {
      imports = [ host ];
      services.punktfunk.host.autoStart = true;

      # The desktop hosts get xdg.portal from their compositor module (niri); this
      # greetd/gamescope appliance has no such module, so wire it here. GTK is the
      # generic backend (also serves Steam file pickers). Gamescope capture itself
      # uses gamescope's own virtual output, not the portal — the host module still
      # wants a portal configured.
      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        # Only one backend here; without a config xdg-desktop-portal >=1.17
        # refuses to pick one. This restores the pre-1.17 "first found" rule.
        config.common.default = "*";
      };
    };
}

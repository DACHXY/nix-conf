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
    { ... }:
    {
      imports = [ host ];
      services.punktfunk.host.autoStart = true;
    };
}

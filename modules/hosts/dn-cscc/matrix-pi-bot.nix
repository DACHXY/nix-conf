# Chat with the pi agent from Matrix (see modules/nixosModules/matrix-pi-bot.nix).
#
# Runs on the workstation because that is where pi, its provider credentials
# and the git checkouts live — the bot is the same agent, so it must see the
# same environment. The tradeoff is availability: the service only answers
# while this machine is awake.
{ config, ... }:
let
  public = config.flake.public.config;
in
{
  configurations.nixos.dn-cscc.module =
    { config, ... }:
    {
      sops.secrets."matrix/pi-bot-token" = {
        owner = "danny";
        group = "users";
        mode = "0400";
      };

      services.matrix-pi-bot = {
        enable = true;
        homeserverUrl = public.services.matrix.endpoint;
        userId = "@pi:${public.domain}";
        # Replace with your own Matrix id — anyone listed here can make the
        # agent run commands as danny.
        allowedUsers = [ "@dachxy:${public.domain}" ];
        workspace = "/home/danny/projects/nix-conf";
        tokenFile = config.sops.secrets."matrix/pi-bot-token".path;
      };
    };
}

{ inputs, ... }:
{
  flake.modules.nixos.gui =
    { config, pkgs, ... }:
    {
      imports = [
        inputs.noctalia-greeter.nixosModules.default
      ];

      services.displayManager.noctalia-greeter = {
        enable = true;
        package = inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;
        greeter-args = "--session Niri";
      };

      # Autologin directly into the Niri session (skips the greeter).
      services.greetd.settings.initial_session = {
        command = "niri-session";
        user = config.my.user.name;
      };
    };
}

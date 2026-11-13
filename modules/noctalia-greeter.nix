{ inputs, ... }:
{
  flake.modules.nixos.gui =
    { pkgs, ... }:
    {
      imports = [
        inputs.noctalia-greeter.nixosModules.default
      ];

      services.displayManager.noctalia-greeter = {
        enable = true;
        package = inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;
        # Preselect Umbriel; the greeter still offers every installed session,
        # including the Niri one registered by nixos.niri.
        greeter-args = "--session Umbriel";
      };
    };
}

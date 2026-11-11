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
        # Preselect Niri; the greeter still offers every installed session,
        # including the Umbriel one registered by nixos.umbriel.
        greeter-args = "--session Niri";
      };
    };
}

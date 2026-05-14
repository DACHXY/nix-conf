{ inputs, ... }:
{
  flake.modules.generic.base =
    { pkgs, ... }:
    {
      stylix = {
        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";
        polarity = "dark";
        enableReleaseChecks = false;
      };
    };

  flake.modules.nixos.base =
    { config, pkgs, ... }:
    let
      caskaydia = {
        name = "CaskaydiaCove Nerd Font Mono";
        package = pkgs.nerd-fonts.caskaydia-cove;
      };
    in
    {
      imports = [
        inputs.stylix.nixosModules.stylix
      ];

      stylix = {
        fonts = {
          serif = config.stylix.fonts.monospace;

          sansSerif = config.stylix.fonts.monospace;

          monospace = caskaydia;

          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };

          sizes = {
            terminal = 15;
            desktop = 14;
            popups = 12;
          };
        };
      };

      fonts = {
        packages = with pkgs; [
          font-awesome
          jetbrains-mono
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          noto-fonts-color-emoji
          liberation_ttf
        ];

        fontDir.enable = true;
      };
    };

  flake.modules.darwin.base = {
    imports = [
      inputs.stylix.darwinModules.stylix
    ];
  };

  flake.modules.homeManager.base =
    { lib, ... }:
    let
      inherit (lib) mkForce;
    in
    {
      stylix.enableReleaseChecks = false;

      stylix.targets.neovim.transparentBackground = {
        main = true;
        numberLine = true;
        signColumn = true;
      };
      stylix.targets = {
        zen-browser.enable = false;
        nvf = {
          enable = true;
          transparentBackground = true;
        };
        helix = {
          enable = true;
          transparent = mkForce true;
        };
        starship.enable = false;
      };
    };
}

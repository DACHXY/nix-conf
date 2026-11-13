{
  # On NixOS the token is decrypted by the system sops-nix (root-only host
  # key) and handed to the user; home-manager only includes the rendered file.
  # nix-darwin hosts keep the home-manager sops secret.
  flake.modules.nixos.danny =
    { config, ... }:
    {
      sops.secrets."github/access_token" = {
        sopsFile = ./secret.yaml;
        owner = config.my.user.name;
        mode = "0400";
      };

      sops.templates."access_token_flake" = {
        owner = config.my.user.name;
        mode = "0400";
        content = ''
          extra-access-tokens = github.com=${config.sops.placeholder."github/access_token"}
        '';
      };
    };

  flake.modules.homeManager.danny =
    {
      config,
      lib,
      pkgs,
      osConfig,
      ...
    }:
    lib.mkMerge [
      (lib.mkIf pkgs.stdenv.isLinux {
        nix.extraOptions = ''
          !include ${osConfig.sops.templates."access_token_flake".path}
        '';
      })

      (lib.mkIf pkgs.stdenv.isDarwin {
        sops.templates."access_token_flake" = {
          content = ''
            extra-access-tokens = github.com=${config.sops.placeholder."github/access_token"}
          '';
        };

        sops.secrets."github/access_token" = {
          mode = "0440";
          sopsFile = ./secret.yaml;
        };

        nix.extraOptions = ''
          !include ${config.sops.templates."access_token_flake".path}
        '';
      })
    ];
}

{
  # Decrypted by the system sops-nix (root-only host key) and handed to the
  # user; home-manager only includes the rendered file. Shared by NixOS and
  # nix-darwin through generic.danny.
  flake.modules.generic.danny =
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
    { osConfig, ... }:
    {
      nix.extraOptions = ''
        !include ${osConfig.sops.templates."access_token_flake".path}
      '';
    };
}

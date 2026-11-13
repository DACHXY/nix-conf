{
  # GitHub token for nix (extra-access-tokens), personal machines only.
  # Decrypted by the system sops-nix (root-only host key) and handed to the
  # user; home-manager only includes the rendered file.
  flake.modules.generic.danny-personal =
    { config, ... }:
    let
      user = config.my.user.name;
    in
    {
      sops.secrets."github/access_token" = {
        sopsFile = ./secret.yaml;
        owner = user;
        mode = "0400";
      };

      sops.templates."access_token_flake" = {
        owner = user;
        mode = "0400";
        content = ''
          extra-access-tokens = github.com=${config.sops.placeholder."github/access_token"}
        '';
      };

      home-manager.users.${user}.nix.extraOptions = ''
        !include ${config.sops.templates."access_token_flake".path}
      '';
    };
}

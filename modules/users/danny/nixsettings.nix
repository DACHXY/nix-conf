{
  flake.modules.homeManager.danny =
    { config, ... }:
    {
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
    };
}

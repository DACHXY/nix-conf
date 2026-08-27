{
  config,
  ...
}:
let
  globalConfig = config;
in
{
  flake.modules.generic.danny-ai =
    { pkgs, config, ... }:
    {
      sops.secrets."cc/mcp-endpoint" = {
        sopsFile = ./secret.yaml;
        mode = "0444";
      };

      environment.systemPackages = [
        (pkgs.writeShellApplication {
          name = "cc-claude-config";
          runtimeInputs = with pkgs; [ claude-code ];
          text = ''
            claude mcp add --transport http gitlab-mcp "$(cat ${config.sops.secrets."cc/mcp-endpoint".path})"
          '';
        })
      ];
    };

  flake.modules.nixos.danny-ai =
    { ... }:
    {
      imports = with globalConfig.flake.modules; [ generic.danny-ai ];
    };
}

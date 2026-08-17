{ inputs, config, ... }:
let
  globalConfig = config;
in
{
  nixpkgs.overlays = [
    inputs.llm-agents.overlays.shared-nixpkgs
  ];

  flake.modules.generic.ai =
    { pkgs, ... }:
    {
      home-manager.sharedModules = with globalConfig.flake.modules.homeManager; [
        ai
      ];

      environment.systemPackages = with pkgs; [
        claude-monitor
        pi-coding-agent
      ];
    };

  flake.modules.homeManager.ai =
    { pkgs, ... }:
    {
      programs.claude-code = {
        enable = true;
        package = pkgs.claude-code;
      };
    };
}

{ inputs, config, ... }:
let
  globalConfig = config;
in
{
  nixpkgs.overlays = [
    inputs.llm-agents.overlays.shared-nixpkgs
  ];

  flake.modules.generic.claude = { pkgs, ... }: {
    home-manager.sharedModules = with globalConfig.flake.modules.homeManager; [
      claude
    ];

    environment.systemPackages = with pkgs; [
      claude-monitor
    ];
  };

  flake.modules.homeManager.claude = { pkgs, ... }: {
    programs.claude-code = {
      enable = true;
      package = pkgs.claude-code;
    };
  };
}

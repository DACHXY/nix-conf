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

      programs.pi-coding-agent = {
        enable = true;
        package = pkgs.pi-coding-agent;
        extraPackages = with pkgs; [
          nodejs
          bun
        ];
        settings = {
          defaultProvider = "deepseek";
          defaultModel = "deepseek-v4-flash";
          packages = [
            "npm:@ooo-razum/pi-open-webui"
            "npm:pi-mcp-adapter"
            "npm:pi-agent-plugins"
            "npm:pi-web-access"
            "npm:pi-subagents"
            "npm:context-mode"
            "npm:billion-context"
            "npm:bigpowers"
            "npm:@dietrichgebert/ponytail"
            "npm:@narumitw/pi-btw"
            "npm:@narumitw/pi-plan-mode"
            "npm:pi-hermes-memory"
            "npm:pi-animations"
            "npm:pi-playwright"
            "npm:pi-ui-design"
            "npm:pi-design-deck"
          ];
        };
      };
    };
}

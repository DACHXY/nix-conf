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
    let
      piThemes = pkgs.fetchFromGitHub {
        owner = "luongnv89";
        repo = "pi-extensions";
        rev = "a035a6b0a53412f61aeb471434bb5bbf96e8bc7c";
        hash = "sha256-7I0UgtAZ7rk0MnXUdt/6MdGVHsy+TZDJPVAxUWyvrR4=";
      };
    in
    {
      home.file.".pi/agent/themes".source = "${piThemes}/themes";

      # Global MCP config read by pi (pi-mcp-adapter) and other MCP clients
      home.file.".config/mcp/mcp.json".source = pkgs.writeText "mcp.json" (
        builtins.toJSON {
          mcpServers = {
            "cloudflare-api" = {
              type = "http";
              url = "https://mcp.cloudflare.com/mcp";
              auth = "oauth";
            };
            # nono-sandboxed server; provided by modules/users/danny/nono.nix
            "opensearch-mcp-server" = {
              command = "nono";
              args = [
                "run"
                "--profile"
                "/etc/nono/profiles/opensearch-mcp.json"
                "--allow-cwd"
                "--"
                "nono-opensearch-mcp"
              ];
            };
          };
        }
      );

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
          defaultThinkingLevel = "low";
          theme = "omarchy";
          quietStartup = true;
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
            "npm:pi-jev-auto-mode"
            "npm:pi-zentui"
            "npm:timestamp-pi"
          ];
        };
      };
    };
}

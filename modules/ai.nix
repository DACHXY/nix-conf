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
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib) optionalAttrs;
      inherit (pkgs.stdenv.hostPlatform) isDarwin;

      piThemes = pkgs.fetchFromGitHub {
        owner = "luongnv89";
        repo = "pi-extensions";
        rev = "a035a6b0a53412f61aeb471434bb5bbf96e8bc7c";
        hash = "sha256-7I0UgtAZ7rk0MnXUdt/6MdGVHsy+TZDJPVAxUWyvrR4=";
      };

      # Zen is a Firefox fork, so point the MCP at its binary instead of Firefox.
      zenPath = "${config.programs.zen-browser.package}/Applications/Zen Browser (Twilight).app/Contents/MacOS/zen";

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
            "--"
            "nono-opensearch-mcp"
          ];
        };
      }
      // optionalAttrs isDarwin {
        "firefox-devtools" = {
          command = "firefox-devtools-mcp";
          args = [
            "--headless"
            "--viewport"
            "1280x720"
            "--firefox-path"
            zenPath
          ];
        };
      };
    in
    {
      home.file.".pi/agent/themes".source = "${piThemes}/themes";

      # Firefox automation MCP
      home.packages = [ pkgs.firefox-devtools-mcp ];

      # Global MCP config read by pi (pi-mcp-adapter) and other MCP clients
      home.file.".config/mcp/mcp.json".source = pkgs.writeText "mcp.json" (
        builtins.toJSON { inherit mcpServers; }
      );

      programs.claude-code = {
        enable = true;
        package = pkgs.claude-code;
      };

      programs.opencode = {
        enable = true;
        package = pkgs.opencode;
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
            "npm:pi-design-deck"
            "npm:pi-jev-auto-mode"
            "npm:pi-zentui"
            "npm:timestamp-pi"
            "npm:pi-claude-bridge"
            "npm:@porche/pi-usage"
            "npm:opencode-pi"
          ];
        };
      };
    };
}

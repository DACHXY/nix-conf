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
      ];
    };

  flake.modules.homeManager.ai =
    {
      pkgs,
      lib,
      ...
    }:
    let
      piThemes = pkgs.fetchFromGitHub {
        owner = "luongnv89";
        repo = "pi-extensions";
        rev = "a035a6b0a53412f61aeb471434bb5bbf96e8bc7c";
        hash = "sha256-7I0UgtAZ7rk0MnXUdt/6MdGVHsy+TZDJPVAxUWyvrR4=";
      };

      mcpServers = {
        "cloudflare-api" = {
          type = "http";
          url = "https://mcp.cloudflare.com/mcp";
          auth = "oauth";
        };
        "codebase-memory" = {
          command = lib.getExe pkgs.codebase-memory-mcp;
          args = [ ];
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
        # Attaches to a Zen started with `zen-mcp` (modules/zen-browser.nix),
        # which turns on Marionette + BiDi on the real profile.
        "firefox-devtools" = {
          command = "firefox-devtools-mcp";
          args = [
            "--connectExisting"
            "--marionettePort"
            "2828"
          ];
        };
      };
    in
    {
      home.file.".pi/agent/themes".source = "${piThemes}/themes";

      # Firefox automation MCP
      home.packages = [ pkgs.firefox-devtools-mcp ];

      # Global MCP config read by pi (pi-mcp-adapter) and other MCP clients
      # pi-mcp-adapter reads ~/.pi/agent/mcp-adapter.json (it no longer reads ~/.pi/agent/mcp.json)
      # and mcp-adapter.json is a superset config, so other MCP clients can keep using .config/mcp/mcp.json
      home.file.".pi/agent/mcp-adapter.json".source = pkgs.writeText "mcp-adapter.json" (
        builtins.toJSON { inherit mcpServers; }
      );
      home.file.".config/mcp/mcp.json".source = pkgs.writeText "mcp.json" (
        builtins.toJSON { inherit mcpServers; }
      );

      programs.claude-code = {
        enable = true;
        package = pkgs.llm-agents.claude-code;
      };

      programs.opencode = {
        enable = true;
        package = pkgs.llm-agents.opencode;
      };

      programs.pi-coding-agent = {
        enable = true;
        package = pkgs.llm-agents.pi;
        extraPackages = with pkgs; [
          nodejs
          bun
          libnotify # notify-send, used by @raidou/pi-notify on Linux
        ];
        settings = {
          defaultProvider = "opencode-go";
          defaultModel = "deepseek-v4.1-flash";
          defaultThinkingLevel = "low";
          theme = "opencode";
          quietStartup = true;
          packages = [
            "npm:@ooo-razum/pi-open-webui"
            "npm:pi-agent-plugins"
            "npm:pi-web-access"
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
            "npm:@earendil-works/pi-durable"
            "npm:@earendil-works/pi-ai"
            "npm:@earendil-works/chord"
            "npm:@andrewjacop/pi-herdr"
            "npm:@raidou/pi-notify"
            "npm:@maheidem/pi-loop"
            # must be listed alongside its consumers (it registers the roles API
            # on session_start; an npm-only install would not load it)
            "npm:@d3ara1n/pi-model-roles"
            "npm:@d3ara1n/pi-subagent"
          ];
          # Models for pi's background sub-tasks. A role with `model = null`
          # (the built-in default for every role) means "keep the current
          # model"; only these two are pinned.
          modelRoles.roles = {
            # Summarisation / session naming: reads the WHOLE conversation,
            # runs often, output is never read by a human -> big context, free.
            utility = {
              model = "opencode-go/deepseek-v4.1-flash";
              thinking = "off";
            };
            # Cross-file refactors, architecture, security review.
            heavy = {
              model = "opencode-go/deepseek-v4-pro";
              thinking = "high";
            };
          };
          piNotify = {
            finished = true;
            onlyNotifyWhenUnfocused = true;
          };
        };
      };
    };
}

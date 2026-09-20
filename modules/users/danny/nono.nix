{ inputs, ... }:
let
  profilePath = "/etc/nono/profiles/opensearch-mcp.json";
in
{
  flake.modules.geneirc.danny-ai =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      nono = inputs.nono.packages.${pkgs.system}.prebuilt;

      nono-opensearch-mcp = pkgs.writeShellApplication {
        name = "nono-opensearch-mcp";
        runtimeInputs = [ pkgs.uv ];
        text = ''
          exec uvx opensearch-mcp-server-py "$@"
        '';
      };

      # nono-wrapped stdio server, shared by claude-code and pi (pi-mcp-adapter)
      mcpServer = {
        command = "nono";
        args = [
          "run"
          "--profile"
          profilePath
          "--allow-cwd"
          "--"
          "nono-opensearch-mcp"
        ];
      };
    in
    {
      sops.secrets =
        lib.genAttrs
          [
            "cc/mcp/opensearch/host"
            "cc/mcp/opensearch/url"
            "cc/mcp/opensearch/username"
            "cc/mcp/opensearch/password"
          ]
          (_: {
            sopsFile = ./secret.yaml;
          });

      sops.templates."nono-opensearch-mcp-profile" = {
        path = profilePath;
        owner = config.my.user.name;
        mode = "0400";
        content = ''
          {
            "extends": "default",
            "meta": {
              "name": "opensearch-mcp",
              "description": "Sandbox for the opensearch-mcp-server-py MCP server"
            },
            "workdir": { "access": "read" },
            "filesystem": {
              "allow": ["~/.cache/uv", "~/.local/share/uv"],
              "read": ["/nix/store", "/run/current-system/sw", "~/.cache/uv", "~/.local/share/uv"]
            },
            "environment": {
              "set_vars": {
                "OPENSEARCH_URL": "${config.sops.placeholder."cc/mcp/opensearch/url"}",
                "OPENSEARCH_USERNAME": "${config.sops.placeholder."cc/mcp/opensearch/username"}",
                "OPENSEARCH_PASSWORD": "${config.sops.placeholder."cc/mcp/opensearch/password"}",
                "SSL_CERT_FILE": "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt",
                "REQUESTS_CA_BUNDLE": "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt",
                "OPENSEARCH_SSL_VERIFY": "false"
              }
            }
          }
        '';
      };

      environment.systemPackages = [
        nono
        nono-opensearch-mcp
      ];

      home-manager.users.${config.my.user.name} = {
        programs.claude-code.mcpServers."opensearch-mcp-server" = {
          type = "stdio";
          command = mcpServer.command;
          args = mcpServer.args;
        };

        # Global MCP config read by pi (pi-mcp-adapter) and other MCP clients
        home.file.".config/mcp/mcp.json".source = pkgs.writeText "mcp.json" ''
          {
            "mcpServers": {
              "opensearch-mcp-server": {
                "command": "${mcpServer.command}",
                "args": ${builtins.toJSON mcpServer.args}
              }
            }
          }
        '';
      };
    };
}

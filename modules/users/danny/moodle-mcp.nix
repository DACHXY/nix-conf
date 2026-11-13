{ inputs, ... }:
let
  profilePath = "/etc/nono/profiles/moodle-mcp.json";
  downloadDir = "~/Downloads/moodle-mcp";
in
{
  # moodle-mcp (https://github.com/loyaniu/moodle-mcp) for NYCU E3
  # (e3p.nycu.edu.tw). Built from a pinned commit instead of `uvx`, and run in
  # a nono sandbox that can only reach e3p and write to its download folder.
  #
  # Needs the secret `cc/mcp/moodle/token` in ./secret.yaml: the "Moodle mobile
  # web service" token from https://e3p.nycu.edu.tw/user/managetoken.php.
  # The token can act as you (submit, post), so the only write tool this server
  # has, `self_enrol_course`, is also denied in ~/.claude/settings.json.
  flake.modules.generic.danny-ai =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      nono = inputs.nono.packages.${pkgs.stdenv.hostPlatform.system}.prebuilt;

      moodle-mcp = pkgs.python3Packages.buildPythonApplication {
        pname = "moodle-mcp";
        version = "0.3.0";
        pyproject = true;

        src = pkgs.fetchFromGitHub {
          owner = "loyaniu";
          repo = "moodle-mcp";
          rev = "1b5c3b21beccf5383ec8c9d806584f2f6c9b37a5";
          hash = "sha256-K+2yfoT/kVzD/oDeYu2cX5A9ywQYWip6G4KJc4xDhHQ=";
        };

        build-system = [ pkgs.python3Packages.setuptools ];
        dependencies = with pkgs.python3Packages; [
          glom
          mcp
          python-dotenv
          requests
        ];

        pythonImportsCheck = [ "moodle_mcp" ];
        meta.mainProgram = "moodle-mcp";
      };
    in
    {
      sops.secrets."cc/mcp/moodle/token" = {
        sopsFile = ./secret.yaml;
      };

      sops.templates."nono-moodle-mcp-profile" = {
        path = profilePath;
        owner = config.my.user.name;
        mode = "0400";
        content = builtins.toJSON {
          extends = "default";
          meta = {
            name = "moodle-mcp";
            description = "Sandbox for moodle-mcp against NYCU E3";
          };
          filesystem = {
            allow = [ downloadDir ];
            read = [
              "/nix/store"
              "/run/current-system/sw"
            ];
          };
          network.allow_domain = [ "e3p.nycu.edu.tw" ];
          environment.set_vars = {
            MOODLE_URL = "https://e3p.nycu.edu.tw/webservice/rest/server.php";
            MOODLE_TOKEN = config.sops.placeholder."cc/mcp/moodle/token";
            MOODLE_MCP_DOWNLOAD_DIR = downloadDir;
            SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
            REQUESTS_CA_BUNDLE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          };
        };
      };

      environment.systemPackages = [ moodle-mcp ];

      home-manager.users.${config.my.user.name} = hm: {
        # nono needs the granted folder to exist.
        home.activation.moodleMcpDownloadDir = hm.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p "$HOME/Downloads/moodle-mcp"
        '';

        programs.claude-code.mcpServers."moodle-mcp" = {
          type = "stdio";
          command = lib.getExe nono;
          args = [
            "run"
            "--profile"
            profilePath
            "--"
            (lib.getExe moodle-mcp)
          ];
        };
      };
    };
}

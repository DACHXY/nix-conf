{ ... }:
{

  flake.modules.nixos.stalwart =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.stalwart-bootstrap;
      planText = lib.concatMapStringsSep "\n" (op: builtins.toJSON op) cfg.plan;
      plan = pkgs.writeText "stalwart-plan.ndjson" planText;
    in
    {
      options.services.stalwart-bootstrap = {
        enable = lib.mkEnableOption "Stalwart configuration bootstrap";
        url = lib.mkOption { type = lib.types.str; };
        credentialsFile = lib.mkOption {
          type = lib.types.path;
          description = "EnvironmentFile with STALWART_USER and STALWART_PASSWORD (or STALWART_TOKEN).";
        };
        plan = lib.mkOption {
          type = lib.types.listOf lib.types.attrs;
          description = "List of stalwart-cli apply operations.";
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.services.stalwart-bootstrap = {
          description = "Stalwart configuration bootstrap";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            EnvironmentFile = cfg.credentialsFile;
            Environment = "STALWART_URL=${cfg.url}";
            ExecStart = "${pkgs.stalwart-cli}/bin/stalwart-cli apply --file ${plan}";
            RemainAfterExit = true;
          };
        };
      };
    };
}

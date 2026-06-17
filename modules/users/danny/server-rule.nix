{ config, ... }:
{
  flake.modules.nixos.danny =
    { lib, ... }@nixosArgs:
    let
      inherit (lib)
        mkEnableOption
        mkOption
        types
        literalExpression
        mapAttrs
        ;

      cfg = nixosArgs.config.server-rules;

      ruleListType = {
        ipv4 = mkOption {
          type = with types; listOf str;
          default = [ ];
        };
        ipv6 = mkOption {
          type = with types; listOf str;
          default = [ ];
        };
        countryCode = mkOption {
          type = with types; listOf str;
          default = [ ];
          example = literalExpression ''
            ["US"] 
          '';
          description = "list of counrty code";
        };
      };

      serviceRuleType =
        with types;
        submodule {
          options = {
            useDefault = mkEnableOption "use default allowedList" // {
              default = true;
            };
            allowed = ruleListType;
            blocked = ruleListType;
          };
        };

      securityModule = "${
        fetchGit {
          url = "${config.flake.public.config.services.forgejo.sshEndpoint}/dachxy/nix-server-security.git";
          rev = "62347a805c013584b2de291ae7f9b3a2c7bd3af1";
          ref = "main";
        }
      }/default.nix";
    in
    {
      options.server-rules = {
        enable = mkEnableOption "enable extra server configuration" // {
          default = true;
        };

        rule = {
          default = {
            allowed = ruleListType;
            blocked = ruleListType;
          };
          services = mkOption {
            type = with types; attrsOf serviceRuleType;
            apply = v: mapAttrs (_: value: if value.useDefault then value // cfg.rule.default else value) v;
          };
        };

        extra = mkOption {
          type = with types; attrsOf attrs;
          default = { };
        };
      };

      imports = [
        securityModule
      ];
    };
}

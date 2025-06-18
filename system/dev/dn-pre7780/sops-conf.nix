{ config, lib, ... }:
{
  sops = {
    secrets = {
      "wireguard/conf" = { };
      "nextcloud/adminPassword" = { };
      "openldap/adminPassword" = lib.mkIf config.services.openldap.enable {
        owner = config.users.users.openldap.name;
        group = config.users.users.openldap.group;
        mode = "0660";
      };
      "lam/env" = { };
      "dovecot/openldap" = lib.mkIf (config.services.postfix.enable && config.services.openldap.enable) {
        owner = config.services.dovecot2.user;
        group = config.services.dovecot2.group;
        mode = "0660";
      };
    };
  };
}

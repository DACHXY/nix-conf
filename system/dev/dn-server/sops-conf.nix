{ config, ... }:
{
  sops = {
    secrets = {
      "wireguard/privateKey" = { };
      "nextcloud/adminPassword" = { };
      "step_ca/password" = { };
      vaultwarden = { };
      "postfix/openldap" = { };
      "openldap/adminPassword" = {
        owner = config.users.users.openldap.name;
        group = config.users.users.openldap.group;
      };
    };
  };
}

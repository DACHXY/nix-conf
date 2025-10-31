{
  config,
  ...
}:
let
  domain = "daccc.info";
  fqdn = "mx1.daccc.info";
in
{
  networking.firewall.allowedTCPPorts = [ 8080 ];
  imports = [
    (import ../../../modules/stalwart.nix {
      inherit domain;

      enableNginx = false;
      dkimKey = config.sops.secrets."stalwart/dkimKey".path;
      adminPassFile = config.sops.secrets."stalwart/adminPassword".path;
      dbPassFile = config.sops.secrets."stalwart/db".path;
      acmeConf = {
        directory = "https://acme-v02.api.letsencrypt.org/directory";
        origin = "${domain}";
        contact = "admin@${domain}";
        domains = [
          domain
          fqdn
        ];
        challenge = "dns-01";
        cache = "${config.services.stalwart-mail.dataDir}/acme";
        default = true;
        provider = "cloudflare";
        renew-before = "30d";
        secret = "%{file:${config.sops.secrets."cloudflare/secret".path}}%";
      };
      ldapConf = {
        type = "ldap";
        url = "ldaps://ldap.net.dn";
        tls.enable = true;
        timeout = "30s";
        base-dn = "ou=people,dc=net,dc=dn";
        attributes = {
          name = "uid";
          email = "mailRoutingAddress";
          secret = "userPassword";
          description = [
            "cn"
            "description"
          ];
          class = "objectClass";
        };
        filter = {
          name = "(&(objectClass=inetOrgPerson)(|(uid=?)(mail=?)(mailRoutingAddress=?)))";
          email = "(&(objectClass=inetOrgPerson)(mailRoutingAddress=?))";
        };
        bind = {
          dn = "cn=admin,dc=net,dc=dn";
          secret = "%{file:${config.sops.secrets."stalwart/ldap".path}}%";
          auth = {
            method = "default";
          };
        };
      };
    })
  ];

}

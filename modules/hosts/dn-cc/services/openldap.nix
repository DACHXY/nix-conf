{ config, ... }:
let
  inherit (config.flake.public.config.services.openldap) olcDomain;
  inherit (config.flake.public.config.machines) dn-server;
in
{
  configurations.nixos.dn-cc.module =
    { config, pkgs, ... }:
    {
      sops.secrets."openldap/replicatorPassword" = {
        owner = "openldap";
        group = "openldap";
        mode = "400";
      };

      sops.templates."openldap-syncrepl.conf" = {
        owner = "openldap";
        group = "openldap";
        mode = "400";
        content = ''
          rid=001 provider=ldap://${dn-server.ip} binddn="cn=replicator,${olcDomain}" bindmethod=simple credentials=${
            config.sops.placeholder."openldap/replicatorPassword"
          } searchbase="${olcDomain}" type=refreshAndPersist retry="60 10 300 +" interval=00:00:05:00 timeout=10
        '';
      };

      services.openldap = {
        enable = true;
        urlList = [
          "ldap:///"
          "ldapi:///"
        ];
        settings = {
          attrs.olcLogLevel = "conns config";

          children = {
            "cn=schema".includes = [
              "${pkgs.openldap}/etc/schema/core.ldif"
              "${pkgs.openldap}/etc/schema/cosine.ldif"
              "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
              "${../../../../misc/inetMailRoutingObject.ldif}"
            ];

            "olcDatabase={1}mdb" = {
              attrs = {
                objectClass = [
                  "olcDatabaseConfig"
                  "olcMdbConfig"
                ];

                olcDatabase = "{1}mdb";
                olcDbDirectory = "/var/lib/openldap/data";

                olcSuffix = olcDomain;

                # Required before olcSyncRepl can be enabled, even though
                # nothing binds as root over the network on a replica.
                olcRootDN = "cn=admin,${olcDomain}";

                # Referral target for any client that tries to write against
                # this read-only replica.
                olcUpdateRef = "ldap://${dn-server.ip}";

                olcSyncRepl.path = config.sops.templates."openldap-syncrepl.conf".path;

                olcAccess = [
                  ''
                    {0}to *
                        by dn.exact="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage
                        by * read
                  ''
                ];
              };
            };
          };
        };
      };
    };
}

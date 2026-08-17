{ config, ... }:
let
  inherit (config.flake.public.config.services.openldap)
    olcDomain
    ;
in
{
  configurations.nixos.dn-server.module =
    { pkgs, ... }:
    {
      # systemd.services.openldap = {
      #   wants = [ "acme-finished-${hostname}.target" ];
      #   serviceConfig.LoadCredential =
      #     let
      #       certDir = config.security.acme.certs."${hostname}".directory;
      #     in
      #     [
      #       "full.pem:${certDir}/full.pem"
      #       "cert.pem:${certDir}/cert.pem"
      #       "key.pem:${certDir}/key.pem"
      #     ];
      # };

      networking.firewall.allowedTCPPorts = [
        389 # LDAP
        636 # LDAPS
      ];

      services.openldap =
        let
          # credsDir = "/run/credentials/openldap.service";
          # caDir = "${credsDir}/full.pem";
          # certDir = "${credsDir}/cert.pem";
          # keyDir = "${credsDir}/key.pem";
        in
        {
          enable = true;
          urlList = [
            "ldap:///"
            "ldapi:///"
          ];
          settings = {
            attrs = {
              olcLogLevel = "conns config";

              # olcTLSCACertificateFile = caDir;
              # olcTLSCertificateFile = certDir;
              # olcTLSCertificateKeyFile = keyDir;
              # olcTLSCipherSuite = "HIGH:MEDIUM:+3DES:+RC4:+aNULL";
              # olcTLSCRLCheck = "none";
              # olcTLSVerifyClient = "never";
              # olcTLSProtocolMin = "3.1";
            };

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

                  olcRootDN = "cn=admin,${olcDomain}";
                  olcRootPW.path = "/var/lib/openldap/olcPasswd";

                  olcAccess = [
                    ''
                      {0}to attrs=userPassword
                          by peername="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage
                          by dn.exact="cn=admin,${olcDomain}" manage
                          by dn.exact="uid=admin,ou=people,${olcDomain}" manage
                          by self write
                          by anonymous auth
                          by * none
                    ''
                    ''
                      {1}to *
                          by peername="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage
                          by dn.exact="cn=admin,${olcDomain}" manage
                          by dn.exact="uid=admin,ou=people,${olcDomain}" manage
                          by self read
                          by anonymous auth
                          by * none
                    ''
                  ];
                };

                children = {
                  "olcOverlay={2}ppolicy".attrs = {
                    objectClass = [
                      "olcOverlayConfig"
                      "olcPPolicyConfig"
                      "top"
                    ];
                    olcOverlay = "{2}ppolicy";
                    olcPPolicyHashCleartext = "TRUE";
                  };

                  "olcOverlay={3}memberof".attrs = {
                    objectClass = [
                      "olcOverlayConfig"
                      "olcMemberOf"
                      "top"
                    ];
                    olcOverlay = "{3}memberof";
                    olcMemberOfRefInt = "TRUE";
                    olcMemberOfDangling = "ignore";
                    olcMemberOfGroupOC = "groupOfNames";
                    olcMemberOfMemberAD = "member";
                    olcMemberOfMemberOfAD = "memberOf";
                  };

                  "olcOverlay={4}refint".attrs = {
                    objectClass = [
                      "olcOverlayConfig"
                      "olcRefintConfig"
                      "top"
                    ];
                    olcOverlay = "{4}refint";
                    olcRefintAttribute = [
                      "memberof"
                      "member"
                      "manager"
                      "owner"
                    ];
                  };
                };
              };
            };
          };
        };
    };
}

{
  config,
  pkgs,
  lib,
  ...
}:
let
  # inherit (config.networking) domain;
  inherit (lib)
    concatStringsSep
    splitString
    getExe
    getExe'
    ;
  inherit (config.sops) secrets;

  getOlcSuffix = domain: concatStringsSep "," (map (dc: "dc=${dc}") (splitString "." domain));

  # NOTE: This domain is about to change
  domain = "net.dn";
  ldapHostname = "ldap";
  olcSuffix = getOlcSuffix domain;
  adminDN = "cn=admin,ou=people,${olcSuffix}";
  localDN = "gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth";
  cfg = config.services.openldap.package;
in
{

  # ==== Admin Password ==== #
  sops.secrets."ldap/password" = { };

  systemd.services.openldap-pre =
    let
      passwordPath = cfg.settings.children."olcDatabase={1}mdb".attrs.olcRootPW.path;
    in
    {
      before = [ "openldap.service" ];
      requiredBy = [ "openldap.service" ];
      serviceConfig = {
        User = "openldap";
        ExecStart = "${getExe pkgs.bash} -c '${getExe' cfg.package "slappasswd"} -T ${secrets."ldap/password".path} > ${passwordPath}";
        ExecStartPost = [
          "${getExe' pkgs.busybox.out "chmod"} 700 ${passwordPath}"
        ];
        Type = "oneshot";
        StateDirectory = [
          "openldap"
        ];
        StateDirectoryMode = "700";
      };
    };

  # ==== TLS Cert ===== #
  systemd.services.openldap = {
    wants = [ "acme-finished-${domain}.target" ];
    serviceConfig.LoadCredential =
      let
        certDir = config.security.acme.certs."${domain}".directory;
      in
      [
        "full.pem:${certDir}/full.pem"
        "cert.pem:${certDir}/cert.pem"
        "key.pem:${certDir}/key.pem"
      ];
  };

  # ===== Openldap Service ==== #
  services.openldap =
    let
      credsDir = "/run/credentials/openldap.service";
      caDir = "${credsDir}/full.pem";
      certDir = "${credsDir}/cert.pem";
      keyDir = "${credsDir}/key.pem";
    in
    {
      enable = true;

      urlList = [
        "ldap:///"
        "ldapi:///"
        "ldaps:///" # TLS
      ];

      settings = {
        attrs = {
          olcLogLevel = "conns config";

          olcTLSCACertificateFile = caDir;
          olcTLSCertificateFile = certDir;
          olcTLSCertificateKeyFile = keyDir;
          olcTLSCipherSuite = "HIGH:MEDIUM:+3DES:+RC4:+aNULL";
          olcTLSCRLCheck = "none";
          olcTLSVerifyClient = "never";
          olcTLSProtocolMin = "3.1";
        };

        children = {
          "cn=schema".includes = [
            "${cfg.package}/etc/schema/core.ldif"
            "${cfg.package}/etc/schema/cosine.ldif"
            "${cfg.package}/etc/schema/inetorgperson.ldif"
          ];

          "olcDatabase={1}mdb" = {
            attrs = {
              objectClass = [
                "olcDatabaseConfig"
                "olcMdbConfig"
              ];

              olcDatabase = "{1}mdb";
              olcDbDirectory = "/var/lib/openldap/data";

              olcSuffix = olcSuffix;

              olcRootDN = "cn=admin,${olcSuffix}";
              olcRootPW.path = "/var/lib/openldap/olcPasswd";

              olcAccess = [
                ''
                  {0}to attrs=userPassword
                      by peername="${localDN}" manage 
                      by dn.exact="${adminDN}" manage
                      by self write
                      by anonymous auth
                      by * none
                ''
                ''
                  {1}to *
                      by peername="${localDN}" manage 
                      by dn.exact="${adminDN}" manage
                      by self read
                      by anonymous auth
                      by * none
                ''
              ];
            };

            children = {
              # ==== Password Policy ==== #
              "olcOverlay={2}ppolicy".attrs = {
                objectClass = [
                  "olcOverlayConfig"
                  "olcPPolicyConfig"
                  "top"
                ];
                olcOverlay = "{2}ppolicy";
                olcPPolicyHashCleartext = "TRUE";
              };

              # ==== Group ==== #
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

}

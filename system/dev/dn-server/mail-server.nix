{
  config,
  pkgs,
  settings,
  ...
}:
with builtins;
let
  interfaces = config.networking.wireguard.interfaces;
  allowedIPs = concatLists [
    (concatLists (map (interface: interfaces.${interface}.ips) (attrNames interfaces)))
    [
      "127.0.0.1"
    ]
  ];
  fqdn = config.networking.fqdn;
  # fqdn = "dn-server.daccc.info";
in
{
  networking.firewall.allowedTCPPorts = [
    25
    587
  ];

  services.postfix = {
    enable = true;
    hostname = fqdn;
    origin = fqdn;
    networks = allowedIPs;
    destination = [
      "localhost"
      "localhost.${fqdn}"
      fqdn
    ];

    config = {
      home_mailbox = "Mailbox";
    };

    postmasterAlias = "root";
    rootAlias = settings.personal.username;

    config = {
      alias_maps = [ "ldap:${config.sops.secrets."postfix/openldap".path}" ];
    };

    extraAliases = ''
      mailer-daemon: postmaster
      nobody: root
      hostmaster: root
      usenet: root
      news: root
      webmaster: root
      www: root
      ftp: root
      abuse: root
      noc: root
      security: root
      vaultwarden: root
    '';
  };
}

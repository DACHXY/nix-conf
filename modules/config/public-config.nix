{ config, self, ... }:
let
  inherit (self.lib.ldap) getOlcSuffix;
  cfg = config.flake.public.config;
in
{
  flake.public.config =
    let
      myDomain = "dnywe.com";
    in
    {
      domain = myDomain;
      legacy = {
        domain = "net.dn";
      };
      common = {
        nix-repo = "/etc/nixos";
      };
      machines = {
        dn-server = rec {
          ip = "10.20.0.2";
          range = "10.20.0.0/24";
          publicKey = "rMain0t9J0YeJR9AjuLuX6WL0Mh5QkFA2lxq/XV9RH4=";
          wg = {
            wg1 = {
              publicKey = publicKey;
              ip = ip;
              interface = "wg1";
            };
          };
        };
        dn-cc = rec {
          ip = "10.20.0.1";
          range = "10.20.0.0/24";
          wg = {
            wg0 = {
              ip = ip;
              interface = "wg0";
              externalInterface = "ens192";
              listenPort = 51820;
              range = range;
            };
          };
        };
        gcp = {
          ip = "10.10.0.1";
          range = "10.10.0.0/24";
        };
      };
      services = {
        netbird = rec {
          hostname = "netbird.${myDomain}";
          endpoint = "https://${hostname}";
          vDomain = "vnet.dn";
        };
        nextcloud = rec {
          hostname = "nextcloud.${myDomain}";
          endpoint = "https://${hostname}";
        };
        talk = rec {
          hostname = "talk.${myDomain}";
          endpoint = "https://${hostname}";
        };
        forgejo = rec {
          hostname = "git.${myDomain}";
          endpoint = "https://${hostname}";
          sshEndpoint = "ssh://${hostname}";
        };
        actual = rec {
          hostname = "actual.${myDomain}";
          endpoint = "https://${hostname}";
        };
        oidc = rec {
          hostname = "login.${myDomain}";
          endpoint = "https://${hostname}";
          realm = "master";
          issuer = "${endpoint}/realms/${realm}";
          oidcConfigEndpoint = "${endpoint}/realms/${realm}/.well-known/openid-configuration";
          userInfoEndpoint = "${issuer}/protocol/openid-connect/userinfo";
        };
        vaultwarden = rec {
          hostname = "bitwarden.${myDomain}";
          endpoint = "https://${hostname}";
        };
        uptime = rec {
          hostname = "uptime.${myDomain}";
          endpoint = "https://${hostname}";
        };
        powerdns = rec {
          hostname = "powerdns.${myDomain}";
          endpoint = "https://${hostname}";
        };
        mailserver = {
          hostname = "mx2.${myDomain}";
          port = 465;
        };
        stalwart = rec {
          hostname = "stalwart.${myDomain}";
          endpoint = "https://${hostname}";
          # Internal-only JMAP/admin listener, reverse-proxied by nginx.
          managementPort = 30092;
        };
        homepage = rec {
          hostname = "${myDomain}";
          alias = [ "www.${myDomain}" ];
          endpoint = "https://${hostname}";
        };
        grafana = rec {
          hostname = "grafana.${myDomain}";
          endpoint = "https://${hostname}";
        };
        prometheus = rec {
          hostname = "metrics.${myDomain}";
          endpoint = "https://${hostname}";
        };
        ntfy = rec {
          hostname = "ntfy.${myDomain}";
          endpoint = "https://${hostname}";
        };
        openldap = rec {
          domain = "net.dn";
          hostname = "ldap.${domain}";
          olcDomain = getOlcSuffix domain;
          endpoint = "ldaps://${hostname}";
        };
        lldap = rec {
          domain = myDomain;
          hostname = "ldap.${domain}";
          endpoint = "ldaps://${hostname}";
          web = {
            hostname = hostname;
            endpoint = "https://${hostname}";
          };
        };
        matrix = rec {
          hostname = "matrix.${myDomain}";
          endpoint = "https://${hostname}";
          web = rec {
            hostname = "element.${myDomain}";
            endpoint = "https://${hostname}";
          };
        };
        # === matrix-authentication-service === #
        mas = rec {
          hostname = "matrix-auth.${myDomain}";
          endpoint = "https://${hostname}";
        };
        coturn = {
          hostname = "coturn.${myDomain}";
          port = 3478;
        };
        paperless = rec {
          hostname = "paperless.${myDomain}";
          endpoint = "https://${hostname}";
        };
        papra = rec {
          hostname = "papra.${myDomain}";
          endpoint = "https://${hostname}";
        };
        webmail = rec {
          hostname = "webmail.${myDomain}";
          endpoint = "https://${hostname}";
        };
      };
      ca = {
        csrootca = builtins.fetchurl {
          url = "${cfg.services.nextcloud.endpoint}/s/gm4BjP9FwGmZkey";
          sha256 = "sha256:1jp9g6i0nvcs5d4wbn122lh2bjc889nhphlphzgf9q5q72xwgc0m";
        };
      };
    };
}

{ config, ... }:
{
  sops.secrets."networkmanager" = {
    sopsFile = ../sops/dn-secret.yaml;
  };

  networking.networkmanager = {
    ensureProfiles = {
      environmentFiles = [
        config.sops.secrets."networkmanager".path
      ];

      profiles = {
        "CSIT VPN" = {
          connection = {
            autoconnect = "false";
            id = "CSIT VPN";
            type = "vpn";
            uuid = "7aa21c9d-4004-49e8-af61-827850fb4370";
          };
          ipv4 = {
            method = "auto";
            ignore-auto-dns = true;
            routes = "10.1.0.0/16";
            never-default = true;
          };
          ipv6 = {
            addr-gen-mode = "stable-privacy";
            method = "auto";
            ignore-auto-dns = true;
          };
          proxy = { };
          vpn = {
            gateway = "$CSIT_VPN_GATEWAY";
            otp-flags = "0";
            password-flags = "0";
            realm = "$CSIT_VPN_REALM";
            service-type = "org.freedesktop.NetworkManager.fortisslvpn";
            trusted-cert = "$CSIT_VPN_TRUST_CERT";
            user = "$CSIT_VPN_IDENTITY";
          };
          vpn-secrets = {
            password = "$CSIT_VPN_PASSWORD";
          };
        };
        "CSIT VPN (test)" = {
          connection = {
            autoconnect = "false";
            id = "CSIT VPN (test)";
            type = "vpn";
            uuid = "561552b7-d7b0-443e-b817-8c8c18367542";
          };
          ipv4 = {
            method = "auto";
            ignore-auto-dns = true;
            routes = "10.2.0.0/16";
            never-default = true;
          };
          ipv6 = {
            addr-gen-mode = "stable-privacy";
            ignore-auto-dns = true;
            method = "auto";
          };
          proxy = { };
          vpn = {
            gateway = "$CSIT_VPN_TEST_GATEWAY";
            otp-flags = "0";
            password-flags = "0";
            realm = "$CSIT_VPN_TEST_REALM";
            service-type = "org.freedesktop.NetworkManager.fortisslvpn";
            trusted-cert = "$CSIT_VPN_TEST_TRUST_CERT";
            user = "$CSIT_VPN_TEST_IDENTITY";
          };
          vpn-secrets = {
            password = "$CSIT_VPN_TEST_PASSWORD";
          };
        };
        NYCU = {
          "802-1x" = {
            eap = "peap";
            identity = "$NYCU_WIFI_IDENTITY";
            password = "$NYCU_WIFI_PASSWORD";
            phase2-auth = "mschapv2";
          };
          connection = {
            id = "NYCU";
            interface-name = "wlp0s20f3";
            type = "wifi";
          };
          ipv4 = {
            method = "auto";
          };
          ipv6 = {
            addr-gen-mode = "default";
            method = "auto";
          };
          proxy = { };
          wifi = {
            mode = "infrastructure";
            ssid = "NYCU";
          };
          wifi-security = {
            key-mgmt = "wpa-eap";
          };
        };
        DACDAC_5G = {
          connection = {
            id = "DACDAC_5G";
            interface-name = "wlp0s20f3";
            type = "wifi";
          };
          ipv4 = {
            method = "auto";
          };
          ipv6 = {
            addr-gen-mode = "default";
            method = "auto";
          };
          proxy = { };
          wifi = {
            mode = "infrastructure";
            ssid = "DACDAC_5G";
          };
          wifi-security = {
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = "$DACDAC_5G_WIFI_PASSWORD";
          };
        };
        CSIT = {
          "802-1x" = {
            eap = "peap";
            identity = "$CSIT_WIFI_IDENTITY";
            password = "$CSIT_WIFI_PASSWORD";
            phase2-auth = "gtc";
          };
          connection = {
            autoconnect-priority = "10";
            id = "CSIT";
            interface-name = "wlp0s20f3";
            type = "wifi";
          };
          ipv4 = {
            method = "auto";
          };
          ipv6 = {
            addr-gen-mode = "default";
            method = "auto";
          };
          proxy = { };
          wifi = {
            mode = "infrastructure";
            ssid = "CSIT";
          };
          wifi-security = {
            key-mgmt = "wpa-eap";
          };
        };
        YCC0121_5G = {
          connection = {
            id = "YCC0121_5G";
            interface-name = "wlp0s20f3";
            type = "wifi";
            uuid = "aa650a47-b76c-4782-979e-c2f71dc31c8c";
          };
          ipv4 = {
            method = "auto";
          };
          ipv6 = {
            addr-gen-mode = "default";
            method = "auto";
          };
          proxy = { };
          wifi = {
            mode = "infrastructure";
            ssid = "YCC0121_5G";
          };
          wifi-security = {
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = "$YCC0121_5G_WIFI_PASSWORD";
          };
        };
      };
    };
  };
}

{
  # VPN configs for ivpn on macOS. Decrypted by the system sops-nix (root-only
  # SSH host key), owned by the user; ivpn reads them from VPN_SECRETS_DIR.
  flake.modules.darwin.danny =
    { config, ... }:
    let
      user = config.my.user.name;
      vpnDir = "${config.users.users.${user}.home}/Documents/vpn-configs";

      secret = {
        sopsFile = ./secret.yaml;
        owner = user;
        mode = "0400";
      };

      vpnConfig = name: passKey: {
        owner = user;
        mode = "0400";
        content = ''
          ${config.sops.placeholder."vpn/${name}"}
          password-file=${config.sops.secrets."vpn/${passKey}".path}
        '';
        path = "${vpnDir}/${name}.conf";
      };
    in
    {
      sops.secrets = {
        "vpn/csit" = secret;
        "vpn/csit-test" = secret;
        "vpn/csit-pass" = secret;
        "vpn/nycu" = secret;
        "vpn/nycu-pass" = secret;
      };

      sops.templates = {
        "vpn/csit" = vpnConfig "csit" "csit-pass";
        "vpn/csit-test" = vpnConfig "csit-test" "csit-pass";
        "vpn/nycu" = vpnConfig "nycu" "nycu-pass";
      };

      home-manager.users.${user} = {
        home.sessionVariables = {
          VPN_SECRETS_DIR = "$HOME/Documents/vpn-configs";
        };
      };
    };
}

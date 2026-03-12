{ hostname }:
{
  self,
  pkgs,
  ...
}:
let
  username = "skydrive";
  serverCfg = self.nixosConfigurations.dn-server.config;
  serverNextcloudCfg = serverCfg.services.nextcloud;
  nextcloudURL =
    (if serverNextcloudCfg.https then "https" else "http") + "://" + serverNextcloudCfg.hostName;
in
{
  systemConf = {
    inherit hostname username;
    domain = "dnywe.com";
    enableHomeManager = true;
    windowManager = "niri";
    face = pkgs.fetchurl {
      url = "${nextcloudURL}/s/EtMnqXqCy78MLt4/preview";
      hash = "sha256-McwMPLFJWiWhh7K12ZHI6uwyvRgj9zW/hFIBl3dLrKE=";
    };
  };

  imports = [
    ../../modules/presets/basic.nix
    ../../modules/virtualization.nix
    ./common
    ./games
    ./sops
    ./utility
    ./network
    ./home
    ../../modules/shells/noctalia
    ../../modules/sunshine.nix
  ];

  services.openssh.settings.PasswordAuthentication = true;

  services.displayManager.sddm.autoLogin.relogin = true;

  services.displayManager.autoLogin = {
    enable = true;
    user = "${username}";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
  ];

  users.users."${username}".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBDk8GmC7b9+XSDxnIj5brYmNLPVO47G5enrL3Q+8fuh 好強上的捷徑"
  ];
}

{ hostname }:
{
  modulesPath,
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  username = "danny";
  domain = "dnywe.com";
in
{
  systemConf = {
    inherit username domain hostname;
  };

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.home-manager.nixosModules.default

    ./disk.nix
    ../../modules/presets/minimal.nix
    ../../modules/netbird-client.nix
  ];

  # Auto Login as root
  services.getty.autologinUser = "root";

  boot.loader.systemd-boot.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.firewall = {
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ ];
  };

  services.openssh = {
    enable = true;
    ports = [
      22
    ];
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
      UseDns = false;
    };
  };

  environment.systemPackages =
    let
      pubKeyPath = "/etc/ssh/ssh_host_ed25519_key.pub";
    in
    map lib.lowPrio [
      pkgs.curl
      pkgs.gitMinimal
      (pkgs.writeShellScriptBin "gen-age" ''
        set -e

        mkdir -p $(dirname ${config.sops.age.keyFile})
        ${pkgs.ssh-to-age}/bin/ssh-to-age -i ${pubKeyPath} -o ${config.sops.age.keyFile}

        chown ${username}:users ${config.sops.age.keyFile}

        echo "Keyfile ${config.sops.age.keyFile} saved"
      '')
    ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII17Qa46NpiXRZfWTgXvGN00wfaQuH1MeHPjvqy4Go4r danny@dn-notebook"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMT/rhCBp90SBW15dObrI1vl48uIdbjzwK+LQxtd/m8m danny@dn-workstation"
  ];
}

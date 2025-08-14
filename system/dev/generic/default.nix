{
  modulesPath,
  lib,
  pkgs,
  nix-version,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk.nix
    ./boot.nix
  ];

  # boot.loader.systemd-boot.enable = true;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    devices = [ "/dev/md126" ];
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.openssh = {
    enable = true;
    ports = [
      22
      30072
    ];
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
      UseDns = false;
    };
  };

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBzLpMKn0Q24ACC6k/7lOX0FIdcFhq15NY6849yROeUK danny@dn-pre7780"
  ];

  system.stateVersion = nix-version;
}

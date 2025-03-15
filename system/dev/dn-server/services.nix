{ username, pkgs, ... }:

{
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

  services = {
    dbus.enable = true;

    blueman.enable = true;

    openssh = {
      enable = true;
      ports = [
        22
        30072
      ];
      settings = {
        PasswordAuthentication = true;
        AllowUsers = [ username ];
        UseDns = true;
        PermitRootLogin = "yes";
      };
    };

    xserver = {
      enable = false;
      xkb.layout = "us";
    };

    # USB auto mount
    gvfs.enable = true;
    udisks2.enable = true;
    devmon.enable = true;

    flatpak.enable = true;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBzLpMKn0Q24ACC6k/7lOX0FIdcFhq15NY6849yROeUK danny@dn-pre7780"
  ];
}

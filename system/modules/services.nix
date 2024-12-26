{ config, pkgs, ... }:

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
    picom.enable = true;

    blueman.enable = true;

    openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        AllowUsers = [ "danny" ];
        UseDns = true;
        PermitRootLogin = "no";
      };
    };

    xserver = {
      enable = true;
      xkb.layout = "us";
    };

    displayManager = {
      sddm.enable = true;
      sddm.theme = "${import ./sddm-theme.nix { inherit pkgs; }}";
    };

    # USB auto mount
    gvfs.enable = true;
    udisks2.enable = true;
    devmon.enable = true;

    flatpak.enable = true;

    # Thuner plugin
    tumbler.enable = true; # Thumbnail
  };
}

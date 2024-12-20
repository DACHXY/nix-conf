{ pkgs, ... }:

{
  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = [ "danny" ];

  virtualisation = {
    docker.enable = true;

    # Run container as systemd service
    oci-containers = {
      backend = "docker";
      containers = { };
    };

    libvirtd = {
      enable = true;
    };

    spiceUSBRedirection.enable = true;
  };
}

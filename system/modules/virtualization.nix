{
  pkgs,
  ...
}:
{
  virtualisation = {
    containers = {
      enable = true;
      containersConf.settings.compose_warning_logs = false;
    };
    oci-containers.backend = "podman";
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    spiceUSBRedirection.enable = true;
  };

  environment.systemPackages = with pkgs; [
    dive # look into docker image layers
    podman-tui
    podman-compose
  ];
}

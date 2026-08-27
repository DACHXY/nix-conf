{
  flake.modules.nixos.base =
    { pkgs, config, ... }:
    {
      virtualisation = {
        containers = {
          enable = true;
          containersConf.settings.compose_warning_logs = false;
          registries.settings.search = [ "docker.io" ];
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

      home-manager.users.${config.my.user.name} = {
        services.podman = {
          enable = true;
        };
      };
    };

  flake.modules.darwin.gui =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        podman-desktop
        podman
        podman-compose
        dive
        podman-tui
      ];
    };
}

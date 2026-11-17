{
  flake.modules.nixos.base =
    {
      pkgs,
      lib,
      config,
      ...
    }:
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

      # Containers keep the store path of the podman that started them in their
      # healthcheck units *and* timers. Swap podman on a rebuild and the old
      # path is GC'd, so every 10s the leftover timer retries a unit whose
      # ExecStart no longer exists (status=203/EXEC). Those failures then show
      # up as "the following units failed" at the end of every rebuild.
      #
      # Two halves: restart NixOS-managed containers whenever podman changes so
      # podman recreates the units on the new path, and sweep the stale
      # hash-named units that unmanaged (podman run / compose) containers leave
      # behind. Podman names them `<container-id>-<random>.{service,timer}`, so
      # the 64-hex prefix is a safe discriminator -- no NixOS unit looks like
      # that.
      systemd.services =
        lib.mapAttrs' (
          name: _: lib.nameValuePair "podman-${name}" { restartTriggers = [ pkgs.podman ]; }
        ) config.virtualisation.oci-containers.containers
        // {
          podman-clear-stale-healthchecks = {
            description = "Stop podman healthcheck units left behind by a previous podman";
            wantedBy = [ "multi-user.target" ];
            restartTriggers = [ pkgs.podman ];
            path = [
              config.systemd.package
              pkgs.gawk
              pkgs.gnugrep
              pkgs.findutils
            ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              systemctl list-units --all --plain --no-legend '*.timer' \
                | awk '$1 ~ /^[0-9a-f]{64}-/ { print $1 }' \
                | xargs -r systemctl stop
              systemctl list-units --failed --plain --no-legend '*.service' \
                | awk '$1 ~ /^[0-9a-f]{64}-/ { print $1 }' \
                | xargs -r systemctl reset-failed
            '';
          };
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
        krunkit
        podman
        podman-compose
      ];

      homebrew = {
        casks = [
          "podman-desktop"
        ];
        brews = [
          "podman-tui"
          "dive"
        ];
      };
    };
}

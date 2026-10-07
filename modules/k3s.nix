{
  flake.modules.nixos.k3s = { config, ... }: {
    networking.firewall.allowedTCPPorts = [
      6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
      # 2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
      # 2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
    ];
    networking.firewall.allowedUDPPorts = [
      # 8472 # k3s, flannel: required if using multi-node for inter-node networking
    ];
    services.k3s.enable = true;
    services.k3s.role = "server";
    services.k3s.extraFlags = toString [
      # "--debug" # Optionally add additional args to k3s
    ];

    # Single node, so the registry lives on this host and k3s reaches it as
    # localhost:5000 (see registries.yaml below). 127.0.0.1 only, no firewall
    # hole - flip listenAddress/openFirewall if other machines must push.
    services.dockerRegistry = {
      enable = true;
      enableDelete = true; # DELETE /v2/..., otherwise dev tags pile up forever
    };

    # Local registry, shared by charts and images. It speaks plain HTTP, so
    # containerd needs to be told that; without the mirror k3s would try HTTPS
    # and fail. k3s reads this file once at startup, hence the restart trigger.
    environment.etc."rancher/k3s/registries.yaml".text = ''
      mirrors:
        "localhost:5000":
          endpoint:
            - "http://localhost:5000"
    '';
    systemd.services.k3s.restartTriggers = [
      config.environment.etc."rancher/k3s/registries.yaml".source
    ];
  };
}

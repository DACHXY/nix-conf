{
  flake.modules.nixos.docker-registry = {
    # Local registry for images pushed from this host (localhost:5000).
    # 127.0.0.1 only, no firewall hole - flip listenAddress/openFirewall if
    # other machines must push.
    services.dockerRegistry = {
      enable = true;
      enableDelete = true; # DELETE /v2/..., otherwise dev tags pile up forever
    };
  };
}

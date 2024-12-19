{ pkgs, ... }:

{
  virtualisation = {
    docker.enable = true;

    # Run container as systemd service
    oci-containers = {
      backend = "docker";
      containers = {};
    };
  };
 }

{
  ...
}:
{
  virtualisation = {
    docker.enable = true;

    # Run container as systemd service
    oci-containers = {
      backend = "podman";
      containers = { };
    };

    spiceUSBRedirection.enable = true;
  };
}

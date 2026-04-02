{ ... }:
let
  stateDirectory = "/var/lib/freeipa";
in
{
  virtualisation.oci-containers.containers = {
    freeipa = {
      image = "";
      autoStart = true;
      ports = [ ];
      volumes = [
        "${stateDirectory}:/data:Z"
      ];
    };
  };

  systemd.services.docker-freeipa = {
    serviceConfig = {
      StateDirectory = "freeipa";
    };
  };
}

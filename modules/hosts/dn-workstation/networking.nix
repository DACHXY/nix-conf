{
  configurations.nixos.dn-workstation.module = { ... }: {

    networking.networkmanager.ensureProfiles.profiles = {
      "enp132s0" = {
        connection = {
          id = "enp132s0";
          type = "ethernet";
          uuid = "20428b79-9bf9-360e-88de-09f912650b3d";
        };
        ipv4 = {
          method = "manual";
          addresses = "192.168.0.3/24";
          gateway = "192.168.0.1";
        };
      };
    };
  };
}

{ ... }: {

  configurations.nixos.dn-workstation.module =
    { config, ... }:
    {
      services.aria2 = {
        enable = true;
        settings = {
          dir = "/home/${config.my.user.name}/Videos/T/Aria";
        };
        openPorts = true;
        rpcSecretFile = config.sops.secrets."aria2/rpcSecret".path;
      };
    };
}

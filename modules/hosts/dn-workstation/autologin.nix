{
  configurations.nixos.dn-workstation.module =
    { config, ... }:
    {
      services.displayManager.autoLogin = {
        enable = true;
        user = config.my.user.name;
      };
    };
}

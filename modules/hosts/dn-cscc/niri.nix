{
  configurations.nixos.dn-cscc.module =
    { config, ... }:
    {
      home-manager.users.${config.my.user.name} = {
        programs.niri.settings = {
          debug = {
            render-drm-device = "/dev/dri/renderD128";
            ignore-drm-device = "/dev/dri/renderD129";
          };
        };
      };
    };
}

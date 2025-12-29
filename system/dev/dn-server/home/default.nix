{
  config,
  ...
}:
let
  inherit (config.systemConf) username;
in
{
  home-manager.users."${username}" = {
    imports = [
      ../../../../home/user/config.nix
      ../../../../home/user/direnv.nix
      ../../../../home/user/environment.nix
      ../../../../home/user/nvf
      ../../../../home/user/shell.nix
      ../../../../home/user/yazi.nix
      ../../../../home/user/ghostty.nix
    ];
  };
}

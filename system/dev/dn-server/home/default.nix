{
  inputs,
  config,
  pkgs,
  ...
}:
let
  inherit (config.systemConf) username;
in
{
  home-manager = {
    users."${username}" = {
      imports = [
        ../../../../home/user/config.nix
        ../../../../home/user/direnv.nix
        ../../../../home/user/environment.nix
        ../../../../home/user/nvf
        ../../../../home/user/shell.nix
        ../../../../home/user/yazi.nix
        {
          home.packages = with pkgs; [
            inputs.ghostty.packages.${system}.default
          ];
        }

        # Git
        (import ../../../../home/user/git.nix {
          inherit username;
          email = "danny10132024@gmail.com";
        })
      ];
    };
  };
}

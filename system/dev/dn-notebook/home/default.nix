{
  config,
  inputs,
  lib,
  self,
  helper,
  ...
}:
let
  inherit (config.systemConf) username;
  inherit (lib) mkForce;
  configDir = "${../../../../home/config}";
in
{
  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      inherit
        inputs
        self
        username
        helper
        ;
    };
    users.${username} =
      { pkgs, lib, ... }:
      {
        imports = [
          inputs.nvf.homeManagerModules.default
          inputs.zen-browser.homeModules.twilight

          ./git.nix
          ./shell.nix
          ./tmux.nix
          ./zen-browser.nix
          ../../../../home/user/nvf
          ../../../../home/user/ghostty.nix
          ../../../../home/user/yazi.nix
        ];

        programs.nvf.settings.vim.clipboard.providers.wl-copy.enable = mkForce false;

        xdg.configFile."starship.toml".source = lib.mkForce "${configDir}/starship/starship.toml";
        home = {
          enableNixpkgsReleaseCheck = false;
          homeDirectory = "/Users/${username}";
          stateVersion = "26.05";
        };
        programs.home-manager.enable = true;
        programs.ghostty.package = pkgs.ghostty-bin;
      };
  };
}

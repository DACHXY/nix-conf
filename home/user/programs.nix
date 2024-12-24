{ pkgs, ... }: {
  programs = {
    neovim = {
      enable = true;
      withNodeJs = true;
      withPython3 = true;
      extraLuaPackages = ps: [ ps.magick ];
      extraPackages = [ pkgs.imagemagick ];
    };
  };
}

{ inputs, pkgs, ... }:

{
	programs = {
		neovim = {
			enable = true;
			withNodeJs = true;
			extraLuaPackages = ps: [ ps.magick ];
			extraPackages = [ pkgs.imagemagick ];
		};
	};

}

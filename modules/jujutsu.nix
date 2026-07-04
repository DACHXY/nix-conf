{ inputs, ... }:
{
  nixpkgs.overlays = [ inputs.jj-starship.overlays.default ];

  flake.modules.homeManager.base = { ... }: {
    programs.jujutsu = {
      enable = true;
    };
  };
}

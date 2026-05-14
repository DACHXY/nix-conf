{ ... }:
{
  flake.modules.nixos.base = {
    programs.nh = {
      enable = true;
      flake = "/etc/nixos";
      clean.enable = true;
      clean.extraArgs = "--keep 5 --keep-since 3d";
    };
  };

  flake.modules.darwin.base =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [ nh ];
    };
}

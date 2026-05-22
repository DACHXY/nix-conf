{
  flake.modules.generic.base =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [ devenv ];
    };
}

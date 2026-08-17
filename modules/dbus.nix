{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      services.dbus = {
        enable = true;
        packages = with pkgs; [ gcr ];
      };
    };
}

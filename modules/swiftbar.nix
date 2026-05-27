{
  flake.modules.darwin.gui =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        swiftbar
      ];
    };
}

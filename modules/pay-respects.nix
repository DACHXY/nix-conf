{
  flake.modules.generic.base =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        pay-respects
      ];
    };

  flake.modules.homeManager.base = {
    programs.pay-respects = {
      enable = true;
      options = [
        "--alias"
        "f"
      ];
    };
  };
}

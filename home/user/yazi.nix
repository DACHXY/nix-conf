{
  inputs,
  system,
  pkgs,
  ...
}:
{
  programs = {
    yazi = {
      enable = true;
      package = inputs.yazi.packages.${system}.default;
      enableFishIntegration = false;
    };
  };

  home.packages = with pkgs; [
    # Drag from yazi
    ripdrag
  ];

  home.file = {
    ".config/yazi" = {
      recursive = true;
      source = ../config/yazi;
    };
  };
}

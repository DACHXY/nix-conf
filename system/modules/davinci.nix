{ pkgs, ... }:
let
in
{
  environment.systemPackages = with pkgs; [
    davinci-resolve
  ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime
      rocmPackages.clr.icd
    ];
  };
}

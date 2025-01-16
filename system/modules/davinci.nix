{ pkgs, ... }:
let
  davinciResolve = pkgs.callPackage ../../pkgs/davinci-resolve { };
in
{
  environment.systemPackages = [
    davinciResolve
  ];

  hardware.graphics.extraPackages = with pkgs; [
    intel-compute-runtime
    rocmPackages.clr.icd
  ];
}

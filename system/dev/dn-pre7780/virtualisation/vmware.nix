{ pkgs, ... }:
{
  virtualisation.vmware.host = {
    enable = true;
    extraPackages = with pkgs; [ open-vm-tools ];
  };
}

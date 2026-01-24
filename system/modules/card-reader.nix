{ pkgs, ... }:
{
  services.pcscd = {
    enable = true;
    plugins = with pkgs; [ ccid ];
  };
}

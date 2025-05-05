{ baseUrl, email }:
{ pkgs, ... }:
{
  programs.rbw = {
    enable = true;
    settings = {
      email = email;
      base_url = baseUrl;
      pinentry = pkgs.pinentry-gnome3;
    };
  };
}

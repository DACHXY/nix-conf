{ ... }:
{
  systemConf.security.allowedDomains = [ "matrix.org" ];

  imports = [
    ../../../modules/selfhost/matrix.nix
  ];
}

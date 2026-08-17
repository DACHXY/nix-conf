{ config, ... }:
{
  flake.modules.homeManager.danny =
    { pkgs, ... }:
    let
      nextcloudURL = config.flake.public.config.services.nextcloud.endpoint;
      face = pkgs.fetchurl {
        url = "${nextcloudURL}/s/NDHdYnwrLqt5Syk/preview";
        hash = "sha256-mrTL+Q9rfp/RSMN19ymv0tV4hcT+wkp3C1dLITvZuR8=";
      };
    in
    {
      home.file.".face".source = face;
    };
}

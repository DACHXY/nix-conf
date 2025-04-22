{ config, ... }:
let
  defaultSopsFile = ../.. + "/system/dev/${config.networking.hostName}/secret.yaml";
  ageKeyFile = "/var/lib/sops-nix/key.txt";
in
{
  sops = {
    defaultSopsFile = defaultSopsFile;

    age = {
      keyFile = ageKeyFile;
    };

    secrets = {
      "wireguard/privateKey" = { };
      "wireguard/conf" = { };
      "nextcloud/adminPassword" = { };
      "step_ca/password" = { };
    };
  };

  environment.variables = {
    SOPS_AGE_KEY_FILE = ageKeyFile;
  };
}

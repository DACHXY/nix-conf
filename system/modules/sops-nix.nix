{ config, ... }:
let
  defaultSopsFile = ../.. + "/system/dev/${config.networking.hostName}/sops/secret.yaml";
  ageKeyFile = "/var/lib/sops-nix/key.txt";
in
{
  sops = {
    defaultSopsFile = defaultSopsFile;

    age = {
      keyFile = ageKeyFile;
    };
  };

  environment.variables = {
    SOPS_AGE_KEY_FILE = ageKeyFile;
  };
}

{
  sops = {
    secrets = {
      "wireguard/privateKey" = { };
      "nextcloud/adminPassword" = { };
      "step_ca/password" = { };
    };
  };
}

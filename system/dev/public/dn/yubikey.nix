{
  config,
  ...
}:
let
  inherit (config.systemConf) username;
in
{
  sops.secrets."u2f_keys" = {
    sopsFile = ../../public/sops/dn-secret.yaml;
    owner = username;
  };

  systemd.tmpfiles.rules = [
    "d /home/${username}/.config/Yubico - ${username} - - -"
    "L /home/${username}/.config/Yubico/u2f_keys - - - - ${config.sops.secrets."u2f_keys".path}"
  ];
}

{
  settings,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ../../modules/presets/basic.nix
    ../../modules/gaming.nix
    ../../modules/virtualization.nix
    ../../modules/wine.nix
    ../../modules/wireguard.nix
  ];

  home-manager = {
    users."${settings.personal.username}" = {
      imports = [
        ../../../home/presets/basic.nix
      ];
    };
  };

  users.users."${settings.personal.username}".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
  ];
}

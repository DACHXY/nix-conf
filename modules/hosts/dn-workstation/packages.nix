{
  configurations.nixos.dn-workstation.module =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [ mattermost-desktop ];
    };
}

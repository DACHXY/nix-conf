{
  flake.modules.nixos.danny =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        mattermost-desktop
      ];
    };
}

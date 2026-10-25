{
  inputs,
  ...
}:
{
  flake.modules.darwin.base =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      user = config.my.user.name;

      ivpn = inputs.ivpn.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      environment.systemPackages = [ pkgs.openconnect ];

      environment.etc."sudoers.d/openconnect".text = ''
        ${user} ALL=(ALL) NOPASSWD: ${lib.getExe pkgs.openconnect}, /run/current-system/sw/bin/openconnect
        ${user} ALL=(ALL) NOPASSWD: /bin/kill
      '';

      home-manager.users.${user} = {
        home.packages = [ ivpn ];

        home.file."Library/Application Support/ivpn/config.json".text = builtins.toJSON {
          secretsDir = "${config.home-manager.users.${user}.home.homeDirectory}/Documents/vpn-configs";
          openconnect = lib.getExe pkgs.openconnect;
        };

        launchd.agents.ivpn = {
          enable = true;
          config = {
            ProgramArguments = [
              "${ivpn}/Applications/IVPN.app/Contents/MacOS/IVPN"
            ];
            RunAtLoad = true;
          };
        };
      };
    };
}

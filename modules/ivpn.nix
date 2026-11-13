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

      # ivpn runs `sudo -n openconnect <args>` and `sudo -n /bin/kill -SIG <pid>`.
      # Without argument restrictions that is root for anyone running as the
      # user (`openconnect --script=...`, `--pid-file=/etc/...`, killing any
      # process), so both are pinned to the exact argument shapes ivpn builds
      # (sudo >= 1.9.10 regex arguments). Inside a `^...$` regex, sudoers'
      # `=` `:` must NOT be backslash-escaped: sudo hands the text to regcomp
      # as is, so `\=` would stay in the pattern.
      environment.etc."sudoers.d/openconnect".text =
        let
          runDir = "${config.users.users.${user}.home}/Library/Application Support/ivpn/run";
          ocArgs = ''^--protocol=(anyconnect|fortinet|gp|nc|pulse|f5|array) --user=[A-Za-z0-9._@+-]+ --passwd-on-stdin --background --pid-file=${runDir}/[A-Za-z0-9._-]+\.pid( --servercert=pin-sha256:[A-Za-z0-9+/=]+)? [A-Za-z0-9.:/_-]+$'';
        in
        ''
          Cmnd_Alias IVPN_OPENCONNECT = ${lib.getExe pkgs.openconnect} ${ocArgs}, /run/current-system/sw/bin/openconnect ${ocArgs}
          Cmnd_Alias IVPN_KILL = /bin/kill ^-(0|TERM|KILL) [0-9]+$
          ${user} ALL=(root) NOPASSWD: IVPN_OPENCONNECT, IVPN_KILL
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

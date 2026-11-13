{ lib, inputs, ... }:
let
  # Same mapping git's includeIf uses (modules/users/danny/git.nix).
  remoteIdentities = import ./users/danny/_remote-identities.nix;

  caseArms = builtins.concatStringsSep "" (
    builtins.map (host: ''
      *${host}*)
        JJ_USER=${lib.escapeShellArg remoteIdentities.${host}.name}
        JJ_EMAIL=${lib.escapeShellArg remoteIdentities.${host}.email}
        ;;
    '') (builtins.attrNames remoteIdentities)
  );
in
{
  nixpkgs.overlays = [ inputs.jj-starship.overlays.default ];

  flake.modules.homeManager.base =
    { pkgs, ... }:
    let
      # jj can only switch config by repo *path* (`--when.repositories`), not by
      # remote URL, so it does not pick up git's
      # `includeIf "hasconfig:remote.*.url:..."`. This wrapper restores the git
      # behaviour: match any of the repo's remote URLs and export
      # JJ_USER/JJ_EMAIL, which take precedence over every jj config file.
      # JJ_USER/JJ_EMAIL set by the caller always win (we never touch them).
      jjWithRemoteIdentity = pkgs.writeShellScriptBin "jj" ''
        set -u

        if [ -z "''${JJ_EMAIL:-}" ] && [ -z "''${JJ_USER:-}" ]; then
          urls=$(git config --get-regexp '^remote\..*\.url$' 2>/dev/null | awk '{print $2}') || urls=""
          case "$urls" in
            ${caseArms}
          esac
          if [ -n "''${JJ_EMAIL:-}" ]; then
            export JJ_EMAIL JJ_USER
          fi
        fi

        exec ${pkgs.jujutsu}/bin/jj "$@"
      '';

      jujutsu = pkgs.symlinkJoin {
        name = "jujutsu-${lib.getVersion pkgs.jujutsu}-with-remote-identity";
        paths = [ pkgs.jujutsu ];
        postBuild = ''
          rm "$out/bin/jj"
          ln -s ${jjWithRemoteIdentity}/bin/jj "$out/bin/jj"
        '';
      };
    in
    {
      programs.jujutsu = {
        enable = true;
        package = jujutsu;
      };
    };
}

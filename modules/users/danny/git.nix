{
  flake.modules.homeManager.danny =
    { lib, ... }:
    let
      remoteIdentities = import ./_remote-identities.nix;
    in
    {
      programs.git = {
        settings = {
          user.name = "dachxy";
        };
        includes = lib.mapAttrsToList (host: identity: {
          condition = "hasconfig:remote.*.url:**/*${host}*/**";
          contents.user = identity;
        }) remoteIdentities;
      };
    };
}

{
  fqdn ? null,
  proxy ? true,
}: {
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (builtins) toString;
  inherit (lib) mkIf;
  finalFqdn =
    if fqdn != null
    then fqdn
    else config.networking.fqdn;

  version = "25.9.0";

  src = pkgs.fetchFromGitHub {
    name = "actualbudget-actual-source";
    owner = "actualbudget";
    repo = "actual";
    tag = "v${version}";
    hash = "sha256-TYvGavj0Ts1ahgseFhuOtmfOSgPkjBIr19SIGOgx++Q=";
  };

  translations = pkgs.fetchFromGitHub {
    name = "actualbudget-translations-source";
    owner = "actualbudget";
    repo = "translations";
    rev = "eba2cb7a8e339cda2efa4e834f15b7c81d145966";
    hash = "sha256-YVjG2fwyIa1nVyZvRvujRQYHN/P9SaIB2nWiJm5m87Y=";
  };

  missingHashes = ./missing-hashes_v1.json;

  actualServer = pkgs.actual-server.overrideAttrs (_: {
    inherit version src;
    srcs = [
      src
      translations
    ];

    srouceRoot = "${src.name}/";

    offlineCache = pkgs.yarn-berry.fetchYarnBerryDeps {
      inherit src missingHashes;
      hash = "sha256-Vod0VfoZG2nwnu35XLAPqY5uuRLVD751D3ZysD0ypL0=";
    };

    postPatch = ''
      ln -sv ../../../${translations.name} ./packages/desktop-client/locale

      patchShebangs --build ./bin ./packages/*/bin

      # Patch all references to `git` to a no-op `true`. This neuter automatic
      # translation update.
      substituteInPlace bin/package-browser \
        --replace-fail "git" "true"

      # Allow `remove-untranslated-languages` to do its job.
      chmod -R u+w ./packages/desktop-client/locale

      # Disable the postinstall script for `protoc-gen-js` because it tries to
      # use network in buildPhase. It's just used as a dev tool and the generated
      # protobuf code is committed in the repository.
      cat <<< $(${lib.getExe pkgs.jq} '.dependenciesMeta."protoc-gen-js".built = false' ./package.json) > ./package.json
    '';
  });
in {
  services = {
    actual = {
      enable = true;
      package = actualServer;
      settings = {
        port = 31000;
        hostname = "127.0.0.1";
        serverFiles = "/var/lib/actual/server-files";
        userFiles = "/var/lib/actual/user-files";
        loginMethod = "openid";
      };
    };

    actual-budget-api = {
      enable = true;
      listenPort = 31001;
      listenHost = "127.0.0.1";
      serverURL = "https://${finalFqdn}";
    };
  };

  services.nginx.virtualHosts."${finalFqdn}" = mkIf proxy {
    enableACME = true;
    forceSSL = true;

    locations."/api/".proxyPass = "http://localhost:${toString config.services.actual-budget-api.listenPort}/";
    locations."/".proxyPass = "http://localhost:${toString config.services.actual.settings.port}";
  };
}

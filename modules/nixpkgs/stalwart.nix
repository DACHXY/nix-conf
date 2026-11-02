{
  lib,
  ...
}:
# Stalwart 1.0 is not in the pinned nixpkgs yet (it still ships 0.16.26), and
# bumping the flake for it would rebuild the whole system. These are the
# upstream release binaries instead: no build, no cargoHash, easy to delete
# once nixpkgs carries `stalwart_1_0`.
let
  # Only the two mail hosts (x86_64-linux) use these.
  target = "x86_64-unknown-linux-gnu";

  mkStalwart =
    final: version: srcHash:
    final.stdenv.mkDerivation {
      pname = "stalwart";
      inherit version;

      src = final.fetchurl {
        url = "https://github.com/stalwartlabs/stalwart/releases/download/v${version}/stalwart-${target}.tar.gz";
        hash = srcHash;
      };

      nativeBuildInputs = [ final.autoPatchelfHook ];
      buildInputs = [ final.stdenv.cc.cc.lib ];

      dontConfigure = true;
      dontBuild = true;
      sourceRoot = ".";

      installPhase = ''
        runHook preInstall
        install -Dm755 stalwart $out/bin/stalwart
        runHook postInstall
      '';

      meta = {
        description = "Secure, modern, all-in-one mail and collaboration server (upstream release binary)";
        homepage = "https://github.com/stalwartlabs/stalwart";
        license = lib.licenses.agpl3Only;
        mainProgram = "stalwart";
        platforms = [ "x86_64-linux" ];
      };
    };

  # WebAdmin is a separate bundle served from Application.resourceUrl; 1.0 only
  # loads a major-version-2 bundle.
  mkWebui =
    final: version: hash:
    final.runCommand "stalwart-webui-${version}"
      {
        src = final.fetchurl {
          url = "https://github.com/stalwartlabs/webui/releases/download/v${version}/webui.zip";
          inherit hash;
        };
      }
      ''
        mkdir -p $out
        cp $src $out/webui.zip
      '';
in
{
  # Every host in this repo shares one pkgs instance (see
  # modules/nixpkgs/instance.nix), so the overlay goes there, not on a host.
  nixpkgs.overlays = [
    (
      final: _prev:
      let
        webui_1 = mkWebui final "2" "sha256-Us+fjCPbVnazy0heUivGm0bQzjbxyTpiiqdFi7wq2OQ=";
      in
      {
      stalwart_1_0 = mkStalwart final "1.0.0" "sha256-QzoA/GfoXm7aRymVQ1Kme/xjnAJQLeQhppNk6GuYmpQ=";

      stalwart-webui = webui_1;

      # nixpkgs' stalwart-cli (1.0.13) is one release behind the 1.0.0 server and
      # cannot parse its /api/schema, so the declarative bootstrap needs this one.
      stalwart-cli =
        final.stdenv.mkDerivation
          {
            pname = "stalwart-cli";
            version = "1.0.14";

            src = final.fetchurl {
              url = "https://github.com/stalwartlabs/cli/releases/download/v1.0.14/stalwart-cli-${target}.tar.xz";
              hash = "sha256-eFhLI4QisCAae9Ij7ZWzwaf7hzWtP6jIhNgYpm/RvGU=";
            };

            nativeBuildInputs = [ final.autoPatchelfHook ];
            buildInputs = [ final.stdenv.cc.cc.lib ];

            dontConfigure = true;
            dontBuild = true;
            sourceRoot = "stalwart-cli-${target}";

            installPhase = ''
              runHook preInstall
              install -Dm755 stalwart-cli $out/bin/stalwart-cli
              runHook postInstall
            '';

            meta = {
              description = "Command-line client for Stalwart (upstream release binary)";
              homepage = "https://github.com/stalwartlabs/cli";
              license = lib.licenses.agpl3Only;
              mainProgram = "stalwart-cli";
              platforms = [ "x86_64-linux" ];
            };
          };

      }
    )
  ];
}

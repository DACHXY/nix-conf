# open-slide — agent-native slide framework (https://github.com/open-slide/open-slide)
{ ... }:
{
  flake.modules.generic.base =
    { pkgs, ... }:
    let
      version = "2.0.0";

      npmDeps = pkgs.stdenvNoCC.mkDerivation {
        pname = "open-slide-npm-deps";
        inherit version;
        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        outputHash = "sha256-OD99u5JabiCb/qeFyRJUkEb8EknYtBj31Yi4OMHEXE0=";

        nativeBuildInputs = [ pkgs.nodejs ];

        buildCommand = ''
          export HOME=$TMPDIR
          export npm_config_cache=$TMPDIR/npm-cache
          export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
          export NODE_EXTRA_CA_CERTS=$SSL_CERT_FILE

          mkdir -p $out/lib && cd $out/lib
          cat > package.json <<EOF
          { "name": "open-slide-bundle", "private": true, "dependencies": { "@open-slide/cli": "${version}" } }
          EOF
          npm install --ignore-scripts --no-audit --no-fund --loglevel=error
        '';
      };

      openSlide = pkgs.writeShellApplication {
        name = "open-slide";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          # ponytail: first invocation copies ~10MB into the cache; races between
          # two concurrent first runs are harmless (same content).
          dir="''${XDG_CACHE_HOME:-$HOME/.cache}/open-slide/${version}/lib"
          if [ ! -f "$dir/node_modules/@open-slide/cli/dist/cli.js" ]; then
            mkdir -p "$dir"
            cp -r ${npmDeps}/lib/. "$dir/"
            chmod -R u+w "$dir"
          fi

          exec ${pkgs.nodejs}/bin/node "$dir/node_modules/@open-slide/cli/dist/cli.js" "$@"
        '';
      };
    in
    {
      environment.systemPackages = [ openSlide ];
    };
}

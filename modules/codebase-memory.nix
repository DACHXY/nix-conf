# Static release binaries of codebase-memory-mcp (github.com/DeusData/codebase-memory-mcp).
# An overlay so every host (darwin + nixos) can use pkgs.codebase-memory-mcp.
{ ... }:
let
  version = "0.11.0";
  assets = {
    "aarch64-darwin" = {
      url = "codebase-memory-mcp-darwin-arm64.tar.gz";
      sha256 = "4dee7f38b63740e6751d7a7ed7eb10291c1f2a3ea2415f599dc68370ca0a2d18";
    };
    "x86_64-darwin" = {
      url = "codebase-memory-mcp-darwin-amd64.tar.gz";
      sha256 = "dbf1c73bfcbde64e7dde4cd1320da7afc02e2c972ee1789ae039521411f5132e";
    };
    "aarch64-linux" = {
      url = "codebase-memory-mcp-linux-arm64.tar.gz";
      sha256 = "c0e46c87cf37e35f1ac0bd9cc7e1d8b0ca4ef40034e1008805d709fa52a4e38a";
    };
    "x86_64-linux" = {
      url = "codebase-memory-mcp-linux-amd64.tar.gz";
      sha256 = "032b33c1833919a2d1de67ff6367fa6ea46aee8689c86ef223c88fae3b6e4536";
    };
  };
in
{
  nixpkgs.overlays = [
    (
      final: prev:
      let
        asset = assets.${prev.stdenv.hostPlatform.system};
      in
      {
        codebase-memory-mcp = prev.stdenvNoCC.mkDerivation {
          pname = "codebase-memory-mcp";
          inherit version;

          src = prev.fetchurl {
            url = "https://github.com/DeusData/codebase-memory-mcp/releases/download/v${version}/${asset.url}";
            sha256 = asset.sha256;
          };

          sourceRoot = ".";
          installPhase = ''
            runHook preInstall
            install -Dm555 codebase-memory-mcp $out/bin/codebase-memory-mcp
            runHook postInstall
          '';

          meta = {
            mainProgram = "codebase-memory-mcp";
            description = "High-performance code intelligence MCP server (static release binary)";
            homepage = "https://github.com/DeusData/codebase-memory-mcp";
            sourceProvenance = with prev.lib.sourceTypes; [ binaryNativeCode ];
            license = prev.lib.licenses.unfree;
          };
        };
      }
    )
  ];
}

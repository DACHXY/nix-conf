prev: final: {
  ferium = prev.ferium.overrideAttrs (
    final: prev: rec {
      cargoHash = "sha256-yedl4KQCpT7Ai1EPvwD5kzhkHesIjGVAcxKjp5k2jmI=";
      version = "4.7.0";
      src = prev.fetchFromGitHub {
        owner = "gorilla-devs";
        repo = prev.pname;
        rev = "v${version}";
        hash = "sha256-jj3BdaxH7ofhHNF2eu+burn6+/0bPQQZ8JfjXAFyN4A=";
      };

      cargoDeps = prev.rustPlatform.fetchCargoVendor {
        inherit (final) pname src version;
        useFetchCargoVendor = true;
        hash = final.cargoHash;
      };
    }
  );
}

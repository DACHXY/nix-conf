final: prev: {
  dovecot = prev.dovecot.overrideAttrs (oldAttrs: rec {
    version = "2.4.0";

    src = prev.fetchurl {
      url = "https://dovecot.org/releases/${prev.lib.versions.majorMinor version}/${oldAttrs.pname}-${version}.tar.gz";
      hash = "sha256-6Q5J+MMbCaUIJJpP7oYF+qZf4yCBm/ytryUkEmJT1a4=";
    };

    # Dovecot 2.4 Not need this patch anymore
    patches = builtins.filter (
      patch: (!(prev.lib.hasInfix "Support-openssl-3.0.patch" (toString patch)))
    ) oldAttrs.patches;

    # Dovecot 2.4 Not need this patch anymore
    postPatch =
      prev.lib.replaceStrings
        [
          # bash
          ''
            # DES-encrypted passwords are not supported by NixPkgs anymore
            sed '/test_password_scheme("CRYPT"/d' -i src/auth/test-libpassword.c
          ''
        ]
        [
          # bash
          ''
            # DES-encrypted passwords are not supported by NixPkgs anymore
            sed '/test_password_scheme("CRYPT"/d' -i src/lib-auth/test-password-scheme.c
          ''
        ]
        oldAttrs.postPatch;
  });
}

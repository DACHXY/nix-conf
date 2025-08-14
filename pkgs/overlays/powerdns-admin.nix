final: prev: {
  powerdns-admin = prev.powerdns-admin.overrideAttrs (
    oldAttrs:
    let
      pname = "powerdns-admin";
      version = "0.4.2";
      src = prev.fetchFromGitHub {
        owner = "PowerDNS-Admin";
        repo = "PowerDNS-Admin";
        rev = "v${version}";
        hash = "sha256-q9mt8wjSNFb452Xsg+qhNOWa03KJkYVGAeCWVSzZCyk=";
      };

      python = prev.python3;

      pythonDeps = with python.pkgs; [
        distutils
        flask
        flask-assets
        flask-login
        flask-sqlalchemy
        flask-migrate
        flask-seasurf
        flask-mail
        flask-session
        flask-session-captcha
        flask-sslify
        mysqlclient
        psycopg2
        sqlalchemy
        certifi
        cffi
        configobj
        cryptography
        bcrypt
        requests
        python-ldap
        pyotp
        qrcode
        dnspython
        gunicorn
        itsdangerous
        python3-saml
        pytz
        rcssmin
        rjsmin
        authlib
        bravado-core
        lima
        lxml
        passlib
        pyasn1
        pytimeparse
        pyyaml
        jinja2
        itsdangerous
        webcolors
        werkzeug
        zipp
        zxcvbn

        standard-imghdr # Add extra dep
      ];

      all_patches = [
        (prev.pkgs.fetchpatch {
          url = "https://raw.githubusercontent.com/NixOS/nixpkgs/refs/heads/nixos-unstable/pkgs/by-name/po/powerdns-admin/0001-Fix-flask-2.3-issue.patch";
          sha256 = "sha256-EcyHbS9NJorEG0/7JlWdbaHFFZrq9Dy9F0IMxDKLMzw=";
        })
      ];

      assets = prev.stdenv.mkDerivation {
        pname = "${pname}-assets";
        inherit version src;

        offlineCache = prev.fetchYarnDeps {
          yarnLock = "${src}/yarn.lock";
          hash = "sha256-rXIts+dgOuZQGyiSke1NIG7b4lFlR/Gfu3J6T3wP3aY=";
        };

        nativeBuildInputs = [
          prev.yarnConfigHook
        ]
        ++ pythonDeps;

        patches = all_patches ++ [
          (prev.pkgs.fetchpatch {
            url = "https://raw.githubusercontent.com/NixOS/nixpkgs/refs/heads/nixos-unstable/pkgs/by-name/po/powerdns-admin/0002-Remove-cssrewrite-filter.patch";
            sha256 = "sha256-/5oRyD6T7PtofG1U26wiSigDVj2F+U6VLDMO5YH926o=";
          })
        ];

        buildPhase = ''
          SESSION_TYPE=filesystem FLASK_APP=./powerdnsadmin/__init__.py flask assets build
        '';

        installPhase = ''
          # https://github.com/PowerDNS-Admin/PowerDNS-Admin/blob/54b257768f600c5548a1c7e50eac49c40df49f92/docker/Dockerfile#L43
          mkdir $out
          cp -r powerdnsadmin/static/{generated,assets,img} $out
          find powerdnsadmin/static/node_modules -name webfonts -exec cp -r {} $out \; -printf "Copying %P\n"
          find powerdnsadmin/static/node_modules -name fonts -exec cp -r {} $out \; -printf "Copying %P\n"
          find powerdnsadmin/static/node_modules/icheck/skins/square -name '*.png' -exec cp {} $out/generated \;
        '';
      };

      assetsPy = prev.writeText "assets.py" ''
        from flask_assets import Environment
        assets = Environment()
        assets.register('js_login', 'generated/login.js')
        assets.register('js_validation', 'generated/validation.js')
        assets.register('css_login', 'generated/login.css')
        assets.register('js_main', 'generated/main.js')
        assets.register('css_main', 'generated/main.css')
      '';
    in
    {
      pythonPath = pythonDeps;

      nativeBuildInputs = [ python.pkgs.wrapPython ];

      installPhase = ''
        runHook preInstall

        # Nasty hack: call wrapPythonPrograms to set program_PYTHONPATH (see tribler)
        wrapPythonPrograms

        mkdir -p $out/share $out/bin
        cp -r migrations powerdnsadmin $out/share/

        ln -s ${assets} $out/share/powerdnsadmin/static
        ln -s ${assetsPy} $out/share/powerdnsadmin/assets.py

        echo "$gunicornScript" > $out/bin/powerdns-admin
        chmod +x $out/bin/powerdns-admin
        wrapProgram $out/bin/powerdns-admin \
          --set PATH ${python.pkgs.python}/bin \
          --set PYTHONPATH $out/share:$program_PYTHONPATH

        runHook postInstall
      '';

      passthru = {
        # PYTHONPATH of all dependencies used by the package
        pythonPath = prev.python3.pkgs.makePythonPath pythonDeps;
        tests = prev.nixosTests.powerdns-admin;
      };
    }
  );
}

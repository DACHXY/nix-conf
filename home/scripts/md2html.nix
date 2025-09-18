{ pkgs, ... }:
let
  cssStyle = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/xz/new.css/refs/heads/master/new.css";
    hash = "sha256-Xd3AMZOeThsrupQusSLjqv3hbNmcpeTms0ieI9nyxOk=";
  };
in
pkgs.writeShellScriptBin "md2html" ''
  set -e

  INPUT="$1"
  shift

  BASENAME="''\${INPUT%.*}"
  HTML_TEMP="''\${BASENAME}.html"
  PDF_OUTPUT="''\${BASENAME}.pdf"

  ${pkgs.pandoc}/bin/pandoc "$INPUT" -s \
  --to=html5 --embed-resources \
  --css=${cssStyle} -o "$HTML_TEMP" "$@"

  echo "generated: $HTML_TEMP"
''

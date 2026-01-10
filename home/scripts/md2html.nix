{ pkgs, ... }:
let
  cssStyle = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/xz/new.css/refs/heads/master/new.css";
    hash = "sha256-Xd3AMZOeThsrupQusSLjqv3hbNmcpeTms0ieI9nyxOk=";
  };
  inlineHeader =
    pkgs.writeText "pandoc-inline-header"
      # html
      ''
        <style>
        h1 { font-size: 1.55em !important; }
        h2 { font-size: 1.35em !important; }
        h3 { font-size: 1.2em !important; }
        h4 { font-size: 1.1em !important; }
        </style>
      '';
in
pkgs.writeShellScriptBin "md2html" ''
  set -e

  INPUT="$1"
  shift

  BASENAME="''\${INPUT%.*}"
  HTML_TEMP="''\${BASENAME}.html"
  PDF_OUTPUT="''\${BASENAME}.pdf"

  ${pkgs.pandoc}/bin/pandoc "$INPUT" -f markdown-implicit_figures \
  --include-in-header=${inlineHeader} -s \
  --to=html5 --embed-resources \
  --css=${cssStyle} -o "$HTML_TEMP" "$@"

  echo "generated: $HTML_TEMP"
''

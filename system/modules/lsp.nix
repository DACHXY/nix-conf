{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ripgrep
    fd
    lua-language-server
    nodejs_22
    nixfmt-rfc-style
    markdownlint-cli2
    shfmt
    nixd
    marksman
    nginx-language-server
    nodePackages_latest.vscode-json-languageserver
  ];
}

{
  pkgs,
  ...
}:
{
  # https://devenv.sh/packages/
  packages = [
    pkgs.git
    pkgs.nixfmt
  ];

  # https://devenv.sh/languages/
  languages.nix = {
    lsp.enable = true;
    lsp.package = pkgs.nixd;
    enable = true;
  };

  # https://devenv.sh/git-hooks/
  git-hooks.hooks = {
    deadnix.enable = true;
    nixfmt.enable = true;
  };
}

{
  lib,
  pkgs,
  ...
}:
{
  home.activation = {
    updateIconCache = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      $DRY_RUN_CMD ${pkgs.gtk3}/bin/gtk-update-icon-cache -t -f ~/.local/share/icons/hicolor
    '';
  };
}

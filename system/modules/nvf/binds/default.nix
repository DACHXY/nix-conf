let
  general = import ./general.nix;
  telescope = import ./telescope.nix;
  neoTree = import ./neo-tree.nix;
in
  general ++ telescope ++ neoTree

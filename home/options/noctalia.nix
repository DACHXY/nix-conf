{ config, lib, ... }:
let
  inherit (lib)
    mkOption
    types
    elem
    isList
    filter
    listToAttrs
    concatMap
    nameValuePair
    attrNames
    isAttrs
    ;

  filterAttrsRecursive' =
    pred: set:
    # Attrs
    if isAttrs set then
      listToAttrs (
        concatMap (
          name:
          let
            v = set.${name};
          in
          if pred name v then
            [
              (nameValuePair name (filterAttrsRecursive' pred v))
            ]
          else
            [ ]
        ) (attrNames set)
      )
    # List
    else if isList set then
      filter (x: pred "" x) (map (x: filterAttrsRecursive' pred x) set)
    else
      set;

  cfg = config.programs.noctalia-shell;
in
{
  options.programs.noctalia-shell = {
    filteredIds = mkOption {
      type = with types; listOf str;
      default = [ ];
    };

    settings = mkOption {
      apply =
        v:
        filterAttrsRecursive' (
          name: value: if value ? id then !(elem value.id cfg.filteredIds) else true
        ) v;
    };
  };
}

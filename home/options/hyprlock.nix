{ config, lib, ... }:
let
  inherit (lib)
    mkOption
    types
    isList
    elemAt
    mapAttrs
    hasAttr
    any
    length
    ;
  cfg = config.programs.hyprlock;
in
{
  options.programs.hyprlock = {
    monitors = mkOption {
      default = [ ];
      type = with types; listOf str;
    };
    excludeMonitor = mkOption {
      default = [
        "general"
        "background"
        "animations"
      ];
      type = with types; listOf str;
    };

    settings = mkOption {
      apply =
        v:
        if length cfg.monitors == 0 then
          v
        else
          mapAttrs (
            name: value:
            let
              mainMonitor = elemAt cfg.monitors 0;
              applyMonitor =
                attrs:
                if hasAttr "monitor" attrs then
                  attrs
                else
                  (
                    attrs
                    // {
                      monitor = mainMonitor;
                    }
                  );
            in
            if any (m: name == m) cfg.excludeMonitor then
              value
            else
              (if (isList value) then (map applyMonitor value) else applyMonitor value)
          ) v;
    };
  };
}

#!/usr/bin/env bash
# Targeted eval of every host — fast check that nothing breaks eval.
# NOTE: `nix flake check` currently fails on a known pre-existing issue
# (stylix option missing in homeManager check module); this script is the
# practical gate until that is fixed.
set -euo pipefail
fail=0
for h in dn-cc dn-cscc dn-gcp dn-server dn-workstation generic generic-desktop; do
  if nix eval --no-warn-dirty .#nixosConfigurations."$h".config.system.build.toplevel.drvPath >/dev/null 2>&1; then
    echo "OK  $h"
  else
    echo "FAIL $h"; fail=1
  fi
done
for h in dn-notebook; do
  if nix eval --no-warn-dirty .#darwinConfigurations."$h".config.system.build.toplevel.drvPath >/dev/null 2>&1; then
    echo "OK  $h"
  else
    echo "FAIL $h"; fail=1
  fi
done
exit $fail

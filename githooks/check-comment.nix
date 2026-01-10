{ pkgs, lib }:
pkgs.writeShellScript "check-comment" ''
  FILES=$("${lib.getExe pkgs.git}" diff --cached --name-only --diff-filter=ACM | grep '\.nix$' | grep -v '^githooks/check-comment.nix$')

  TODO_FOUND=0

  for file in $FILES; do
    if grep -nHE '#\s*(TODO|FIXME|FIX):' "$file"; then
      TODO_FOUND=1
    fi
  done

  if [ $TODO_FOUND -eq 1 ]; then
    echo "Remove all the '#TODO|FIXME|FIX' before committing"
    exit 1
  fi

  exit 0
''

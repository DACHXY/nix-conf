{ pkgs, lib, ... }:

let
  findDirs = [
    "~/practice"
    "~/projects"
    "~/notes"
  ];
  tmuxSessionizer = pkgs.writeShellScriptBin "tmux-sessionizer" ''
    if [[ $# -eq 1 ]]; then
        selected=$1
    else
        selected=$(find ${lib.concatStringsSep " " findDirs} mindepth 1 -maxdepth 1 -type d | fzf)
    fi

    if [[ -z $selected ]]; then
        exit 0
    fi

    selected_name=$(basename "$selected" | tr . _)
    tmux_running=$(pgrep tmux)

    if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
        tmux new-session -s $selected_name -c $selected
        exit 0
    fi

    if ! tmux has-session -t=$selected_name 2> /dev/null; then
        tmux new-session -ds $selected_name -c $selected
    fi

    tmux switch-client -t $selected_name
  '';

  ryank = pkgs.writeShellScriptBin "ryank" ''
    # copy via OSC 52
    buf=$( cat "$@" )
    len=$( printf %s "$buf" | wc -c ) max=74994
    test $len -gt $max && echo "$0: input is $(( len - max )) bytes too long" >&2
    printf "\033]52;c;$( printf %s "$buf" | head -c $max | base64 | tr -d '\r\n' )\a"
  '';
in
{
  home.packages = [
    tmuxSessionizer
    ryank
  ];
}

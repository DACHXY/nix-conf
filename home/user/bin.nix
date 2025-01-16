{ pkgs, lib, ... }:

let
  findDirs = [
    "~/practice"
    "~/projects"
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

  # ffmpeg
  toMov = pkgs.writeShellScriptBin "toMov" ''
    if [ -z "$1" ]; then
      echo "Please provide an input file."
      exit 1
    fi
    input_file="$1"
    output_file="''\${input_file%.*}.mov"
    ffmpeg -i "$input_file" -c:v dnxhd -profile:v dnxhr_hq -c:a pcm_s16le -pix_fmt yuv422p "$output_file"
    echo "Conversion complete: $output_file"
  '';
in
{
  home.packages = [
    tmuxSessionizer
    toMov
  ];
}

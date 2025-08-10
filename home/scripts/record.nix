{
  pkgs,
  ...
}:
let
  record = pkgs.writeShellScript "toggle-wf-record" ''
    PID_FILE="/tmp/wf-recorder.pid"
    OUTPUT_DIR="$HOME/Videos/recordings"
    FILENAME="$OUTPUT_DIR/recording_$(date +%Y%m%d_%H%M%S).mp4"
    SINK_DEV="$(${pkgs.pulseaudio.out}/bin/pactl get-default-sink).monitor"

    declare -A recordOptions=(
        [Monitor]="${pkgs.slurp}/bin/slurp -o"
        [Area]="${pkgs.slurp}/bin/slurp"
    )

    if [[ -f "$PID_FILE" ]]; then
      pid=$(cat "$PID_FILE")

      if kill "$pid" 2>/dev/null; then
        rm "$PID_FILE"
        echo "Stopped recording"
        notify-send "󰑋 RECORD" "Recording saved to $FILENAME"
      else
        echo "No process found, cleaning up"
        notify-send "󰑋 RECORD" "Failed: No process found, cleaning up"
        rm "$PID_FILE"
      fi
    else
      # Start recording
      choice=$(printf "%s\n" "''\${!recordOptions[@]}" | rofi -i -dmenu -config ~/.config/rofi/config.rasi -p "Which mode")

      if [[ -z "$choice" ]]; then
        notify-send "󰑋 RECORD" "Cancelled"
        exit 1
      fi

      mkdir -p "$OUTPUT_DIR"

      geometry="$(''\${recordOptions[$choice]})"

      if [[ -z "$geometry" ]]; then
        notify-send "󰑋 RECORD" "Cancelled"
        exit 1
      fi

      ${pkgs.wf-recorder}/bin/wf-recorder -y \
      -g "$geometry" \
      --audio="$SINK_DEV" \
      -f "$FILENAME" &
      echo $! > "$PID_FILE"
      echo "Started recording: $FILENAME"
    fi
  '';
in
record

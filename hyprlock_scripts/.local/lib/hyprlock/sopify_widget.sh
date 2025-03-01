#!/usr/bin/env bash

icon=""
if [[ -f "$XDG_RUNTIME_DIR/waybar-playerctl.info" ]]; then
  source "$XDG_RUNTIME_DIR/waybar-playerctl.info" 2>/dev/null
fi

base_path="$HOME/.local/lib/hyprlock/covers"
case "$icon" in
"")
  path="$base_path/"$(basename $arturl)
  if [[ ! -e "$path.png" ]]; then
    curl -s "$arturl" -o "$path"
    magick $path "$path".png
    rm "$path"
  fi
  echo "$path.png"
  ;;
"")
  path="$base_path/"$(basename $url)
  if [[ ! -e "$path" ]]; then
    curl -s "$arturl" -o "$path"
    magick $path "$path"
  fi
  echo "$path"
  ;;
"")
  echo "$base_path/Amazon_Prime.png"
  ;;
"")
  echo "$base_path/Moodle-logo.png"
  ;;
*)
  echo "󰗹"
  ;;
esac

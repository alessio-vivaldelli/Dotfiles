#!/usr/bin/env bash

icon=""

sleep 1
case $1 in
previous)
  button=""
  ;;
play)
  button=""
  ;;
next)
  button=""
  ;;
*)
  buttons="DIO"
  ;;
esac

if [[ -f "$XDG_RUNTIME_DIR/waybar-playerctl.info" ]]; then
  source "$XDG_RUNTIME_DIR/waybar-playerctl.info" 2>/dev/null
  case $icon in
  "")
    text='<span foreground=\"#a6e3a1\">'"$button"'</span>'
    ;;
  "")
    text='<span foreground=\"#f38ba8\">'"$button"'</span>'
    ;;
  "")
    text='<span foreground=\"#89dceb\">'"$button"'</span>'
    ;;
  "")
    text='<span foreground=\"#fab387\">'"$button"'</span>'
    ;;
  "")
    text='<span foreground=\"#fab387\">'""'</span>'
    ;;
  *)
    text='<span foreground=\"#D1D5FF\">'"$button"'</span>'
    ;;
  esac
  printf '{"text":"%s","tooltip":"","class":""}\n' \
    "$text"
else
  while [[ ! -f "$XDG_RUNTIME_DIR/waybar-playerctl.info" ]]; do
    sleep 1
    echo "SLEEP" >$HOME/.local/lib/waybar/text.txt
  done
fi

while inotifywait -qq -e close_write,delete,modify,close,create,open "$XDG_RUNTIME_DIR/waybar-playerctl.info"; do
  source "$XDG_RUNTIME_DIR/waybar-playerctl.info" 2>/dev/null
  case $icon in
  "")
    text='<span foreground=\"#a6e3a1\">'"$button"'</span>'
    ;;
  "")
    text='<span foreground=\"#f38ba8\">'"$button"'</span>'
    ;;
  "")
    text='<span foreground=\"#89dceb\">'"$button"'</span>'
    ;;
  "")
    text='<span foreground=\"#fab387\">'"$button"'</span>'
    ;;
  "")
    text='<span foreground=\"#fab387\">'""'</span>'
    ;;
  *)
    text='<span foreground=\"#D1D5FF\">'"$button"'</span>'
    ;;
  esac

  printf '{"text":"%s","tooltip":"","class":""}\n' \
    "$text" || break 2

  sleep 5
done

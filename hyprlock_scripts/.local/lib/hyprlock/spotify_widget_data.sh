#!/usr/bin/env bash

key=$1
# text_t=$(playerctl metadata --format "{{ $key }}" 2>/dev/null)
#

# echo '<span foreground="#a6e3a1">  TESTO  </span>'
if [[ -f "$XDG_RUNTIME_DIR/waybar-playerctl.info" ]]; then
  source "$XDG_RUNTIME_DIR/waybar-playerctl.info" 2>/dev/null

  option=""
  case "$key" in
  title)
    option=$title
    ;;
  album)
    option=$album
    ;;
  icon)
    option=" $icon "
    ;;
  artist)
    option=$artist
    ;;
  *)
    option=""
    ;;
  esac

  case $icon in
  "")
    text="#a6e3a1"
    ;;

  "")
    text=#f38ba8
    ;;

  "")
    text=#89dceb
    ;;

  "")
    text=#fab387
    ;;

  "")
    text=#fab387
    ;;

  *)
    text=#D1D5FF
    ;;
  esac

  option=${option:0:20}
  echo '<span foreground='\"$text\"'>'$option'</span>'

fi
# echo $text

# echo '<span foreground='"#$text"'>'$text_t'</span>'
# echo '<span foreground="##a6e3a1">  TESTO  </span>'

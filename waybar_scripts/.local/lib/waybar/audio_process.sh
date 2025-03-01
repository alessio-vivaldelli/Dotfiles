#!/usr/bin/env bash

cleanup() {
  echo "Cleaning up before exiting..."

  # Termina il processo playerctl in background
  if [[ -f "$XDG_RUNTIME_DIR/waybar-playerctl.pid" ]]; then
    kill "$(<"$XDG_RUNTIME_DIR/waybar-playerctl.pid")" 2>/dev/null
    rm "$XDG_RUNTIME_DIR/waybar-playerctl.pid"
  fi

  # Elimina eventuali file temporanei
  [[ -f "$XDG_RUNTIME_DIR/waybar-playerctl.info" ]] && rm "$XDG_RUNTIME_DIR/waybar-playerctl.info"

  # Esci con successo
  exit 0
}

# Associa il segnale SIGINT (Ctrl+C) alla funzione cleanup
trap cleanup SIGINT

[[ -f "$XDG_RUNTIME_DIR/waybar-playerctl.info" ]] && rm "$XDG_RUNTIME_DIR/waybar-playerctl.info"
exec 2>"$XDG_RUNTIME_DIR/waybar-playerctl.log"
IFS=$'\n\t'

while true; do

  # read from stdin (produced previsuly from playerctl)
  while read -r position length name artist title arturl hpos hlen url album; do
    # remove leaders
    playing=${playing:1} position=${position:1} length=${length:1} name=${name:1} url=${url:1} album=${album:1}
    artist=${artist:1} title=${title:1} arturl=${arturl:1} hpos=${hpos:1} hlen=${hlen:1}

    # build line
    line="${artist:+$artist ${title:+- }}${title:+$title }${hpos:+$hpos${hlen:+|}}$hlen"
    line="${artist:+$artist ${title:+- }}${title:+$title }"
    # json escaping
    line="${line//\"/\\\"}"
    ((percentage = length ? (100 * (position % length)) / length : 0))
    # case $playing in
    # Paused) text='<span foreground=\"#cccc00\" size=\"smaller\">'"$line"'</span>' ;;
    # Playing) text="<small>$line</small>" ;;
    # *) text='<span foreground=\"#073642\">⏹</span>' ;;
    # esac
    if [[ $line == "" ]]; then
      text=""
    fi

    icon="󰗹"
    if [[ "$url" == *"spotify"* ]]; then
      text='<span foreground=\"#a6e3a1\"> '" $line"'</span>'
      icon=""
    elif [[ "$url" == *"youtube"* ]]; then
      icon=""
      text='<span foreground=\"#f38ba8\">  '" $line"'</span>'
    elif [[ "$url" == *"moodle"* ]]; then
      text='<span foreground=\"#fab387\">  '" $line"'</span>'
      icon=""
    elif [[ "$url" == "" ]]; then
      if [[ "$title" == *"Prime Video"* ]]; then
        text='<span foreground=\"#89dceb\">  '" $line"'</span>'
        icon=""
      else
        icon=""
      fi
    fi

    # integrations for other services (nwg-wrapper)
    if [[ $title != "$ptitle" || $artist != "$partist" || $parturl != "$arturl" ]]; then
      # typeset -> print variables content format like:
      # declare -- playing="spotify"
      typeset -p playing length name artist title arturl url icon album >"$XDG_RUNTIME_DIR/waybar-playerctl.info"
      pkill -8 nwg-wrapper
      ptitle=$title partist=$artist parturl=$arturl
    fi

    tooltip="$line"
    # tooltip="<img src='$arturl'/>"

    # exit if print fails
    printf '{"text":"%s","tooltip":"%s","class":"%s","percentage":%s}\n' \
      "$text" "$tooltip" "$percentage" "$percentage" || break 2

  done < <(
    # requires playerctl>=2.0
    # Add non-space character ":" before each parameter to prevent 'read' from skipping over them
    # --player=spotify
    playerctl metadata --follow --format \
      $':{{position}}\t:{{mpris:length}}\t:{{playerName}}\t:{{markup_escape(artist)}}\t:{{markup_escape(title)}}\t:{{mpris:artUrl}}\t:{{duration(position)}}\t:{{duration(mpris:length)}}\t:{{xesam:url}}\t:{{xesam:album}}' &
    echo $! >"$XDG_RUNTIME_DIR/waybar-playerctl.pid"
    # $! contains PID of playerctl ... command witch is running in backgrounf
  )

  # no current players
  # exit if print fails
  echo '<span foreground=#dc322f>⏹</span>' || break
  sleep 15

done

echo "killing process..."
kill "$(<"$XDG_RUNTIME_DIR/waybar-playerctl.pid")"

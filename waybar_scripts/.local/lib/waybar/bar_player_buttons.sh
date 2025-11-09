#!/usr/bin/env bash

# This script displays player control buttons for Waybar, updating dynamically
# based on the currently active media player detected by playerctl.

# Determine which button to display based on the script's argument.
case $1 in
  previous) button="" ;;
  play) button="" ;;
  next) button="" ;;
  *) button="" # Default to no button if argument is invalid
esac

# Exit if no valid button type is provided.
if [[ -z "$button" ]]; then
  exit 1
fi

INFO_FILE="$XDG_RUNTIME_DIR/waybar-playerctl.info"

# Ensure the runtime directory exists to prevent inotifywait from failing.
mkdir -p "$XDG_RUNTIME_DIR"

# Loop indefinitely to keep the widget updated.
while true; do
  icon="" # Reset icon at the start of each iteration.

  # Source the player info file only if it exists.
  if [[ -f "$INFO_FILE" ]]; then
    # The file contains variables like 'icon', 'artist', 'title'.
    source "$INFO_FILE" 2>/dev/null
  fi

  # Determine the button's appearance based on the player's icon.
  # The icon variable is sourced from the INFO_FILE.
  case "$icon" in
    "")  # Spotify
      text="<span size='16pt' rise='-1600' foreground='#a6e3a1'>$button</span>"
      ;;
    "")  # YouTube
      text="<span size='16pt' rise='-1600' foreground='#f38ba8'>$button</span>"
      ;;
    "")  # Prime Video
      text="<span size='16pt' rise='-1600' foreground='#89dceb'>$button</span>"
      ;;
    "")  # Moodle
      text="<span size='16pt' rise='-1600' foreground='#fab387'>$button</span>"
      ;;
    "")   # No player active or file is missing.
      text=""
      ;;
    *)
      text="<span size='16pt' rise='-1600' foreground='#D1D5FF'>$button</span>"
      ;;
  esac

  # Print the JSON output for Waybar. If printf fails, exit the loop.
  printf '{"text":"%s","tooltip":"","class":""}\n' "$text" || break

  # Wait for the next change. This is the critical part for dynamic updates.
  # We need a robust way to wait for changes on a file that might be deleted and recreated.

  # Watch the directory for 'create' and 'delete' events.
  # Watch the file itself for 'modify' events if it exists.
  if ! [[ -f "$INFO_FILE" ]]; then
    # If the file doesn't exist, wait for it to be created.
    # We watch the directory for a 'create' event.
    inotifywait -qq -e create "$XDG_RUNTIME_DIR" | while read -r dir ev file; do
        if [[ "$file" = "waybar-playerctl.info" ]]; then break; fi
    done
  else
    # If the file exists, watch it for modifications or deletion.
    inotifywait -qq -e modify,delete_self "$INFO_FILE"
  fi
done
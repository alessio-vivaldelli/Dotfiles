# Section 2
shutdown="󰐥"
reboot="󰜉"
lock="󰍁"
suspend="󰒲"
logout="󰍃"

options="$lock\n$suspend\n$logout\n$reboot\n$shutdown"
echo -e "$options"
echo -e "$options" | wofi --conf ~/.config/wofi/powermenu --style ~/.config/wofi/powermenu.css --show dmenu

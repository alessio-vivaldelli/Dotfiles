battery=$(sh /home/alessio/.local/lib/hyprlock/battery.sh)
wifi=$(sh /home/alessio/.local/lib/hyprlock/wifi.sh)

res="  $wifi  $battery  "
text="#cdd6f4"
# Stampa il risultato
echo '<span foreground='\"$text\"'>'$res'</span>'

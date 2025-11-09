battery=$(sh /home/alessio/.local/lib/hyprlock/battery.sh)
wifi=$(sh /home/alessio/.local/lib/hyprlock/wifi.sh)

res="  $wifi  $battery  "
text="#cdd6f4"
# Stampa il risultato
echo '<span size='\"16pt\"' rise='\"-1600\"' foreground='\"$text\"'>'$res'</span>'
# echo '<span size=\"16pt\" rise=\"-1600\" foreground=\"#a6e3a1\">'$res'</span>'

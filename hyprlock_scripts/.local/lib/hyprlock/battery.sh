#!/bin/bash
battery_info=$(upower -i /org/freedesktop/UPower/devices/battery_BAT1)
battery=$(echo "$battery_info" | grep -E "percentage" | awk '{print $2}' | tr -d '%')

# Controlla se la batteria è in carica
status=$(echo "$battery_info" | grep -E "state" | awk '{print $2}')

# Seleziona l'icona in base alla percentuale
if [ "$battery" -le 20 ]; then
  icon="  " # Batteria scarica
elif [ "$battery" -le 40 ]; then
  icon="  " # Bassa carica
elif [ "$battery" -le 60 ]; then
  icon="  " # Carica media
elif [ "$battery" -le 80 ]; then
  icon="  " # Buona carica
else
  icon="  " # Carica alta
fi

charging=""
if [[ "$status" == "charging" || "$status" == "fully-charged" ]]; then
  charging="  "
fi

# Stampa il risultato
echo $charging$icon

#!/bin/bash

# Controlla se NetworkManager è in esecuzione
if ! command -v nmcli &>/dev/null; then
  echo "❌ nmcli non trovato! Assicurati che NetworkManager sia installato e attivo."
  exit 1
fi
#
# # Ottieni il nome della rete Wi-Fi a cui sei connesso
# ssid=$(nmcli -t -f active,ssid dev wifi | grep ^yes | cut -d ':' -f2)
#
# # Controlla se sei connesso
# if [[ -z "$ssid" ]]; then
#   echo " 󰤮 "
#   exit 0
# fi
#
# Ottieni il livello di segnale (in dBm)
signal=$(nmcli -t -f IN-USE,SIGNAL dev wifi | grep '*' | cut -d ':' -f2)

# Determina l'icona in base al livello del segnale
if [ "$signal" -le 25 ]; then
  icon=" 󰤯 " # Segnale molto basso 🔴
elif [ "$signal" -le 50 ]; then
  icon=" 󰤟 " # Segnale basso 🟠
elif [ "$signal" -le 75 ]; then
  icon=" 󰤢 " # Segnale medio 🟡
else
  icon=" 󰤨 " # Segnale forte 🟢
fi

# Stampa il risultato
echo "$icon"

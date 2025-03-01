#!/bin/bash

# Controlla se wofi è già in esecuzione
if pgrep -x "wofi" >/dev/null; then
  # Chiude tutte le istanze di wofi
  pkill -x "wofi"
else
  # Avvia wofi
  wofi --show drun
fi

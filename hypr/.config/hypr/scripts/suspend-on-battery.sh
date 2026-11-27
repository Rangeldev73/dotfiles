#!/usr/bin/env bash
# Called by hypridle after 20 idle minutes: suspend only when the charger is
# unplugged. ACAD is the LOQ AC adapter (/sys/class/power_supply/ACAD).
set -euo pipefail

ac="/sys/class/power_supply/ACAD/online"
if [[ -r "$ac" && "$(cat "$ac")" == "0" ]]; then
    systemctl suspend
fi

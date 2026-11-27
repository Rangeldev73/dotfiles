#!/usr/bin/env bash
# Big block clock for the showcase (tty-clock style, no extra package).
# Digits are 3x5 bitmaps; each lit cell is "██" (2 columns x 1 row, about
# square because terminal cells are twice as tall as wide). Ice cyan (#7dcfff) digits, English date in muted grey
# (#7d8590), centred, redrawn every second.
set -u
tput civis
trap 'tput cnorm' EXIT

cyan=$'\e[38;2;125;207;255m'
muted=$'\e[38;2;125;133;144m'
reset=$'\e[0m'

declare -A glyph=(
    [0]="111 101 101 101 111"  [1]="001 001 001 001 001"
    [2]="111 001 111 100 111"  [3]="111 001 111 001 111"
    [4]="101 101 111 001 001"  [5]="111 100 111 001 111"
    [6]="111 100 111 101 111"  [7]="111 001 001 001 001"
    [8]="111 101 111 101 111"  [9]="111 101 111 001 111"
    [:]="0 1 0 1 0"
)
on='██'
off='  '

while true; do
    cols=$(tput cols)
    lines=$(tput lines)
    time=$(date +%H:%M)
    day=$(LC_TIME=C date +"%A, %d %B")

    # Build the 5 bitmap rows of the whole time string.
    rows=("" "" "" "" "")
    for (( c = 0; c < ${#time}; c++ )); do
        read -ra g <<< "${glyph[${time:c:1}]}"
        for r in 0 1 2 3 4; do
            bits=${g[r]}
            for (( b = 0; b < ${#bits}; b++ )); do
                [[ ${bits:b:1} == 1 ]] && rows[r]+=$on || rows[r]+=$off
            done
            rows[r]+=' '
        done
    done

    width=$(( ${#rows[0]} - 1 ))
    height=$(( 5 + 2 ))
    top=$(( (lines - height) / 2 )); (( top < 0 )) && top=0
    left=$(( (cols - width) / 2 )); (( left < 0 )) && left=0
    pad=$(printf '%*s' "$left" '')

    frame=$'\e[H\e[2J'
    for (( i = 0; i < top; i++ )); do frame+=$'\n'; done
    for r in 0 1 2 3 4; do
        frame+="${pad}${cyan}${rows[r]}${reset}"$'\n'
    done
    frame+=$'\n'"$(printf '%*s' $(( (cols - ${#day}) / 2 )) '')${muted}${day}${reset}"
    printf '%s' "$frame"
    sleep 1
done

#!/bin/bash

cpu=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}')
ram=$(free | awk '/Mem:/ {print $3*100/$2}')

printf '{"cpu": %.1f, "ram": %.1f}\n' "$cpu" "$ram"

#!/bin/sh
# Fenestra Search — https://github.com/naykkalak/fenestra-search
# SPDX-FileCopyrightText: 2026 naykkalak
# SPDX-License-Identifier: GPL-3.0-or-later
# "Menu size" setting of Fenestra Menu 11 (0 = automatic, 1 = small, 2 = large)
# Prints Taille=N (Taille=0 when Fenestra Menu 11 is not found)
f="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
t=0
if [ -f "$f" ]; then
    r=$(awk '
        FNR == NR {
            if ($0 ~ /^\[/) sec = $0
            if ($0 ~ /^plugin=org\.fenestra\.menu11[ \t]*$/) pre[sec] = 1
            next
        }
        /^\[/ {
            sec = $0; ok = 0
            if (sec ~ /\[Configuration\]\[General\]$/) {
                p = substr(sec, 1, length(sec) - length("[Configuration][General]"))
                if (p in pre) ok = 1
            }
            next
        }
        ok && /^menuSize=[0-9]+/ { sub(/^menuSize=/, ""); print $0 + 0; exit }
    ' "$f" "$f")
    [ -n "$r" ] && t=$r
fi
echo "Taille=$t"

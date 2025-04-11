#!/bin/bash
# ver 1.0
. $HOME/.local/share/kio/servicemenus/s2fLocalization.sh

function add_prefix_name() {
    NUM=0
    TEMP="$1"
    while [ -d "$TEMP" ]
        do
            NUM="$(($NUM+1))"
            TEMP="$1"\ "($NUM)"
        done
    printf "$TEMP"
}
function ask_name() {
    kdialog --title "$(window_title)" --inputbox "$(window_message)" "$1" --geometry 450x300
}
NAME="$(def_name)"
NAME="$(add_prefix_name "$NAME")"
NAME="$(ask_name "$NAME")"
while [ -d "$NAME" ]
    do
        NAME="$(add_prefix_name "$NAME")"
        NAME="$(ask_name "$NAME")"
    done
mkdir -p "$NAME" && cd "$NAME" && mv "$@"

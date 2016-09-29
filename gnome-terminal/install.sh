#!/bin/bash
set -e

dconfdir="/org/gnome/terminal/legacy/profiles:"
profile_id="$(dconf list /org/gnome/terminal/legacy/profiles:/ | sed -e 's/\///g' -n -e '1p')"
profile_path="$dconfdir/$profile_id"

# Font.
dconf write "$profile_path/use-system-font" "false"
dconf write "$profile_path/font" "'Source Code Pro for Powerline 10'"

# Custom startup command.
#dconf write "$profile_path/use-custom-command" "true"
#dconf write "$profile_path/custom-command" "'env COLORTERM=gnome-terminal fish'"


## Modified Jellybeans colors for gnome-terminal (with dconf).

palette="['rgb(0,0,0)', 'rgb(205,0,0)', 'rgb(0,205,0)', 'rgb(205,205,0)', 'rgb(30,144,255)', 'rgb(205,0,205)', 'rgb(0,205,205)', 'rgb(229,229,229)', 'rgb(76,76,76)', 'rgb(255,0,0)', 'rgb(0,255,0)', 'rgb(255,255,0)', 'rgb(70,130,180)', 'rgb(255,0,255)', 'rgb(0,255,255)', 'rgb(255,255,255)']"
foreground_color="'#e8e8d3'"
background_color="'#151515'"
bold_color="'#adadad'"

# Color palette.
dconf write "$profile_path/palette" "$palette"

# Foreground, background and highlight color.
dconf write "$profile_path/foreground-color" "$foreground_color"
dconf write "$profile_path/background-color" "$background_color"
dconf write "$profile_path/bold-color" "$bold_color"

# Profile does not use theme colors.
dconf write "$profile_path/use-theme-colors" "false"

# Highlighted color different from foreground color.
dconf write "$profile_path/bold-color-same-as-fg" "false"

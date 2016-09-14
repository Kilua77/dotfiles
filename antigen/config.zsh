# Treat Pre-conditions
if [[ -z $1 ]]; then
    # Enable (or not) THEME_POWERLINE themes
    export THEME_POWERLINE=${THEME_POWERLINE:-true}
    export POWERLINE_RIGHT_A="exit-status"
    export POWERLINE_PATH="short"

# Treat Post-conditions
elif [[ $1 == "POST" ]]
then
    # zsh-autosuggestions config
    export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=9'
fi

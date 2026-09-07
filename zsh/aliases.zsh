# zsh/aliases.zsh — general aliases.
# Git aliases do NOT live here: they are the curated oh-my-zsh subset in
# zsh/git-aliases.zsh.

# Reload the shell configuration after an edit.
alias reload!='. ~/.zshrc'
alias cls='clear'

# Prefer the Neovim binary over vi(m) when it is installed.
command -v nvim >/dev/null 2>&1 && alias vim='nvim'

# eza replaces ls when available (dirs grouped first), with ll/la/lt variants.
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first'
    alias ll='eza -lah --group-directories-first'
    alias la='eza -a --group-directories-first'
    alias lt='eza --tree --group-directories-first'
else
    # No eza: keep at least a usable long listing.
    alias ll='ls -lah'
fi

# cat -> bat (packaged as batcat on Debian/Ubuntu).
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
elif command -v batcat >/dev/null 2>&1; then
    alias cat='batcat --paging=never'
fi

# fd is packaged as fdfind on Debian/Ubuntu; alias only when fd is missing.
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    alias fd='fdfind'
fi

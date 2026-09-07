# zsh/fpath.zsh — extra community completions.
# zsh-completions is fpath-only: there is no script to source, the plugin
# is a pile of _* completion functions. Its src/ directory joins fpath
# here, and compinit (run by the loader after all topic files) picks the
# files up. Guarded so a fresh machine without the clone stays quiet.
if [ -d "$HOME/.local/share/zsh/plugins/zsh-completions/src" ]; then
    fpath=("$HOME/.local/share/zsh/plugins/zsh-completions/src" $fpath)
fi

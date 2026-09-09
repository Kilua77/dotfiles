# vscode/env.zsh — keep the VS Code remote environment usable inside tmux.
#
# The remote `code` CLI and VS Code's git askpass talk to the window's server
# through per-window sockets ($VSCODE_IPC_HOOK_CLI, $VSCODE_GIT_IPC_HANDLE);
# each reconnect mints new ones and deletes the old. tmux freezes a pane's
# environment at spawn time and only refreshes VSCODE_* for NEW panes
# (tmux.conf extends update-environment), so a shell older than the last
# reconnect holds dead sockets and `code` fails with ENOENT. At startup,
# re-read any vanished variable from the session environment — the attach
# that follows every reconnect has already published the live value there.
# Topic order matters: this loads before zsh/env.zsh, which tests the socket
# to choose $EDITOR.

if [[ -n "$TMUX" ]]; then
  for _vsc_var in VSCODE_IPC_HOOK_CLI VSCODE_GIT_IPC_HANDLE; do
    _vsc_val="${(P)_vsc_var}"
    if [[ -n "$_vsc_val" && ! -S "$_vsc_val" ]]; then
      _vsc_fresh="$(tmux show-environment "$_vsc_var" 2>/dev/null)"
      case "$_vsc_fresh" in
        "$_vsc_var="?*) export "$_vsc_fresh" ;; # live value republished by attach
        *) unset "$_vsc_var" ;;                 # no VS Code behind this tmux
      esac
    fi
  done
  unset _vsc_var _vsc_val _vsc_fresh
fi

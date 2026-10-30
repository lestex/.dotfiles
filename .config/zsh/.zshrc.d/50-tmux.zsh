# tmux shortcuts, from omarchy's default/bash (aliases and fns/tmux), in zsh.

# Attach to the last session, or start one called Work. Ghostty and Alacritty
# already open in tmux; this is for kitty and SSH.
alias t='tmux attach || tmux new -s Work'

# Dev layout in the current window: editor on the left, an AI tool on the
# right 30% (two stacked if a second is given), a shell along the bottom 15%.
# Usage: tdl <ai> [<second_ai>]
tdl() {
  [[ -z $1 ]] && { echo "Usage: tdl <ai> [<second_ai>]"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdl."; return 1; }

  local current_dir="$PWD" ai="$1" ai2="$2"
  local editor_pane="$TMUX_PANE" ai_pane ai2_pane

  tmux rename-window -t "$editor_pane" "${current_dir:t}"
  tmux split-window -v -l 15% -t "$editor_pane" -c "$current_dir"
  ai_pane=$(tmux split-window -h -l 30% -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')

  if [[ -n $ai2 ]]; then
    ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$current_dir" -P -F '#{pane_id}')
    tmux send-keys -t "$ai2_pane" -l "$ai2"
    tmux send-keys -t "$ai2_pane" C-m
  fi

  tmux send-keys -t "$ai_pane" -l "$ai"
  tmux send-keys -t "$ai_pane" C-m
  tmux send-keys -t "$editor_pane" -l "${EDITOR:-nvim} ."
  tmux send-keys -t "$editor_pane" C-m

  # omarchy selects an unset $opencode_pane here; focus the editor instead.
  tmux select-pane -t "$editor_pane"
}

# A tdl window for each subfolder of the current folder; the session is
# renamed after the current folder.
# Usage: tdlm <ai> [<second_ai>]
tdlm() {
  [[ -z $1 ]] && { echo "Usage: tdlm <ai> [<second_ai>]"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdlm."; return 1; }

  local cmd="tdl ${(q)1}" base_dir="$PWD" dir pane_id first=true
  [[ -n $2 ]] && cmd+=" ${(q)2}"

  # tmux does not allow dots or colons in session names.
  tmux rename-session "$(print -r -- "${base_dir:t}" | tr '.:' '--')"

  for dir in "$base_dir"/*(N/); do
    if $first; then
      # Reuse the current window for the first folder.
      tmux send-keys -t "$TMUX_PANE" -l "cd ${(q)dir} && $cmd"
      tmux send-keys -t "$TMUX_PANE" C-m
      first=false
    else
      pane_id=$(tmux new-window -c "$dir" -P -F '#{pane_id}')
      tmux send-keys -t "$pane_id" -l "$cmd"
      tmux send-keys -t "$pane_id" C-m
    fi
  done
}

# Tile the current window into <pane_count> panes, each running <command>.
# Usage: tsl <pane_count> <command>
tsl() {
  [[ -z $1 || -z $2 || $1 != <1-> ]] && { echo "Usage: tsl <pane_count> <command>"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tsl."; return 1; }

  local count="$1" cmd="$2" current_dir="$PWD" pane new_pane
  local -a panes=("$TMUX_PANE")

  tmux rename-window -t "$TMUX_PANE" "${current_dir:t}"

  while (( ${#panes} < count )); do
    new_pane=$(tmux split-window -h -t "${panes[-1]}" -c "$current_dir" -P -F '#{pane_id}')
    panes+=("$new_pane")
    tmux select-layout -t "${panes[1]}" tiled
  done

  for pane in "${panes[@]}"; do
    tmux send-keys -t "$pane" -l "$cmd"
    tmux send-keys -t "$pane" C-m
  done

  tmux select-pane -t "${panes[1]}"
}

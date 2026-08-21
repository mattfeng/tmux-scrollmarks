#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$CURRENT_DIR/scripts/scrollmarks.sh"

get_tmux_option() {
    local option="$1"
    local default_value="$2"
    local value

    value="$(tmux show-option -gqv "$option" 2>/dev/null || true)"
    if [[ -n "$value" ]]; then
        printf '%s' "$value"
    else
        printf '%s' "$default_value"
    fi
}

add_key="$(get_tmux_option '@scrollmarks-add-key' 'm')"
prev_key="$(get_tmux_option '@scrollmarks-prev-key' 'M-p')"
next_key="$(get_tmux_option '@scrollmarks-next-key' 'M-n')"
clear_key="$(get_tmux_option '@scrollmarks-clear-key' 'M-c')"

for table in copy-mode copy-mode-vi; do
    tmux bind-key -T "$table" "$add_key" \
        run-shell -b "\"$SCRIPT\" add \"#{pane_id}\""

    tmux bind-key -T "$table" "$prev_key" \
        run-shell -b "\"$SCRIPT\" prev \"#{pane_id}\""

    tmux bind-key -T "$table" "$next_key" \
        run-shell -b "\"$SCRIPT\" next \"#{pane_id}\""

    tmux bind-key -T "$table" "$clear_key" \
        run-shell -b "\"$SCRIPT\" clear \"#{pane_id}\""
done

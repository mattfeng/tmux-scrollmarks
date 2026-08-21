#!/usr/bin/env bash

set -euo pipefail

ACTION="${1:-}"
PANE="${2:-}"
STATE_OPTION='@scrollmarks'

if [[ -z "$ACTION" || -z "$PANE" ]]; then
    printf 'usage: %s {add|prev|next|clear} PANE_ID\n' "$0" >&2
    exit 2
fi

message() {
    tmux display-message -t "$PANE" "scrollmarks: $*"
}

require_copy_mode() {
    local in_mode
    in_mode="$(tmux display-message -p -t "$PANE" -F '#{pane_in_mode}')"
    if [[ "$in_mode" != '1' ]]; then
        message 'not in copy mode'
        exit 0
    fi
}

# Return the copy-mode cursor's physical grid row, counted from the oldest
# retained history row. Existing rows keep the same number as new output is
# appended, until tmux evicts old history or reflows lines after a resize.
current_position() {
    local history_size scroll_position cursor_y
    IFS='|' read -r history_size scroll_position cursor_y < <(
        tmux display-message -p -t "$PANE" \
            -F '#{history_size}|#{scroll_position}|#{copy_cursor_y}'
    )

    if [[ ! "$history_size" =~ ^[0-9]+$ ||
          ! "$scroll_position" =~ ^[0-9]+$ ||
          ! "$cursor_y" =~ ^[0-9]+$ ]]; then
        message 'cannot read copy-mode position'
        exit 1
    fi

    printf '%d\n' "$((history_size - scroll_position + cursor_y))"
}

load_marks() {
    local raw
    raw="$(tmux show-option -pqv -t "$PANE" "$STATE_OPTION" 2>/dev/null || true)"
    MARKS=()

    if [[ -n "$raw" ]]; then
        IFS=',' read -r -a MARKS <<< "$raw"
    fi
}

save_marks() {
    if ((${#MARKS[@]} == 0)); then
        tmux set-option -pu -t "$PANE" "$STATE_OPTION" 2>/dev/null || true
        return
    fi

    local joined
    joined="$(IFS=,; printf '%s' "${MARKS[*]}")"
    tmux set-option -p -t "$PANE" "$STATE_OPTION" "$joined"
}

sort_unique_marks() {
    if ((${#MARKS[@]} == 0)); then
        return
    fi

    mapfile -t MARKS < <(printf '%s\n' "${MARKS[@]}" | sort -n -u)
}

mark_index() {
    local target="$1"
    local i
    for i in "${!MARKS[@]}"; do
        if [[ "${MARKS[$i]}" == "$target" ]]; then
            printf '%d\n' "$((i + 1))"
            return 0
        fi
    done
    return 1
}

add_mark() {
    require_copy_mode
    local current
    current="$(current_position)"

    load_marks
    MARKS+=("$current")
    sort_unique_marks
    save_marks

    local index
    index="$(mark_index "$current")"
    message "mark $index/${#MARKS[@]}"
}

find_prev() {
    local current="$1"
    local candidate=''
    local mark

    for mark in "${MARKS[@]}"; do
        if ((mark < current)); then
            candidate="$mark"
        else
            break
        fi
    done

    printf '%s' "$candidate"
}

find_next() {
    local current="$1"
    local mark

    for mark in "${MARKS[@]}"; do
        if ((mark > current)); then
            printf '%s' "$mark"
            return 0
        fi
    done

    printf ''
}

jump_to() {
    local current="$1"
    local target="$2"
    local delta

    delta="$((target - current))"

    if ((delta < 0)); then
        tmux send-keys -t "$PANE" -X -N "$((-delta))" cursor-up
    elif ((delta > 0)); then
        tmux send-keys -t "$PANE" -X -N "$delta" cursor-down
    fi
}

jump_mark() {
    local direction="$1"
    require_copy_mode

    local current target index
    current="$(current_position)"

    load_marks
    sort_unique_marks

    if ((${#MARKS[@]} == 0)); then
        message 'no marks'
        return
    fi

    case "$direction" in
        prev)
            target="$(find_prev "$current")"
            if [[ -z "$target" ]]; then
                message 'no earlier mark'
                return
            fi
            ;;
        next)
            target="$(find_next "$current")"
            if [[ -z "$target" ]]; then
                message 'no later mark'
                return
            fi
            ;;
        *)
            printf 'unknown jump direction: %s\n' "$direction" >&2
            exit 2
            ;;
    esac

    jump_to "$current" "$target"
    index="$(mark_index "$target")"
    message "mark $index/${#MARKS[@]}"
}

clear_marks() {
    tmux set-option -pu -t "$PANE" "$STATE_OPTION" 2>/dev/null || true
    message 'cleared'
}

case "$ACTION" in
    add)   add_mark ;;
    prev)  jump_mark prev ;;
    next)  jump_mark next ;;
    clear) clear_marks ;;
    *)
        printf 'unknown action: %s\n' "$ACTION" >&2
        exit 2
        ;;
esac

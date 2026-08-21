# tmux-scrollmarks

Multiple ordered bookmarks for tmux copy-mode scrollback.

Instead of naming marks, press one key to add the current copy-mode location to a pane-local list. Navigation always uses the cursor's current location:

- `M-p` jumps to the closest earlier mark.
- Repeating `M-p` walks toward older marks.
- `M-n` jumps to the closest later mark.
- Repeating `M-n` walks toward newer marks.
- Manually scroll anywhere, then use `M-p` or `M-n`; navigation resumes from that location.

Marks are stored per pane as a tmux pane option, so different panes have independent lists.

## Installation with TPM

Add this to `~/.tmux.conf`:

```tmux
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'YOUR_GITHUB_USERNAME/tmux-scrollmarks'

run '~/.tmux/plugins/tpm/tpm'
```

Reload tmux and press `prefix + I` to install the plugin.

## Default bindings

Bindings are active in both `copy-mode` and `copy-mode-vi`.

| Key | Action |
| --- | --- |
| `m` | Add the current location to the mark list |
| `M-p` | Jump to the closest earlier mark |
| `M-n` | Jump to the closest later mark |
| `M-c` | Clear all marks in the current pane |

Enter copy mode first, normally with `prefix + [`.

## Configuration

Set any of these before the TPM initialization line:

```tmux
set -g @scrollmarks-add-key   'm'
set -g @scrollmarks-prev-key  'M-p'
set -g @scrollmarks-next-key  'M-n'
set -g @scrollmarks-clear-key 'M-c'
```

Then reload `~/.tmux.conf`.

## Example

If marks exist at scrollback rows 100, 450, 700, and 1200, and the cursor is at row 800:

```text
M-p: 800 -> 700 -> 450 -> 100
```

Starting at row 450:

```text
M-n: 450 -> 700 -> 1200
```

If you manually move to row 600, `M-p` goes to 450 and `M-n` goes to 700.

## How it works

The plugin records a physical tmux grid row derived from `history_size`, `scroll_position`, and `copy_cursor_y`. Jumping is relative: it sends repeated `cursor-up` or `cursor-down` copy-mode commands until the target row is reached.

This keeps existing marks stable while new output is appended. Marks can become stale if tmux evicts old history after reaching `history-limit`, or if resizing the pane causes wrapped lines to reflow.

## Requirements

- tmux with the `history_size`, `scroll_position`, and `copy_cursor_y` format variables
- Bash
- TPM for plugin installation (manual sourcing also works)

## Manual installation

Clone the repository, then add:

```tmux
run-shell '/path/to/tmux-scrollmarks/scrollmarks.tmux'
```

## License

MIT

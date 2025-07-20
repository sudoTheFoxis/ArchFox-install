#!/bin/bash

### =============================================
### ===== (TX) Tmux =============================
### =============================================
# tools to easily manage and interact with tmux

#   check if running in tmux, if not, re run in tmux
AFI_TX_CHECK () {
    if [ -z "$TMUX" ]; then
        if tmux has-session -t "AFI" 2>/dev/null; then
            AFI_WARN "tmux instance: AFI already exists..."
            AFI_C "do you want to reattach? " && tmux attach -d -t AFI
        else
            AFI_INFO "Re running in tmux (AFI) with: $0 ${AFI_V_ARGS[*]}"
            tmux new-session -s "AFI" -n "archox-install" "$0" "${AFI_V_ARGS[*]}" >/dev/null
        fi
        exit 0
    #else
    #    tmux set-option -t "AFI" status-bg "colour${AFI_CC_PRIMARY}"
    #    tmux set-option -t "AFI" status-fg "colour${AFI_CC_SECONDARY}"
    fi
}

#   simple tmux prompt/popup
AFI_TX_POPUP () {
    tmux popup -w 50% -h 25% -E bash -c "read -r -p \"$*\" input;tmux set-environment AFI_TEMP_POPUP \"\$input\""
    local output="$(tmux show-environment AFI_TEMP_POPUP | cut -d= -f2-)"
    echo "$output"
}

#   create window with two pannels, if one panel closes entire window will be closed
AFI_TX_DUALPANNEL () {
    local window_name="selector"

    tmux new-window -n "$window_name" -t "$AFI_V_TS_NAME" bash -c "${1:-bash}"
    tmux split-window -h -t "${AFI_V_TS_NAME}:${window_name}" bash -c "${2:-bash}"

    tmux set-hook -t "${AFI_V_TS_NAME}:${window_name}" pane-exited "run-shell 'tmux kill-window -t "${AFI_V_TS_NAME}:${window_name}"'"

    tmux select-window -t "${AFI_V_TS_NAME}:${window_name}"
    tmux select-pane -t "${AFI_V_TS_NAME}:${window_name}.0"
}

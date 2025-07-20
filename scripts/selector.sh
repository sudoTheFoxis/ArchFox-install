#!/bin/bash
# fzf/skim replacement created witch pure bash

# ===== Some terminal voodoo
oldstty=$(stty -g) # save terminal settings
tput smcup  # Switch to alternate buffor
tput civis
stty -echo -icanon time 0 min 1
tput cup 0 0 # reset cursor position
cleanup () {
    stty "$oldstty" # restore terminal settings
    tput rmcup  # Switch back to original buffor
    tput cnorm
    trap - INT TERM HUP
}
trap 'cleanup && exit 1' INT TERM HUP # bind cleanup in case of manual exit

# ===== Parse Flags
multiselection=0
outputfile=""
previewfile=""
help="[Esc] exit | [Enter/Space] select | [Up/Down/PgUp/PgDn] move | [Tab] force rerender"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--multi)
            multiselection=1
            shift
            ;;
        -o|--output)
            outputfile="$2"
            shift 2
            ;;
        -p|--preview)
            previewfile="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "unknown flag: $1"
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# ===== Variables
listAll=("$@")
list=()
listLength=0

declare -A selected=()
search_old=""
search=""
cursor_old=0
cursor=0
offset_old=0
offset=0

forcerender=1
height=$(tput lines)
width=$(tput cols)
HeaderHeight=2
FooterHeight=1
FooterText=$help
ContentHeight=$(($height - $HeaderHeight - $FooterHeight))

# ===== Render
render () { # main render function
    if (($forcerender)); then
        clear
        listUpdate
        renderHeader
        renderFooter
        renderContent
        moveCursor
        renderStatus
        forcerender=0
    else
        if [ "$offset" != "$offset_old" ]; then # update content if offset changed
            renderContent
            offset_old=$offset
        fi
        moveCursor
        renderStatus
    fi
}
renderHeader () { # render top section
    tput cup 0 0
    printf 'Search: %s\n' "$search"
    printf '───────────────'
}
renderStatus() { # render status (top right line counter)
    local status=${1:-"($(($cursor+$offset+1))/$listLength)"}
    #local status="CH: $ContentHeight | l: $listLength | o: $offset:$offset_old | c: $cursor:$cursor_old | i: $(($HeaderHeight + $cursor + $offset - 1)):$(($HeaderHeight + $cursor_old + $offset_old - 1))"
    tput cup 0 $((8 + ${#search}))
    printf '%*s' "$(($width - 9 - ${#search}))" "$status"
}
renderLine () {
    tput cup $(($HeaderHeight + $1)) 1
    local entry="${list[$(($1+$offset))]}"
    if [ -v selected["$entry"] ]; then
        printf 'x %s\e[K' "$entry"
    else
        printf '  %s\e[K' "$entry"
    fi
}
renderContent () { # render list/middle section
    for ((index=0; index<ContentHeight; index++)); do
        renderLine $index
    done
}
renderFooter () { # render bottom section
    tput cup $(($height - $FooterHeight)) 0
    printf '%s\e[K' "$FooterText"
}

# ===== other functions
listUpdate () { # update list
    if [ -n "$search" ]; then
        list=()
        for entry in "${listAll[@]}"; do
            if [[ "$entry" == *"$search"* ]]; then
                list+=("$entry")
            fi
        done
    else
        list=("${listAll[@]}")
    fi
    listLength="${#list[@]}"
    search_old=$search
    cursor=0
    offset=0
    renderContent
    renderHeader
}
moveCursor () { # render cursor
    # limit cursor to list
    if (( $offset+$cursor < 0 )); then
        cursor=$((-$offset)) # set cursor to negative offset
    elif (( $offset+$cursor+1 > $listLength )); then
        cursor=$(($listLength-1)) # set cursor to end of list
    fi
    # move viewport to cursor
    if ((cursor < 0)); then # check if cursor is outside top edge
        ((offset+=$cursor))
        cursor=0
    elif ((cursor > $ContentHeight-1)); then # check if cursor if outside bottom edge
        ((offset+=$cursor-$ContentHeight+1))
        cursor=$(($ContentHeight-1))
    fi
    # fix when list is empty
    ((listLength < 1)) && cursor=0 && offset=0
    # check if cursor re render is nesesary
    if (($cursor != $cursor_old)) || (($forcerender)); then
        tput cup "$(($HeaderHeight + $cursor_old ))" 0
        printf ' '
        tput cup "$(($HeaderHeight + $cursor ))" 0
        printf '>' #\e[K
        cursor_old=$cursor
    fi
    # update preview
    [ -n "$previewfile" ] && printf '%s' "${list[$(($offset+$cursor))]}" > "$previewfile"
}
voidInput () {
    while read -rs -t 0.0001 junk; do :; done
}
inputHandler () { # handle heys
    case "$1" in
        # Arrows
        $'\e[A') ((cursor--)); moveCursor; voidInput ;;
        $'\e[B') ((cursor++)); moveCursor; voidInput ;;
        #$'\e[C') echo "→" ;;
        #$'\e[D') echo "←" ;;
        # Page Up / Page Down
        $'\e[5~') ((cursor-=$ContentHeight-1)); moveCursor; voidInput ;;
        $'\e[6~') ((cursor+=$ContentHeight-1)); moveCursor; voidInput ;;
        # Enter | Space
        ''|' ')
            ((listLength < 1)) && return 0;
            local entry="${list[$(($offset+$cursor))]}"
            if [ -v selected["$entry"] ]; then
                unset "selected["$entry"]"
            else
                selected["$entry"]=1
            fi
            [ -n "$outputfile" ] && printf '%s\n' "${!selected[@]}" > "$outputfile" # update selected
            ((multiselection)) && renderLine "$cursor" || working=0
            ;;
        # Backspace
        $'\x7f'|$'\177') search="${search%?}"; listUpdate ;;
        # Tab
        $'\t') forcerender=1 ;;
        # numbers and letters
        [a-zA-Z0-9]) search+="$1"; listUpdate ;;
        # Esc
        $'\e') working=0 ;;
        # other
        *) return 1 ;;
    esac
    return 0;
}

# ===== Main Loop
render # initial render
working=1;
while (($working)); do
    IFS= read -rsn1 key || continue
    [[ $key == $'\e' ]] && read -rsn2 -t 0.02 rest && key+="$rest"
    while ! inputHandler "$key"; do
        read -rsn1 -t 0.01 rest
        if [ ! -n "$rest" ] || [ ${#key} -ge 10 ]; then
            #printf 'unknown seqence: %q + %q\n' "$key"
            voidInput
            break
        fi
        key+=$rest
    done
    render
done

# ===== Exit
cleanup
printf '%s\n' "${!selected[@]}"
exit 0


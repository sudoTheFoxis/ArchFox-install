#!/bin/bash

### =============================================
### ===== (D) Dev ===============================
### =============================================
# function to test terminal color display, parts of AFI

#   execute all tests in order
AFI_D () {
    local AFI_TEMP_WIDTH=$(tput cols || printf "80\n") AFI_TEMP_HEIGHT=$(tput lines || printf "40\n")
    
    local AFI_TEMP_STRING="==================== 4-bit color test ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING})));printf "\n"
    AFI_D_4bit
    local AFI_TEMP_STRING="==================== 8-bit color test ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING}))); printf "\n"
    AFI_D_8bit
    local AFI_TEMP_STRING="==================== 24-bit color test ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING}))); printf "\n"
    AFI_D_24bit $AFI_TEMP_WIDTH $AFI_TEMP_HEIGHT
    if [ "$AFI_CONF_RAINBOW" != false ]; then
        local AFI_TEMP_STRING="==================== RAINBOW, because I'm bored ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING}))); printf "\n"
        AFI_D_RAINBOW $AFI_TEMP_WIDTH $AFI_TEMP_HEIGHT $((AFI_TEMP_WIDTH * $(($AFI_TEMP_HEIGHT-28))))
    fi
    printf '\n'; AFI_PAUSE
    
    local AFI_TEMP_STRING="==================== output test ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING}))); printf "\n"
    AFI_D_OUTPUT
    printf '\n'; AFI_PAUSE

    local AFI_TEMP_STRING="==================== defined variables ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING}))); printf "\n"
    AFI_D_PRINTPREFIX
    printf '\n'; AFI_PAUSE
}

#   some help function
AFI_D_COLORCALC () {
    local length=$(($(tput cols || printf "80\n") / 35))
    for c; do 
        printf "\033[38;5;%dm%*d" $c ${length} $c
    done
    printf '\033[0m\n'
}

#   print all colors that exists in 4-bit color space
AFI_D_4bit () {    
    AFI_D_COLORCALC {0..15}
}

# print all colors that exists in 8-bit color space
AFI_D_8bit () {
    for ((i=0;i<6;i++)); do AFI_D_COLORCALC $(seq $((i*36+16)) $((i*36+51))); done; AFI_D_COLORCALC {232..255}
}

#   print all colors that exists in 24-bit color space
AFI_D_24bit () {
    local AFI_TEMP_WIDTH=${1:-$(tput cols || printf "80\n")} AFI_TEMP_HEIGHT=${2:-$(tput lines || printf "40\n")}
    local R G B
    # ==================== RED
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # R + G
        R=255
        G=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100))
        B=0
        printf '\033[38;2;%s;%s;%sm' "$R" "$G" "$B"
        printf '\033[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '\033[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # R + BG
        R=255
        G=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100))
        B=$G
        printf '\033[38;2;%s;%s;%sm' "$R" "$G" "$B"
        printf '\033[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '\033[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # R + B
        R=255
        G=0
        B=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100))
        printf '\033[38;2;%s;%s;%sm' "$R" "$G" "$B"
        printf '\033[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '\033[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # R -
        R=$((255 - col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100))
        G=0
        B=0
        printf '\033[38;2;%s;%s;%sm' "$R" "$G" "$B"
        printf '\033[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '\033[0m\n'
    # ==================== GREEN
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # G + R
        G=255
        R=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100))
        B=0
        printf '\033[38;2;%s;%s;%sm' "$R" "$G" "$B"
        printf '\033[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '\033[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # G + RB
        G=255
        R=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100))
        B=$R
        printf '\033[38;2;%s;%s;%sm' "$R" "$G" "$B"
        printf '\033[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '\033[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # G + B
        G=255
        R=0
        B=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100))
        printf '\033[38;2;%s;%s;%sm' "$R" "$G" "$B"
        printf '\033[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '\033[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # G -
        G=$((255 - col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100))
        R=0
        B=0
        printf '\033[38;2;%s;%s;%sm' "$R" "$G" "$B"
        printf '\033[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '\033[0m\n'
    # ==================== BLUE
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # B + R
        B=255
        G=0
        R=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100))
        printf '\033[38;2;%s;%s;%sm' "$R" "$G" "$B"
        printf '\033[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '\033[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # B + GR
        B=255
        G=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100))
        R=$G
        printf '\033[38;2;%s;%s;%sm' "$R" "$G" "$B"
        printf '\033[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '\033[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # B + G
        B=255
        G=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100))
        R=0
        printf '\033[38;2;%s;%s;%sm' "$R" "$G" "$B"
        printf '\033[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '\033[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # B -
        B=$((255 - col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100))
        G=0
        R=0
        printf '\033[38;2;%s;%s;%sm' "$R" "$G" "$B"
        printf '\033[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '\033[0m\n'
}

#   print rainbow
AFI_D_RAINBOW () { # RAINBOW
    local AFI_TEMP_WIDTH=${1:-$(tput cols || printf "80\n")} AFI_TEMP_HEIGHT=${2:-$(tput lines || printf "40\n")}
    local R G B length=${3:-$((AFI_TEMP_WIDTH * $(($AFI_TEMP_HEIGHT-32))))}
    if [ "$length" -le 0 ]; then 
        length=$AFI_TEMP_WIDTH
    fi
    for (( i = 0; i < length; i++ )); do
        if (( i < length/6 )); then        # G = 255
            R=255
            G=$(( 255 * 6 * i / length ))
            B=0
        elif (( i < 2*length/6 )); then    # R = 0
            R=$(( 255 - 255 * 6 * (i - length/6) / length ))
            G=255
            B=0
        elif (( i < 3*length/6 )); then    # B = 255
            R=0
            G=255
            B=$(( 255 * 6 * (i - 2*length/6) / length ))
        elif (( i < 4*length/6 )); then    # G = 0
            R=0
            G=$(( 255 - 255 * 6 * (i - 3*length/6) / length ))
            B=255
        elif (( i < 5*length/6 )); then    # R = 255
            R=$(( 255 * 6 * (i - 4*length/6) / length ))
            G=0
            B=255
        else                                            # B = 0
            R=255
            G=0
            B=$(( 255 - 255 * 6 * (i - 5*length/6) / length ))
        fi
        # Fix Color Range
        R=$(( R < 0 ? 0 : (R > 255 ? 255 : R) ))
        G=$(( G < 0 ? 0 : (G > 255 ? 255 : G) ))
        B=$(( B < 0 ? 0 : (B > 255 ? 255 : B) ))
        # Print Color
        printf "\033[38;2;%d;%d;%dm" "$R" "$G" "$B" # foreground
        printf "\033[48;2;%d;%d;%dm" "$R" "$G" "$B" # background
        printf "%s\033[0m" " " # print char
        if ((i % AFI_TEMP_WIDTH == AFI_TEMP_WIDTH - 1)); then printf "\n"; fi
    done;
}

#   output function test
AFI_D_OUTPUT () {
    AFI_P "normal message"
    AFI_INFO "title" "info" "message"
    AFI_DEBUG "title" "debug" "message"
    AFI_WARN "title" "warn" "message"
    AFI_ERROR "title" "error" "message"
}

#   print all variables starting with provided prefx
AFI_D_PRINTPREFIX () {
    local prefix="$1"
    for var in $(compgen -v); do
        [[ "$var" == "$prefix"* ]] || continue
        case "$(declare -p "$var" 2>/dev/null)" in
            declare\ -a*)
                local -n arr="$var"
                printf '%s:\n' "${var#$prefix}"
                for i in "${!arr[@]}"; do
                    printf '    [%s]=%s\n' "$i" "${arr[$i]}"
                done
                ;;
            declare\ -A*)
                local -n assoc="$var"
                printf '%s:\n' "${var#$prefix}"
                for key in "${!assoc[@]}"; do
                    val="${assoc[$key]}"
                    printf '    [%s]=%s\n' "$key" "$val"
                done
                ;;
            *)
                val="${!var}"
                printf '%s: %s\n' "${var#$prefix}" "$val"
                ;;
        esac
    done
}

#   convert hex color code to terminal color code
AFI_D_TRANSLATECOLOR () {
    local colormode=${2:-0}
    if [ "$colormode" == 0 ]; then
        # auto-wybór trybu w zależności od środowiska
        if [[ "$COLORTERM" == *truecolor* ]]; then
            colormode="24"
        elif [[ "$TERM" == *256color* ]]; then
            colormode="8"
        else
            colormode="4"
        fi
    fi

    local hex="${!var,,}"
    local r g b
    hex="${hex#\#}"
    if [[ ! "$hex" =~ ^[0-9a-f]{6}$ ]]; then
        AFI_WARN "Invalid HEX code: $hex"; continue
    fi
    r=$((16#${hex:0:2}))
    g=$((16#${hex:2:2}))
    b=$((16#${hex:4:2}))

    case "$colormode" in
        -1)
            ;;
        1)
            printf ""
            ;;
        4) # 4-bit ANSI 16 colors
            local index=30
            (( r > 127 )) && (( index+=1 ))
            (( g > 127 )) && (( index+=2 ))
            (( b > 127 )) && (( index+=4 ))
            if (( r + g + b > 509 )); then
                (( index+=60 ))
            fi
            printf "\033[${index}m"
            ;;
        8) # 8-bit ANSI 256 colors
            r=$(( (r * 5) / 255 ))
            g=$(( (g * 5) / 255 ))
            b=$(( (b * 5) / 255 ))
            printf "\033[38;5;$(( 16 + (r * 36) + (g * 6) + b ))m"
            ;;
        24)
            printf "\033[38;2;${r};${g};${b}m"
            ;;
        *)
            AFI_ERROR "Unsupported color mode: $colormode\n"
            return 1
            ;;
    esac
}

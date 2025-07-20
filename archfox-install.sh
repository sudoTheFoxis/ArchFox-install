#!/bin/bash

AFI_VERSION="1.0.0-A"
AFI_AUTHOR=( sudoTheFoxis )

# LOGs
AFI_LOG=true                        #   create logs of install process
AFI_LOG_COPY=true                   #   copy logs (only stage 0)
AFI_LOG_OVERRIDE=false              #   override existing logs

# Color Codes
AFI_CC_PRIMARY="202"                #   Primary color 
AFI_CC_SECONDARY="232"              #   Secondary color
AFI_CC_FG="231"                     #   primary color code of massages
AFI_CC_BG="240"                     #   secondary color code of messages
AFI_CC_ERROR="196"                  #   error prefix color code
AFI_CC_WARN="220"                   #   warn -//-
AFI_CC_INFO="27"                    #   info -//-
AFI_CC_DEBUG="201"                  #   debug -//-

AFI_TEMPDIR="/tmp/ArchFox-install"

### =============================================
### ===== Variables =============================
### =============================================

AFI_V_IGNORE=0                      #   ignore warn messages
AFI_V_VERBOSE=0                     #   display debug info
AFI_V_SAFEMODE=0                    #   wont modify any files/settings, except saving config file in current directory
AFI_V_HEADLESS=0                    #   headless mode

AFI_V_PWD=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd) # working directory
AFI_V_CMD="$(basename "${BASH_SOURCE[0]}")" # file name
AFI_V_ARGS=("$@")                   #   arguments

declare -A AFI_V_IMPORTED=()        #   imported file list

### =============================================
### ===== Utils =================================
### =============================================

# functions for easy output/input handling
AFI_P () {
    printf '%s\n' "$@" >&2
}
AFI_C () {
    read -p "$* [y/n]: " yn
    case $yn in
        [Yy]*) return 0  ;;  
        *) return  1 ;;
    esac
}
AFI_PAUSE () {
    read -p "Press any key to continue..." -n1 -s
    printf '\n' >&2
}
AFI_INFO () {
    printf "\033[38;5;${AFI_CC_PRIMARY}m[AFI]\033[38;5;${AFI_CC_INFO}m[INFO]\033[38;5;${AFI_CC_FG}m:  %s \033[38;5;${AFI_CC_BG}m%s \033[0m\n" "${1}" "${*:2}" >&2
}
AFI_DEBUG () {
    if (($AFI_V_VERBOSE)); then
        printf "\033[38;5;${AFI_CC_PRIMARY}m[AFI]\033[38;5;${AFI_CC_DEBUG}m[DEBUG]\033[38;5;${AFI_CC_FG}m: %s \033[38;5;${AFI_CC_BG}m%s \033[0m\n" "${1}" "${*:2}" >&2
    fi
}
AFI_WARN () {
    if ! (($AFI_V_IGNORE)); then
        printf "\033[38;5;${AFI_CC_PRIMARY}m[AFI]\033[38;5;${AFI_CC_WARN}m[WARN]\033[38;5;${AFI_CC_FG}m:  %s \033[38;5;${AFI_CC_BG}m%s \033[0m\n" "${1}" "${*:2}" >&2
    fi
}
AFI_ERROR () {
    printf "\033[38;5;${AFI_CC_PRIMARY}m[AFI]\033[38;5;${AFI_CC_ERROR}m[ERROR]\033[38;5;${AFI_CC_FG}m: %s \033[38;5;${AFI_CC_BG}m%s \033[0m\n" "${1}" "${*:2}" >&2
}

# function to import other functions from files when they are needed
AFI_IMPORT() {
    for entry in "$@"; do
        local file fun
        IFS='@' read -r file fun <<< "$entry"

        if [ -n "$fun" ]; then
            # check if function already exists (source overrides old function declaration if they exists)
            if declare -f "$fun" >/dev/null; then
                #AFI_DEBUG "AFI_IMPORT: $fun already imported or exists";
                continue;
            fi
            #AFI_DEBUG "AFI_IMPORT: binding lazy import for $fun to $file"
            
            builtin eval "
            $fun() {
                if [[ -n \"${AFI_V_IMPORTED[\"$file\"]}\" ]]; then
                    AFI_DEBUG "IMPORT: $file has been already imported";
                else
                    AFI_DEBUG "AFI_IMPORT: importing all functions from $file"
                    AFI_V_IMPORTED[$file]=1
                    source \"$AFI_V_PWD/utils/$file.sh\"
                    $fun \$@
                fi
            }
            "
        else
            if [ -n "${AFI_V_IMPORTED["$file"]}" ]; then
                AFI_DEBUG "IMPORT: $file has been already imported"; continue;
            else
                AFI_DEBUG "AFI_IMPORT: importing all functions from $file"
                AFI_V_IMPORTED[$file]=1
                source "$AFI_V_PWD/utils/$file.sh"
            fi
        fi
    done
}

# create sudo loop to avoid typing password again
AFI_SUDO_LOOP () {
    AFI_INFO "Creating sudo loop..."
    while true; do
        sudo -v
        sleep 30
    done &
}

# parse flags
AFI_FLAGPARSER () {
    ## ==================== flag parser ======================================
    # Parse arguments, eg: [-abc --dir hello -pl] > [-a -b -c --dir hello -p -l]
    local args=()
    for ((ai=0; ai<${#AFI_V_ARGS[@]}; ai++)); do
        case "${AFI_V_ARGS[$ai]}" in
            --*)
                args+=("${AFI_V_ARGS[$ai]}") ;;
            -*) 
                for ((fi = 1; fi < ${#AFI_V_ARGS[$ai]}; fi++)); do
                    args+=("-${AFI_V_ARGS[$ai]:$fi:1}")
                done ;;
            *)  
                args+=("${AFI_V_ARGS[$ai]}") ;;
        esac
    done
    AFI_V_ARGS=("${args[@]}")

    ## ==================== flag resolver ====================================
    # Extract flags from each other, eg: [ -a my code -b is really working ] > [ -a my code ] [ -b is really working ]
    AFI_INDEX=0
    while [[ $AFI_INDEX -lt ${#AFI_V_ARGS[@]} ]]; do
        # add current flag to temp array, eg: [ -a ]
        local flag=()
        flag+=("${AFI_V_ARGS[$AFI_INDEX]}")
        ((AFI_INDEX++))

        # get flag's args, eg: [ -a my code ]
        while [[ 
            $AFI_INDEX -lt ${#AFI_V_ARGS[@]} && # check if position exists
            ${AFI_V_ARGS[$AFI_INDEX]} != -* || # stop if its another flag (-* or --*)
            ${AFI_V_ARGS[$AFI_INDEX]} == ---* # pass if its sub argument (---*)
        ]]; do
            flag+=("${AFI_V_ARGS[$AFI_INDEX]}")
            ((AFI_INDEX++))
        done

        # execute flag with its args
        case "${flag[0]}" in
            -v|--verbose)
                AFI_V_VERBOSE=1
                AFI_DEBUG "enabled debug messages"
                ;;
            -i|--ignore)
                AFI_V_IGNORE=1
                AFI_DEBUG "disabled warn messages, no warnings will be displayed"
                ;;
            --safemode)
                AFI_V_SAFEMODE=1
                AFI_DEBUG "enabled safemode, no changes will be done to any file system"
                ;;
            --headless)
                AFI_V_HEADLESS=1
                AFI_DEBUG "running in headless mode, some functions may not work properly"
                ;;
            # unknown flags
            ---*)
                AFI_ERROR "Error while resolving flags: sub arguments without flag: ${flag[*]}" ;;
            -*|--*)
                AFI_WARN "unknown flag: ${flag[*]}" ;;
            *)  
                AFI_ERROR "Error while resolving flags: arguments without flag: ${flag[*]}" ;;
        esac
    done
}

### =============================================
### ===== Main ==================================
### =============================================

# parse arguments if they exists
if [ ${#AFI_V_ARGS[@]} -gt 0 ]; then
    AFI_FLAGPARSER
fi

# run in headless mode
if (($AFI_V_HEADLESS)); then
    AFI_P "headless"
    exit 0
fi

# create temp dir
mkdir -p $AFI_TEMPDIR
# load config
source './defaultconfig.sh'
# lazy import

#packages=($(pacman -Slq)) # lub twoja lista
scripts/selector.sh -m -o "$AFI_TEMPDIR/selection" -p "$AFI_TEMPDIR/preview" $(pacman -Sql)

AFI_PAUSE

# end
if [ -n "$AFI_TEMPDIR" ]; then
    AFI_DEBUG "removing temp directory: $AFI_TEMPDIR"
    rm -rf "$AFI_TEMPDIR"
fi
exit 0

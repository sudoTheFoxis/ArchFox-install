#!/bin/bash
AFI_VERSION="1.1.2-B"
AFI_AUTHOR=( sudoTheFoxis )





### =================================================================================================================================================
### ==================== CONFIG =====================================================================================================================
### =================================================================================================================================================

# display settings
AFI_CONF_IGNORE=false               #   dont display warn messages.
AFI_CONF_VERBOSE=false              #   display debug info.
AFI_CONF_COLORS=true                #   enable color mode.
AFI_CONF_RAINBOW=true               #   display rainbow in dev test mode.

# installator settings
AFI_CONF_DEMO=false                 #   run in demo mode.
AFI_CONF_MODE=1                  #   installator mode.
AFI_CONF_DEFAULT=false              #   don't ask for configuration, use the default values.
AFI_CONF_AUTO=false                 #   don't ask for anything, choose the default option, full auto installation. (except configuration)

## S0
AFI_CONF_S0_PKGS=(                  #   required packages for script to work
    archlinux-keyring
    arch-install-scripts
    util-linux
    dosfstools
    e2fsprogs
    coreutils
    parted
    grep
    vim
    bc
)

## S1
AFI_DCONF_DEV="/dev/sda"            #   disk that will be used
AFI_DCONF_DISKLABEL=gpt             #   disk label (MBR - legacy bootloader, GPT - efi bootloader) (currently installator support only gpt)
AFI_DCONF_PARTLAYOUT=(              #   partition layout
    # [start]/[end] set where partition will begin and end 
    # [fstype]      set what file system will be on this partition
    # [label]       set partition label
    # [type]        boot - partition with bootloader
    #               root - system partiton
    #               swap - swap partition
    #               data - primary data partition
    #               home - partition that will be mounted as /home
    "( [start]='1MB' [end]='257MB' [fs]='fat32' [label]='BOOT' [type]='boot' )"
    "( [start]='258MB' [end]='-1MB' [fs]='ext4' [label]='ROOT' [type]='root' )"
)
AFI_DCONF_HARDFORMAT=false          #   make hard format (dd if=/dev/zero of=/dev/sdx)
AFI_DCONF_PREC_UNIT="KB"            #   unit in which the disk/partition will be calculated (b,B,s,KB,MB,GB,TB), do not use units larger than MB as they are too imprecise

## Variables
AFI_VAR_VALIDATED=false             #   true if validation has been already executed
AFI_VAR_PWD=$PWD                    #   store defult path where script runs
AFI_VAR_CMD=$0                      #   script file name





### =================================================================================================================================================
### ==================== CODE =======================================================================================================================
### =================================================================================================================================================



# Check if everything is right
AFI_S0 () {
    AFI_DEBUG "triggering AFI_S0"  
    if [ "$AFI_CONF_DEMO" == false ]; then
        if [ "$(sudo whoami)" != "root" ]; then 
            AFI_ERROR "S0: Root privileges are required to run this function.";exit 10
        fi

        sudo pacman --noconfirm -Sy ${AFI_CONF_S0_PKGS[*]}      # install packages
        sudo pacman --noconfirm -Sc                             # clean pacman cache
    
    else AFI_DEBUG "S0: Running in demo mode, skipping...";fi
    AFI_DEBUG "AFI_S0: done."
}

# prepare disk for system installation (format disk and create partitions)
AFI_S1 () {
    AFI_DEBUG "triggering AFI_S1"
    if [ "$AFI_CONF_DEMO" == false ]; then
        if [ "$(sudo whoami)" != "root" ]; then 
            AFI_ERROR "S1: Root privileges are required to run this function.";exit 10
        fi

    else AFI_DEBUG "S1: Running in demo mode, skipping...";fi
    AFI_DEBUG "AFI_S1: done."
}

# install bare bones system on prepared disk
AFI_S2 () {
    AFI_DEBUG "triggering AFI_S2"
    if [ "$AFI_CONF_DEMO" == false ]; then
        if [ "$(sudo whoami)" != "root" ]; then 
            AFI_ERROR "S2: Root privileges are required to run this function.";exit 10
        fi

    else AFI_DEBUG "S2: Running in demo mode, skipping...";fi
    AFI_DEBUG "AFI_S2: done."
}

# configure system, make it more accessible/usable
AFI_S3 () {
    AFI_DEBUG "triggering AFI_S3"
    if [ "$AFI_CONF_DEMO" == false ]; then
        if [ "$(sudo whoami)" != "root" ]; then 
            AFI_ERROR "S3: Root privileges are required to run this function.";exit 10
        fi

    else AFI_DEBUG "S3: Running in demo mode, skipping...";fi
    AFI_DEBUG "AFI_S3: done."
}

# help list
AFI_HELP () {
    AFI_DEBUG "triggering AFI_HELP"
    # changelog
    cd $AFI_VAR_PWD;AFI_TEMP_CHANGELOG=()
    if [[ ! -f "changelog.txt" ]]; then AFI_ERROR "changelog.txt does not exists.";
    else 
        while IFS= read -r line; do AFI_TEMP_CHANGELOG+="    $line\n";done < changelog.txt
    fi
    # scripts
    cd scripts;AFI_TEMP_SCRIPTS=()
    for folder in ./*; do
        if [[ -d "$folder" ]]; then
            if [[ ! -f "$folder/init.sh" ]]; then AFI_WARN "The $folder S3 script does not contain a init.sh file"; continue; fi
            # check files
            if [[ -f "$folder/description.txt" ]]; then AFI_TEMP_DESFILE=description.txt
            elif [[ -f "$folder/README.md" ]]; then AFI_TEMP_DESFILE=README.md
            else AFI_TEMP_DESFILE="null"; fi
            # read script description
            fill=$(printf "%0.s┈" $(seq 1 $(( 135 - ${#folder} - ${#AFI_TEMP_DESFILE} - 8)) ))
            local AFI_TEMP_TEXT="$(printf "    ${folder} ${fill} (${AFI_TEMP_DESFILE})")\n"
            # parse script description to look cooler
            if [ $AFI_TEMP_DESFILE != "null" ]; then
                while IFS= read -r line || [[ -n "$line" ]]; do AFI_TEMP_TEXT+="      ┃ $line\n"
                done < "$folder/$AFI_TEMP_DESFILE"; AFI_TEMP_TEXT="$(printf "$AFI_TEMP_TEXT" | sed '$ s/      ┃/      ╹/')\n"
            #else AFI_TEMP_TEXT+="      ╹ This S3 script does not contain a description.txt or README.md file\n"
            fi; AFI_TEMP_SCRIPTS+=$AFI_TEMP_TEXT
        fi
    done;unset AFI_TEMP_DESFILE
    # print help
    printf "INFO: type \":q\" or press <Esc> to exit.

     .--..--..--..--..--..--..--..--..--..--..--..--..--..--..--..--..--..--..--..--..--.
    / .. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \ 
    \ \/\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \/ /
     \/ /\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\/ /
     / /\                                                                            / /\ 
    / /\ \       █████╗ ██████╗  ██████╗██╗  ██╗    ███████╗ ██████╗ ██╗  ██╗       / /\ \ 
    \ \/ /      ██╔══██╗██╔══██╗██╔════╝██║  ██║    ██╔════╝██╔═══██╗╚██╗██╔╝       \ \/ /
     \/ /       ███████║██████╔╝██║     ███████║    █████╗  ██║   ██║ ╚███╔╝         \/ /
     / /\       ██╔══██║██╔══██╗██║     ██╔══██║    ██╔══╝  ██║   ██║ ██╔██╗         / /\ 
    / /\ \      ██║  ██║██║  ██║╚██████╗██║  ██║    ██║     ╚██████╔╝██╔╝ ██╗       / /\ \ 
    \ \/ /      ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═╝      ╚═════╝ ╚═╝  ╚═╝       \ \/ /
     \/ /                                ver: ${AFI_VERSION}                                \/ /
     / /\.--..--..--..--..--..--..--..--..--..--..--..--..--..--..--..--..--..--..--./ /\ 
    / /\ \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \.. \/\ \ 
    \ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`'\ \`' /
     \`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'\`--'

DESCRIPTION
    ArchFox is based on Arch Linux, as if that wasn't obvious.
    installator modes:
      ┣ main    ━ Easy full install, script will 
      ┣ S0      ━ Check if everything is right.
      ┣ S1      ━ Prepare disk for linux installation.
      ┣ S2      ━ Install system with minimal configuration, just enough for the system to work properly (bare bones linux).
      ┣ S3      ━ Configure the system according to the configuration, install additional packages eg. desktop environment/window manager.
      ┗ dev     ━ triggers dev function, no wipe, delete or install command will be executed.
    ArchFox can also be installed on an existing Arch Linux installation, just run installator with \"-m S3\" flag.
    After installing ArchFox, the installer can be found in /root/archfox-install for easy modifications, e.g.
    install an additional window/desktop environment, apply additional configuration.
    This script isn't very idiot proof, so keep that in mind if you don't run it on bootable media, unless you want to wipe the entire system with all the data.
    If you have any ideas, questions, or found any bugs, please tell me about it on: https://github.com/sudoTheFoxis/ArchFox-install

OPTIONS
    command [flags]
      ┣ --help       -h  ━ show this help list and exit.
      ┣ --mode       -m  ━ change mode of installation (default: main).
      ┃   ┗ <mode>       ━ enter the mode in which you want to run the installer [main S1 S2 S3 dev null].
      ┣ --conf-file  -c  ━ config file from which the settings will be imported.
      ┃   ┗ <file>       ━ configuration file path/name.
      ┣ --auto       -a  ━ automatically selects the default option at every stage of system installation,
      ┃                    except for the installer configuration, of course.
      ┣ --default    -d  ━ run the installer with the default configuration.
      ┣ --verbose    -v  ━ display debug info.
      ┣ --ignore     -i  ━ ignore warns.
      ┣ --nochecksum -N  ━ skip sources verification.
      ┣ --colors     -C  ━ disable or forcibly enable color mode.
      ┃   ┗ <mode>       ━ type \"false\" to disable, or \"true\" to forcibly enable colors.
      ┗ --demo       -D  ━ run installator in demo mode. (overrides all other flags).

SYNTAX
    command [flags]
      ┗ --example   -e  ━ this is not a real flag, its just a example to show the syntax.   (\"-e\" or \"--example\")
        ┣ args          ━ this is an required argument of flag, you can add it after flag   (-e args)
        ┗*args          ━ this is an optional argument of flag, you can add it after flag   (-e args)
    examples:
      ┃ # this command will run fully automatic install with additional debug info, and no colors.
      ┃ # make sure you enter the correct drive in the configuration at the top of script file to avoid wiping the wrong drive.
      ┣ command -vdaC false -m full
      ┃ # this command will run dev function, display color test and run demo install.
      ┣ command -m dev
      ┃ # this command will run semi-automatic install, with additional debug info, and enabled colors.
      ┗ command -vC true -m full
    this script has a custom flag resolver where you can insert flags as follows (the order doesn't matter):
      ┣ command -abg
      ┣ command -a -b -g
      ┗ command --alpha --beta --gamma
    flag arguments are strings from a given flag to the next flag that do not start with "-" or "--"
    changelog
    <version> <date>:
      + added
      - removed
      = changed/modified/fixed

SCRIPTS
$AFI_TEMP_SCRIPTS
CHANGELOG
$AFI_TEMP_CHANGELOG
\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n
HELLO THERE
\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n
STF) you want linux, dont you?
" | vim -c 'map <Esc> :q!<CR>' -R -M -m -
    unset AFI_TEMP_CHANGELOG; unset AFI_TEMP_SCRIPTS
    AFI_DEBUG "AFI_HELP: done."
}

## dev function
AFI_DEV () {
    AFI_DEBUG "triggering AFI_DEV"
    AFI_CONF_DEMO=true
    printf "running in $AFI_VAR_CMODE color(s) mode.\n"
    AFI_TEMP_WIDTH=$(tput cols || printf "80\n"); AFI_TEMP_HEIGHT=$(tput lines || printf "40\n")
    # 3-bit/4-bit test
    AFI_TEMP_STRING="==================== 16 colors (3-bit/4-bit) test ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING})));printf "\n"
    color () { AFI_TEMP_LENGHT=$(($AFI_TEMP_WIDTH / 36)); for c; do printf "[38;5;%dm%*d" $c ${AFI_TEMP_LENGHT} $c; done; printf '[0m\n'; unset AFI_TEMP_LENGHT; }
    color {0..15}
    # 8-bit color test
    AFI_TEMP_STRING="==================== 256 colors (8-bit) test ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING}))); printf "\n"
    for ((i=0;i<6;i++)); do color $(seq $((i*36+16)) $((i*36+51))); done; color {232..255}
    # RGB test
    AFI_TEMP_STRING="==================== true color (16-bit/24-bit) test ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING}))); printf "\n"
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # R + G #RED
        R=255;G=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));B=0; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"; done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # R + BG
        R=255;G=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));B=$G; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"; done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # R + B
        R=255;G=0;B=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100)); printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"; done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # R -
        R=$((255 - col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));G=0;B=0; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"; done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # G + R #GREEN
        G=255;R=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));B=0; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"; done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # G + RB
        G=255;R=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));B=$R; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"; done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # G + B
        G=255;R=0;B=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100)); printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"; done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # G -
        G=$((255 - col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));R=0;B=0; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"; done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # B + R #BLUE
        B=255;G=0;R=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100)); printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"; done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # B + GR
        B=255;G=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));R=$G; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"; done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # B + G
        B=255;G=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));R=0; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"; done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # B -
        B=$((255 - col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));G=0;R=0; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"; done; printf '[0m\n'
    # RAINBOW
    if [ "$AFI_CONF_RAINBOW" != false ]; then
        AFI_TEMP_STRING="==================== RAINBOW, because I'm bored ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING}))); printf "\n"
        AFI_TEMP_RGB_LENGTH=$((AFI_TEMP_WIDTH * $(($AFI_TEMP_HEIGHT-34))))
        if [ "$AFI_TEMP_RGB_LENGTH" -le 0 ]; then AFI_TEMP_RGB_LENGTH=$AFI_TEMP_WIDTH; fi
        for (( i = 0; i < AFI_TEMP_RGB_LENGTH; i++ )); do
            if (( i < AFI_TEMP_RGB_LENGTH/6 )); then        # G = 255
                AFI_TEMP_R=255;AFI_TEMP_G=$(( 255 * 6 * i / AFI_TEMP_RGB_LENGTH ));AFI_TEMP_B=0;
            elif (( i < 2*AFI_TEMP_RGB_LENGTH/6 )); then    # R = 0
                AFI_TEMP_R=$(( 255 - 255 * 6 * (i - AFI_TEMP_RGB_LENGTH/6) / AFI_TEMP_RGB_LENGTH ));AFI_TEMP_G=255;AFI_TEMP_B=0;
            elif (( i < 3*AFI_TEMP_RGB_LENGTH/6 )); then    # B = 255
                AFI_TEMP_R=0;AFI_TEMP_G=255;AFI_TEMP_B=$(( 255 * 6 * (i - 2*AFI_TEMP_RGB_LENGTH/6) / AFI_TEMP_RGB_LENGTH ));
            elif (( i < 4*AFI_TEMP_RGB_LENGTH/6 )); then    # G = 0
                AFI_TEMP_R=0;AFI_TEMP_G=$(( 255 - 255 * 6 * (i - 3*AFI_TEMP_RGB_LENGTH/6) / AFI_TEMP_RGB_LENGTH ));AFI_TEMP_B=255;
            elif (( i < 5*AFI_TEMP_RGB_LENGTH/6 )); then    # R = 255
                AFI_TEMP_R=$(( 255 * 6 * (i - 4*AFI_TEMP_RGB_LENGTH/6) / AFI_TEMP_RGB_LENGTH ));AFI_TEMP_G=0;AFI_TEMP_B=255;
            else                                            # B = 0
                AFI_TEMP_R=255;AFI_TEMP_G=0;AFI_TEMP_B=$(( 255 - 255 * 6 * (i - 5*AFI_TEMP_RGB_LENGTH/6) / AFI_TEMP_RGB_LENGTH ));
            fi
            # Fix Color Range
            AFI_TEMP_R=$(( AFI_TEMP_R < 0 ? 0 : (AFI_TEMP_R > 255 ? 255 : AFI_TEMP_R) ));AFI_TEMP_G=$(( AFI_TEMP_G < 0 ? 0 : (AFI_TEMP_G > 255 ? 255 : AFI_TEMP_G) ));AFI_TEMP_B=$(( AFI_TEMP_B < 0 ? 0 : (AFI_TEMP_B > 255 ? 255 : AFI_TEMP_B) ))
            # Print Color
            printf "\e[38;2;%d;%d;%dm" "$AFI_TEMP_R" "$AFI_TEMP_G" "$AFI_TEMP_B" # foreground
            printf "\e[48;2;%d;%d;%dm" "$AFI_TEMP_R" "$AFI_TEMP_G" "$AFI_TEMP_B" # background
            printf "%s[0m" " " # print char
            if ((i % AFI_TEMP_WIDTH == AFI_TEMP_WIDTH - 1)); then printf "\n"; fi
        done; unset AFI_TEMP_RGB_LENGTH
    fi
    # output test
    AFI_TEMP_STRING="==================== output test ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING}))); printf "\n"
    AFI_INFO "AFI_INFO PRINT TEST"
    AFI_DEBUG "AFI_DEBUG PRINT TEST"
    AFI_WARN "AFI_WARN PRINT TEST"
    AFI_ERROR "AFI_ERROR PRINT TEST"
    printf "\n"

    AFI_DEBUG "AFI_DEV: done."
    unset AFI_TEMP_STRING; unset AFI_TEMP_WIDTH; unset AFI_TEMP_HEIGHT
}





### =================================================================================================================================================
### ==================== CUI ========================================================================================================================
### =================================================================================================================================================



AFI_S1_CUI () {
    AFI_DEBUG "triggering AFI_S1_CUI"

        # validate disk
        if [[ ! -b "$AFI_CONF_DEV" ]]; then AFI_ERROR "chosen disk does not exists"; exit 4; fi
        d_size=($(AFI_CONVU "$(cat /sys/class/block/${AFI_DCONF_DEV//"/dev/"}/size)s" $AFI_DCONF_PREC_UNIT))
        d_reamaning=${d_size[0]}


        # validate partitions
        for AFI_TEMP_PART in "${AFI_CONF_PARTLAYOUT[@]}"; do
            eval "declare -A AFI_TEMP_PART_KEYS=$AFI_TEMP_PART"
            p_start=($(AFI_CONVU ${AFI_TEMP_PART_KEYS[start]} $AFI_CONF_PREC_UNIT))
            p_end=($(AFI_CONVU ${AFI_TEMP_PART_KEYS[end]} $AFI_CONF_PREC_UNIT))
            if [ ${p_end[0]} -lt 0 ]; then p_end[0]=$((${p_end[0]} + ${d_size[0]})); fi
            p_size=$(( ${p_end[0]} - ${p_start[0]} ))
            if [ $p_size -lt 1 ]; then AFI_ERROR "Partition size is less than 0: (start: ${p_start[*]}, end: ${p_end[*]}, size: $p_size $AFI_DCONF_PREC_UNIT)"; return 4; fi
            d_reamaning=$(($d_reamaning - ${p_size[0]}))
        done
        unset AFI_TEMP_PART;unset AFI_TEMP_PART_KEYS

    AFI_DEBUG "AFI_S1_CUI: done."
}

AFI_S2_CUI () {
    AFI_DEBUG "triggering AFI_S2_CUI"
    AFI_DEBUG "AFI_S2_CUI: done."
}

AFI_S3_CUI () {
    AFI_DEBUG "triggering AFI_S3_CUI"
    AFI_DEBUG "AFI_S3_CUI: done."
}





### =================================================================================================================================================
### ==================== FUNCTIONS ==================================================================================================================
### =================================================================================================================================================

# convert unit to unit
AFI_CONVU () {
    value=$(echo "$1" | grep -oP "^-?[0-9]+")
    from_unit=$(echo "$1" | grep -oP "[a-zA-Z]+")
    declare -A units;units=( 
        [b]=1                                   # 1 bit
        [B]=8                                   # 1 bajt = 8 bitów
        [s]=$((512 * 8))                        # 1 sektor = 512 bajtów = 4096 bitów
        [KB]=$((8 * 1024))                      # 1 KB = 1024 bajtów = 8192 bitów
        [MB]=$((8 * 1024 * 1024))               # 1 MB = 1024 * 1024 bajtów = 8388608 bitów
        [GB]=$((8 * 1024 * 1024 * 1024))        # 1 GB = 1024 * 1024 * 1024 bajtów
        [TB]=$((8 * 1024 * 1024 * 1024 * 1024)) # 1 TB = 1024 * 1024 * 1024 * 1024 bajtów
    )
    if [[ -z "${units[$from_unit]}" || -z "${units[$2]}" ]]; then printf "unknown unit: $from_unit/$2, known units: b, B, KB, MB, GB, TB, s\n";return 1;fi
    value_in_bits=$(echo "$value * ${units[$from_unit]}" | bc)              #   convert to bits
    result=("$(echo "scale=0; $value_in_bits / ${units[$2]}" | bc)" "$2")   #   convert to destined unit
    echo "${result[@]}"                                                     #   return result
}

# Update Color Sheme
AFI_UpdateCS () {
    AFI_DEBUG "triggering AFI_UpdateCS"
    if [ $AFI_CONF_COLORS == true ]; then
        case "$(tput colors)" in 
            8) # 3-bit color mode
                AFI_COLOR_WHITE="[38;5;7m"
                AFI_COLOR_ORANGE="[38;5;3m"
                AFI_COLOR_CYAN="[38;5;6m"
                AFI_COLOR_BLUE="[38;5;12;1m"
                AFI_COLOR_GREEN="[38;5;10;1m"
                AFI_COLOR_RED="[38;5;9;1m"
                AFI_COLOR_YELLOW="[38;5;11;1m"
                AFI_VAR_CMODE=8 ;;
            16) # 4-bit color mode
                AFI_COLOR_WHITE="[38;5;15m"
                AFI_COLOR_ORANGE="[38;5;14m"
                AFI_COLOR_CYAN="[38;5;12m"
                AFI_COLOR_BLUE="[38;5;12;1m"
                AFI_COLOR_GREEN="[38;5;10;1m"
                AFI_COLOR_RED="[38;5;9;1m"
                AFI_COLOR_YELLOW="[38;5;11;1m"
                AFI_VAR_CMODE=16 ;;
            256) # 8-bit color mode
                AFI_COLOR_WHITE="[38;5;231;1m"
                AFI_COLOR_ORANGE="[38;5;202;1m"
                AFI_COLOR_CYAN="[38;5;39;1m"
                AFI_COLOR_BLUE="[38;5;12;1m"
                AFI_COLOR_GREEN="[38;5;10;1m"
                AFI_COLOR_RED="[38;5;9;1m"
                AFI_COLOR_YELLOW="[38;5;11;1m"
                AFI_VAR_CMODE=256 ;;
            *) # unknown color mode
                AFI_VAR_CMODE=1 ;;
        esac
    else
        AFI_COLOR_WHITE=""
        AFI_COLOR_ORANGE=""
        AFI_COLOR_CYAN=""
        AFI_COLOR_BLUE=""
        AFI_COLOR_GREEN=""
        AFI_COLOR_RED=""
        AFI_COLOR_YELLOW=""
        AFI_CONF_COLORS=false
        AFI_VAR_CMODE=1
    fi
    AFI_COLOR_RESET="[0m"
    AFI_DEBUG "AFI_UpdateCS: done."
}

# output handling
AFI_INFO () {
    printf "${AFI_COLOR_WHITE}[${AFI_COLOR_CYAN}A${AFI_COLOR_ORANGE}F${AFI_COLOR_WHITE}I]"
    printf "${AFI_COLOR_GREEN}[INFO]"; printf "${AFI_COLOR_RESET}:  ${1}"; printf "${AFI_COLOR_RESET}\n"
}
AFI_DEBUG () {
    if [ "$AFI_CONF_VERBOSE" == true ]; then 
        printf "${AFI_COLOR_WHITE}[${AFI_COLOR_CYAN}A${AFI_COLOR_ORANGE}F${AFI_COLOR_WHITE}I]"
        printf "${AFI_COLOR_BLUE}[DEBUG]"; printf "${AFI_COLOR_RESET}: ${1}"; printf "${AFI_COLOR_RESET}\n"
    fi
}
AFI_WARN () {
    if [ "$AFI_CONF_IGNORE" == false ]; then 
        printf "${AFI_COLOR_WHITE}[${AFI_COLOR_CYAN}A${AFI_COLOR_ORANGE}F${AFI_COLOR_WHITE}I]"
        printf "${AFI_COLOR_YELLOW}[WARN]"; printf "${AFI_COLOR_RESET}:  ${1}"; printf "${AFI_COLOR_RESET}\n"
    fi
}
AFI_ERROR () {
    printf "${AFI_COLOR_WHITE}[${AFI_COLOR_CYAN}A${AFI_COLOR_ORANGE}F${AFI_COLOR_WHITE}I]"
    printf "${AFI_COLOR_RED}[ERROR]"; printf "${AFI_COLOR_RESET}: ${1}"; printf "${AFI_COLOR_RESET}\n"
}





### =================================================================================================================================================
### ==================== MAIN =======================================================================================================================
### =================================================================================================================================================



AFI_UpdateCS # adapt colors to supported color mode

# Parse arguments, eg: [-abc --dir hello -pl] > [-a -b -c --dir hello -p -l]
AFI_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --*)
            AFI_ARGS+=("$1");shift;;
        -*) 
            for ((i = 1; i < ${#1}; i++)); do
                char="${1:$i:1}";if [[ $char != - ]];then AFI_ARGS+=("-$char");fi;unset char
            done;shift;;
        *)  
            AFI_ARGS+=("$1");shift;;
    esac
done

# Extract flags from each other, eg: [ -a my code -b is really working ] > [ -a my code ] [ -b is really working ]
AFI_INDEX=0
while [[ $AFI_INDEX -lt ${#AFI_ARGS[@]} ]]; do
    AFI_TEMP_FLAG=(); AFI_TEMP_FLAG+=("${AFI_ARGS[$AFI_INDEX]}"); ((AFI_INDEX++))   # save current flag to temp array, eg: [ -a ]
    while [[                                                                        # get flag's args, eg: [ -a my code ]
        $AFI_INDEX -lt ${#AFI_ARGS[@]} &&   # check if position exists
        ${AFI_ARGS[$AFI_INDEX]} != -* ||    # return if its another flag
        ${AFI_ARGS[$AFI_INDEX]} == ---*     # pass if its starting with "---*"
    ]]; do AFI_TEMP_FLAG+=("${AFI_ARGS[$AFI_INDEX]}");((AFI_INDEX++));done
    case "${AFI_TEMP_FLAG[0]}" in                                                   # execute flag with its args
        -h|--help)
            AFI_HELP;                           AFI_DEBUG "inserted --help (-h) flag, program will exit after showing help list";exit 0;;
        -m|--mode)
            AFI_CONF_MODE="${AFI_TEMP_FLAG[1]}";AFI_DEBUG "inserted --mode (-m) flag, installator mode is set to: ${AFI_CONF_MODE}";;
        -a|--auto)
            AFI_CONF_AUTO=true;                 AFI_DEBUG "inserted --auto (-a) flag, all choices will be done automatically.";;
        -d|--default)
            AFI_CONF_DEFAULT=true;              AFI_DEBUG "inserted --default (-d) flag, installation will be started with default settings.";;
        -v|--verbose)
            AFI_CONF_VERBOSE=true;              AFI_DEBUG "inserted --verbose (-v) flag, from this point on, debugging information will be displayed.";;
        -i|--ignore)
            AFI_CONF_IGNORE=true;               AFI_DEBUG "inserted --ignore (-I) flag, from now on warnings will not be displayed.";;
        -D|--demo)
            AFI_CONF_DEMO=true;                 AFI_DEBUG "inserted --demo (-D) flag, the installer will run in demo mode.";;
        # unknown flags
        ---*)
            AFI_ERROR "Error while resolving flags: arguments without flag: ${AFI_TEMP_FLAG[*]}" ;;
        -*|--*)
            AFI_WARN "unknown flag: ${AFI_TEMP_FLAG[*]}" ;;
        *)  
            AFI_ERROR "Error while resolving flags: arguments without flag: ${AFI_TEMP_FLAG[*]}" ;;
    esac; 
done; unset AFI_TEMP_FLAG

# trigger choosen mode
case "${AFI_CONF_MODE}" in
    [Mm]*|[Ss][Mm] )    AFI_MAIN;;
    0|[Ss]0 )           AFI_S0  ;;
    1|[Ss]1 )           AFI_S1  ;;
    2|[Ss]2 )           AFI_S2  ;;
    3|[Ss]3 )           AFI_S3  ;;
    [Dd]* )             AFI_DEV ;;
    *)                  AFI_ERROR "Error while triggering installator mode, this is an unknown mode: ${AFI_CONF_MODE}";;
esac

# end
unset $(compgen -v AFI_)
exit 0

# exit codes:
# 0 - no error
# 1 - unknown or undescribed error
# 2 - process aborted by user
# 3 - dev break point (just find the "exit 3" and delete it)
# 4 - configuration error
# 10 - no sudo permission
#
#
#
#
#







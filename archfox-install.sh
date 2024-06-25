#!/bin/bash
AFI_VERSION="1.0.7-A"
AFI_AUTHOR=( sudoTheFoxis )



### =================================================================================================================================================
### ==================== CONFIG =====================================================================================================================
### =================================================================================================================================================

## display settings
AFI_CONF_IGNORE=false               #   dont display warn messages.
AFI_CONF_VERBOSE=false              #   display debug info.
AFI_CONF_COLORS=true                #   display colors in terminal? (may fix some visual bugs and/or slightly improve performance)
AFI_CONF_RAINBOW=true               #   display rainbow in dev test mode

## AFI main config
AFI_CONF_FILE="AFI_CONFIG.conf"     #   config file name, from with configuration will be imported. (overrides everything)

## installator configuration
AFI_CONF_DEMO=false                 #   run in demo mode.
AFI_CONF_MODE=main                  #   installator mode.
AFI_CONF_DEFAULT=false              #   don't ask for configuration, use the default values.
AFI_CONF_AUTO=false                 #   don't ask for anything, choose the default option, full auto installation. (except configuration)

## ==================== S0
AFI_CONF_S0_PKGS=(
    archlinux-keyring
    arch-install-scripts
    util-linux
    dosfstools
    e2fsprogs
    coreutils
    parted
    vim
)

## ==================== S1
AFI_CONF_DEV="/dev/sdx"             #   disk that will be used
AFI_CONF_HARDFORMAT=false           #   make hard format (dd if=/dev/zero of=/dev/sdx)

## ==================== S2
AFI_CONF_HOSTNAME="archfox"         #   system/computer name
AFI_CONF_USERNAME="home"            #   user name
AFI_CONF_USERPASS="home"            #   user password
AFI_CONF_ROOTPASS="root"            #   root password
AFI_CONF_LOCALE="en_US.UTF-8"       #   UTF-8 keyboard layout
AFI_CONF_TIMEZONE="Europe/Warsaw"   #   timezone (from /usr/share/zoneinfo/)
AFI_CONF_MOUNTPATH="/mnt"           #   path where disk will be mounted
AFI_CONF_AUTOUMOUNT=false           #   automatically unmount partitions from mount path after installation is complete
AFI_CONF_S2_PKGS=(                  #   packages that will be installed on the S2 stage
    linux
    base
    mkinitcpio
    dbus-daemon-units
    efibootmgr
    linux-firmware
    networkmanager
    sudo
    curl
)

## ==================== S3
AFI_CONF_PROFILE="dev"              #   profile that will be installed
AFI_CONF_GPUDRI="none"              #   for what gpu drivers will be installed
AFI_CONF_USEYAY=true                #   set to true if you want to install aur packages, it will install and use yay pkg manager
AFI_CONF_S3_PKGS=(                  #   packages that will be installed on the S3 stage
    # xorg
    xorg-xinit
    xorg-xinput
    xorg-xrandr
    xorg-server
    # audio
    jack2
    pipewire
    pipewire-pulse
    pipewire-alsa
    wireplumber
    pulsemixer
    # apps
    htop
    nano
    neovim
    neofetch
    # dev
    base-devel
    autoconf
    make
    git
    gcc
    # other
    ttf-dejavu
)

## some variables (This is not part of the config)
AFI_VAR_VALIDATED=false             #   set to true if you want to skip validation
AFI_VAR_PWD=$PWD                    #   path where script runs
AFI_VAR_CMD=$0                      #   script file name



### =================================================================================================================================================
### ==================== FUNCTIONS ==================================================================================================================
### =================================================================================================================================================

## ==================== MAIN =============================================
AFI_MAIN () {
    AFI_DEBUG "triggering AFI_MAIN"  

    AFI_INFO "This function is currently under development."
    exit 3;

    # import config from file
    cd $AFI_VAR_PWD
    if [ -f "$AFI_CONF_FILE" ]; then
        read -r AFI_TEMP_INPUT -p "do you want to import the configuration from $AFI_CONF_FILE? (Y/n): "
        case "$AFI_TEMP_INPUT" in
            [Nn0]* )
                AFI_INFO "The configuration has not been imported." ;;
            * )
                AFI_INFO "Reading file, importing configuration..."
                AFI_CONF_DEFAULT=true
                
                ;;
        esac
    fi
    
    # Ask the user about the configuration
    if [ "$AFI_CONF_DEFAULT" != true ]; then
        AFI_INFO "Initializing the configuration"
        # cli for easy configuration

    fi

    # config basic validation

    # save config to file?

    # execute functions
    if [ "$AFI_CONF_DEMO" == false ]; then
        # S0 stage
        AFI_S0
        # S1 stage
        AFI_S1
        # S2 stage
        AFI_CONF_AUTOUMOUNT=false
        AFI_S2
    else
        AFI_DEBUG "MAIN: Running in demo mode, skipping..."
    fi
    AFI_DEBUG "AFI_MAIN: done."
}

## ==================== S0 ===============================================
# install needed packages for script to work
AFI_S0 () {
    AFI_DEBUG "triggering AFI_S0"  
    if [ "$AFI_CONF_DEMO" == false ]; then
        if [ "$(sudo whoami)" != "root" ]; then 
            AFI_ERROR "S0: Root privileges are required to run this function."
            exit 10
        fi

        # install packages
        sudo pacman --noconfirm -Sy ${AFI_CONF_S0_PKGS[*]}
        # clean pacman cache
        sudo pacman --noconfirm -Sc

    else
        AFI_DEBUG "S0: Running in demo mode, skipping..."
    fi
    AFI_DEBUG "AFI_S0: done."
}

## ==================== S1 ===============================================
# prepare disk for system installation (format disk and create partitions)
AFI_S1 () {
    AFI_DEBUG "triggering AFI_S1"
    if [ "$AFI_CONF_DEMO" == false ]; then
        if [ "$(sudo whoami)" != "root" ]; then 
            AFI_ERROR "S1: Root privileges are required to run this function."
            exit 10
        fi

        # check if disk exists
        if [[ ! -b "$AFI_CONF_DEV" ]]; then
            AFI_ERROR "chosen disk does not exists"; exit 7;
        fi

        # format disk
        if [ "$AFI_CONF_S1_HARDFORMAT" == true ]; then
            AFI_DEBUG "Starting Hard Format on $AFI_CONF_DEV, this may take a while on large disks"
            sudo dd if=/dev/zero of=$AFI_CONF_DEV bs=16K status=progress
        else
            AFI_DEBUG "Wiping all partition tables on $AFI_CONF_DEV"
            sudo wipefs -a $AFI_CONF_DEV
        fi

        # create partitons
        AFI_DEBUG "Creating partitons on $AFI_CONF_DEV"
        sudo parted -s -f -- $AFI_CONF_DEV \
            mklabel gpt \
            mkpart primary 1MiB 257MiB \
            name 1 BOOT \
            set 1 boot on \
            mkpart primary 258MiB -1MiB \
            name 2 ROOT
        
        sudo mkfs.fat -F 32 "${AFI_CONF_DEV}1" # create boot fs
        sudo mkfs.ext4 "${AFI_CONF_DEV}2" # craete root fs

        # print partition tabble
        lsblk -f

    else
        AFI_DEBUG "S1: Running in demo mode, skipping..."
    fi
    AFI_DEBUG "AFI_S1: done."
}

## ==================== S2 ===============================================
# install working system with basic functionality (bare bones arch linux)
AFI_S2 () {
    AFI_DEBUG "triggering AFI_S2"
    if [ "$AFI_CONF_DEMO" == false ]; then
        if [ "$(sudo whoami)" != "root" ]; then 
            AFI_ERROR "S2: Root privileges are required to run this function."
            exit 10
        fi

        # mount prepared disk
        AFI_DEBUG "Mounting partitions in ${AFI_CONF_MOUNTPOINT}"
        sudo mount -m "${AFI_CONF_DEV}2" ${AFI_CONF_MOUNTPOINT} # mount ROOT on /mnt
        sudo mount -m "${AFI_CONF_DEV}1" ${AFI_CONF_MOUNTPOINT}/boot # mount BOOT on /mnt/boot

        # create swap file
        AFI_DEBUG "Creating swap in ${AFI_CONF_MOUNTPOINT}/swap_deleteme"
        sudo mkswap -U clear --size 4G --file ${AFI_CONF_MOUNTPOINT}/swap_deleteme
        sudo swapon ${AFI_CONF_MOUNTPOINT}/swap_deleteme

        # install linux
        AFI_DEBUG "Cleaning pacman cache"
        sudo pacman --noconfirm -Sc
        AFI_DEBUG "Updating pacman database"
        sudo pacman --noconfirm -Syy
        AFI_DEBUG "Installing linux in ${AFI_CONF_MOUNTPOINT}"
        sudo pacstrap ${AFI_CONF_MOUNTPOINT} ${AFI_CONF_S2_PKGS[*]}

        # create fstab
        sudo genfstab -U ${AFI_CONF_MOUNTPOINT} >> ${AFI_CONF_MOUNTPOINT}/etc/fstab

        # configuration required for basic functionality
        AFI_DEBUG "Creating init script ${AFI_CONF_MOUNTPOINT}/init_deleteme"
        sudo printf "#!/bin/bash
## this is the init script from archfox-install, remove it if it somehow wasn't automatically removed after installation

# change host name
printf \"[AFI][chroot]: changing host name\\n\"
printf \"$AFI_CONF_HOSTNAME\" > /etc/hostname

# configure hosts 
printf \"[AFI][chroot]: configuring hosts\\n\"
printf \"\\n127.0.0.1	localhost\\n::1		localhost\\n127.0.1.1	$AFI_CONF_HOSTNAME.localdomain	$AFI_CONF_HOSTNAME\" > /etc/hosts

# set locals
printf \"[AFI][chroot]: configuring and generating locales\\n\"
printf \"\\n## archfox\\n${AFI_CONF_LOCALE} UTF-8\" >> /etc/locale.gen
printf \"LANG=${AFI_CONF_LOCALE}\\nLC_ALL=${AFI_CONF_LOCALE}\\n\" > /etc/locale.conf

# set time
ln -sf /usr/share/zoneinfo/${AFI_CONF_TIMEZONE} /etc/localtime

# create user and change password for user/root
printf \"[AFI][chroot]: creating user, changing user/root passwords\n\"
useradd -m $AFI_CONF_USERNAME
usermod -p \$( printf \"$AFI_CONF_USERPASS\" | openssl passwd -1 -stdin ) $AFI_CONF_USERNAME
usermod -p \$( printf \"$AFI_CONF_ROOTPASS\" | openssl passwd -1 -stdin ) root
sed -i \"106i ${AFI_CONF_USERNAME} ALL=\(ALL:ALL\) ALL\" /etc/sudoers # give user the sudo rights

# create autostart.service
printf \"[AFI][chroot]: creating autostart service\\n\"
printf \"\\n[Unit]\\nDescription=runs /etc/autostart.sh on system boot\\n[Service]\\nExecStart=sh -c /etc/autostart.sh\\n[Install]\\nWantedBy=multi-user.target\" > /etc/systemd/system/autostart.service
printf \"#!/bin/sh\\n\" > /etc/autostart.sh

# configuring bootloader
printf \"[AFI][chroot]: configuring bootloader\\n\"
bootctl --path=/boot install
printf \"timeout	3\\ndefault	$AFI_CONF_HOSTNAME.conf\\n\" > /boot/loader/loader.conf
printf \"title	$AFI_CONF_HOSTNAME\\nlinux	/vmlinuz-linux\\ninitrd	/initramfs-linux.img\\noptions	root=/dev/sda2	rw\\n\" > /boot/loader/entries/$AFI_CONF_HOSTNAME.conf

# configure pacman and update mirrorlist
printf \"[AFI][chroot]: configuring pacman\\n\"
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
sed -i \"s/#ParallelDownloads.*/ParallelDownloads = 5/\" /etc/pacman.conf
sed -i \"/\[multilib\]/,/Include/\"'s/^#//' /etc/pacman.conf

# update mirrorlist
printf \"[AFI][chroot]: updating mirrorlist\\n\"
curl -v -o /etc/pacman.d/mirrorlist \"https://archlinux.org/mirrorlist/?country=all&protocol=http&protocol=https&ip_version=4\"
sed -i '0,/#Server/s//Server/; 0,/#Server/s//Server/; 0,/#Server/s//Server/' /etc/pacman.d/mirrorlist

# updating packages
printf \"[AFI][chroot]: starting update\\n\"
pacman --noconfirm -Syu archlinux-keyring

# cleaning pacman cache
printf \"[AFI][chroot]: cleaning pacman cache\\n\"
{
    printf \"y\\n\" && 
    printf \"y\\n\" 
} | pacman -Scc

printf \"[AFI][chroot]: enabling services\\n\"
systemctl enable NetworkManager.service
systemctl enable autostart.service

hwclock --systohc
locale-gen

printf \"[AFI][chroot]: Exitting the chroot environment\\n\"
 " > ${AFI_CONF_MOUNTPOINT}/init_deleteme
        sudo chmod +x ${AFI_CONF_MOUNTPOINT}/init_deleteme

        # run init script in chroot
        AFI_DEBUG "Entering the chroot environment"
        sudo arch-chroot ${AFI_CONF_MOUNTPOINT} /bin/bash /init_deleteme

        AFI_DEBUG "Cleaning..."
        # delete init script
        sudo rm -f ${AFI_CONF_MOUNTPOINT}/init_deleteme

        # delete swap
        sudo swapoff ${AFI_CONF_MOUNTPOINT}/swap_deleteme
        sudo rm -f ${AFI_CONF_MOUNTPOINT}/swap_deleteme

        # umount disk
        if [ "$AFI_CONF_AUTOUMOUNT" == true ]; then
            AFI_DEBUG "Umounting partitions from ${AFI_CONF_MOUNTPOINT}"
            sudo umount ${AFI_CONF_MOUNTPOINT}/boot # umount BOOT from /mnt/boot
            sudo umount ${AFI_CONF_MOUNTPOINT} # umount ROOT from /mnt
        fi

    else
        AFI_DEBUG "S2: Running in demo mode, skipping..."
    fi
    AFI_DEBUG "AFI_S2: done."
}

## ==================== S3 ===============================================
# install ArchFox, system configuration, apply configuration files, install additional packages, run profile installation
AFI_S3 () {
    AFI_DEBUG "triggering AFI_S3"
    if [ "$AFI_CONF_DEMO" == false ]; then
        if [ "$(sudo whoami)" != "root" ]; then 
            AFI_ERROR "S3: Root privileges are required to run this function."
            exit 10
        fi
        AFI_INFO "This function is currently under development."

    else
        AFI_DEBUG "S3: Running in demo mode, skipping..."
    fi
    AFI_DEBUG "AFI_S3: done."
}





## ==================== Help =============================================
AFI_HELP () {
    AFI_DEBUG "triggering AFI_HELP"
    # get changelog
    cd $AFI_VAR_PWD
    AFI_TEMP_CHANGELOG=()
    if [[ ! -f "changelog.txt" ]]; then
        AFI_ERROR "changelog.txt does not exists.";
    else
        while IFS= read -r line; do
            if [[ $line == "  "* ]]; then
                AFI_TEMP_CHANGELOG+="    ┃ $line\n"
            else
                AFI_TEMP_CHANGELOG+="    ┣ $line\n"
            fi
        done < changelog.txt
    fi
    AFI_TEMP_CHANGELOG="${AFI_TEMP_CHANGELOG%\\n}" # delete last \n
    AFI_TEMP_CHANGELOG="${AFI_TEMP_CHANGELOG%┣ *}┗ ${AFI_TEMP_CHANGELOG##*┣ }" # change last "┣" to "┗"
    AFI_TEMP_A=${AFI_TEMP_CHANGELOG%┗*} # store all points except last      < start ; line with "┗" )
    AFI_TEMP_B="┗${AFI_TEMP_CHANGELOG##*┗}" # store last point              < line with "┗" ; end >
    AFI_TEMP_B="${AFI_TEMP_B//┃ /  }" # change all "┃" to "  " in AFI_TEMP_B
    AFI_TEMP_CHANGELOG="${AFI_TEMP_A}${AFI_TEMP_B}\n" # combine both parts
    unset AFI_TEMP_A
    unset AFI_TEMP_B

#    # make profile list
#    cd $AFI_VAR_PFDIR
#    AFI_TEMP_PROFILES=()
#    for folder in *; do
#        if [[ -d "$folder" ]]; then
#            if [[ ! -f "$folder/init.sh" ]]; then
#                AFI_WARN "The $folder profile does not contain a init.sh file"; continue;
#            fi
#            # check files
#            if [[ -f "$folder/description.txt" ]]; then AFI_TEMP_DESFILE=description.txt
#            elif [[ -f "$folder/README.md" ]]; then AFI_TEMP_DESFILE=README.md
#            else AFI_TEMP_DESFILE="null"
#            fi
#            # print description
#            fill=$(printf "%0.s┈" $(seq 1 $(( 135 - ${#folder} - ${#AFI_TEMP_DESFILE} - 8)) ))
#            AFI_TEMP_TEXT="$(printf "    ${folder} ${fill} (${AFI_TEMP_DESFILE})")\n"
#
#            if [ $AFI_TEMP_DESFILE != "null" ]; then
#                while IFS= read -r line || [[ -n "$line" ]]; do
#                    AFI_TEMP_TEXT+="      ┃ $line\n"
#                done < "$folder/$AFI_TEMP_DESFILE"
#                AFI_TEMP_TEXT="$(printf "$AFI_TEMP_TEXT" | sed '$ s/      ┃/      ╹/')\n"
#            #else AFI_TEMP_TEXT+="      ╹ This profile does not contain a description.txt or README.md file\n"
#            fi
#            AFI_TEMP_PROFILES+=$AFI_TEMP_TEXT
#        fi
#    done
#    unset AFI_TEMP_TEXT
#    unset AFI_TEMP_DESFILE

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

NAME
    ArchFox-Install by: ${AFI_AUTHOR}

DESCRIPTION
    ArchFox is based on Arch Linux, as if that wasn't obvious.
    installator modes:
      ┣ demo    ━ demo installation, test of the automatic configuration, no wipe, delete or install command will be executed.
      ┣ null    ━ just exit, created mainly to test flags/configuration.
      ┣ main    ━ fully automatic installation, just select disk, configure what you want 
      ┃           on your system (or not) and wait for the script to finish. 
      ┣ S0      ━ preparation, files validation, 
      ┣ S1      ━ prepare the selected disk (format, create partitions, make filesystem).
      ┣ S2      ━ install packages required for system and basic functionality to work,
      ┃           add user, change passwords for user and root, copy configuration,
      ┃           copy the installer to the /root directory for further configuration/installation (can be disabled in custom profile).
      ┗ S3      ━ apply configuration, install additional packages e.g. window/desktop enviroment,
                  login manager, file manager, terminal emuletor, and other apps.
    ArchFox can also be installed on an existing Arch Linux installation, just run S3 mode.
    After installing ArchFox, the installer can be found in /root/archfox-install for easy modifications, e.g.
    install an additional window/desktop environment, apply additional configuration.

OPTIONS
    command [flags]
     ┣ --help       -h  ━ show this help list and exit.
     ┃ ┗ noexit         ━ you can add this argument after this flag to cancel program exit.
     ┣ --mode       -m  ━ change mode of installation (default: main).
     ┃ ┗*mode           ━ enter the mode in which you want to run the installer [main S1 S2 S3 demo null].
     ┣ --conf-file  -c  ━ config file from which the settings will be imported.
     ┃ ┗ file           ━ configuration file path/name.
     ┣ --auto       -a  ━ automatically selects the default option at every stage of system installation,
     ┃                    except for the installer configuration, of course.
     ┣ --default    -d  ━ run the installer with the default configuration.
     ┣ --verbose    -V  ━ display debug info.
     ┣ --ignore     -I  ━ ignore warns.
     ┣ --nochecksum -N  ━ skip checksum verification.    
     ┣ --colors     -C  ━ turn off colors or change color mode by specifying the mode.
     ┃ ┗ mode*          ━ color mode [8 16 256], \"true\" to select automatically or \"false\" to disable.
     ┗ --dev        -D  ━ run color debug test, and installator in demo mode. (overrides all other flags).
       ┗ noexit         ━ you can add this argument after this flag to cancel program exit.

SYNTAX
    command [flags]
      ┗ --example   -e  ━ this is not a real flag, its just a example to show the syntax.   (\"-e\" or \"--example\")
        ┣*args          ━ this is an required argument of flag, you can add it after flag   (-e args)
        ┗ args          ━ this is an optional argument of flag, you can add it after flag   (-e args)
    examples:
      ┃ # this command will run fully automatic install with additional debug info, and no colors.
      ┃ # make sure you enter the correct drive in the configuration at the top of script file to avoid wiping the wrong drive.
      ┣ command -vdaC false -m full
      ┃ # this command will run debug command, display color test and run demo install.
      ┣ command --dev
      ┃ # this command will run semi-automatic install, with additional debug info, and enabled colors.
      ┗ command -vC true -m full
    this script has a custom flag resolver where you can insert flags as follows (the order doesn't matter):
      ┣ command -abg
      ┣ command -a -b -g
      ┗ command --alpha --beta --gamma
    flag arguments are strings from a given flag to the next flag that do not start with "-" or "--"
    changelog
    <version> <date>:
      # comment
      + added
      - removed
      = changed/modified/fixed

PROFILES
    [in development]

CHANGELOG
$AFI_TEMP_CHANGELOG

\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n
HELLO THERE
\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n
STF; you want linux, dont you?
" | vim -c 'map <Esc> :q!<CR>' -R -M -m -
    unset AFI_TEMP_CHANGELOG
    AFI_DEBUG "AFI_HELP: done."
}

## ==================== Dev function =====================================
AFI_DEV () {
    AFI_DEBUG "triggering AFI_DEV"
    printf "running in $AFI_VAR_CMODE color(s) mode.\n"
    AFI_TEMP_WIDTH=$(tput cols || printf "80\n");
    AFI_TEMP_HEIGHT=$(tput lines || printf "40\n")


    AFI_TEMP_STRING="==================== 16 colors (3-bit/4-bit) test ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING})));printf "\n"
    color () {
        AFI_TEMP_LENGHT=$(($AFI_TEMP_WIDTH / 36)); for c; do printf "[38;5;%dm%*d" $c ${AFI_TEMP_LENGHT} $c; done; printf '[0m\n'; unset AFI_TEMP_LENGHT
    }
    color {0..15}

    AFI_TEMP_STRING="==================== 256 colors (8-bit) test ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING}))); printf "\n"
    for ((i=0;i<6;i++)); do color $(seq $((i*36+16)) $((i*36+51))); done
    color {232..255}

    AFI_TEMP_STRING="==================== true color (16-bit/24-bit) test ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING}))); printf "\n"
    # RED
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # R +G
        R=255;G=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));B=0; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # R +BG
        R=255;G=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));B=$G; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # R +B
        R=255;G=0;B=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100)); printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # -R
        R=$((255 - col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));G=0;B=0; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '[0m\n'
    #GREEN
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # G + R
        G=255;R=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));B=0; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # G + RB
        G=255;R=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));B=$R; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # G + B
        G=255;R=0;B=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100)); printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # -G
        G=$((255 - col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));R=0;B=0; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '[0m\n'
    #BLUE
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # B + R
        B=255;G=0;R=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100)); printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # B + GR
        B=255;G=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));R=$G; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # B + G
        B=255;G=$((col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));R=0; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # -B
        B=$((255 - col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));G=0;R=0; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '[0m\n'
    
    if [ "$AFI_CONF_RAINBOW" != false ]; then
        AFI_TEMP_STRING="==================== RAINBOW, because I'm bored ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING}))); printf "\n"
        AFI_TEMP_RGB_LENGTH=$((AFI_TEMP_WIDTH * $(($AFI_TEMP_HEIGHT-38))))
        if [ "$AFI_TEMP_RGB_LENGTH" -le 0 ]; then AFI_TEMP_RGB_LENGTH=$AFI_TEMP_WIDTH; fi
        for (( i = 0; i < AFI_TEMP_RGB_LENGTH; i++ )); do
            if (( i < AFI_TEMP_RGB_LENGTH/6 )); then        # G = 255
                AFI_TEMP_R=255
                AFI_TEMP_G=$(( 255 * 6 * i / AFI_TEMP_RGB_LENGTH ))
                AFI_TEMP_B=0
            elif (( i < 2*AFI_TEMP_RGB_LENGTH/6 )); then    # R = 0
                AFI_TEMP_R=$(( 255 - 255 * 6 * (i - AFI_TEMP_RGB_LENGTH/6) / AFI_TEMP_RGB_LENGTH ))
                AFI_TEMP_G=255
                AFI_TEMP_B=0
            elif (( i < 3*AFI_TEMP_RGB_LENGTH/6 )); then    # B = 255
                AFI_TEMP_R=0
                AFI_TEMP_G=255
                AFI_TEMP_B=$(( 255 * 6 * (i - 2*AFI_TEMP_RGB_LENGTH/6) / AFI_TEMP_RGB_LENGTH ))
            elif (( i < 4*AFI_TEMP_RGB_LENGTH/6 )); then    # G = 0
                AFI_TEMP_R=0
                AFI_TEMP_G=$(( 255 - 255 * 6 * (i - 3*AFI_TEMP_RGB_LENGTH/6) / AFI_TEMP_RGB_LENGTH ))
                AFI_TEMP_B=255
            elif (( i < 5*AFI_TEMP_RGB_LENGTH/6 )); then    # R = 255
                AFI_TEMP_R=$(( 255 * 6 * (i - 4*AFI_TEMP_RGB_LENGTH/6) / AFI_TEMP_RGB_LENGTH ))
                AFI_TEMP_G=0
                AFI_TEMP_B=255
            else                                            # B = 0
                AFI_TEMP_R=255
                AFI_TEMP_G=0
                AFI_TEMP_B=$(( 255 - 255 * 6 * (i - 5*AFI_TEMP_RGB_LENGTH/6) / AFI_TEMP_RGB_LENGTH ))
            fi
            # Fix Color Range
            AFI_TEMP_R=$(( AFI_TEMP_R < 0 ? 0 : (AFI_TEMP_R > 255 ? 255 : AFI_TEMP_R) ))
            AFI_TEMP_G=$(( AFI_TEMP_G < 0 ? 0 : (AFI_TEMP_G > 255 ? 255 : AFI_TEMP_G) ))
            AFI_TEMP_B=$(( AFI_TEMP_B < 0 ? 0 : (AFI_TEMP_B > 255 ? 255 : AFI_TEMP_B) ))
            # Print Color
            printf "\e[38;2;%d;%d;%dm" "$AFI_TEMP_R" "$AFI_TEMP_G" "$AFI_TEMP_B" # foreground
            printf "\e[48;2;%d;%d;%dm" "$AFI_TEMP_R" "$AFI_TEMP_G" "$AFI_TEMP_B" # background
            printf "%s[0m" " " # print char
            if ((i % AFI_TEMP_WIDTH == AFI_TEMP_WIDTH - 1)); then printf "\n"; fi
        done
        unset AFI_TEMP_RGB_LENGHT
    fi
    
    ## ==================== output =======================================
    AFI_TEMP_STRING="==================== output test ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING}))); printf "\n"
    AFI_INFO "AFI_INFO PRINT TEST"
    AFI_DEBUG "AFI_DEBUG PRINT TEST"
    AFI_WARN "AFI_WARN PRINT TEST"
    AFI_ERROR "AFI_ERROR PRINT TEST"
    
    printf "\n"

    unset AFI_TEMP_STRING
    unset AFI_TEMP_WIDTH
    unset AFI_TEMP_HEIGHT

    AFI_DEBUG "AFI_DEV: done."
}

## ==================== Update Color Sheme ===============================
AFI_UpdateCS () {
    AFI_DEBUG "triggering AFI_UpdateCS"
    if [ $AFI_CONF_COLORS == true ]; then # if colors are enabled
        AFI_TEMP_COLORS=$(tput colors)
        case "${AFI_TEMP_COLORS}" in 
            8) # 3-bit color mode
                AFI_VAR_CMODE=8; AFI_VAR_PREFIX="[38;5;7m[[38;5;6mA[38;5;3mF[38;5;7mI]" ;;
            16) # 4-bit color mode
                AFI_VAR_CMODE=16; AFI_VAR_PREFIX="[38;5;15m[[38;5;12mA[38;5;14mF[38;5;15mI]" ;;
            256) # 8-bit color mode
                AFI_VAR_CMODE=256; AFI_VAR_PREFIX="[38;5;231;1m[[38;5;39;1mA[38;5;202;1mF[38;5;231;1mI]" ;;
            *)
                AFI_VAR_CMODE=null; AFI_VAR_PREFIX="[AFI]" ;;
        esac
        unset AFI_TEMP_COLORS
        AFI_VAR_INFO_PREFIX="[38;5;10;1m[INFO][0m: "
        AFI_VAR_DEBUG_PREFIX="[38;5;12;1m[DEBUG][0m:"
        AFI_VAR_WARN_PREFIX="[38;5;11;1m[WARN][0m: "
        AFI_VAR_ERROR_PREFIX="[38;5;9;1m[ERROR][0m:"
    else # if colors are disabled
        AFI_CONF_COLORS=false
        AFI_VAR_CMODE=1 # 1-bit color mode
        AFI_VAR_PREFIX="[AFI]"
        AFI_VAR_INFO_PREFIX="[INFO]: "
        AFI_VAR_DEBUG_PREFIX="[DEBUG]:"
        AFI_VAR_WARN_PREFIX="[WARN]: "
        AFI_VAR_ERROR_PREFIX="[ERROR]:"
    fi
    AFI_DEBUG "AFI_UpdateCS: done."
}

## ==================== validation =======================================
AFI_VALIDATE () {
    if [ "$AFI_VAR_VALIDATED" == true ]; then
        AFI_INFO "validation: Files have already been verified, skipping..."
    fi
    
    ## file validation
    AFI_INFO "validation: File integrity check."
    cd $AFI_VAR_PWD; AFI_TEMP_ERROR=false
    if [ -f "archfox-install.sh" ]; then # archfox-instal.sh
        AFI_DEBUG "validation: file 'archfox-install.sh' exists."
    else 
        AFI_WARN "validation: file 'archfox-install.sh' does not exist,\n make sure you run this script in the same folder as the script."; AFI_TEMP_ERROR=true
    fi
    if [ "$AFI_TEMP_ERROR" == true ]; then AFI_ERROR "validation: failed."; exit 5; fi # Error status check
    
    ## checksum verification
    AFI_INFO "validation: Verifying the checksum."
    printf "Checksum validation has not yet been implemented, sorry...\n"
    
    ## config validation
    AFI_INFO "validation: Verifying the config settings."
    printf "Config validation has not yet been implemented, sorry...\n"

    AFI_INFO "validation: succesfull."
    unset AFI_TEMP_ERROR
    AFI_VAR_VALIDATED=true
}

## ==================== config file handling =============================
# AFI_CONF_XXX *<path> *<varname> <content>
AFI_CONF_SET () {
    local AFI_TEMP_A="$1"; shift # get file path
    local AFI_TEMP_B="$1"; shift # get variable name
    if grep -q "^${AFI_TEMP_B}=" "$AFI_TEMP_A"; then 
        sed -i "s/^${AFI_TEMP_B}=.*/${AFI_TEMP_B}=\"$@\"/" "$AFI_TEMP_A" # if the variable exists, replace its contents
    else
        echo "$AFI_TEMP_B=\"$@\"" >> "$AFI_TEMP_A" # if the variable does not exist, create it at the end of the file
    fi
}

AFI_CONF_GET () {
    echo "$(grep "^$2=" "$1" | cut -d'=' -f2- | tr -d '"')"
}

AFI_CONF_DEL () {
    if grep -q "^$2=" "$1"; then sed -i "/^$2=/d" "$1"; fi
}

## ==================== output handling ==================================
AFI_INFO () {
    printf "${AFI_VAR_PREFIX}${AFI_VAR_INFO_PREFIX} ${1}[0m\n";
}
AFI_DEBUG () {
    if [ "$AFI_CONF_VERBOSE" == true ]; then printf "${AFI_VAR_PREFIX}${AFI_VAR_DEBUG_PREFIX} ${1}[0m\n"; fi
}
AFI_WARN () {
    if [ "$AFI_CONF_IGNORE" == false ]; then printf "${AFI_VAR_PREFIX}${AFI_VAR_WARN_PREFIX} ${1}[0m\n"; fi
}
AFI_ERROR () {
    printf "${AFI_VAR_PREFIX}${AFI_VAR_ERROR_PREFIX} ${1}[0m\n";
}



### =================================================================================================================================================
### ==================== MAIN =======================================================================================================================
### =================================================================================================================================================

## ==================== set color sheme ==================================
AFI_UpdateCS

## ==================== flag parser ======================================
# Parse arguments, eg: [-abc --dir hello -pl] > [-a -b -c --dir hello -p -l]
AFI_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --*)
            AFI_ARGS+=("$1"); shift ;;
        -*) 
            for ((i = 1; i < ${#1}; i++)); do
                char="${1:$i:1}"; if [[ $char != - ]]; then AFI_ARGS+=("-$char"); fi; unset char
            done; shift ;;
        *)  
            AFI_ARGS+=("$1"); shift ;;
    esac
done

## ==================== flag resolver ====================================
# Extract flags from each other, eg: [ -a my code -b is really working ] > [ -a my code ] [ -b is really working ]
AFI_INDEX=0
while [[ $AFI_INDEX -lt ${#AFI_ARGS[@]} ]]; do
    # save current flag to temp array, eg: [ -a ]
        AFI_TEMP_FLAG=(); AFI_TEMP_FLAG+=("${AFI_ARGS[$AFI_INDEX]}"); ((AFI_INDEX++))

    # get flag's args, eg: [ -a my code ]
        while [[ 
            $AFI_INDEX -lt ${#AFI_ARGS[@]} && # check if position exists
            ${AFI_ARGS[$AFI_INDEX]} != -* || # return if its another flag
            ${AFI_ARGS[$AFI_INDEX]} == ---* # pass if its starting with "---*"
        ]]; do
            AFI_TEMP_FLAG+=("${AFI_ARGS[$AFI_INDEX]}"); ((AFI_INDEX++))
        done

    # execute flag with its args
        case "${AFI_TEMP_FLAG[0]}" in
            # main flags
            -h|--help)
                AFI_DEBUG "inserted --help (-h) flag, program will exit after showing help list"
                AFI_HELP
                case "${AFI_TEMP_FLAG[1]}" in
                    [0NnFf]* )
                        AFI_INFO "inserted --help flag with "NoExit" parameter."; read -s -n 1 -p "press any key to resume the installer..." ;;
                    *) 
                        exit 0 ;;
                esac ;;
            -m|--mode) # ============================= MODE
                case "${AFI_TEMP_FLAG[1]}" in
                    [Mm]|[Ss][Mm] ) # main install
                        AFI_CONF_MODE="main" ;;
                    0|[Ss]0 ) # S0 only
                        AFI_CONF_MODE="S0" ;;
                    1|[Ss]1 ) # S1 only
                        AFI_CONF_MODE="S1" ;;
                    2|[Ss]2 ) # S2 only
                        AFI_CONF_MODE="S2" ;;
                    3|[Ss]3 ) # S3 only
                        AFI_CONF_MODE="S3" ;;
                    [Dd]* ) # dev mode
                        AFI_CONF_MODE="dev" ;;
                    [Nn]* ) # null (just exit)
                        AFI_CONF_MODE="null" ;;
                esac
                AFI_DEBUG "inserted --mode (-m) flag, installator mode is set to: ${AFI_CONF_MODE}" ;;
            -c|--conf-file)
                cd $AFI_VAR_PWD
                if [ -f "${AFI_TEMP_FLAG[1]}" ]; then
                    AFI_DEBUG "imported config from: ${AFI_TEMP_FLAG[1]}"
                    AFI_CONF_FILE=${AFI_TEMP_FLAG[1]}
                else 
                    AFI_DEBUG "config import failed: ${AFI_TEMP_FLAG[1]} file dosnt exists."
                fi ;;
            -a|--auto) # ============================= AUTO
                AFI_DEBUG "inserted --auto (-a) flag, all choices will be done automatically."; AFI_CONF_AUTO=true ;;
            -d|--default) # ========================== DEFAULT
                AFI_DEBUG "inserted --default (-d) flag, installation will be started with default settings."; AFI_CONF_DEFAULT=true ;;
            -D|--demo) # ================================= DEV
                AFI_DEBUG "inserted --demo (-D) flag, the installer will run in demo mode."; AFI_CONF_DEMO=true ;;
            -V|--verbose) # ========================== VERBOSE
                AFI_CONF_VERBOSE=true; AFI_DEBUG "inserted --verbose (-V) flag, from this point on, debugging information will be displayed." ;;
            -I|--ignore) # ========================== IGNORE
                AFI_CONF_IGNORE=true; AFI_DEBUG "inserted --ignore (-I) flag, from now on warnings will not be displayed." ;;
            
            # unknown flags
            ---*)
                AFI_ERROR "Error while resolving flags: arguments without flag: ${AFI_TEMP_FLAG[*]}" ;;
            -*|--*)
                AFI_WARN "unknown flag: ${AFI_TEMP_FLAG[*]}" ;;
            *)  
                AFI_ERROR "Error while resolving flags: arguments without flag: ${AFI_TEMP_FLAG[*]}" ;;
        esac
        unset AFI_TEMP_FLAG # clean TEMP
done

## ==================== trigger installator mode =========================
case "${AFI_CONF_MODE}" in
    main )
        AFI_MAIN ;;
    S0 )
        AFI_S0 ;;
    S1 )
        AFI_S1 ;;
    S2 )
        AFI_S2 ;;
    S3 )
        AFI_S3 ;;
    dev )
        AFI_DEV ;;
    null)
        AFI_WARN "mode is set to null, program will exit now..." ;;
    *)
        AFI_ERROR "Error while triggering installator mode, this is an unknown mode: ${AFI_CONF_MODE}"; exit 1
    ;;
esac

## ==================== END, clear all variables =========================
unset $(compgen -v AFI_)
exit 0


# exit codes:
# 0 - no error
# 1 - unknown or undescribed error
# 2 - process aborted by user
# 3 - dev break point (just find the "exit 3" command and delete it)
# 5 - sources validation failed
# 6 - profile not found
# 7 - chosen disk does not exists
# 10 - no sudo permission
#
#
#
#
#








































# github.com: sudoTheFoxis
#!/bin/bash
AFI_VERSION="1.0.3-A"
AFI_AUTHOR=( sudoTheFoxis )



### =================================================================================================================================================
### ==================== CONFIG =====================================================================================================================
### =================================================================================================================================================

# AFI main config
AFI_CONF_MODE=auto              #   installator mode.
AFI_CONF_FILE="afi.conf"        #   config file name.

AFI_CONF_DEFAULT=false          #   don't ask for configuration, use the default one.
AFI_CONF_AUTO=false             #   don't ask for anything, choose the default option (except configuration).
AFI_CONF_DEMO=false             #   run in demo mode (overrides everything)

AFI_CONF_IGNORE=false           #   dont display warn messages.
AFI_CONF_VERBOSE=false          #   display debug info.
AFI_CONF_COLORS=true            #   display colors in terminal? (may fix some visual bugs and/or slightly improve performance)

# default configuration
# S0
AFI_CONF_S0_PKGS=(
    archlinux-keyring
    arch-install-scripts
    dosfstools
    e2fsprogs
    coreutils
    parted
    wipefs
    vim
)
# S1
AFI_CONF_S1_DEV="/dev/sdz"      #   disk that will be used
AFI_CONF_S1_HARDFORMAT=false    #   make hard format (dd if=/dev/zero of=/dev/...)
# S2
AFI_CONF_S2_HOSTNAME="archfox"  #   system/computer name
AFI_CONF_S2_USERNAME="home"     #   user name
AFI_CONF_S2_USERPASS="home"     #   user password
AFI_CONF_S2_ROOTPASS="root"     #   root password
AFI_CONF_S2_PKGS=(              #   packages that will be installed on the S2 stage
    linux
    base
    efibootmgr
    linux-firmware
    networkmanager
    sudo
)
# S3
AFI_CONF_S3_PROFILE="dev"       #   profile that will be installed
AFI_CONF_S3_GPUDRI="none"       #   for what gpu drivers will be installed
AFI_CONF_S3_USEYAY="true"       #   set to true if you want to install aur packages, it will install and use yay pkgmgr
AFI_CONF_S3_PKGS=(              #   packages that will be installed on the S3 stage
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
    wget
    git
    gcc
    # other
    ttf-dejavu
)
# some variables (don't change it if you don't know what it is)
AFI_VAR_PFDIR="profiles"        #   directory of profiles folder
AFI_VAR_RFSDIR="rootfs"         #   directory of rootfs folder
AFI_VAR_VALIDATED=false         #   set to true if you want to skip validation
AFI_VAR_PWD=$PWD                #   path where script runs
AFI_VAR_CMD=$0                  #   script file name

### =================================================================================================================================================
### ==================== FUNCTIONS ==================================================================================================================
### =================================================================================================================================================

# preparation
AFI_S0 () {
    AFI_DEBUG "triggering AFI_S0"  
    if [ "$AFI_CONF_DEMO" == false ]; then
        if [ "$(sudo whoami)" != "root" ]; then 
            AFI_ERROR "S0: Root privileges are required to run this function."
            exit 10
        fi
        # validation
        AFI_VALIDATE  

        sudo pacman --noconfirm -Syu ${AFI_CONF_S0_PKGS[*]}

    else
        AFI_DEBUG "S0: Running in demo mode, skipping..."
    fi
    AFI_DEBUG "AFI_S0: done."
}

# disk init, prepare disk for system installation
AFI_S1 () {
    AFI_DEBUG "triggering AFI_S1"
    if [ "$AFI_CONF_DEMO" == false ]; then
        if [ "$(sudo whoami)" != "root" ]; then 
            AFI_ERROR "S1: Root privileges are required to run this function."
            exit 10
        fi
        # validation
        AFI_VALIDATE

        if [ "$AFI_CONF_S1_HARDFORMAT" == true ]; then
            AFI_DEBUG "Starting Hard Format on $AFI_CONF_S1_DEV, this may take a while on large disks"
            sudo dd if=/dev/zero of=$AFI_CONF_S1_DEV bs=16K status=progress
        else
            AFI_DEBUG "Wiping all partition tables on $AFI_CONF_S1_DEV"
            sudo wipefs -a $AFI_CONF_S1_DEV
        fi

        AFI_DEBUG "Creating partitons on $AFI_CONF_S1_DEV"
        sudo parted -s -f -- $AFI_CONF_S1_DEV \
            mklabel gpt \
            mkpart primary 1MiB 257MiB \
            name 1 BOOT \
            set 1 boot on \
            mkpart primary 258MiB -1MiB \
            name 2 ROOT \
            set 2 root on
        # create boot fs
        sudo mkfs.fat -F 32 "${AFI_CONF_S1_DEV}1"
        # craete root fs
        sudo mkfs.ext4 "${AFI_CONF_S1_DEV}2"

    else
        AFI_DEBUG "S1: Running in demo mode, skipping..."
    fi
    AFI_DEBUG "AFI_S1: done."
}

# system installation, install working system with minimal functionality
AFI_S2 () {
    AFI_DEBUG "triggering AFI_S2"
    if [ "$AFI_CONF_DEMO" == false ]; then
        if [ "$(sudo whoami)" != "root" ]; then 
            AFI_ERROR "S2: Root privileges are required to run this function."
            exit 10
        fi
        # validation
        AFI_VALIDATE

        AFI_DEBUG "Mounting partitions in /mnt"
        # mount ROOT on /mnt
        sudo mkdir /mnt && sudo mount "${AFI_CONF_S1_DEV}2" /mnt
        # mount BOOT on /mnt/boot
        sudo mkdir /mnt/boot && sudo mount "${AFI_CONF_S1_DEV}1" /mnt/boot
        # install linux
        sudo pacman --noconfirm -Syu
        sudo pacstrap -U /mnt ${AFI_CONF_S2_PKGS[*]}

        # basic configuration
        AFI_DEBUG "Entering the chroot environment"
        sudo chroot /mnt bash -c "# change host name
printf \"[AFI-chroot]: changing host name\\n\"
printf \"$AFI_CONF_S2_HOSTNAME\" > /etc/hostname

# configure hosts 
printf \"[AFI-chroot]: configuring hosts\\n\"
printf \"127.0.0.1	localhost\\n::1		localhost\\n127.0.1.1	$AFI_CONF_S2_HOSTNAME.localdomain	$AFI_CONF_S2_HOSTNAME\" > /etc/hosts

# set locals
printf \"[AFI-chroot]: configuring and generating locales\\n\"
printf \"#archfox\\nen_US.UTF-8\\npl_PL.UTF-8\" >> /etc/locale.gen
printf \"LANG=en_US.UTF-8\\nLC_ALL=en_US.UTF-8\" > /etc/locale.conf
locale-gen

# create user and change password for user/root
printf \"[AFI-chroot]: creating user, changing user/root passwords\\n\"
useradd -m $AFI_CONF_S2_USERNAME
usermod -p $( printf "$AFI_CONF_S2_USERPASS" | openssl passwd -1 -stdin ) $AFI_CONF_S2_USERNAME
usermod -p $( printf "$AFI_CONF_S2_ROOTPASS" | openssl passwd -1 -stdin ) root
# give user the sudo rights
sed -i \"106i ${AFI_CONF_S2_USERNAME} ALL=(ALL:ALL) ALL\" /etc/sudoers

# configuring bootloader
printf \"[AFI-chroot]: configuring bootloader\\n\"
bootctl --path=/boot install
printf \"timeout	3\\ndefault	$AFI_CONF_S2_HOSTNAME.conf\" > /boot/loader/loader.conf
printf \"title	$AFI_CONF_S2_HOSTNAME\\nlinux	/vmlinuz-linux\\ninitrd	/initramfs-linux.img\\noptions	root=/dev/sda2	rw\" > /boot/loader/entries/$AFI_CONF_S2_HOSTNAME.conf

# screate service file
printf \"[AFI-chroot]: creating autostart service\\n\"
printf \"[Unit]\\nDescription=Running /etc/autostart.sh on system boot\\nConditionPathExists=/etc/autostart.sh\\n\\n[service]\\nExecStart=/bin/bash /etc/autostart.sh\\n[Install]\\nWantedBy=multi-user.target\" > /etc/systemd/system/autostart.service
# create script file
printf \"#!/bin/bash\\n \" > /etc/autostart.sh

# updating packages
printf \"[AFI-chroot]: starting update\\n\"
pacman --noconfirm -Syu archlinux-keyring

printf \"[AFI-chroot]: Exitting the chroot environment\"
"
        AFI_DEBUG "copying installator files to /root"
        # copying installator files
        cd $AFI_VAR_PWD
        sudo mkdir -p /mnt/root/archfox-install
        sudo cp -r * /mnt/root/archfox-install

        AFI_DEBUG "Umounting partitions from /mnt"
        # umount BOOT from /mnt/boot
        sudo umount /mnt/boot
        # umount ROOT from /mnt
        sudo umount /mnt

    else
        AFI_DEBUG "S2: Running in demo mode, skipping..."
    fi
    AFI_DEBUG "AFI_S2: done."
}

# system configuration, apply configuration files, install additional packages eg. desktop enviroment
AFI_S3 () {
    AFI_DEBUG "triggering AFI_S3"
    if [ "$AFI_CONF_DEMO" == false ]; then
        if [ "$(sudo whoami)" != "root" ]; then 
            AFI_ERROR "S3: Root privileges are required to run this function."
            exit 10
        fi
        # validation
        AFI_VALIDATE

        # check if chosen profile exists
        cd $AFI_VAR_PWD
        if [ ! -d "$AFI_VAR_PFDIR/$AFI_CONF_S3_PROFILE" ]; then
            AFI_ERROR "The selected profile does not exist: ./$AFI_VAR_PFDIR/$AFI_CONF_S3_PROFILE"
            exit 1;
        else
            if [ ! -f "$AFI_VAR_PFDIR/$AFI_CONF_S3_PROFILE" ]; then
                AFI_ERROR "The selected profile does not have a init.sh file: ./$AFI_VAR_PFDIR/$AFI_CONF_S3_PROFILE"
                exit 1;
            fi
        fi

        if [ ! -f /etc/archfox.ver ]; then
            # make backup of some files
            AFI_DEBUG "Making backups of some files"
            if [ -d "/etc/skel" ]; then sudo mv /etc/skel /etc/skel.bak; fi
            sudo mv /etc/pacman.conf /etc/pacman.conf.bak
            sudo mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

            # apply basic config files
            AFI_DEBUG "Applying config files/themes to the system from: ${AFI_VAR_PWD}/${AFI_VAR_RFSDIR}"
            cd $AFI_VAR_PWD
            cd $AFI_VAR_RFSDIR
            sudo cp -vfr ./etc/* /etc
            sudo cp -vfr ./usr/* /usr

            # applying conf files to user
            if [ "$(whoami)" == "root" ]; then 
                AFI_WARN "The script was run by root, the configuration files could not be applied.\nYou must manually copy the files from the \etc\skel folder to the user's home directory to apply the user-specific configuration."
            else
                AFI_DEBUG "Applying config files for user $(whoami)"
                AFI_TEMP_USERDIR=$(/bin/sh -c "echo ~$(whoami)")
                if [ "$AFI_TEMP_USERDIR" != /home/* ]; then 
                    AFI_WARN "Unable to find home directory, the configuration files could not be applied.\nYou must manually copy the files from the \etc\skel folder to the user's home directory to apply the user-specific configuration."
                else
                    cd $AFI_TEMP_USERDIR
                    if [ -f ".config/neofetch/config.conf" ]; then mv -vf .config/neofetch/config.conf .config/neofetch/config.conf.bak; fi
                    if [ -f ".config/.gtkrc-2.0" ]; then mv -vf .config/.gtkrc-2.0 .config/.gtkrc-2.0.bak; fi
                    if [ -f ".gtkrc-2.0" ]; then mv -vf .gtkrc-2.0 .gtkrc-2.0.bak; fi
                    if [ -f ".zshrc" ]; then mv -vf .zshrc .zshrc.bak; fi
                    cp -vfr /etc/skel/* .
                fi
            fi
            sudo echo $AFI_VERSION > /etc/archfox.ver
        else
            AFI_WARN "Existing ArchFox installation detected, skipping.\nremove /etc/archfox.ver if you still want to continue"
        fi

        # install graphics drivers
        AFI_DEBUG "Installing selected GPU drivers"
        case "${AFI_CONF_S3_GPUDRI}" in
            "none" )
                AFI_INFO "The selected GPU driver for install is none, skipping.";;
            "intel" )
                sudo pacman --noconfirm -Syu mesa xf86-video-intel ;;
            "nvidia" )
                sudo pacman --noconfirm -Syu nvidia nvidia-utils ;;
            "nvidia-open" )
                sudo pacman --noconfirm -Syu nvidia-open nvidia-utils ;;
            "amd" )
                sudo pacman --noconfirm -Syu mesa xf86-video-amdgpu ;;
            "vmware" )
                sudo pacman --noconfirm -Syu mesa xf86-input-vmmouse xf86-video-vmware ;;
            #"noveau" )
            #    sudo pacman --noconfirm -Syu
            #    ;;
            * )
                AFI_ERROR "This installation script does not support the installation of this GPU driver: $AFI_CONF_S3_GPUDRI." ;;
        esac

        # install packages
        if [ "$AFI_CONF_S3_USEYAY" == true ]; then
            if [[ "$(yay --version)" != yay* ]]; then
                AFI_DEBUG "Installing yay"
                cd $AFI_VAR_PWD
                mkdir temp && cd temp
                git clone https://aur.archlinux.org/yay.git && cd yay
                makepkg -LAsif --noconfirm
                cd $AFI_VAR_PWD
            fi
            AFI_DEBUG "Installing additional packages via yay"
            yay --noconfirm -Syu ${AFI_CONF_S3_PKGS[*]}
        else
            AFI_DEBUG "Installing additional packages via pacman"
            sudo pacman --noconfirm -Syu ${AFI_CONF_S3_PKGS[*]}
        fi

        # run profile install script
        cd $AFI_VAR_PWD
        cd $AFI_VAR_PFDIR
        if [ -d "$AFI_CONF_S3_PROFILE" ]; then cd $AFI_CONF_S3_PROFILE; fi
        if [[ ! -x "init.sh" ]]; then
            if [[ ! -f "init.sh" ]]; then
                AFI_ERROR "File init.sh not found inside $(pwd)"
            else
                while true; do
                    AFI_WARN "The init.sh file is not executable"
                    read -r AFI_TEMP_INPUT -p "do you want to give execute permission and continue? (y/n): "
                    case "$AFI_TEMP_INPUT" in
                        [Yy1Tt]* )
                            sudo chmod +x init.sh; break ;;
                        [Nn0]* )
                            exit 2 ;;
                        * )
                            printf "This is not a valid choice: ${AFI_TEMP_INPUT}\n" ;;
                    esac
                done
            fi
        fi
        AFI_DEBUG "Triggering init.sh file of ${AFI_CONF_S3_PROFILE}/${AFI_CONF_S3_PROFILE}"
        exec ./init.sh

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

    # make profile list
    cd $AFI_VAR_PFDIR
    AFI_TEMP_PROFILES=()
    for folder in *; do
        if [[ -d "$folder" ]]; then
            if [[ ! -f "$folder/init.sh" ]]; then
                AFI_WARN "The $folder profile does not contain a init.sh file"; continue;
            fi
            # check files
            if [[ -f "$folder/description.txt" ]]; then AFI_TEMP_DESFILE=description.txt
            elif [[ -f "$folder/README.md" ]]; then AFI_TEMP_DESFILE=README.md
            else AFI_TEMP_DESFILE="null"
            fi
            # print description
            fill=$(printf "%0.s┈" $(seq 1 $(( 135 - ${#folder} - ${#AFI_TEMP_DESFILE} - 8)) ))
            AFI_TEMP_TEXT="$(printf "    ${folder} ${fill} (${AFI_TEMP_DESFILE})")\n"

            if [ $AFI_TEMP_DESFILE != "null" ]; then
                while IFS= read -r line || [[ -n "$line" ]]; do
                    AFI_TEMP_TEXT+="      ┃ $line\n"
                done < "$folder/$AFI_TEMP_DESFILE"
                AFI_TEMP_TEXT="$(printf "$AFI_TEMP_TEXT" | sed '$ s/      ┃/      ╹/')\n"
            #else AFI_TEMP_TEXT+="      ╹ This profile does not contain a description.txt or README.md file\n"
            fi
            AFI_TEMP_PROFILES+=$AFI_TEMP_TEXT
        fi
    done
    unset AFI_TEMP_TEXT
    unset AFI_TEMP_DESFILE

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
      ┣ auto    ━ fully automatic installation, just select disk, configure what you want 
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
     ┣ --mode       -m  ━ change mode of installation (default: auto).
     ┃ ┗*mode           ━ enter the mode in which you want to run the installer [auto S1 S2 S3 demo null].
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
      - removed
      + added
      = changed/modified

PROFILES
$AFI_TEMP_PROFILES

CHANGELOG
$AFI_TEMP_CHANGELOG

\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n
HELLO THERE
\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n
STF; you want linux, dont you?
" | vim -c 'map <Esc> :q!<CR>' -R -M -m -
    unset AFI_TEMP_PROFLIST
    unset AFI_TEMP_CHANGELOG
    AFI_DEBUG "AFI_HELP: done."
}

## ==================== Dev function =====================================
AFI_DEV () {
    AFI_DEBUG "triggering AFI_DEV"
    printf "running in $(tput colors) color(s) mode.\n"
    AFI_TEMP_WIDTH=$(tput cols || printf "80\n");
    AFI_TEMP_HEIGHT=$(tput lines || printf "40\n")

    ## ==================== colors test ==================================
    AFI_TEMP_STRING="==================== 16 colors (3-bit/4-bit) test ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING})));printf "\n"
    color () {
        AFI_TEMP_LENGHT=$(($AFI_TEMP_WIDTH / 36))
        for c; do printf "[38;5;%dm%*d" $c ${AFI_TEMP_LENGHT} $c; done
        printf '[0m\n'; unset AFI_TEMP_LENGHT
    }
    color {0..15}
    AFI_TEMP_STRING="==================== 256 colors (8-bit) test ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING}))); printf "\n"
    for ((i=0;i<6;i++)); do color $(seq $((i*36+16)) $((i*36+51))); done
    color {232..255}
    AFI_TEMP_STRING="==================== true color (16-bit/24-bit) test ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING}))); printf "\n"
    # ==================== RGB fade test
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # RED
        R=$((255 - col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));G=0;B=0; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # GREEN
        G=$((255 - col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));R=0;B=0; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '[0m\n'
    for ((col = 0; col < AFI_TEMP_WIDTH; col++)); do # BLUE
        B=$((255 - col * $((255 * 100 / AFI_TEMP_WIDTH)) / 100));G=0;R=0; printf '[38;2;%s;%s;%sm' "$R" "$G" "$B"; printf '[48;2;%s;%s;%sm ' "$R" "$G" "$B"
    done; printf '[0m\n'
    # ==================== RGB transition test
    AFI_TEMP_RGB_LENGTH=$((AFI_TEMP_WIDTH * $(($AFI_TEMP_HEIGHT-26))))
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

    ## ==================== other tests ==================================
    AFI_TEMP_STRING="==================== other tests ";printf "$AFI_TEMP_STRING";printf "%0.s=" $(seq 1 $(($AFI_TEMP_WIDTH-${#AFI_TEMP_STRING}))); printf "\n"
    AFI_INFO "AFI_INFO PRINT TEST"
    AFI_DEBUG "AFI_DEBUG PRINT TEST"
    AFI_WARN "AFI_WARN PRINT TEST"
    AFI_ERROR "AFI_ERROR PRINT TEST"

    unset AFI_TEMP_STRING
    unset AFI_TEMP_WIDTH
    unset AFI_TEMP_HEIGHT
    printf "\n"
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
        AFI_VAR_PREFIX=[AFI]
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
    AFI_INFO "validation: File integrity check."
    cd $AFI_VAR_PWD
    AFI_TEMP_ERROR=false
    # archfox-instal.sh
    if [ -f "archfox-install.sh" ]; then
        AFI_DEBUG "validation: file 'archfox-install.sh' exists."
    else 
        AFI_WARN "validation: file 'archfox-install.sh' does not exist,\n make sure you run this script in the same folder as the script."; AFI_TEMP_ERROR=true
    fi
    # rootfs
    AFI_VAR_RFSDIR="rootfs"
    if [ -d "$AFI_VAR_RFSDIR" ]; then
        AFI_DEBUG "validation: directory 'rootfs' exists."
    else 
        AFI_WARN "validation: directory 'rootfs' does not exists."; AFI_TEMP_ERROR=true
    fi
    # profiles
    AFI_VAR_PFDIR="profiles"
    if [ -d "$AFI_VAR_PFDIR" ]; then
        AFI_DEBUG "validation: directory 'profiles' exists."
    else 
        AFI_WARN "validation: directory 'profiles' does not exists."; AFI_TEMP_ERROR=true
    fi
    # check error
    if [ "$AFI_TEMP_ERROR" == true ]; then
        AFI_ERROR "validation: failed."; exit 5
    fi
    
    AFI_INFO "validation: Verifying the check sum."
    printf "Checksum validation has not yet been implemented, sorry...\n"



    AFI_INFO "validation: succesfull."
    AFI_VAR_VALIDATED=true
}

## ==================== config file handling =============================
AFI_CONF_CHK () {
    if [ ! -f "$AFI_CONF_FILE" ]; then
        touch "$AFI_CONF_FILE"
    fi
}
AFI_CONF_SET () {
    AFI_CONF_CHK
    local AFI_TEMP_VNAME="$1"
    shift

    if grep -q "^${AFI_TEMP_VNAME}=" "$AFI_CONF_FILE"; then
        sed -i "s/^${AFI_TEMP_VNAME}=.*/${AFI_TEMP_VNAME}=\"$@\"/" "$AFI_CONF_FILE"
    else
        echo "$AFI_TEMP_VNAME=\"$@\"" >> "$AFI_CONF_FILE"
    fi
}

AFI_CONF_GET () {
    AFI_CONF_CHK
    echo "$(grep "^$1=" "$AFI_CONF_FILE" | cut -d'=' -f2- | tr -d '"')"
}

AFI_CONF_DEL () {
    AFI_CONF_CHK
    if grep -q "^$1=" "$AFI_CONF_FILE"; then
        sed -i "/^$1=/d" "$AFI_CONF_FILE"
    fi
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
                    [Aa]|[Ss][Aa] ) # auto install
                        AFI_CONF_MODE="auto" ;;
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
    auto )
        AFI_AUTO ;;
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
# 5 - sources validation failed
# 10 - no sudo permission
# 
#
#
#
#








































# github.com: sudoTheFoxis

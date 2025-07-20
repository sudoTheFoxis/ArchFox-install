#!/bin/bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ITS NOT A STAND ALONE SCRIPT, DO NOT RUN IT MANUALLY!"; exit 1
fi

### =============================================
### ===== Default Config ========================
### =============================================
# this is hardcoded DEFAULT config, separated from main file to optimize it (do not change it)

AFI_DC_PKGMGR="pacman"              #   package manager, currently supported: pacman, yay, paru
AFI_DC_PM_AUR=true                  #   enable AUR support (manage manually if no package manager with AUR support is installed)
AFI_DC_PMC_SYNC=""                  #   update repos
AFI_DC_PMC_IPKG=""                  #   install packages
AFI_DC_PMC_IAPKG=""                 #   install AUR packages
AFI_DC_PMC_DPKG=""                  #   delete packages
AFI_DC_PMC_GPKG=""                  #   get package info
AFI_DC_PMC_GAPKG=""                 #   get AUR package info
AFI_DC_PMC_LPKG=""                  #   list all packages alongside ther repo in order: <repo> <pkg> ... (nothing after that matters)
AFI_DC_PMC_LAPKG=""                 #   list all AUR packages (dont worry about duplicates)
declare -A AFI_DC_CUSTOMREPOS=(     #   define own pacman compatibile repositories (uses SigLevel = Optional TrustAll)
    #['<name>']='<url>\n<url>'
    #   name                - name of repository
    #   url                 - url adress of repo server
)

## ===== Stage 0 (init) =========================
declare -a AFI_DC_S0_PKG=(          #   required dependencies for script to work
    # To define replacement in case dependency is not avalibare type another package name after ':' without space.
    # To use specific repository, place '<repo>/' before package name. (AUR suppoort must be enabled to install pkgs form AUR)
    # To define optional packages place '?' before entry. Same rules apply to all package lists.
    # Examples: <pkg> | <pkg>:<pkg> | ?<pkg>:<pkg> | <repo>/<pkg> | ?<repo>/<pkg> | ?<repo>/<pkg>:<repo>/<pkg>:<pkg>
    coreutils sudo
    tmux
    ?git ?gzip ?curl ?jq   # to manage aur packages manually
)
AFI_DC_S0_VALIDATE=true             #   validate files (it's not a security feature! it's only to detect corrupted/missing files)
AFI_DC_S0_CONFFILE="./config.json"  #   path to the config file



## ===== Stage 1 (base) =========================
declare -a AFI_DC_S1_PKG=(          #   packages to be installed in stage 1
    base linux linux-firmware base-devel archlinux-keyring
)
AFI_DC_S1_BOOTLOADER="systemd"      #   bootloader to be used: systemd, grub, runit, openrc ( only systemd is supported, as for now )
AFI_DC_S2_ROOTPASS="root"           #   encrypted/unencrypted root password
declare -A AFI_DC_S1_DISK_MASTER=(  #   disk configuration
    #['<name>']='<dev>:<serial>:<size>:<pttable>:<format>'
    #   name        disk configuration id
    #   dev         device name (sdX)
    #   serial      serial identifier (find disk by serial if device name has changed, leave empty to not bound configuration to specific disk)
    #   size        size of disk (an fast check if part layout will fit, if not set, size will be calculated from partlayout)
    #   pttable     GPT/MBR - disk partition table  
    #   format      none    - do not format the disk (default)
    #               fast    - wipe the disk with "wipefs -a /dev/sdX" (default when empty)
    #               hard    - zero the disk with "dd if=/dev/zero of=/dev/sdX" (slow)
    ['main']='sda:::gpt:fast'
)
declare -a AFI_DC_S1_DISK_main=(    #   partition configuration of specific disks (AFI_DC_S1_DISK_<name>)
    #'<start>:<end>:<fstype>:<label>:<type>:<format>'
    #   start/end   set where partition will begin and end ( in any supported unit )
    #   fstype      set what file system will be on this partition
    #   label       set partition label
    #   type        data    - primary data partition (default)
    #               boot    - create bootloader on this partition
    #               root    - system partiton
    #               swap    - swap partition
    #               home    - partition that will be mounted as /home
    #               dual    - merge with bootloader on this partition, or add entry if it is on another disk (BETA!)
    #   format      none    - do not format or recreate filesystem on this partition (default)
    #               fast    - wipe (wipefs /dev/sdXX) and recteate file system (fast) (default when creating partition)
    #               hard    - zero (dd if=/dev/zero of=/dev/sdXX) and recreate file system (slow)
    '1MB:257MB:fat32:BOOT:boot:fast'
    '258MB:-1MB:ext4:ROOT:root:fast'
)
AFI_DC_S1_UNIT="auto"               # unit in with sizes will be displayed: auto, B, KB, MB, GB, TB



## ===== Stage 2 (configuration) ================
declare -a AFI_DC_S2_PKG=(          #   packages to be installed in stage 2
    # dev utilities
    git gcc make cmake pkgconf meson cpio
    # useful tools
    dosfstools android-tools minicom edk2-shell
    mediainfo testdisk htop stress
    # other utilities
    sudo nano neovim fastfetch wget 7zip
)
declare -a AFI_DC_S2_USERS=(        # configuration of user accounts
    #'<name>:<pass>:<home>:<sudo>'
    #   name        name of the user
    #   pass        encrypted/unencrypted user password (default: same as username)
    #   home        user directory (default: /home/<username>)
    #   sudo        true/false give user sudo permission (default: false)
    'home:::true'
)
AFI_DC_S2_LANG="en_US.UTF-8"        #   language (multiple langs can be specified seperated with ':', first is default)
AFI_DC_S2_TIMEZONE="UTC"            #   timezone
AFI_DC_S2_HOSTNAME="archfox"        #   name of the host
AFI_DC_S2_AUDIOSERVER="pipewire"    #   audio server to be installed: none, pipewire, pulseaudio



## ===== Stage 3 (customization) ================
declare -a AFI_DC_S3_PKG=(          #   packages to be installed in stage 3
    
)

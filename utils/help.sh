#!/bin/bash

### =============================================
### ===== (H) Help ==============================
### =============================================
# all functions nedded to manage and display all avalibare informations about this script

#   prints help message
AFI_H () {
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

    ArchFox can also be installed on an existing Arch Linux installation.
    After installing ArchFox, the installer can be found in /opt/archfox-install for easy use of configuration options.
    This script isn't very idiot proof (yet), so keep that in mind if you don't run it on bootable media and clean disk,
    unless you want to wipe the entire system with all the data on it.
    If you have any ideas, questions, or found any bugs, please tell me about it on: https://github.com/sudoTheFoxis/ArchFox-install

MODES
    stage 0 - envinroment init (default)
      ├ check/install required dependencies
      ├ check/validate files (it's not a security feature! it's only to detect corrupted/missing files)
      ├ configure installation
      └ run stage 1 (optional)
    stage 1 - bare bones arch linux
      ├ format disk, create partitions
      ├ install minimal packages for system to work and boot
      ├ configure bootloader and root password
      └ run stage 2 (optional)
    stage 2 - minimal installation
      ├ install drivers, basic tools
      ├ copy files from installator (config files, wallpapers, icons, fonts, themes)
      ├ configure: kb layout, time, language, users
      └ run stage 3 (optional)
    stage 3 - fully functional system
      └ install graphical envinroment, audio server, applications

OPTIONS
    command [flags]
      ┣ --verbose     -v  ━ display debug info.
      ┣ --ignore      -i  ━ ignore warns messages.
      ┣ --headless <cmd>  ━ run specific function of the script without loading anything else
      ┣ --safemode        ━ prevent any chenges to real file system of any disk (only the settings will be able to be saved)
      ┗

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

    " | vim -c 'map <Esc> :q!<CR>' -R -M -m -
}

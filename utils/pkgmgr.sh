#!/bin/bash

AFI_V_PM_SYNCED=0               #   to avoid updating repositories indefinetly
AFI_V_PM_CACHED=0               #   store package list in variable to reduce i/o
declare -g -A AFI_V_PM_PKGLIST=()  #   list of packages

AFI_C_PKGMGR=""                 #   package manager: pacman, aura, yay, custom
AFI_C_PM_AUR=true               #   enable AUR support (install packages manually if choosen package manager dosnt support it)
AFI_C_PMC_SYNC=""               #   update repos
AFI_C_PMC_IPKG=""               #   install packages
AFI_C_PMC_IAPKG=""              #   install AUR packages
AFI_C_PMC_DPKG=""               #   delete packages
AFI_C_PMC_GPKG=""               #   get package info
AFI_C_PMC_GAPKG=""              #   get AUR package info
AFI_C_PMC_LPKG=""               #   list all packages
AFI_C_PMC_LAPKG=""              #   list all AUR packages (dont worry about duplicates)



### =============================================
### ===== (PM) pkgmgr Support ===================
### =============================================
# essentials to interact with package managers

#   set commands to use based on choosen package manager
AFI_PM_INIT () {
    case "$AFI_C_PKGMGR" in
        pacman)
            AFI_C_PMC_SYNC="sudo pacman -Syy"
            AFI_C_PMC_IPKG="sudo pacman -S"
            AFI_C_PMC_IAPKG="AFI_PM_AUR_IPKG"
            AFI_C_PMC_DPKG="sudo pacman -R"
            AFI_C_PMC_GPKG="pacman -Si"
            AFI_C_PMC_GAPKG="AFI_PM_AUR_GPKG"
            AFI_C_PMC_LPKG="pacman -Sl"
            AFI_C_PMC_LAPKG="AFI_PM_AUR_LPKG"
            ;;
        yay)
            AFI_C_PMC_SYNC="sudo yay -Syy"
            AFI_C_PMC_IPKG="sudo yay -S"
            AFI_C_PMC_IAPKG="sudo yay -S"
            AFI_C_PMC_DPKG="sudo yay -R"
            AFI_C_PMC_GPKG="yay -Si"
            AFI_C_PMC_GAPKG="yay -Si"
            AFI_C_PMC_LPKG="yay -Sl"
            AFI_C_PMC_LAPKG="yay -Sl"
            ;;
        paru)
            AFI_C_PMC_SYNC="sudo paru -Syy"
            AFI_C_PMC_IPKG="sudo paru -S"
            AFI_C_PMC_IAPKG="sudo paru -S"
            AFI_C_PMC_DPKG="sudo paru -R"
            AFI_C_PMC_GPKG="paru -Si"
            AFI_C_PMC_GAPKG="paru -Si"
            AFI_C_PMC_LPKG="paru -Sl"
            AFI_C_PMC_LAPKG="paru -Sl"
            ;;
        custom)
            AFI_WARN "AFI_PM_INIT: using custom package manager commands, some functions may not work properly" ;;
        *)
            AFI_ERROR "AFI_PM_INIT: chosen unsupported package manager: $AFI_C_PKGMGR, defaulting to pacman"; AFI_C_PKGMGR="pacman"; AFI_PM_INIT ;;
    esac
}

#   cache package list
AFI_PM_CACHE () {
    AFI_DEBUG "AFI_PM_CACHE: caching package list"
    while read -r repo pkg _; do #  cache official packages
        AFI_V_PM_PKGLIST[$pkg]="$repo"
    done < <($AFI_C_PMC_LPKG)
    if [ "$AFI_C_PM_AUR" == "true" ]; then # cache AUR packages
        AFI_DEBUG "AFI_PM_CACHE: caching AUR package list"
        while read -r repo pkg _; do
            AFI_V_PM_PKGLIST[$pkg]="$repo"
        done < <($AFI_C_PMC_LAPKG)
    fi
    AFI_V_PM_CACHED=1
}

#   check if any entry from package list is missing (dosnt have any avalibare packages)
AFI_PM_CHECK_EXISTS () {
    local entry_pass=0 entry_miss=0
    for entry in "$@"; do
        local pkgs_valid=0 opt=0 pkgs=()
        if [[ "$entry" == \?* ]];then opt=1;entry=${entry:1};fi # check if entry is optional
        IFS=':' read -ra pkgs <<< "$entry"              # deserialize entry into pkgs
        ! (($AFI_V_PM_CACHED)) && AFI_PM_CACHE      # cache valid pkg list
        for pkg in "${pkgs[@]}"; do             # check if pkgs exists
            if [[ "$pkg" == */* ]]; then    # check if specific repo is defined
                repo="${pkg%%/*}";name="${pkg##*/}"
                if [[ "${AFI_V_PM_PKGLIST[$name]}" == "$repo" ]]; then ((pkgs_valid++))
                else AFI_WARN "AFI_PM_CHECK_EXISTS: package ${AFI_V_PM_PKGLIST[$name]}/$name found, but not in specified repository: $repo";fi
            else
                if [[ ${AFI_V_PM_PKGLIST[$pkg]} ]]; then ((pkgs_valid++))
                else AFI_WARN "AFI_PM_CHECK_EXISTS: package $pkg not found in cached pkg list";fi
            fi
        done
        if [ $pkgs_valid -gt 0 ]; then ((entry_pass++)) # update stats
        else ! ((opt)) && ((entry_miss++));fi
    done
    printf "$entry_miss\n" # return number of missing entries (not packages)
}



### =============================================
### ===== AUR support ===========================
### =============================================
# custom AUR packages management

#   download and return all registered packages from AUR
AFI_PM_AUR_LPKG () {
    local tmpfile="$AFI_TEMPDIR/aur_packages.gz"
    # download archive
    if [ ! -f "$tmpfile" ]; then
        curl -s "https://aur.archlinux.org/packages.gz" -o "$tmpfile" || {
            AFI_ERROR "failed to download AUR package list"
            rm -f "$tmpfile"
            return 1
        }
    fi
    # decompress and return package list
    gzip -d "$tmpfile" --stdout | while read -r pkg _; do
        printf 'aur %s\n' "$pkg"
    done
}

#   return details about package from AUR
AFI_PM_AUR_GPKG () {
    for pkg in "$@"; do
        jq -n -r \
            --arg query "$pkg" \
            --argjson res "$(curl -s "https://aur.archlinux.org/rpc/?v=5&type=info&arg[]=${pkg}")" \
        '
            if $res.resultcount < 1 then
                "error: package \"" + $query + "\" was not found"
            else
                def safejoin(arr):
                    if ((arr // [] | length) > 0) then arr | join("  ") else "None" end;

                $res.results[0] as $p |
                "Repository                    : aur\n" +
                "Name                          : \($p.Name)\n" +
                "Version                       : \($p.Version)\n" +
                "Description                   : \($p.Description)\n" +
                "URL                           : \($p.URL)\n" +
                "Licenses                      : \(safejoin($p.License))\n" +
                "Groups                        : None\n" +
                "Provides                      : \(safejoin($p.Provides))\n" +
                "Depends On                    : \(safejoin($p.Depends))\n" +
                "Optional Deps                 : \(safejoin($p.OptDepends))\n" +
                "Make Deps                     : None\n" +
                "Check Deps                    : None\n" +
                "Conflicts With                : \(safejoin($p.Conflicts))\n" +
                "Replaces                      : \($p.Replaces // "None")\n" +
                "AUR URL                       : https://aur.archlinux.org/packages/\($p.Name)\n" +
                "First Submitted               : \($p.FirstSubmitted | strflocaltime("%a %d %b %Y %I:%M:%S %p %Z"))\n" +
                "Keywords                      : \(safejoin($p.Keywords))\n" +
                "Last Modified                 : \($p.LastModified | strflocaltime("%a %d %b %Y %I:%M:%S %p %Z"))\n" +
                "Maintainer                    : \($p.Maintainer // "None")\n" +
                "Popularity                    : \($p.Popularity | tostring)\n" +
                "Votes                         : \($p.NumVotes | tostring)\n" +
                "Out-of-date                   : \(if $p.OutOfDate == null then "No" else "Yes" end)\n"
            end
        '
    done
}

#   install package from AUR manually
AFI_PM_AUR_IPKG () {
    for pkg in "$@"; do
        local tempdir="$AFI_TEMPDIR/aur/$pkg"
        # download package if not exists
        if [ ! -d "$tempdir" ]; then
            AFI_DEBUG "cloning AUR package: $pkg"
            if ! git clone --depth=1 "https://aur.archlinux.org/${pkg}.git" "$tempdir"; then
                AFI_ERROR "failed to download package from AUR: $pkg"
                rm -rf "$tempdir"
                return 1
            fi
        else
            AFI_DEBUG "AUR package: $pkg, already exists"
        fi
        # build package
        AFI_INFO "building package: $pkg"
        (
            cd "$tempdir"
            makepkg -si --noconfirm
        )
    done
}

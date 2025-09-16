#!/bin/bash
################################################################################
### Universal Helper Functions - 
### Loads Project Configuration Files with circular dependency Detection
### Provides comprehensive Configuration loading for bash Framework Projects
################################################################################
### Project: Universal Helper Library
### Version: 2.0.4
### Author:  Mawage (Development Team)
### Date:    2025-09-16
### License: MIT
### Usage:   Source this Function to load Project Configurations with Dependencies
### Commit:  Complete Configuration Loader with Dependency Tracking and Project Compliance"
################################################################################

# shellcheck disable=SC2155

################################################################################


REPO_RAW_URL="https://raw.githubusercontent.com/Tabes/Helper/refs/heads/main"
path="/opt/helper"
logfile="$path/logs/install.log"

#### === Farben === ###
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

### === Flags === ###
dry_run=false
only_files=()

### === Argument-Parser === ###
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry)
            dry_run=true
            ;;

        --only)
            shift

            while [[ $# -gt 0 && "$1" != --* ]]; do

                only_files+=("$1")
                shift

            done
            continue
            ;;

    esac

    shift

done

### === Logging-Funktion === ###
log() {
    echo -e "$1" | tee -a "$logfile"
}

validate_files() {
    local valid_files=("$@")
    local invalid=()

    for requested in "${only_files[@]}"; do
        if [[ ! " ${valid_files[*]} " =~ " $requested " ]]; then
            invalid+=("$requested")
        fi
    done

    if [[ ${#invalid[@]} -gt 0 ]]; then
        echo -e "\n❌ Ungültige Datei(en) in --only: ${invalid[*]}"
        echo "➡️  Erlaubt sind: ${valid_files[*]}"
        exit 1
    fi
}

### === Download-Funktion === ###
download() {
    local subdir="$1"
    shift
    local files=("$@")

    ### === Validierung bei --only === ###
    if [[ ${#only_files[@]} -gt 0 ]]; then
        validate_files "${files[@]}"
    fi

    log "\n📦 Downloading: ${files[*]}\n"

    for file in "${files[@]}"; do
        # Wenn --only gesetzt ist, nur diese Dateien verarbeiten
        if [[ ${#only_files[@]} -gt 0 ]]; then

            [[ ! " ${only_files[*]} " =~ " $file " ]] && continue

        fi

        local target="$path/$subdir/$file"
        local url="$REPO_RAW_URL/$subdir/$file"

        if $dry_run; then

            log "  ${YELLOW}DRY: Would download $file → $target${RESET}"
            continue

        fi

        rm -f "$target"

        if curl -sSfL "$url" -o "$target" 2>/dev/null; then

            chmod +x "$target"
            local version=$(grep -oP '^### Version:\s*\K[0-9]+\.[0-9]+\.[0-9]+' "$target")

            if [[ -n "$version" ]]; then

                log "  ${GREEN}$(printf '%-15s' "$file") v$version${RESET}"

            else

                log "  ${YELLOW}$(printf '%-15s' "$file") unknown${RESET}"

            fi

        else

            log "  ${RED}$(printf '%-15s' "$file") failed${RESET}"

        fi

    done

    echo

}

### === Hauptdateien (optional auch in --only integrierbar) === ###
if ! $dry_run && [[ ${#only_files[@]} -eq 0 ]]; then
    curl -sSfL "$REPO_RAW_URL/start.sh" -o /opt/start.sh
    curl -sSfL "$REPO_RAW_URL/scripts/helper.sh" -o "$path/scripts/helper.sh"
fi

### === Plugins === ###
download "scripts/plugins" \
    cmd.sh log.sh network.sh print.sh secure.sh show.sh update.sh

### === Utilities === ###
download "utilities" \
    dos2linux.sh gitclone.sh work.sh

### === Configs === ###
download "configs" \
    project.conf helper.conf update.conf

echo; echo

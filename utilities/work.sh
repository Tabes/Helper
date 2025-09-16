#!/bin/bash
################################################################################
### Universal Helper Functions - 
### Loads Project Configuration Files with circular dependency Detection
### Provides comprehensive Configuration loading for bash Framework Projects
################################################################################
### Project: Universal Helper Library
### Version: 1.0.11
### Author:  Mawage (Development Team)
### Date:    2025-09-16
### License: MIT
### Usage:   Source this Function to load Project Configurations with Dependencies
### Commit:  Complete Configuration Loader with Dependency Tracking and Project Compliance"
################################################################################


################################################################################


REPO_RAW_URL="https://raw.githubusercontent.com/Tabes/Helper/refs/heads/main"
path="/opt/helper"
logfile="$path/logs/install.log"

# === Farben ===
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# === Flags ===
dry_run=false
only_files=()

# === Argument-Parser ===
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

# === Logging-Funktion ===
log() {
    echo -e "$1" | tee -a "$logfile"
}

# === Download-Funktion ===
download_and_report() {
    local subdir="$1"
    shift
    local files=("$@")

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

        if curl -sSfL "$url" -o "$target"; then
            chmod +x "$target"
            local version=$(grep -oP '^### Version:\s*\K[0-9]+\.[0-9]+\.[0-9]+' "$target")
            if [[ -n "$version" ]]; then
                log "  ${GREEN}$(printf '%-20s' "$file") v $version${RESET}"
            else
                log "  ${YELLOW}$(printf '%-20s' "$file") v unknown${RESET}"
            fi
        else
            log "  ${RED}$(printf '%-20s' "$file") download failed${RESET}"
        fi
    done
}

# === Hauptdateien (optional auch in --only integrierbar) ===
if ! $dry_run && [[ ${#only_files[@]} -eq 0 ]]; then
    curl -sSfL "$REPO_RAW_URL/start.sh" -o /opt/start.sh
    curl -sSfL "$REPO_RAW_URL/scripts/helper.sh" -o "$path/scripts/helper.sh"
fi

# === Plugins ===
download_and_report "scripts/plugins" \
    cmd.sh log.sh print.sh secure.sh show.sh update.sh

# === Utilities ===
download_and_report "utilities" \
    gitclone.sh work.sh



















exit

REPO_RAW_URL="https://raw.githubusercontent.com/Tabes/Helper/refs/heads/main"
path="/opt/helper"

echo
echo "Download URL: $REPO_RAW_URL"
echo "Target Path:  $path"
echo

curl -sSfL "$REPO_RAW_URL/start.sh" -o /opt/start.sh
curl -sSfL "$REPO_RAW_URL/scripts/helper.sh" -o "$path"/scripts/helper.sh



files=(cmd.sh log.sh print.sh secure.sh show.sh update.sh)
echo "Download...  ${files[*]}"; echo

for file in "${files[@]}"; do

    rm "$path/scripts/plugins/$file"
    curl -sSfL "$REPO_RAW_URL/scripts/plugins/$file" -o "$path/scripts/plugins/$file"
    chmod +x "$path/scripts/plugins/$file"

    printf "  %-20s v%s\n" "$file" "$(grep -oP '^### Version:\s*\K[0-9]+\.[0-9]+\.[0-9]+' "$path/scripts/plugins/$file")"
done
echo

files=(gitclone.sh work.sh)
echo "Download...  ${files[*]}"; echo

for file in "${files[@]}"; do

    rm "$path/utilities/$file"
    curl -sSfL "$REPO_RAW_URL/utilities/$file" -o "$path/utilities/$file"
    chmod +x "$path/utilities/$file"

    printf "  %-20s v %s\n" "$file" "$(grep -oP '^### Version:\s*\K[0-9]+\.[0-9]+\.[0-9]+' "$path/utilities/$file")"
done
echo

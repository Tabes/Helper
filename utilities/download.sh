#!/bin/bash
################################################################################
### Universal Helper Functions - 
### Loads Project Configuration Files with circular dependency Detection
### Provides comprehensive Configuration loading for bash Framework Projects
################################################################################
### Project: Universal Helper Library
### Version: 2.1.14
### Author:  Mawage (Development Team)
### Date:    2025-09-17
### License: MIT
### Usage:   Source this Function to load Project Configurations with Dependencies
### Commit:  Complete Configuration Loader with Dependency Tracking and Project Compliance"
################################################################################

# shellcheck disable=SC2076,SC2086,SC2155

################################################################################


### === Repository and Subpaths === ###
REPO_RAW_URL="https://raw.githubusercontent.com/Tabes/Helper/refs/heads/main"
path="/opt/helper"

backup_path="$path/backups"
plugins_path="scripts/plugins"
utilities_path="utilities"
configs_path="configs"

logfile="$path/logs/install.log"

### === Terminal Colors === ###
GN="\e[32m"; RD="\e[31m"; YE="\e[33m"; NC="\e[0m"

### === Flags and Filters === ###
dry_run=false
only_files=()
groups=()
list_mode=false
interactive_mode=false
summary_mode=false
backup_enabled=false

### === File Groups Definition === ###
declare -A file_groups=(

    [plugins]="cmd.sh log.sh network.sh print.sh secure.sh show.sh update.sh"
    [utilities]="download.sh dos2linux.sh gitclone.sh work.sh"
    [configs]="project.conf helper.conf update.conf"

)

### === Summary Collector === ###
declare -A summary_versions=()
declare -A summary_groups=()

### === Argument Parser === ###
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry) dry_run=true ;;
        --list) list_mode=true ;;
        --interactive) interactive_mode=true ;;
        --summary) summary_mode=true ;;
        --backup) backup_enabled=true ;;
        --only)
            shift

            while [[ $# -gt 0 && "$1" != --* ]]; do
                only_files+=("$1"); shift
            done
            continue
            ;;

        --group)
            shift
            while [[ $# -gt 0 && "$1" != --* ]]; do
                groups+=("$1"); shift
            done
            continue

            ;;

    esac

    shift

done

### === Logger === ###
log() { echo -e "$1" | tee -a "$logfile"; }

### === Suggest similar filenames === ###
similar_files() {
    local input="$1"; shift
    local candidates=("$@")

    for candidate in "${candidates[@]}"; do
        local dist=$(awk -v a="$input" -v b="$candidate" '

        function min(x,y,z){return x<y?(x<z?x:z):(y<z?y:z)}
        BEGIN{
            len_a=length(a); len_b=length(b)
            for(i=0;i<=len_a;i++) d[i,0]=i
            for(j=0;j<=len_b;j++) d[0,j]=j
            for(i=1;i<=len_a;i++){
                for(j=1;j<=len_b;j++){
                    cost=(substr(a,i,1)==substr(b,j,1)?0:1)
                    d[i,j]=min(d[i-1,j]+1,d[i,j-1]+1,d[i-1,j-1]+cost)
                }
            }
            print d[len_a,len_b]
        }')

        [[ "$dist" -le 3 ]] && printf "    → Did you mean: ${YE}%s${NC}\n\n" "$candidate"

    done

}

### === Validate --only Files === ###
validate_files() {
    local valid_files=("$@")
    local invalid=()

    for requested in "${only_files[@]}"; do

        [[ ! " ${valid_files[*]} " =~ " $requested " ]] && invalid+=("$requested")

    done

    if [[ ${#invalid[@]} -gt 0 ]]; then

        echo -e "\n❌ Invalid file(s) in --only: ${invalid[*]}"
        echo "➡️  Allowed files: ${valid_files[*]}"

        for wrong in "${invalid[@]}"; do

            similar_files "$wrong" "${valid_files[@]}"

        done

        exit 1

    fi

}

### === Check if group should be downloaded === ###
download_group() {
    local group="$1"

    [[ ${#groups[@]} -eq 0 ]] && return 0
    [[ " ${groups[*]} " =~ " $group " ]] && return 0

    return 1

}

### === List available groups and files === ###
if $list_mode; then
    echo -e "\n📂 Available groups and files:\n"

    for group in "${!file_groups[@]}"; do

        echo "🔹 $group:"

        for file in ${file_groups[$group]}; do

            echo "    - $file"

        done

        echo

    done

    exit 0

fi

### === Interactive group selection === ###
if $interactive_mode; then
    echo -e "\n\n🧭 Select group(s) to download:\n"

    select group in "${!file_groups[@]}" "All" "Cancel"; do
        case "$group" in
            Cancel) echo -e "\n❌ Cancelled...\n\n"; exit 0 ;;
            All) groups=(); break ;;
            *) groups+=("$group"); break ;;
        esac

    done

fi

### === Download Function === ###
download() {
    local subdir="$1"; shift
    local files=("$@")
    local group="${subdir##*/}"

    download_group "$group" || return

    if [[ ${#only_files[@]} -gt 0 ]]; then
        local matched=()

        for f in "${files[@]}"; do

            [[ " ${only_files[*]} " =~ " $f " ]] && matched+=("$f")

        done

        if [[ ${#matched[@]} -eq 0 ]]; then

            return

        fi

        validate_files "${files[@]}"

    fi

    log "\n📦 Downloading group: $group\n"

    for file in "${files[@]}"; do
        [[ ${#only_files[@]} -gt 0 && ! " ${only_files[*]} " =~ " $file " ]] && continue

        local target="$path/$subdir/$file"
        local url="$REPO_RAW_URL/$subdir/$file"

        if $dry_run; then

            printf "   [${YE}DRY${NC}]   %-14s → %s${NC}\n" "$file" "$target"
            continue

        fi

        # === Backup existing file ===
        if $backup_enabled && [[ -f "$target" ]]; then

            mkdir -p "$backup_path/$subdir"
            cp "$target" "$backup_path/$subdir/$file"

            printf "   [${YE}BACKUP${NC}] %-13s → %s${NC}\n" "$file" "$backup_path/$subdir/$file"

        fi

        rm -f "$target"

        if curl -sSfL "$url" -o "$target" 2>/dev/null; then
            chmod +x "$target"

            local version=$(grep -oP '^### Version:\s*\K[0-9]+\.[0-9]+\.[0-9]+' "$target")

            summary_versions["$file"]="${version:-unknown}"
            summary_groups["$file"]="$group"

            printf "   [${GN}OK${NC}]     %-15s v%s${NC}\n" "$file" "${version:-${YE}unknown${NC}}"

        else

            summary_versions["$file"]="failed"
            summary_groups["$file"]="$group"

            printf "   [${RD}FAIL${NC}]   %-15s failed\n" "$file"

        fi

    done

    echo

}

### === Download Core Files (unless --only or --dry) === ###
if ! $dry_run && [[ ${#only_files[@]} -eq 0 ]]; then

    curl -sSfL "$REPO_RAW_URL/start.sh" -o /opt/start.sh
    curl -sSfL "$REPO_RAW_URL/scripts/helper.sh" -o "$path/scripts/helper.sh"

fi

### === Execute Downloads by Group === ###
download "$plugins_path"   ${file_groups[plugins]}
download "$utilities_path" ${file_groups[utilities]}
download "$configs_path"   ${file_groups[configs]}

### === Summary Output === ###
if $summary_mode; then
    echo -e "\n📊 Summary of downloaded files:"

    for group in plugins utilities configs; do
        printf "\n%s\n\n" "🔹 Group: $group"
        printf "   %-20s %s${NC}\n" "File" "Version"
        printf "   %-20s %s${NC}\n" "--------------------" "--------"

        for file in "${!summary_versions[@]}"; do
            [[ "${summary_groups[$file]}" == "$group" ]] && \

            printf "   %-20s %s${NC}\n" "$file" "${summary_versions[$file]}"

        done

        echo

    done
fi

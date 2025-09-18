#!/bin/bash
################################################################################
### Universal Helper Functions - 
### Loads Project Configuration Files with circular dependency Detection
### Provides comprehensive Configuration loading for bash Framework Projects
################################################################################
### Project: Universal Helper Library
### Version: 2.1.39
### Author:  Mawage (Development Team)
### Date:    2025-09-18
### License: MIT
### Usage:   Source this Function to load Project Configurations with Dependencies
### Commit:  Complete Configuration Loader with Dependency Tracking and Project Compliance"
################################################################################

# shellcheck disable=SC1090,SC2076,SC2086,SC2155

################################################################################


### === Repository and Subpaths === ###
REPO_RAW_URL="https://raw.githubusercontent.com/Tabes/Helper/refs/heads/main"
path="/opt/helper"

backup_path="$path/backups"
helper_path="scripts"
plugins_path="$helper_path/plugins"
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
sourcing=false
verbose_mode=false

### === Column Positions === ###
declare -A pos=(
    [P1]=3
    [P2]=9
    [P3]=16
    [file]=20
    [version]=10
    [status]=12
    [path]=40
    [size]=10
    [mod]=20
)

### === File Groups Definition === ###
declare -A file_groups=(

    [project]="start.sh"
    [helper]="helper.sh"
    [plugins]="cmd.sh log.sh debug.sh network.sh print.sh secure.sh show.sh update.sh"
    [utilities]="download.sh dos2linux.sh gitclone.sh work.sh"
    [configs]="project.conf helper.conf update.conf"

)

### === Status Symbole === ###
declare -A symbol=(
    [ok]="✅"
    [skipped]="⏩"
    [failed]="❌"
    [unknown]="❓"
    [downloaded]="🟢"
    [dry]="💧"
    [backup]="📦"
    [sourced]="📜"
)

### === Status Symbole === ###
declare -A lable=(
    [ok]="OK"
    [skipped]="skipped"
    [failed]="FAIL"
    [unknown]="unknown"
    [downloaded]="downloaded"
    [dry]="dry"
    [backup]="backup"
    [sourced]="sourced"
)

### === Summary Collector === ###
declare -A summary_versions=()
declare -A summary_groups=()
declare -A summary_status=()

### === Argument Parser === ###
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry) dry_run=true ;;
        --list) list_mode=true ;;
        --sourcing) sourcing=true ;;
        --interactive) interactive_mode=true ;;
        --summary) summary_mode=true ;;
        --backup) backup_enabled=true ;;
        --verbose) verbose_mode=true ;;
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

    log "\n📦 Downloading group: ${YE}$group${NC}\n"

    for file in "${files[@]}"; do
        [[ ${#only_files[@]} -gt 0 && ! " ${only_files[*]} " =~ " $file " ]] && continue

        local target="$path/$subdir/$file"
        local url="$REPO_RAW_URL/$subdir/$file"

        if $dry_run; then
            printf "   [${YE}DRY${NC}]   %-${pos[file]}s → %s${NC}\n" "$file" "$target"
            continue
        fi

        # === Backup existing file ===
        if $backup_enabled && [[ -f "$target" ]]; then
            mkdir -p "$backup_path/$subdir"
            cp "$target" "$backup_path/$subdir/$file"
            printf "   [${YE}BACKUP${NC}] %-${pos[file]}s → %s${NC}\n" "$file" "$backup_path/$subdir/$file"
        fi

        local curl_opts=(--silent --show-error --fail --location --remote-time)
        [[ -f "$target" ]] && curl_opts+=(--time-cond "$target")

        if curl "${curl_opts[@]}" -o "$target" "$url" 2>/dev/null; then
            chmod +x "$target"
            $sourcing && source "${target}"

            local version=$(grep -oP '^### Version:\s*\K[0-9]+\.[0-9]+\.[0-9]+' "$target")
            summary_versions["$file"]="${version:-unknown}"
            summary_groups["$file"]="$group"
            summary_status["$file"]="downloaded"

            # printf "   [${GN}OK${NC}]     %-${pos[file]}s v%-${pos[version]}s " "$file" "${version:-${YE}unknown${NC}}"
            printf "%-${pos[P1]}s [${GN}%-${pos[P2]}s${NC}] %-${pos[file]}s v%-${pos[version]}s" ' ' "OK" "$file" "${version:-${YE}unknown${NC}}"

            if $sourcing; then

                printf "${GN}%-${pos[status]}s${NC}\n" "sourced"

            else

                printf "%-${pos[status]}s\n" ""

            fi

        elif curl -s -o /dev/null -w "%{http_code}" --location --time-cond "$target" "$url" | grep -q "304"; then
            summary_versions["$file"]="cached"
            summary_groups["$file"]="$group"
            summary_status["$file"]="skipped"
            continue

        else
            summary_versions["$file"]="failed"
            summary_groups["$file"]="$group"
            summary_status["$file"]="failed"
            printf "   [${RD}FAIL${NC}]   %-${pos[file]}s %-${pos[version]}s %-${pos[status]}s\n" "$file" "failed" ""
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
download "$configs_path"   ${file_groups[configs]}
download "$plugins_path"   ${file_groups[plugins]}
download "$utilities_path" ${file_groups[utilities]}
download "$helper_path"    ${file_groups[helper]}
download ""                ${file_groups[project]}

### === Summary Output === ###
if $summary_mode; then
    echo -e "\n📊 Summary of processed files:\n"

    for group in project helper plugins utilities configs; do
        printf "\n%s\n\n" "🔹 Group: $group"

        # Header
        printf "   %-${pos[file]}s %-${pos[version]}s %-${pos[status]}s" "File" "Version" "Status"
        if $verbose_mode; then
            printf " %-${pos[path]}s %-${pos[size]}s %-${pos[mod]}s" "Path" "Size" "Modified"
        fi
        echo

        # Divider
        printf "   %-${pos[file]}s %-${pos[version]}s %-${pos[status]}s" \
            "$(printf '%.0s-' $(seq 1 ${pos[file]}))" \
            "$(printf '%.0s-' $(seq 1 ${pos[version]}))" \
            "$(printf '%.0s-' $(seq 1 ${pos[status]}))"
        if $verbose_mode; then
            printf " %-${pos[path]}s %-${pos[size]}s %-${pos[mod]}s" \
                "$(printf '%.0s-' $(seq 1 ${pos[path]}))" \
                "$(printf '%.0s-' $(seq 1 ${pos[size]}))" \
                "$(printf '%.0s-' $(seq 1 ${pos[mod]}))"
        fi
        echo

        # Rows
        for file in "${!summary_versions[@]}"; do
            [[ "${summary_groups[$file]}" == "$group" ]] || continue

            raw_status="${summary_status[$file]}"
            version="${summary_versions[$file]}"
            full_path="$path/$group/$file"
            size="–"
            mod="–"

            case "$raw_status" in
                downloaded) status_text="✅ downloaded"; status_color="$GN" ;;
                skipped)    status_text="⏩ skipped";    status_color="$YE" ;;
                failed)     status_text="❌ failed";     status_color="$RD" ;;
                *)          status_text="❓ unknown";    status_color="$RD" ;;
            esac

            if $verbose_mode && [[ -f "$full_path" ]]; then
                size=$(stat -c %s "$full_path" 2>/dev/null)
                mod=$(date -r "$full_path" +"%Y-%m-%d %H:%M:%S" 2>/dev/null)
            fi

            printf "   %-${pos[file]}s %-${pos[version]}s " "$file" "$version"
            printf "${status_color}%-${pos[status]}s${NC}" "$status_text"

            if $verbose_mode; then
                printf " %-${pos[path]}s %-${pos[size]}s %-${pos[mod]}s" "$full_path" "$size" "$mod"
            fi

            echo
        done

        echo
    done
fi

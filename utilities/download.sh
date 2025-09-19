#!/bin/bash
################################################################################
### Universal Helper Functions - 
### Loads Project Configuration Files with circular dependency Detection
### Provides comprehensive Configuration loading for bash Framework Projects
################################################################################
### Project: Universal Helper Library
### Version: 2.1.54 
### Author:  Mawage (Development Team)
### Date:    2025-09-19
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
    [P0]=2          # Position #0
    [P1]=4          # Position #1
    [P2]=12         # Position #2
    [P3]=32         # Position #3
    [P4]=45         # Position #4
    [File]=15       # File
    [Version]=9     # Version
    [Status]=14     # Status
    [Path]=40       # Path
    [Size]=10       # Size
    [Modified]=20   # Modified
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

### === Status Labels === ###
declare -A label=(
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

### === Logger === ###
log() { echo -e "$1" | tee -a "$logfile"; }

### === Suggest similar filenames === ###
similar_files() {
    local input="$1"; shift
    local candidates=("$@")

    for candidate in "${candidates[@]}"; do
        local dist
        dist=$(awk -v a="$input" -v b="$candidate" '
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

### === Build global file list === ###
all_known_files() {
    local acc=()
    local g
    for g in "${!file_groups[@]}"; do
        acc+=(${file_groups[$g]})
    done
    printf "%s\n" "${acc[@]}"
}

### === Validate --only Files (global) === ###
validate_files() {
    local valid=()
    mapfile -t valid < <(all_known_files)

    local invalid=()
    local f
    for f in "${only_files[@]}"; do
        [[ " ${valid[*]} " =~ " $f " ]] || invalid+=("$f")
    done

    if [[ ${#invalid[@]} -gt 0 ]]; then
        echo -e "\n${RD}❌ Invalid file(s) in --only:${NC} ${invalid[*]}"
        echo -e "➡️  Allowed files: ${valid[*]}"
        # Hilfsvorschläge
        local v
        for v in "${invalid[@]}"; do
            similar_files "$v" "${valid[@]}"
        done
        exit 1
    fi
}

### === Resolve groups from --only === ###
resolve_groups() {
    local f g
    local resolved=()
    for f in "${only_files[@]}"; do
        for g in "${!file_groups[@]}"; do
            if [[ " ${file_groups[$g]} " =~ " $f " ]]; then
                resolved+=("$g")
                break
            fi
        done
    done
    # merge with --group if provided, else replace groups entirely
    if [[ ${#groups[@]} -eq 0 ]]; then
        # unique
        mapfile -t groups < <(printf "%s\n" "${resolved[@]}" | sort -u)
    else
        # keep only intersection of user --group and resolved
        local keep=()
        local rg
        for rg in "${groups[@]}"; do
            [[ " ${resolved[*]} " =~ " $rg " ]] && keep+=("$rg")
        done
        mapfile -t groups < <(printf "%s\n" "${keep[@]}" | sort -u)
    fi
}

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
        *) ;;
    esac
    shift
done

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

### === Prepare: validate and resolve groups for --only === ###
if [[ ${#only_files[@]} -gt 0 ]]; then
    validate_files
    resolve_groups
fi

### === Check if Group should be downloaded === ###
download_group() {
    local group="$1"
    [[ ${#groups[@]} -eq 0 ]] && return 0
    [[ " ${groups[*]} " =~ " $group " ]] && return 0
    return 1
}

### === Download Function === ###
download() {
    local subdir="$1"; shift
    local files=("$@")
    local group="${subdir##*/}"

    download_group "$group" || return

    # If --only is set, reduce to matching files of this group
    if [[ ${#only_files[@]} -gt 0 ]]; then
        local filtered=()
        local f
        for f in "${files[@]}"; do
            [[ " ${only_files[*]} " =~ " $f " ]] && filtered+=("$f")
        done
        # If no matches for this group, skip it silently
        [[ ${#filtered[@]} -eq 0 ]] && return
        files=("${filtered[@]}")
    fi

    log "\n📦 Downloading group: ${YE}$group${NC}\n"

    local file
    for file in "${files[@]}"; do
        local target="$path/$subdir/$file"
        local url="$REPO_RAW_URL/$subdir/$file"

        if $dry_run; then
            printf "   [${YE}DRY${NC}]     %-20s → %s\n" "$file" "$target"
            continue
        fi

        # Backup
        if $backup_enabled && [[ -f "$target" ]]; then
            mkdir -p "$backup_path/$subdir"
            cp "$target" "$backup_path/$subdir/$file"
            printf "   [${YE}BACKUP${NC}]  %-20s → %s\n" "$file" "$backup_path/$subdir/$file"
        fi

        local curl_opts=(--silent --show-error --fail --location --remote-time)
        [[ -f "$target" ]] && curl_opts+=(--time-cond "$target")

        if curl "${curl_opts[@]}" -o "$target" "$url" 2>/dev/null; then
            chmod +x "$target"
            $sourcing && source "${target}"

            local version
            version=$(grep -oP '^### Version:\s*\K[0-9]+\.[0-9]+\.[0-9]+' "$target")
            summary_versions["$file"]="${version:-unknown}"
            summary_groups["$file"]="$group"
            summary_status["$file"]="downloaded"

            printf "   [${GN}OK${NC}]       %-20s v%-10s %-12s\n" \
                "$file" "${version:-${YE}unknown${NC]}" "$([[ $sourcing == true ]] && echo -e "${GN}sourced${NC}")"

        elif curl -s -o /dev/null -w "%{http_code}" --location --time-cond "$target" "$url" | grep -q "304"; then
            summary_versions["$file"]="cached"
            summary_groups["$file"]="$group"
            summary_status["$file"]="skipped"
            # Optional: Ausgabe für skipped
            printf "   [${YE}SKIP${NC}]     %-20s cached\n" "$file"

        else
            summary_versions["$file"]="failed"
            summary_groups["$file"]="$group"
            summary_status["$file"]="failed"
            printf "   [${RD}FAIL${NC}]     %-20s failed\n" "$file"
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
        # Nur Gruppen ausgeben, die Dateien enthalten
        group_has_files=false
        for file in "${!summary_versions[@]}"; do
            [[ "${summary_groups[$file]}" == "$group" ]] && group_has_files=true && break
        done
        $group_has_files || continue  # Gruppe überspringen, wenn leer

        printf "\n🔹 Group: %s\n\n" "$group"
        printf "   %-${pos[File]}s %-${pos[Version]}s %-${pos[Status]}s" "File" "Version" "Status"
        if $verbose_mode; then
            printf " %-${pos[Path]}s %-${pos[Size]}s %-${pos[Modified]}s" "Path" "Size" "Modified"
        fi
        echo

        printf "   %-${pos[File]}s %-${pos[Version]}s %-${pos[Status]}s" "---------------" "--------" "----------------"
        if $verbose_mode; then
            printf " %-${pos[Path]}s %-${pos[Size]}s %-${pos[Modified]}s" "----------------------------------------" "----------" "--------------------"
        fi
        echo

        for file in "${!summary_versions[@]}"; do
            [[ "${summary_groups[$file]}" == "$group" ]] || continue

            raw_status="${summary_status[$file]}"
            version="${summary_versions[$file]}"
            full_path="$path/$group/$file"
            size="–"
            mod="–"

            case "$raw_status" in
                downloaded) status_text="${symbol[downloaded]} ${label[downloaded]}"; status_color="$GN" ;;
                skipped)    status_text="${symbol[skipped]} ${label[skipped]}";     status_color="$YE" ;;
                failed)     status_text="${symbol[failed]} ${label[failed]}";       status_color="$RD" ;;
                *)          status_text="${symbol[unknown]} ${label[unknown]}";     status_color="$RD" ;;
            esac

            if $verbose_mode && [[ -f "$full_path" ]]; then
                size=$(stat -c %s "$full_path" 2>/dev/null)
                mod=$(date -r "$full_path" +"%Y-%m-%d %H:%M:%S" 2>/dev/null)
            fi

            printf "   %-${pos[File]}s %-${pos[Version]}s ${status_color}%-${pos[Status]}s${NC}" "$file" "$version" "$status_text"
            if $verbose_mode; then
                printf " %-${pos[Path]}s %-${pos[Size]}s %-${pos[Modified]}s" "$full_path" "$size" "$mod"
            fi
            echo
        done

        echo
    done
fi

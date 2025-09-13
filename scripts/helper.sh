#!/bin/bash
################################################################################
### Universal Helper Functions - Complete Utility Library
### Comprehensive Collection of Helper Functions for bash Scripts
### Provides Output, Logging, Validation, System, Network and Utility Functions
################################################################################
### Project: Universal Helper Library
### Version: 2.1.0
### Author:  Mawage (Development Team)
### Date:    2025-08-31
### License: MIT
### Usage:   Source this File to Load Helper Functions
################################################################################

readonly header="Universal Helper Functions"

readonly version="2.1.0"
readonly commit="Initial Helper Functions Library Structure"


################################################################################
### Parse Command Line Arguments ###
################################################################################

### Parse Command Line Arguments ###
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;

            --version|-V)
                print --version "${header}" "${version}" "${commit}"
                exit 0
                ;;

            *)
                ### Pass all other arguments to main processing ###
                break
                ;;
        esac
        shift
    done
}


################################################################################
### === INITIALIZATION === ###
################################################################################

### Load Configuration and Dependencies ###
# shellcheck disable=SC2120,SC2155,SC1090,SC2153,SC2015,SC2068 
#!/bin/bash

################################################################################
### Load Configuration and Dependencies - Improved Version ###
################################################################################

# shellcheck disable=SC2120,SC2155,SC1090,SC2153,SC2015,SC2068 
load_config() {
    local project_root_arg="$1"
    local debug="${2:-false}"

    ### Enable debug output if requested ###
    [[ "$debug" == "true" ]] && set -x

    ### Determine Project root Path ###
    local project_root
    if [[ -n "$project_root_arg" ]]; then
        project_root="$project_root_arg"
        if [[ ! -d "$project_root" ]]; then
            print --error "Error: Provided path '$project_root' is not a directory."
            return 1
        fi
    else
        # Dynamically find project root
        local script_path
        script_path="$(realpath "${BASH_SOURCE[0]}")"
        local script_dir
        script_dir="$(dirname "$script_path")"
        project_root="$(dirname "$script_dir")"
        
        [[ "$debug" == "true" ]] && echo "DEBUG: Auto-detected project_root: $project_root"
    fi

    ### Search for project.conf in standard locations ###
    local project_conf_path
    local config_found=false
    
    # Try multiple locations
    for conf_location in \
        "$project_root/configs/project.conf" \
        "$project_root/project.conf" \
        "$project_root/config/project.conf"; do
        
        if [[ -f "$conf_location" ]]; then
            project_conf_path="$conf_location"
            config_found=true
            [[ "$debug" == "true" ]] && echo "DEBUG: Found config at: $conf_location"
            break
        fi
    done

    ### Exit if no configuration found ###
    if [[ "$config_found" != "true" ]]; then
        print --error "Error: Project configuration not found in any standard location."
        return 1
    fi

    ### Source project.conf ###
    # shellcheck source=/dev/null
    source "$project_conf_path" || {
        print --error "Error: Failed to source project configuration."
        return 1
    }

    ### Set PROJECT_ROOT to match discovered path ###
    PROJECT_ROOT="$project_root"
    export PROJECT_ROOT
    
    [[ "$debug" == "true" ]] && echo "DEBUG: Set PROJECT_ROOT=$PROJECT_ROOT"

    ### Source HELPER_CONFIG if it exists ###
    if [[ -n "$HELPER_CONFIG" && -f "$HELPER_CONFIG" ]]; then
        # shellcheck source=/dev/null
        source "$HELPER_CONFIG" || {
            print --warning "Warning: Failed to source helper configuration: $HELPER_CONFIG"
        }
        [[ "$debug" == "true" ]] && echo "DEBUG: Sourced HELPER_CONFIG: $HELPER_CONFIG"
    fi

    ### Load files from configured directories ###
    if [[ -n "${LOAD_CONFIG_DIRS[*]}" ]]; then
        local dir file pattern basename exclude exclusion
        local files_loaded=0
        
        for dir in "${LOAD_CONFIG_DIRS[@]}"; do
            [[ -d "$dir" ]] || {
                [[ "$debug" == "true" ]] && echo "DEBUG: Skipping non-existent directory: $dir"
                continue
            }
            
            [[ "$debug" == "true" ]] && echo "DEBUG: Processing directory: $dir"
            
            ### Process each pattern ###
            for pattern in "${LOAD_CONFIG_PATTERN[@]}"; do
                # Use nullglob to handle cases where no files match
                shopt -s nullglob
                
                for file in "$dir"/$pattern; do
                    [[ -f "$file" ]] || continue
                    
                    basename=$(basename "$file")
                    exclude=0
                    
                    ### Check exclusion patterns ###
                    for exclusion in "${LOAD_CONFIG_EXCLUSION[@]}"; do
                        case "$basename" in
                            $exclusion)
                                exclude=1
                                [[ "$debug" == "true" ]] && echo "DEBUG: Excluding $file (matches $exclusion)"
                                break
                                ;;
                        esac
                    done
                    
                    ### Skip excluded files ###
                    [[ "$exclude" -eq 1 ]] && continue
                    
                    ### Skip self-referencing ###
                    [[ "$file" -ef "${BASH_SOURCE[0]}" ]] && {
                        [[ "$debug" == "true" ]] && echo "DEBUG: Skipping self-reference: $file"
                        continue
                    }
                    
                    ### Source the file ###
                    [[ "$debug" == "true" ]] && echo "DEBUG: Sourcing: $file"
                    # shellcheck source=/dev/null
                    source "$file" || {
                        print --warning "Warning: Failed to source: $file"
                        continue
                    }
                    
                    ((files_loaded++))
                done
                
                shopt -u nullglob
            done
        done
        
        [[ "$debug" == "true" ]] && echo "DEBUG: Total files loaded: $files_loaded"
    fi

    ### Validate required directories (if defined) ###
    if [[ -n "${REQUIRED_DIRS[*]}" ]]; then
        local missing_dirs=()
        
        for dir in "${REQUIRED_DIRS[@]}"; do
            [[ -d "$dir" ]] || missing_dirs+=("$dir")
        done
        
        if [[ ${#missing_dirs[@]} -gt 0 ]]; then
            print --warning "Warning: Missing required directories: ${missing_dirs[*]}"
        fi
    fi

    ### Disable debug output ###
    [[ "$debug" == "true" ]] && set +x

    return 0
}

################################################################################
### Enhanced Configuration Loader with Dependency Management ###
################################################################################

load_config_with_deps() {
    local project_root="$1"
    local debug="${2:-false}"
    
    ### Track loaded files to prevent circular dependencies ###
    declare -A loaded_files
    local load_order=()
    
    _load_file() {
        local file="$1"
        local real_file
        real_file=$(realpath "$file" 2>/dev/null) || return 1
        
        ### Skip if already loaded ###
        [[ -n "${loaded_files[$real_file]}" ]] && return 0
        
        ### Mark as loading to detect circular deps ###
        loaded_files["$real_file"]="loading"
        
        ### Source the file ###
        # shellcheck source=/dev/null
        source "$file" || {
            print --error "Failed to load: $file"
            return 1
        }
        
        ### Mark as loaded ###
        loaded_files["$real_file"]="loaded"
        load_order+=("$file")
        
        [[ "$debug" == "true" ]] && echo "DEBUG: Successfully loaded: $file"
        return 0
    }
    
    ### Load configuration using the enhanced loader ###
    load_config "$project_root" "$debug" || return 1
    
    ### Export load information for debugging ###
    if [[ "$debug" == "true" ]]; then
        echo "DEBUG: Load order:"
        printf "  %s\n" "${load_order[@]}"
    fi
    
    return 0
}


_load_config() {
   ### Determine Project root dynamically ###
   local script_path="$(realpath "${BASH_SOURCE[0]}")"
   local script_dir="$(dirname "$script_path")"
   local project_root="$(dirname "$script_dir")"
   
   ### Look for project.conf in Standard Locations ###
   local config_file=""
   if [ -f "$project_root/configs/project.conf" ]; then

       config_file="$project_root/configs/project.conf"

   elif [ -f "$project_root/project.conf" ]; then

       config_file="$project_root/project.conf"

   else

       print --error "Project configuration not found"
       return 1

   fi
   
   ### Source main configuration if found ###
   if [ -f "$config_file" ]; then

       source "$config_file"

   fi
   
   ### Load additional configuration files from configs/ ###
   if [ -d "$project_root/configs" ]; then

       for conf in "$project_root/configs"/*.conf; do

           ### Skip files starting with underscore and project.conf (already loaded) ###
           local basename=$(basename "$conf")

           if [[ ! "$basename" =~ ^_ ]] && [ "$conf" != "$config_file" ] && [ -f "$conf" ]; then

               source "$conf"

           fi

       done

   fi
   
   ### Load helper scripts from scripts/helper/ ###
   if [ -d "$project_root/scripts/helper" ]; then

       for script in "$project_root/scripts/helper"/*.sh; do

           ### Skip files starting with underscore ###
           local basename=$(basename "$script")

           if [[ ! "$basename" =~ ^_ ]] && [ -f "$script" ]; then

               source "$script"

           fi

       done

   fi
   
   ### Load additional scripts from scripts/ ###
   if [ -d "$project_root/scripts" ]; then

       for script in "$project_root/scripts"/*.sh; do

           ### Skip files starting with underscore and helper.sh (avoid self-sourcing) ###
           local basename=$(basename "$script")

           if [[ ! "$basename" =~ ^_ ]] && [ "$script" != "$script_path" ] && [ -f "$script" ]; then

               source "$script"

           fi

       done

   fi

    ### Load utility Scripts from utilities/ ###
    if [ -d "$project_root/utilities" ]; then

        for util in "$project_root/utilities"/*.sh; do

            ### Skip files starting with underscore ###
            local basename=$(basename "$util")

            if [[ ! "$basename" =~ ^_ ]] && [ -f "$util" ]; then

                source "$util"

            fi

        done

    fi

   return 0
}


################################################################################
### === USER INTERACTION FUNCTIONS === ###
################################################################################

### Universal User Input Function ###
ask() {
    ### Log startup arguments ###
    log --info "${FUNCNAME[0]} called with Arguments: ($*)"

    ################################################################################
    ### === INTERNAL ASK FUNCTIONS === ###
    ################################################################################
    
    ### Ask yes/no Question (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _yes_no() {
        local question="$1"
        local default="${2:-no}"
        
        ### Auto-answer with yes if YES variable is set to true ###
        if [ "${YES:-false}" = "true" ]; then
            print --info "$question [auto-answered: yes]"
            return 0
        fi
        
        local prompt="$question"
        case "$default" in
            yes|y) prompt="$prompt [Y/n]" ;;
            no|n)  prompt="$prompt [y/N]" ;;
            *)     prompt="$prompt [y/n]" ;;
        esac
        
        while true; do
            read -p "$prompt: " answer
            
            ### Use default if empty ###
            if [ -z "$answer" ]; then
                answer="$default"
            fi
            
            case "$answer" in
                yes|y|Y|YES) return 0 ;;
                no|n|N|NO)   return 1 ;;
                *) print --warning "Please answer yes or no" ;;
            esac
        done
    }
    
    ### Ask for Input with Validation (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _input() {
        local prompt="$1"
        local default="$2"
        local validator="$3"  ### Optional validation function ###
        
        while true; do
            if [ -n "$default" ]; then
                read -p "$prompt [$default]: " input
                input="${input:-$default}"
            else
                read -p "$prompt: " input
            fi
            
            ### Validate Input if validator provided ###
            if [ -n "$validator" ] && declare -f "$validator" >/dev/null 2>&1; then
                if "$validator" "$input"; then
                    echo "$input"
                    return 0
                else
                    print --warning "Invalid input, please try again"
                fi
            else
                echo "$input"
                return 0
            fi
        done
    }
    
    ### Ask for Password (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _password() {
        local prompt="${1:-Enter password}"
        local verify="${2:-false}"
        
        while true; do
            read -s -p "$prompt: " password
            echo ""
            
            if [ "$verify" = "true" ]; then
                read -s -p "Verify password: " password2
                echo ""
                
                if [ "$password" = "$password2" ]; then
                    echo "$password"
                    return 0
                else
                    print --error "Passwords do not match. Please try again."
                fi
            else
                echo "$password"
                return 0
            fi
        done
    }
    
    ### Select from Menu (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _select() {
        local title="$1"
        shift
        local options=("$@")
        
        print --header "$title"
        
        for i in "${!options[@]}"; do
            print "  [$((i+1))] ${options[$i]}"
        done
        print "  [0] Cancel"
        print --cr
        
        while true; do
            read -p "Please select [0-${#options[@]}]: " selection
            
            if [ "$selection" = "0" ]; then
                return 1
            elif [ "$selection" -ge 1 ] && [ "$selection" -le "${#options[@]}" ] 2>/dev/null; then
                echo $((selection - 1))
                return 0
            else
                print --warning "Invalid selection"
            fi
        done
    }
    
    ### Confirm action (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _confirm() {
        local action="$1"
        local danger="${2:-false}"
        
        if [ "$danger" = "true" ]; then
            print --warning "This action cannot be undone!"
        fi
        
        _yes_no "Are you sure you want to $action?" "no"
    }
    
    ### Parse Arguments ###
    case "$1" in
        --yes-no|-y)
            shift
            _yes_no "$@"
            ;;

        --input|-i)
            shift
            _input "$@"
            ;;

        --password|-p)
            shift
            _password "$@"
            ;;

        --select|-s)
            shift
            _select "$@"
            ;;

        --confirm|-c)
            shift
            _confirm "$@"
            ;;
            
        --help|-h)
            show_help
            return 0
            ;;

        *)
            print --invalid "${FUNCNAME[0]}" "$1"
            return 1
            ;;

    esac
}


################################################################################
### === UTILITY & FLOW CONTROL FUNCTIONS === ###
################################################################################

### Universal Utility Function ###
utility() {
    ### Log startup arguments ###
    log --info "${FUNCNAME[0]} called with Arguments: ($*)"

    ################################################################################
    ### === INTERNAL UTILITY FUNCTIONS === ###
    ################################################################################
    
    ### Pause execution (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _pause() {
        local message="${1:-Press Enter to continue...}"
        read -p "$message" -r
    }
    
    ### Countdown timer (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _countdown() {
        local seconds="${1:-10}"
        local message="${2:-Continuing in}"
        
        while [ $seconds -gt 0 ]; do
            printf "\r%s %d seconds... " "$message" "$seconds"
            sleep 1
            ((seconds--))
        done
        printf "\r%*s\r" ${#message} ""  ### Clear line ###
    }
    
    ### Show spinner (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _spinner() {
        local pid="$1"
        local delay="${2:-0.1}"
        local spinstr='|/-\'
        
        while kill -0 "$pid" 2>/dev/null; do
            local temp=${spinstr#?}
            printf " [%c]  " "$spinstr"
            local spinstr=$temp${spinstr%"$temp"}
            sleep $delay
            printf "\b\b\b\b\b\b"
        done
        printf "    \b\b\b\b"
    }
    
    ### Progress bar (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _progress() {
        local current="$1"
        local total="$2"
        local description="${3:-Progress}"
        local width="${4:-50}"
        
        local percent=$((current * 100 / total))
        local filled=$((width * current / total))
        
        printf "\r["
        printf "%${filled}s" | tr ' ' '='
        printf "%$((width - filled))s" | tr ' ' '-'
        printf "] %3d%% %s" "$percent" "$description"
        
        [ "$current" -eq "$total" ] && echo
    }
    
    ### Clear screen with optional lines (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _clear() {
        local lines="${1:-0}"
        
        if [ "$lines" -eq 0 ]; then
            clear
        else
            for ((i=0; i<lines; i++)); do
                printf "\n"
            done
        fi
    }
    
    ### Parse Arguments ###
    case "$1" in
        --pause|-p)
            shift
            _pause "$@"
            ;;

        --countdown|-c)
            shift
            _countdown "$@"
            ;;

        --spinner|-s)
            shift
            _spinner "$@"
            ;;

        --progress|-pr)
            shift
            _progress "$@"
            ;;

        --clear|-cl)
            shift
            _clear "$@"
            ;;
            
        --help|-h)
            show_help
            return 0
            ;;

        *)
            print --invalid "${FUNCNAME[0]}" "$1"
            return 1
            ;;

    esac
}


################################################################################
### === MAIN EXECUTION === ###
################################################################################

### Cleanup Function ###
cleanup() {
    log --info "Helper Functions cleanup"
}

### Main Function ###
main() {
    clear

    ### Load configuration and dependencies ###
    load_config
    
    ### Initialize logging ###
    log --init "${LOG_DIR}/${PROJECT_NAME:-helper}.log" "${LOG_LEVEL:-INFO}"
    
    ### Log startup ###
    log --info "${header} v${version} startup: $*"
    
    ### Check if no arguments provided ###
    if [ $# -eq 0 ]; then
        show --header "${header} v${version}"
        show --doc --help
        exit 0
    else
        ### Parse and execute arguments ###
        parse_arguments "$@"
    fi
}

### Initialize when run directly ###
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
   ### Running directly ###
   main "$@"
else
   ### Being sourced ###
   load_config
   print --success "Helper functions loaded. Type 'show --menu' for an interactive Menu."
fi

#!/bin/bash
################################################################################
### Load Configuration with Dependency Management — Complete Utility Function
### Loads Project Configuration Files with circular dependency Detection
### Provides comprehensive Configuration loading for bash Framework Projects
################################################################################
### Project: Universal Helper Library
### Version: 3.0.1
### Author:  Mawage (Development Team)
### Date:    2025-09-13
### License: MIT
### Usage:   Source this Function to load Project Configurations with Dependencies
################################################################################

readonly header="Configuration Loader with Dependency Management"

readonly version="3.0.1"
readonly commit="Complete Configuration Loader with Dependency Tracking and Project Compliance"


################################################################################
### === CONFIGURATION LOADING WITH DEPENDENCY MANAGEMENT === ###
################################################################################

### Load Configuration Files with Dependency Tracking ###
load_config() {

	### Log startup arguments ###
	log --info "${FUNCNAME[0]} called with arguments: ($*)"

	################################################################################
	### === INTERNAL LOAD_CONFIG FUNCTIONS === ###
	################################################################################

	### Load file with dependency tracking (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_load_file() {
		local file="$1"
		local real_file

		real_file=$(realpath "$file" 2>/dev/null) || return 1

		### Skip if already loaded ###
		if [[ -n "${loaded_files[$real_file]}" ]]; then				### Check load status ###

			case "${loaded_files[$real_file]}" in

				"loading")
					[[ "$debug" == "true" ]] && echo "DEBUG: Circular dependency detected: $file"
					return 0
					;;

				"loaded")
					[[ "$debug" == "true" ]] && echo "DEBUG: Already loaded, skipping: $file"
					return 0
					;;

			esac

		fi

		### Mark as loading ###
		loaded_files["$real_file"]="loading"
		[[ "$debug" == "true" ]] && echo "DEBUG: Loading: $file"

		### Source the file ###
		# shellcheck source=/dev/null
		if source "$file"; then							### Load successful ###

			loaded_files["$real_file"]="loaded"
			load_order+=("$file")
			[[ "$debug" == "true" ]] && echo "DEBUG: Successfully loaded: $file"
			return 0

		else									### Load failed ###

			unset loaded_files["$real_file"]
			print --error "Failed to load: $file"
			return 1

		fi

	}

	### Validate directory existence (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_validate_dirs() {
		local missing_dirs=()

		if [[ -n "${REQUIRED_DIRS[*]}" ]]; then				### Check required directories ###

			[[ "$debug" == "true" ]] && echo "DEBUG: Validating required directories: ${REQUIRED_DIRS[*]}"

			for dir in "${REQUIRED_DIRS[@]}"; do

				eval "dir=\"$dir\""					### Expand variables ###

				if [[ ! -d "$dir" ]]; then				### Directory missing ###

					missing_dirs+=("$dir")
					[[ "$debug" == "true" ]] && echo "DEBUG: Missing required directory: $dir"

				fi

			done

			if [[ ${#missing_dirs[@]} -gt 0 ]]; then			### Report missing directories ###

				print --warning "Warning: Missing required directories: ${missing_dirs[*]}"

			fi

		fi

	}

	### Validate file existence (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_validate_files() {
		local missing_files=()

		if [[ -n "${REQUIRED_FILES[*]}" ]]; then			### Check required files ###

			[[ "$debug" == "true" ]] && echo "DEBUG: Validating required files: ${REQUIRED_FILES[*]}"

			for file in "${REQUIRED_FILES[@]}"; do

				eval "file=\"$file\""					### Expand variables ###

				if [[ ! -f "$file" ]]; then				### File missing ###

					missing_files+=("$file")
					[[ "$debug" == "true" ]] && echo "DEBUG: Missing required file: $file"

				fi

			done

			if [[ ${#missing_files[@]} -gt 0 ]]; then		### Report missing files ###

				print --warning "Warning: Missing required files: ${missing_files[*]}"

			fi

		fi

	}

	################################################################################
	### === MAIN LOAD_CONFIG LOGIC === ###
	################################################################################

    ### Parse Parameters with intelligent Detection ###
    local project_root_arg=""
    local debug="false"

    ### Intelligent parameter parsing ###
    if [[ $# -eq 1 ]]; then						### Single parameter ###

        if [[ "$1" == "true" || "$1" == "false" ]]; then		### Boolean parameter ###

            debug="$1"
            project_root_arg=""					### Use auto-detection ###

        else								### Path parameter ###

            project_root_arg="$1"
            debug="false"

        fi

    elif [[ $# -eq 2 ]]; then						### Two parameters ###

        project_root_arg="$1"
        debug="$2"

    fi

	### Enable debug output ###
	[[ "$debug" == "true" ]] && set -x

	### Initialize dependency tracking ###
	declare -A loaded_files
	local load_order=()

	### Determine project root path ###
	local project_root

	if [[ -n "$project_root_arg" ]]; then					### Use provided path ###

		project_root="$project_root_arg"

		if [[ ! -d "$project_root" ]]; then				### Validate provided path ###

			print --error "Error: Provided path '$project_root' is not a directory."
			return 1

		fi

		[[ "$debug" == "true" ]] && echo "DEBUG: Using provided project_root: $project_root"

	else									### Auto-detect project root ###

		local script_path script_dir

		script_path="$(realpath "${BASH_SOURCE[0]}")"
		script_dir="$(dirname "$script_path")"
		project_root="$(dirname "$script_dir")"

		[[ "$debug" == "true" ]] && echo "DEBUG: Auto-detected project_root: $project_root"

	fi

	### Search for project.conf ###
	local project_conf_path
	local config_found=false

    ### Try multiple locations ###
    local config_locations=(
        "$project_root/configs/project.conf"
        "$project_root/project.conf" 
        "$project_root/config/project.conf"
    )

    for conf_location in "${config_locations[@]}"; do
        if [[ -f "$conf_location" ]]; then
            project_conf_path="$conf_location"
            config_found=true
            [[ "$debug" == "true" ]] && echo "DEBUG: Found config at: $conf_location"
            break
        fi
    done

	### Exit if no configuration found ###
	if [[ "$config_found" != "true" ]]; then				### No config found ###

		print --error "Error: Project configuration not found in any standard location."
		return 1

	fi

	### Load project.conf with dependency tracking ###
	_load_file "$project_conf_path" || {					### Load main config ###

		print --error "Error: Failed to source project configuration."
		return 1

	}

	### Set PROJECT_ROOT ###
	PROJECT_ROOT="$project_root"
	export PROJECT_ROOT

	[[ "$debug" == "true" ]] && echo "DEBUG: Set PROJECT_ROOT=$PROJECT_ROOT"

	### Load HELPER_CONFIG if exists ###
	if [[ -n "$HELPER_CONFIG" && -f "$HELPER_CONFIG" ]]; then		### Load helper config ###

		_load_file "$HELPER_CONFIG" || {
			print --warning "Warning: Failed to source helper configuration: $HELPER_CONFIG"
		}

		[[ "$debug" == "true" ]] && echo "DEBUG: Processed HELPER_CONFIG: $HELPER_CONFIG"

	fi

	### Load files from configured directories ###
	if [[ -n "${LOAD_CONFIG_DIRS[*]}" ]]; then				### Process configured directories ###

		local dir file pattern basename exclude exclusion
		local files_loaded=0

		[[ "$debug" == "true" ]] && echo "DEBUG: Processing LOAD_CONFIG_DIRS: ${LOAD_CONFIG_DIRS[*]}"
		[[ "$debug" == "true" ]] && echo "DEBUG: Using patterns: ${LOAD_CONFIG_PATTERN[*]}"
		[[ "$debug" == "true" ]] && echo "DEBUG: Exclusion patterns: ${LOAD_CONFIG_EXCLUSION[*]}"

		for dir in "${LOAD_CONFIG_DIRS[@]}"; do

			eval "dir=\"$dir\""					### Expand variables ###

			if [[ ! -d "$dir" ]]; then				### Skip non-existent directories ###

				[[ "$debug" == "true" ]] && echo "DEBUG: Skipping non-existent directory: $dir"
				continue

			fi

			[[ "$debug" == "true" ]] && echo "DEBUG: Processing directory: $dir"

			for pattern in "${LOAD_CONFIG_PATTERN[@]}"; do		### Process each pattern ###

				[[ "$debug" == "true" ]] && echo "DEBUG: Searching for pattern: $pattern in $dir"

				shopt -s nullglob					### Handle no matches ###

				for file in "$dir"/$pattern; do

					[[ -f "$file" ]] || continue			### Skip non-files ###

					basename=$(basename "$file")
					exclude=0

					if [[ -n "${LOAD_CONFIG_EXCLUSION[*]}" ]]; then	### Check exclusions ###

						for exclusion in "${LOAD_CONFIG_EXCLUSION[@]}"; do

							case "$basename" in

								$exclusion)
									exclude=1
									[[ "$debug" == "true" ]] && echo "DEBUG: Excluding $file (matches $exclusion)"
									break
									;;

							esac

						done

					fi

					[[ "$exclude" -eq 1 ]] && continue		### Skip excluded ###

					if [[ "$file" -ef "${BASH_SOURCE[0]}" ]]; then	### Skip self-reference ###

						[[ "$debug" == "true" ]] && echo "DEBUG: Skipping self-reference: $file"
						continue

					fi

					### Skip already loaded files ###
					real_file_path=$(realpath "$file" 2>/dev/null)

					if [[ -n "${loaded_files[$real_file_path]}" ]]; then	### Already processed ###

						[[ "$debug" == "true" ]] && echo "DEBUG: Skipping already loaded: $file"
						continue

					fi

					### Load file with dependency tracking ###
					if _load_file "$file"; then			### Load successful ###

						((files_loaded++))
						[[ "$debug" == "true" ]] && echo "DEBUG: Loaded file #$files_loaded: $file"

					else						### Load failed ###

						print --warning "Warning: Failed to load: $file"

					fi

				done

				shopt -u nullglob					### Restore glob behavior ###

			done

		done

		[[ "$debug" == "true" ]] && echo "DEBUG: Total additional files loaded: $files_loaded"

	else									### No directories configured ###

		[[ "$debug" == "true" ]] && echo "DEBUG: No LOAD_CONFIG_DIRS defined, skipping pattern-based loading"

	fi

	### Validate required resources ###
	_validate_dirs								### Check directories ###
	_validate_files								### Check files ###

	### Export configuration status ###
	export PROJECT_CONFIG_LOADED="true"
	export PROJECT_CONFIG_VERSION="${PROJECT_VERSION:-unknown}"
	export LOAD_CONFIG_FILES_COUNT="${#load_order[@]}"

	### Disable debug output ###
	[[ "$debug" == "true" ]] && set +x

	### Final debug report ###
	if [[ "$debug" == "true" ]]; then					### Debug summary ###

		echo "DEBUG: =========================================="
		echo "DEBUG: Configuration loading completed"
		echo "DEBUG: Project Root: $PROJECT_ROOT"
		echo "DEBUG: Total files loaded: ${#load_order[@]}"
		echo "DEBUG: Load order:"

		local i=1

		for file in "${load_order[@]}"; do

			printf "DEBUG:   %2d. %s\n" "$i" "$file"
			((i++))

		done

		echo "DEBUG: =========================================="

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

### Main Function ###
main() {

	### Load configuration and dependencies ###
	load_config

	### Initialize logging ###
	log --init "${LOG_DIR}/${PROJECT_NAME:-helper}.log" "${LOG_LEVEL:-INFO}"

	### Log startup ###
	log --info "${header} v${version} startup: $*"

	### Check if no Arguments provided ###
	if [ $# -eq 0 ]; then

		show --header "${header} v${version}"
		show --doc --help
		exit 0

	else

        ### Parse Arguments ###
        parse_arguments "$@"

	fi

}


### Initialize when run directly ###
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
	### Running directly as Script ###
	main "$@"
else
	### Being sourced as library ###
	### Functions loaded and ready for use ###
	:
fi
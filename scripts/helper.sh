#!/bin/bash
################################################################################
### Load Configuration with Dependency Management — Complete Utility Function
### Loads Project Configuration Files with circular dependency Detection
### Provides comprehensive Configuration loading for bash Framework Projects
################################################################################
### Project: Universal Helper Library
### Version: 3.0.15
### Author:  Mawage (Development Team)
### Date:    2025-09-17
### License: MIT
### Usage:   Source this Function to load Project Configurations with Dependencies
### Commit:  Complete Configuration Loader with Dependency Tracking and Project Compliance"
################################################################################


################################################################################
### Parse Command Line Arguments ###
################################################################################

### Parse all Command Line Arguments ###
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
                ### Pass all other Arguments ###
                exit $?
                ;;
        esac
    done
}


################################################################################
### === CONFIGURATION LOADING WITH DEPENDENCY MANAGEMENT === ###
################################################################################

### Load Configuration Files with Dependency Tracking ###
load_config() {

    ### Log only if Log Function exists ###
    if declare -f log >/dev/null 2>&1; then
    	### Log Startup Arguments ###
        log --info "${FUNCNAME[0]} Called with Arguments: ($*)"
    fi

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
### === CONFIGURATION LOADING WITH DEPENDENCY MANAGEMENT === ###
################################################################################

debug() {
	local log_level="${1:---info}"
	local caller_function="$2"
	local parameter="${3:-empty}"
	local level="${4:-1}"
	local msg="${5:-no message}"

	printf "  ${GN}%-10s${NC} %-30s ${MG}%s${NC} %-10s${NC} %-10s ${GR}%-30s${NC}\n" \
			"${caller_function}" "${parameter}" "Level:" "${level}" "${msg}"

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

### Header Information Management, Reading & Writing of the Header Information ###
header() {

	### Log Startup Arguments ###
	log --info "${FUNCNAME[0]} called with Arguments: ($*)"

	################################################################################
	### === INTERNAL HEADER FUNCTIONS === ###
	################################################################################

	### Create new header block (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_create_header() {
		local file="$1"
		local template_file="$HELP_FILE_DIR/header.md"
		local current_date

		current_date=$(date +%Y-%m-%d)

		### Check if template exists ###
		if [[ ! -f "$template_file" ]]; then
			print --error "Header template not found: $template_file"
			return 1
		fi

		### Read template and substitute variables ###
		local template_content
		template_content=$(cat "$template_file")

		### Substitute project variables ###
		template_content=${template_content//\${PROJECT_NAME}/${PROJECT_NAME:-"Unknown Project"}}
		template_content=${template_content//\${PROJECT_AUTHOR}/${PROJECT_AUTHOR:-"Unknown Author"}}
		template_content=${template_content//\${PROJECT_LICENSE}/${PROJECT_LICENSE:-"MIT"}}
		template_content=${template_content//\${CURRENT_DATE}/$current_date}

		### Write to target file ###
		echo "$template_content" > "$file"
	}

	### Get header field value (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_get_field() {
		local file="$1"
		local field="$2"

		case "$field" in
			header)
				grep "^### .*—" "$file" | head -1 | sed 's/^### \(.*\) —.*/\1/' | sed 's/[[:space:]]*$//'
				;;

			description)
				grep "^### .*—" "$file" -A 1 | tail -1 | sed 's/^### //' | sed 's/[[:space:]]*$//'
				;;

			purpose)
				grep "^### .*—" "$file" -A 2 | tail -1 | sed 's/^### //' | sed 's/[[:space:]]*$//'
				;;

			project)
				grep "^### Project:" "$file" | sed 's/^### Project:[[:space:]]*//'
				;;

			version)
				grep "^### Version:" "$file" | sed 's/^### Version:[[:space:]]*//'
				;;

			author)
				grep "^### Author:" "$file" | sed 's/^### Author:[[:space:]]*//'
				;;

			date)
				grep "^### Date:" "$file" | sed 's/^### Date:[[:space:]]*//'
				;;

			license)
				grep "^### License:" "$file" | sed 's/^### License:[[:space:]]*//'
				;;

			usage)
				grep "^### Usage:" "$file" | sed 's/^### Usage:[[:space:]]*//'
				;;

			commit)
				grep "^### Commit:" "$file" | sed 's/^### Commit:[[:space:]]*//'
				;;

			*)
				return 1
				;;

		esac
	}

	### Set header field value (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_set_field() {
		local file="$1"
		local field="$2"
		local value="$3"
		local current_date

		current_date=$(date +%Y-%m-%d)

		case "$field" in
			header)
				sed -i "s/^### .*—.*/### $value — Main Description/" "$file"
				;;

			description)
				### Find line after header line and replace ###
				local line_num
				line_num=$(grep -n "^### .*—" "$file" | head -1 | cut -d: -f1)
				if [[ -n "$line_num" ]]; then
					sed -i "$((line_num + 1))s/.*/### $value/" "$file"
				fi
				;;

			purpose)
				### Find second line after header line and replace ###
				local line_num
				line_num=$(grep -n "^### .*—" "$file" | head -1 | cut -d: -f1)
				if [[ -n "$line_num" ]]; then
					sed -i "$((line_num + 2))s/.*/### $value/" "$file"
				fi
				;;

			project)
				if grep -q "^### Project:" "$file"; then
					sed -i "s/^### Project:.*/### Project: $value/" "$file"
				else
					_insert_field_after_header "$file" "Project: $value"
				fi
				;;

			version)
				if _validate_version "$value"; then
					if grep -q "^### Version:" "$file"; then
						sed -i "s/^### Version:.*/### Version: $value/" "$file"
					else
						_insert_field_after_header "$file" "Version: $value"
					fi
					### Auto-update date ###
					sed -i "s/^### Date:.*/### Date:    $current_date/" "$file"
				else
					print --error "Invalid version format: $value"
					return 1
				fi
				;;

			author)
				if grep -q "^### Author:" "$file"; then
					sed -i "s/^### Author:.*/### Author:  $value/" "$file"
				else
					_insert_field_after_header "$file" "Author:  $value"
				fi
				;;

			date)
				if grep -q "^### Date:" "$file"; then
					sed -i "s/^### Date:.*/### Date:    $value/" "$file"
				else
					_insert_field_after_header "$file" "Date:    $value"
				fi
				;;

			license)
				if grep -q "^### License:" "$file"; then
					sed -i "s/^### License:.*/### License: $value/" "$file"
				else
					_insert_field_after_header "$file" "License: $value"
				fi
				;;

			usage)
				if grep -q "^### Usage:" "$file"; then
					sed -i "s/^### Usage:.*/### Usage:   $value/" "$file"
				else
					_insert_field_after_header "$file" "Usage:   $value"
				fi
				;;

			commit)
				if grep -q "^### Commit:" "$file"; then
					sed -i "s/^### Commit:.*/### Commit:  $value/" "$file"
				else
					_insert_field_after_header "$file" "Commit:  $value"
				fi

				### Auto-update date ###
				sed -i "s/^### Date:.*/### Date:    $current_date/" "$file"
				;;
			*)
				return 1
				;;

		esac
	}

	### Insert field after header block (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_insert_field_after_header() {
		local file="$1"
		local field="$2"
		local line_num

		### Find end of first header block ###
		line_num=$(grep -n "^################################################################################$" "$file" | sed -n '2p' | cut -d: -f1)

		if [[ -n "$line_num" ]]; then
			### Insert before the closing header line ###
			sed -i "${line_num}i### $field" "$file"
		fi
	}

	### Validate version format (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_validate_version() {
		local version="$1"

		### Check semantic versioning format (MAJOR.MINOR.PATCH) ###
		if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			return 0
		else
			return 1
		fi
	}

	### Check if file has header (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_has_header() {
		local file="$1"

		grep -q "^### .*—" "$file" 2>/dev/null
	}

	### Display current header (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_show_header() {
		local file="$1"

		if [[ ! -f "$file" ]]; then
			print --error "File not found: $file"
			return 1
		fi

		print --header "Header Information: $file"
		print --cr

		local fields=("header" "description" "purpose" "project" "version" "author" "date" "license" "usage" "commit")

		for field in "${fields[@]}"; do
			local value
			value=$(_get_field "$file" "$field")
			if [[ -n "$value" ]]; then
				printf "%-12s: %s\n" "$field" "$value"
			fi
		done
	}

	################################################################################
	### === MAIN HEADER LOGIC === ###
	################################################################################

	local target_file=""
	local operation=""
	local field=""
	local value=""

	### Parse Arguments ###
	while [[ $# -gt 0 ]]; do

		case "$1" in

			--file|-f)
				target_file="$2"
				shift 2
				;;

			--get|-g)
				operation="get"
				field="$2"
				shift 2
				;;

			--set|-s)
				operation="set"
				if [[ -n "$2" && "$2" != --* ]]; then
					field="$2"
					shift 2
				else
					shift
				fi
				;;

			--show|--display)
				operation="show"
				shift
				;;

			--create)
				operation="create"
				shift
				;;

			--header)
				if [[ "$operation" == "set" ]]; then
					field="header"
					value="$2"
					shift 2
				else
					operation="get"
					field="header"
					shift
				fi
				;;

			--description)
				if [[ "$operation" == "set" ]]; then
					field="description"
					value="$2"
					shift 2
				else
					operation="get"
					field="description"
					shift
				fi
				;;

			--purpose)
				if [[ "$operation" == "set" ]]; then
					field="purpose"
					value="$2"
					shift 2
				else
					operation="get"
					field="purpose"
					shift
				fi
				;;

			--project)
				if [[ "$operation" == "set" ]]; then
					field="project"
					value="$2"
					shift 2
				else
					operation="get"
					field="project"
					shift
				fi
				;;

			--version|-v)
				if [[ "$operation" == "set" ]]; then
					field="version"
					value="$2"
					shift 2
				else
					operation="get"
					field="version"
					shift
				fi
				;;

			--author|-a)
				if [[ "$operation" == "set" ]]; then
					field="author"
					value="$2"
					shift 2
				else
					operation="get"
					field="author"
					shift
				fi
				;;

			--date|-d)
				if [[ "$operation" == "set" ]]; then
					field="date"
					value="$2"
					shift 2
				else
					operation="get"
					field="date"
					shift
				fi
				;;

			--license|-l)
				if [[ "$operation" == "set" ]]; then
					field="license"
					value="$2"
					shift 2
				else
					operation="get"
					field="license"
					shift
				fi
				;;

			--usage|-u)
				if [[ "$operation" == "set" ]]; then
					field="usage"
					value="$2"
					shift 2
				else
					operation="get"
					field="usage"
					shift
				fi
				;;

			--commit|-c)
				if [[ "$operation" == "set" ]]; then
					field="commit"
					value="$2"
					shift 2
				else
					operation="get"
					field="commit"
					shift
				fi
				;;

			--help|-h)
				show --help
				return 0
				;;

			*)
				### Handle value for set operation ###
				if [[ "$operation" == "set" && -n "$field" && -z "$value" ]]; then
					value="$1"
					shift
				else
					print --invalid "${FUNCNAME[0]}" "$1"
					return 1
				fi
				;;

		esac

	done

	### Validate required parameters ###
	if [[ -z "$target_file" ]]; then
		print --error "No target file specified. Use --file <filename>"
		return 1
	fi

	### Execute operation ###
	case "$operation" in

		get)
			if [[ -z "$field" ]]; then
				print --error "No field specified for get operation"
				return 1
			fi

			if [[ ! -f "$target_file" ]]; then
				print --error "File not found: $target_file"
				return 1
			fi

			_get_field "$target_file" "$field"
			;;

		set)
			if [[ -z "$field" ]]; then
				print --error "No field specified for set operation"
				return 1
			fi

			if [[ -z "$value" ]]; then
				print --error "No value specified for set operation"
				return 1
			fi

			### Create file if it doesn't exist ###
			if [[ ! -f "$target_file" ]]; then
				touch "$target_file"
				_create_header "$target_file"
			elif ! _has_header "$target_file"; then
				### Add header to existing file ###
				local temp_file
				temp_file=$(mktemp)
				_create_header "$temp_file"
				cat "$target_file" >> "$temp_file"
				mv "$temp_file" "$target_file"
			fi

			_set_field "$target_file" "$field" "$value"
			;;

		show)
			_show_header "$target_file"
			;;

		create)
			if [[ -f "$target_file" ]]; then
				print --warning "File already exists: $target_file"
				ask --confirm "overwrite existing file" "true" || return 1
			fi

			_create_header "$target_file"
			print --success "Header created in: $target_file"
			;;

		*)
			print --error "No operation specified"
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
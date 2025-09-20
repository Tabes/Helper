#!/bin/bash
################################################################################
### Load Configuration with Dependency Management — Complete Utility Function
### Loads Project Configuration Files with circular dependency Detection
### Provides comprehensive Configuration loading for bash Framework Projects
################################################################################
### Project: Universal Helper Library
### Version: 3.0.19
### Author:  Mawage (Development Team)
### Date:    2025-09-20
### License: MIT
### Usage:   Source this Function to load Project Configurations with Dependencies
### Commit:  Complete Configuration Loader with Dependency Tracking and Project Compliance"
################################################################################

# shellcheck disable=

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

	### Validate required Parameters ###
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

### Universal Cursor Position Management ###
cursor_pos() {
    local action=""
    local col_param=""
    local row_param=""
    local get_col=false
    local get_row=false
    local save_pos=false
    local restore_pos=false
    
    ### Parse arguments ###
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --get)
                action="get"
                shift
                ;;

            --set)
                action="set"
                shift
                ### Parse numeric parameters for set ###
                if [[ "$1" =~ ^[+-]?[0-9]+$ ]]; then

                    col_param="$1"
                    shift

                    if [[ "$1" =~ ^[+-]?[0-9]+$ ]]; then

                        row_param="$1"
                        shift

                    fi

                fi
                ;;

            --col)
                get_col=true
                shift
                ;;

            --row)
                get_row=true
                shift
                ;;

            --save)
                save_pos=true
                shift
                ;;

            --restore)
                restore_pos=true
                shift
                ;;

            *)
                # TODO: Log unknown parameter when logging system available
                return 1
                ;;
        esac
    done
    
    ### Execute restore first if requested ###
    [[ "$restore_pos" == "true" ]] && {
        [[ -n "${POS[col]}" && -n "${POS[row]}" ]] && {
            tput cup $((POS[row] - 1)) $((POS[col] - 1)) 2>/dev/null || {
                # TODO: Log cursor movement failure when logging system available
                return 1
            }
        } || {
            # TODO: Log no saved position available when logging system available
            return 1
        }
    }
    
    ### Handle main action ###
    case "$action" in
        get)
            ### Get current cursor position and update POS array ###
            if IFS=';' read -sdR -p $'\E[6n' row col; then
                row="${row#*[}"
                POS[row]="$row"
                POS[col]="$col"
                
                ### Return requested Values ###
                if [[ "$get_col" == "true" && "$get_row" == "true" ]]; then

                    echo "${POS[col]} ${POS[row]}"

                elif [[ "$get_col" == "true" ]]; then

                    echo "${POS[col]}"

                elif [[ "$get_row" == "true" ]]; then

                    echo "${POS[row]}"

                else

                    echo "${POS[col]} ${POS[row]}"

                fi

            else

                echo "1 1"
                return 1

            fi
            ;;
            
		set)
			### Validate set parameters ###
			[[ -z "$col_param" ]] && {

				# TODO: Log no values provided for set when logging system available
				return 1

			}
			
			[[ ! "$col_param" =~ ^[+-]?[0-9]+$ ]] && {

				# TODO: Log validation failure when logging system available
				return 1

			}
			
			[[ -n "$row_param" && ! "$row_param" =~ ^[+-]?[0-9]+$ ]] && {

				# TODO: Log validation failure when logging system available
				return 1

			}
			
			### Get REAL current position from terminal ###
			local current_row=1
			local current_col=1
			
			if IFS=';' read -sdR -p $'\E[6n' row col; then

				current_row="${row#*[}"
				current_col="$col"

			fi
			
			local new_col="$col_param"
			local new_row="$current_row"  # Keep current row
			
			### Handle relative Column Positioning ###
			[[ "$col_param" =~ ^[+-] ]] && {

				new_col=$((current_col + col_param))

			}
			
			### Handle row Parameter if provided ###
			[[ -n "$row_param" ]] && {

				if [[ "$row_param" =~ ^[+-] ]]; then

					new_row=$((current_row + row_param))

				else

					new_row="$row_param"

				fi

			}
			
			### Bounds checking ###
			[[ "$new_col" -lt 1 ]] && new_col=1
			[[ "$new_row" -lt 1 ]] && new_row=1
			[[ "$new_col" -gt 200 ]] && new_col=200
			[[ "$new_row" -gt 200 ]] && new_row=200
			
			### Move Cursor to Position ###
			tput cup $((new_row - 1)) $((new_col - 1)) 2>/dev/null || {

				# TODO: Log cursor movement failure when logging system available
				return 1

			}
			;;

       "")
            ### No Action specified ###
            if [[ "$restore_pos" == "true" ]]; then

                # restore already handled above
                :

            else

                # TODO: Log no action specified when logging system available
                return 1

            fi
            ;;
            
        *)

            # TODO: Log invalid action when logging system available
            return 1
            ;;

    esac
    
    ### Handle save if requested ###
    [[ "$save_pos" == "true" ]] && {
        if IFS=';' read -sdR -p $'\E[6n' row col; then

            row="${row#*[}"
            POS[row]="$row"
            POS[col]="$col"

        fi
    }
    
    return 0
}

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
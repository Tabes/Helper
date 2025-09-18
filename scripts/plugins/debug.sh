#!/bin/bash
################################################################################
### Universal Helper Functions - Debug Output Plugin
### Advanced Debug System with Tabular Display and Call Stack Analysis
### Provides comprehensive debugging with auto-sized columns and function tracking
################################################################################
### Project: Universal Helper Library
### Version: 1.0.0
### Author:  Mawage (Development Team)
### Date:    2025-09-18
### License: MIT
### Usage:   Source this File to load Debug Functions or run directly for Demo
### Commit:  Initial Debug Plugin with tabular output and call stack tracking
################################################################################

# shellcheck disable=SC2120,SC2317,SC2329

### Enhanced Debug Function with Call Stack and Tabular Output ###
debug() {
	### Skip if debug is disabled ###
	[ "${debug:-false}" != "true" ] && return 0

	################################################################################
	### === INTERNAL DEBUG FUNCTIONS === ###
	################################################################################

	### Calculate column widths for tabular display (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_calculate_widths() {
		local -n data_ref=$1
		local -n widths_ref=$2
		local col_count="$3"
		
		### Initialize widths array ###
		for ((i=0; i<col_count; i++)); do
			widths_ref[$i]=0
		done
		
		### Calculate maximum width for each column ###
		for row in "${data_ref[@]}"; do
			IFS='|' read -ra cols <<< "$row"
			for ((i=0; i<${#cols[@]} && i<col_count; i++)); do
				local len=${#cols[$i]}
				[ $len -gt ${widths_ref[$i]} ] && widths_ref[$i]=$len
			done
		done
	}

	### Format and print table row (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_print_table_row() {
		local row="$1"
		local -n widths_ref=$2
		local is_header="${3:-false}"
		
		IFS='|' read -ra cols <<< "$row"
		
		### Print row with proper spacing ###
		printf "  ${GN}│${NC}"
		for ((i=0; i<${#cols[@]}; i++)); do
			if [ "$is_header" = "true" ]; then
				printf " ${BU}%-${widths_ref[$i]}s${NC} ${GN}│${NC}" "${cols[$i]}"
			else
				printf " %-${widths_ref[$i]}s ${GN}│${NC}" "${cols[$i]}"
			fi
		done
		printf "\n"
	}

	### Print table separator (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_print_separator() {
		local -n widths_ref=$1
		local col_count="$2"
		local char="${3:-─}"
		
		printf "  ${GN}├${NC}"
		for ((i=0; i<col_count; i++)); do
			printf "${GN}%s${NC}" "$(printf "%*s" $((${widths_ref[$i]} + 2)) | tr ' ' "$char")"
			[ $i -lt $((col_count - 1)) ] && printf "${GN}┼${NC}"
		done
		printf "${GN}┤${NC}\n"
	}

	### Get call stack information (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_get_call_stack() {
		local -n stack_ref=$1
		local max_depth="${2:-3}"
		
		stack_ref=()
		
		### Build call stack (skip debug function itself) ###
		for ((i=2; i<=${#FUNCNAME[@]} && i<=$((max_depth+1)); i++)); do
			local func="${FUNCNAME[$i]:-main}"
			local line="${BASH_LINENO[$((i-1))]:-?}"
			local file="${BASH_SOURCE[$i]:-${0##*/}}"
			
			### Extract filename only ###
			file="${file##*/}"
			
			stack_ref+=("${func}() [${file}:${line}]")
		done
	}

	### Format variables for display (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_format_variables() {
		local -n vars_ref=$1
		local -n data_ref=$2
		
		data_ref=("Variable|Value|Type|Length")
		
		for var_spec in "${vars_ref[@]}"; do
			IFS=':' read -ra parts <<< "$var_spec"
			local var_name="${parts[0]}"
			local var_value="${parts[1]:-${!var_name}}"
			local var_type="${parts[2]:-auto}"
			
			### Auto-detect type if not specified ###
			if [ "$var_type" = "auto" ]; then
				if [[ "$var_value" =~ ^[0-9]+$ ]]; then
					var_type="int"
				elif [[ "$var_value" =~ ^[0-9]*\.[0-9]+$ ]]; then
					var_type="float"
				elif [[ "$var_value" =~ ^(true|false)$ ]]; then
					var_type="bool"
				elif declare -p "$var_name" 2>/dev/null | grep -q "declare -a"; then
					var_type="array"
				else
					var_type="string"
				fi
			fi
			
			### Truncate long values ###
			local display_value="$var_value"
			if [ ${#display_value} -gt 30 ]; then
				display_value="${display_value:0:27}..."
			fi
			
			### Calculate length ###
			local length="${#var_value}"
			
			data_ref+=("$var_name|$display_value|$var_type|$length")
		done
	}

	################################################################################
	### === MAIN DEBUG LOGIC === ###
	################################################################################

	local log_level="info"
	local caller_function=""
	local parameters=""
	local level=1
	local message=""
	local variables=()
	local show_stack=false
	local max_stack_depth=3
	local table_columns=4

	### Parse Arguments ###
	while [[ $# -gt 0 ]]; do
		case $1 in
			--info|--error|--warning)
				log_level="${1#--}"
				shift
				;;
				
			--function|-f)
				caller_function="$2"
				shift 2
				;;
				
			--params|-p)
				parameters="$2"
				shift 2
				;;
				
			--level|-l)
				level="$2"
				shift 2
				;;
				
			--message|-m)
				message="$2"
				shift 2
				;;
				
			--vars|-v)
				### Parse variable specifications: var1:value1:type1,var2:value2:type2 ###
				IFS=',' read -ra variables <<< "$2"
				shift 2
				;;
				
			--stack|-s)
				show_stack=true
				[ -n "$2" ] && [[ "$2" =~ ^[0-9]+$ ]] && max_stack_depth="$2" && shift
				shift
				;;
				
			--columns|-c)
				table_columns="$2"
				shift 2
				;;
				
			*)
				### Positional arguments (legacy compatibility) ###
				[ -z "$caller_function" ] && caller_function="$1" && shift && continue
				[ -z "$parameters" ] && parameters="$1" && shift && continue
				[ -z "$level" ] && level="$1" && shift && continue
				[ -z "$message" ] && message="$1" && shift && continue
				shift
				;;
		esac
	done

	### Set defaults ###
	caller_function="${caller_function:-${FUNCNAME[1]:-unknown}}"
	parameters="${parameters:-empty}"
	message="${message:-no message}"

	### Color coding by log level ###
	local level_color=""
	case "$log_level" in
		error)   level_color="${RD}" ;;
		warning) level_color="${YE}" ;;
		info)    level_color="${CY}" ;;
		*)       level_color="${NC}" ;;
	esac

	### Print debug header with call information ###
	printf "\n${GN}┌─ DEBUG ─────────────────────────────────────────────────────────────────────┐${NC}\n"
	printf "${GN}│${NC} %s${level_color}%-8s${NC} ${GN}Function:${NC} %-20s ${GN}Level:${NC} %-2s ${GN}Params:${NC} %s${GN}│${NC}\n" \
		"[$(date '+%H:%M:%S')]" "$log_level" "$caller_function" "$level" "$parameters"
	printf "${GN}│${NC} ${GN}Message:${NC} %-66s ${GN}│${NC}\n" "$message"

	### Show call stack if requested ###
	if [ "$show_stack" = "true" ]; then
		local call_stack=()
		_get_call_stack call_stack "$max_stack_depth"
		
		printf "${GN}├─ Call Stack ───────────────────────────────────────────────────────────────┤${NC}\n"
		for ((i=0; i<${#call_stack[@]}; i++)); do
			printf "${GN}│${NC} %2d. %-70s ${GN}│${NC}\n" "$((i+1))" "${call_stack[$i]}"
		done
	fi

	### Show variables table if provided ###
	if [ ${#variables[@]} -gt 0 ]; then
		local table_data=()
		local column_widths=()
		
		_format_variables variables table_data
		_calculate_widths table_data column_widths "$table_columns"
		
		printf "${GN}├─ Variables ─────────────────────────────────────────────────────────────────┤${NC}\n"
		
		### Print header ###
		_print_table_row "${table_data[0]}" column_widths "true"
		_print_separator column_widths "$table_columns"
		
		### Print data rows ###
		for ((i=1; i<${#table_data[@]}; i++)); do
			_print_table_row "${table_data[$i]}" column_widths
		done
	fi

	### Close debug block ###
	printf "${GN}└─────────────────────────────────────────────────────────────────────────────┘${NC}\n"
}

################################################################################
### === USAGE EXAMPLES === ###
################################################################################

### Demo function to show debug usage ###
demo_debug() {
	local debug=true  # Enable debug for demo
	local user_name="John Doe"
	local user_age=30
	local is_active=true
	local config_path="/etc/myapp/config.conf"
	
	### Basic debug call ###
	debug --info --function "${FUNCNAME[0]}" --params "demo mode" --level 1 \
		  --message "Starting demo with basic debug output"
	
	### Debug with variables ###
	debug --warning --function "${FUNCNAME[0]}" --params "($*)" --level 2 \
		  --message "Processing user data" \
		  --vars "user_name:$user_name:string,user_age:$user_age:int,is_active:$is_active:bool,config_path:$config_path:path"
	
	### Debug with call stack ###
	debug --error --function "${FUNCNAME[0]}" --params "error simulation" --level 3 \
		  --message "Critical error occurred during processing" \
		  --stack 5 \
		  --vars "errno:404:int,error_msg:File not found:string"
}

### Simplified debug call (legacy compatibility) ###
debug_simple() {
	local debug=true
	debug --info "${FUNCNAME[0]}" "($*)" 2 "Legacy style debug call"
}

################################################################################
### === INTEGRATION EXAMPLE === ###
################################################################################

### Example of integration into existing print function ###
print_with_debug() {
	local debug=true
	local output_buffer=""
	local current_color="${NC}"
	local suppress_newline=false
	
	### Enhanced debug call showing internal state ###
	debug --info --function "${FUNCNAME[0]}" --params "($*)" --level 3 \
		  --message "Processing print arguments" \
		  --vars "output_buffer:$output_buffer:string,current_color:$current_color:string,suppress_newline:$suppress_newline:bool"
	
	### Your existing print logic here ###
	printf "This is a demo print with debug integration\n"
}
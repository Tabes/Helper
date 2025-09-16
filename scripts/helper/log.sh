#!/bin/bash
################################################################################
### Universal Helper Functions - Logging Library
### Comprehensive Logging Functions using print() Engine for Formatting
### Provides unified Log Function with structured Positioning and Formatting
################################################################################
### Project: Universal Helper Library
### Version: 2.1.1
### Author:  Mawage (Development Team)
### Date:    2025-09-15
### License: MIT
### Usage:   Source this File to load Logging Functions or run directly
### Commit:  Complete rewrite with helper.conf Integration and Numeric Parameters
################################################################################


################################################################################
### Parse Command Line Arguments ###
################################################################################

### Parse Command Line Arguments ###
parse_arguments() {

	while [[ $# -gt 0 ]]; do

		case $1 in
			--help|-h)
				show_help "log"
				exit 0
				;;

			--version|-V)
				print --version "${header}" "${version}" "${commit}"
				exit 0
				;;

			--demo|-d)
				log_demo
				exit 0
				;;

			--test|-t)
				run_log
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
### === LOGGING FUNCTIONS === ###
################################################################################

### Simple Test Version... ###
log() {
    case $1 in
        --info) level="INFO"; shift ;;
        --error) level="ERROR"; shift ;;
        --warning) level="WARNING"; shift ;;
        --debug) level="DEBUG"; shift ;;
        --success) level="SUCCESS"; shift ;;
        *) level="INFO" ;;  # Standard fallback
    esac
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="${LOG_FILE:-/tmp/script.log}"
    
    # Einfache Ausgabe
    echo "[$timestamp] [$level] $*" >> "$log_file"
    
    # Console output falls gewünscht
    [ "${VERBOSE:-false}" = "true" ] && echo "[$level] $*"
}

### Unified log Function using print() as formatting engine ###
_log() {

	### Local variables ###
	local log_level=""
	local log_file="${LOG_FILE:-${LOG_DIR:-/tmp}/${SCRIPT_NAME:-script}.log}"
	local timestamp=""
	local has_print_params=false
	local level_color=""
	local level_symbol=""

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_convert_numeric_positions() {
		### Convert numeric position parameters to -pos format for print() ###
		local converted_args=()
		local i=0
		local args=("$@")

		while [ $i -lt ${#args[@]} ]; do

			if [[ "${args[i]}" =~ ^[0-9]+$ ]]; then

				### Check if next parameter is also numeric (row parameter) ###
				if [ $((i+1)) -lt ${#args[@]} ] && [[ "${args[$((i+1))]}" =~ ^[0-9]+$ ]]; then

					### Position and row ###
					converted_args+=("-pos" "${args[i]}" "${args[$((i+1))]}")
					i=$((i+2))

				else

					### Position only ###
					converted_args+=("-pos" "${args[i]}")
					i=$((i+1))

				fi

			else

				### Regular parameter ###
				converted_args+=("${args[i]}")
				i=$((i+1))

			fi

		done

		printf '%s\n' "${converted_args[@]}"
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_create_log_file() {
		### Create log file with header if it doesn't exist ###
		local file="$1"
		local script_name="${SCRIPT_NAME:-${0##*/}}"

		if [ ! -f "$file" ]; then

			### Create directory if needed ###
			local log_dir=$(dirname "$file")
			[ ! -d "$log_dir" ] && mkdir -p "$log_dir"

			### Initialize log file with header using print() ###
			print -file "$file" -overwrite \
				--header "Log Session Started: $(date '+%Y-%m-%d %H:%M:%S')" \
				--cr \
				1 "Script:  $script_name" --cr \
				1 "PID:     $$" --cr \
				1 "User:    $(whoami)" --cr \
				1 "Host:    $(hostname)" --cr \
				1 "Dir:     $(pwd)" --cr \
				--cr \
				-line "=" 80 --cr

		fi
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_get_timestamp() {
		### Generate timestamp based on LOG_FORMAT ###
		case "${LOG_FORMAT:-timestamp}" in
			timestamp)
				timestamp=$(date '+%Y-%m-%d %H:%M:%S')
				;;
			iso8601)
				timestamp=$(date -Iseconds)
				;;
			unix)
				timestamp=$(date +%s)
				;;
			short)
				timestamp=$(date '+%H:%M:%S')
				;;
			*)
				timestamp=$(date '+%Y-%m-%d %H:%M:%S')
				;;
		esac
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_get_level_formatting() {
		### Set color and symbol for log level ###
		local level="$1"

		case "$level" in
			error)
				level_color="RD"
				level_symbol="${SYMBOL_ERROR:-✗}"
				;;
			warning)
				level_color="YE"
				level_symbol="${SYMBOL_WARNING:-⚠}"
				;;
			info)
				level_color="CY"
				level_symbol="${SYMBOL_INFO:-ℹ}"
				;;
			debug)
				level_color="MG"
				level_symbol="${SYMBOL_DEBUG:-🐛}"
				;;
			success)
				level_color="GN"
				level_symbol="${SYMBOL_SUCCESS:-✓}"
				;;
			*)
				level_color="NC"
				level_symbol="•"
				;;
		esac
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_log_rotate() {
		### Rotate log file if size limit exceeded ###
		local file="${1:-$log_file}"
		local max_size="${LOG_MAX_SIZE:-10M}"
		local max_files="${LOG_MAX_FILES:-5}"

		### Convert size to bytes ###
		local size_bytes
		case "$max_size" in
			*K) size_bytes=$((${max_size%K} * 1024)) ;;
			*M) size_bytes=$((${max_size%M} * 1024 * 1024)) ;;
			*G) size_bytes=$((${max_size%G} * 1024 * 1024 * 1024)) ;;
			*)  size_bytes="$max_size" ;;
		esac

		### Check if file exists and get size ###
		[ ! -f "$file" ] && return 0

		local current_size=0
		if command -v stat >/dev/null 2>&1; then
			current_size=$(stat --format=%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo 0)
		fi

		### Rotate if size exceeds limit ###
		if [ "$current_size" -gt "$size_bytes" ]; then

			### Rotate existing logs ###
			for ((i=$((max_files-1)); i>=1; i--)); do
				[ -f "${file}.$i" ] && mv "${file}.$i" "${file}.$((i+1))"
			done

			### Move current log ###
			mv "$file" "${file}.1"

			### Create new log with rotation notice ###
			print -file "$file" -overwrite \
				--header "Log Rotated: $(date '+%Y-%m-%d %H:%M:%S')" \
				--cr \
				1 "Previous log: ${file}.1" --cr \
				1 "Size: $current_size bytes (limit: $max_size)" --cr \
				--cr \
				-line "=" 80 --cr

		fi
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_standard_log_format() {
		### Standard log format using print() with helper.conf positions ###
		local level="$1"
		shift

		_get_timestamp
		_get_level_formatting "$level"

		### Check for rotation before writing ###
		if [ "${LOG_ROTATION:-true}" = "true" ]; then
			_log_rotate "$log_file"
		fi

		### Create log file if needed ###
		_create_log_file "$log_file"

		### Use LOG_TAB_POS from helper.conf or defaults ###
		local pos_timestamp="${LOG_TAB_POS[0]:-1}"
		local pos_level="${LOG_TAB_POS[2]:-22}"
		local pos_message="${LOG_TAB_POS[3]:-35}"

		### Standard positioned log entry ###
		if [ "${LOG_USE_REAL_TABS:-false}" = "true" ]; then

			### Use real tabs instead of positioning ###
			print -file "$log_file" \
				"[$timestamp]" -txt $'\t' \
				"[$level_symbol ${level^^}]" -txt $'\t' \
				"$*" \
				--cr

		else

			### Use positioned output with helper.conf positions ###
			print -file "$log_file" \
				"$pos_timestamp" "[$timestamp]" \
				"$pos_level" "$level_color" "[$level_symbol ${level^^}]" \
				"$pos_message" NC "$@" \
				--cr

		fi

		### Write to central log if configured ###
		if [ -n "$CENTRAL_LOG" ] && [ "$CENTRAL_LOG" != "$log_file" ]; then

			print -file "$CENTRAL_LOG" \
				"$pos_timestamp" "[$timestamp]" \
				"$pos_level" "$level_color" "[${SCRIPT_NAME:-script}] [$level_symbol ${level^^}]" \
				"$pos_message" NC "$@" \
				--cr

		fi

		### Console output if verbose enabled ###
		if [ "${VERBOSE:-false}" = "true" ] || [ "${DEBUG:-false}" = "true" ]; then

			case "$level" in
				error)
					print --error "$*"
					;;
				warning)
					print --warning "$*"
					;;
				info)
					print --info "$*"
					;;
				debug)
					[ "${DEBUG:-false}" = "true" ] && print "$level_color" "[DEBUG] $*"
					;;
				success)
					print --success "$*"
					;;
			esac

		fi
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_check_print_params() {
		### Check if parameters contain print() formatting options or numeric positions ###
		for arg in "$@"; do
			case "$arg" in
				-pos|-file|-array|-row|-ruler|-ruler2|-scale|-demo|-reset|\
				-header|-line|-msg|-txt|-t|--left|--right|-l|-r|--cr|-cr|\
				-back|-up|-delete|-override|-rel|-append|-overwrite|\
				-debug|-delay|-max|NC|RD|GN|YE|BU|CY|WH|MG)
					return 0
					;;

				*)
					### Check for numeric position parameters ###
					if [[ "$arg" =~ ^[0-9]+$ ]]; then

						return 0

					fi
					;;

			esac
		done

		return 1
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_log_search() {
		### Search in log files with highlighted output ###
		local pattern="$1"
		local file="${2:-$log_file}"
		local context="${3:-0}"

		if [ -f "$file" ]; then

			print --header "Search Results for '$pattern' in $(basename "$file")"
			print --cr

			if [ "$context" -gt 0 ]; then
				grep -n -C "$context" "$pattern" "$file"
			else
				grep -n "$pattern" "$file"
			fi | while IFS= read -r line; do

				case "$line" in
					*"[ERROR]"*)
						print RD "$line"
						;;
					*"[WARNING]"*)
						print YE "$line"
						;;
					*"[INFO]"*)
						print CY "$line"
						;;
					*"[DEBUG]"*)
						print MG "$line"
						;;
					*)
						print "$line"
						;;
				esac

			done

		else

			print --error "Log file not found: $file"
			return 1

		fi
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_log_tail() {
		### Show last entries from log file with colored output ###
		local file="${1:-$log_file}"
		local lines="${2:-20}"

		if [ -f "$file" ]; then

			print --header "Last $lines entries from $(basename "$file")"
			print --cr

			tail -n "$lines" "$file" | while IFS= read -r line; do

				case "$line" in
					*"[ERROR]"*)
						print RD "$line"
						;;
					*"[WARNING]"*)
						print YE "$line"
						;;
					*"[INFO]"*)
						print CY "$line"
						;;
					*"[DEBUG]"*)
						print MG "$line"
						;;
					*"###"*|*"#####"*)
						print BU "$line"
						;;
					*)
						print "$line"
						;;
				esac

			done

		else

			print --error "Log file not found: $file"
			return 1

		fi
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_log_template() {
		### Apply predefined log templates using helper.conf positions ###
		local template="$1"
		shift

		_get_timestamp
		_create_log_file "$log_file"

		### Use LOG_TAB_POS positions ###
		local pos_timestamp="${LOG_TAB_POS[0]:-1}"
		local pos_level="${LOG_TAB_POS[2]:-22}"
		local pos_func="${LOG_TAB_POS[3]:-35}"
		local pos_time="${LOG_TAB_POS[4]:-55}"
		local pos_extra="${LOG_TAB_POS[5]:-70}"

		case "$template" in
			performance)
				### Performance metrics template ###
				local func_name="$1"
				local exec_time="$2"
				local memory="$3"

				print -file "$log_file" \
					"$pos_timestamp" "[$timestamp]" \
					"$pos_level" GN "[PERF]" \
					"$pos_func" "Function: $func_name" \
					"$pos_time" "Time: ${exec_time}s" \
					"$pos_extra" "Mem: $memory" \
					--cr
				;;

			error-trace)
				### Error with stack trace template ###
				local error_msg="$1"
				local stack_trace="$2"

				print -file "$log_file" \
					"$pos_timestamp" "[$timestamp]" \
					"$pos_level" RD "[ERROR]" \
					"$pos_func" "$error_msg" \
					--cr \
					"$pos_func" "Stack: $stack_trace" \
					--cr
				;;

			security)
				### Security event template ###
				local event="$1"
				local user="$2"
				local source="$3"

				print -file "$log_file" \
					"$pos_timestamp" "[$timestamp]" \
					"$pos_level" RD "[SECURITY]" \
					"$pos_func" "Event: $event" \
					"$pos_time" "User: $user" \
					"$pos_extra" "From: $source" \
					--cr
				;;

			*)
				print --error "Unknown log template: $template"
				return 1
				;;
		esac
	}

	### Parse main log arguments ###
	while [[ $# -gt 0 ]]; do

		case $1 in
			--info|--error|--warning|--debug|--success)
				log_level="${1#--}"
				shift

				### Check if remaining parameters contain print() formatting ###
				if _check_print_params "$@"; then

					### Advanced formatting: convert numeric positions and pass to print() ###
					_get_timestamp
					_get_level_formatting "$log_level"
					_create_log_file "$log_file"

					### Convert numeric positions to -pos format ###
					local converted_params
					readarray -t converted_params < <(_convert_numeric_positions "$@")

					### Use LOG_TAB_POS positions or defaults ###
					local pos_timestamp="${LOG_TAB_POS[0]:-1}"
					local pos_level="${LOG_TAB_POS[2]:-22}"
					local pos_message="${LOG_TAB_POS[3]:-35}"

					### Add timestamp and level, then pass converted parameters to print() ###
					print -file "$log_file" \
						"$pos_timestamp" "[$timestamp]" \
						"$pos_level" "$level_color" "[$level_symbol ${log_level^^}]" \
						"$pos_message" NC "${converted_params[@]}"

					### Write to central log if configured ###
					if [ -n "$CENTRAL_LOG" ] && [ "$CENTRAL_LOG" != "$log_file" ]; then

						print -file "$CENTRAL_LOG" \
							"$pos_timestamp" "[$timestamp]" \
							"$pos_level" "$level_color" "[${SCRIPT_NAME:-script}] [$level_symbol ${log_level^^}]" \
							"$pos_message" NC "${converted_params[@]}"

					fi

					### Console output if enabled ###
					if [ "${VERBOSE:-false}" = "true" ]; then

						### Extract text content for console (remove positioning) ###
						local console_text=""
						for param in "${converted_params[@]}"; do
							case "$param" in

								-pos|[0-9]*|NC|RD|GN|YE|BU|CY|WH|MG) ;;
								*) console_text="$console_text $param" ;;

							esac
						done

						case "$log_level" in

							error)   print --error "${console_text# }" ;;
							warning) print --warning "${console_text# }" ;;
							info)    print --info "${console_text# }" ;;
							success) print --success "${console_text# }" ;;

						esac

					fi

				else

					### Standard format ###
					_standard_log_format "$log_level" "$@"

				fi

				return 0
				;;

			--init)
				### Initialize logging ###
				log_file="${2:-$log_file}"
				export LOG_FILE="$log_file"
				_create_log_file "$log_file"
				print --success "Logging initialized: $log_file"
				shift 2
				;;

			--rotate)
				### Rotate log files ###
				_log_rotate "${2:-$log_file}"
				print --success "Log rotation completed"
				shift 2
				;;

			--tail)
				### Show log tail ###
				_log_tail "${2:-$log_file}" "${3:-20}"
				return 0
				;;

			--search)
				### Search in logs ###
				_log_search "$2" "${3:-$log_file}" "${4:-0}"
				return 0
				;;

			--clear)
				### Clear log file ###
				local file="${2:-$log_file}"
				> "$file"
				_create_log_file "$file"
				print --success "Log file cleared: $file"
				shift 2
				;;

			--template)
				### Use log template ###
				_log_template "$2" "${@:3}"
				return 0
				;;

			--help|-h)
				show_help "log"
				return 0
				;;

			*)
				print --error "Unknown log operation: $1"
				show_help "log"
				return 1
				;;

		esac

		shift

	done

}


################################################################################
### === LOG DEMO AND TESTING === ###
################################################################################

### Demonstrate log formatting capabilities ###
log_demo() {

	print --header "Log Function Demo"
	print --cr

	### Standard logging ###
	print --info "Testing standard log formats..."
	log --info "Standard info message"
	log --error "Standard error message"
	log --warning "Standard warning message" 
	log --debug "Standard debug message"
	log --success "Standard success message"

	print --cr
	print --info "Testing positioned logging with numeric parameters..."

	### Positioned logging with numeric parameters ###
	log --info 35 "Function: demo_function" 60 "Status: OK"
	log --error 35 "Function: failed_function" 60 "Status: FAILED"

	print --cr
	print --info "Testing templates..."

	### Template logging ###
	log --template performance "backup_database" "45.2" "128MB"
	log --template error-trace "Database connection failed" "connect.sh:line 42"

	print --cr
	print --info "Testing structured data..."

	### Structured logging ###
	log --info -array \
		"Operation: File backup" \
		"Files:     1,247" \
		"Size:      2.3GB" \
		"Duration:  3m 45s"

	print --cr
	print --success "Demo completed - Check log file: ${LOG_FILE:-/tmp/script.log}"
}

### Run log function tests ###
run_log() {

	print --header "Log Function Test Suite"

	### Test basic logging ###
	print --info "Testing basic log functions..."
	log --init "/tmp/log_test.log"
	log --info "Test info message"
	log --error "Test error message"
	log --warning "Test warning message"

	### Test numeric positioning ###
	print --info "Testing numeric positioned logging..."
	log --info 35 "Function:" 50 "test_function"
	log --error 35 "Error in:" 50 "critical_function"

	### Test templates ###
	print --info "Testing templates..."
	log --template performance "test_func" "0.123" "45MB"

	### Test file operations ###
	print --info "Testing file operations..."
	if [ -f "/tmp/log_test.log" ]; then
		log --tail "/tmp/log_test.log" 5
		print --success "File operations test passed"
		rm -f "/tmp/log_test.log"
	else
		print --error "File operations test failed"
	fi

	### Test central logging ###
	if [ -n "$CENTRAL_LOG" ]; then
		print --info "Testing central log..."
		export LOG_FILE="/tmp/script_test.log"
		log --info "Test message for central log"
		print --success "Central log test completed"
	fi

	print --cr
	print --success "All log tests completed"
}


################################################################################
### === MAIN EXECUTION === ###
################################################################################

### Main Function ###
main() {

	### Check if no arguments provided ###
	if [ $# -eq 0 ]; then

		show_help "log"
		exit 0

	else

		### Parse and execute arguments ###
		parse_arguments "$@"

		### If arguments remain, pass them to log function ###
		if [ $# -gt 0 ]; then

			log "$@"

		fi

	fi

}

### Initialize when run directly ###
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then

	### Running directly as script ###
	main "$@"

else

	### Being sourced as library ###
	### Functions loaded and ready for use ###
	:

fi
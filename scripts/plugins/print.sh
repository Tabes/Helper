#!/bin/bash
################################################################################
### Universal Helper Functions - Print Output Library
### Comprehensive Output Functions for formatted Terminal Display
### Provides unified print Function for all Output Operations and Formatting
################################################################################
### Project: Universal Helper Library
### Version: 2.1.12
### Author:  Mawage (Development Team)
### Date:    2025-09-15
### License: MIT
### Usage:   Source this File to load Print Functions or run directly for Demo
### Commit:  Complete Framework Integration with parse_arguments and main function
################################################################################

# shellcheck disable=SC2120

################################################################################
### Parse Command Line Arguments ###
################################################################################

### Parse Command Line Arguments ###
parse_arguments() {

	while [[ $# -gt 0 ]]; do

		case $1 in
			--debug|-d)
				debug=true
				$debug && debug --info "${FUNCNAME[0]}" "($*)" 1 "message" ### Debug Function to show Variables and Status ###
				;;

			--help|-h)
				show_help "print"
				exit 0
				;;

			--version|-V)
				print --version "${header}" "${version}" "${commit}"
				exit 0
				;;

			--test)
				run_print
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
### === STATUS & NOTIFICATION FUNCTIONS, LOGGING === ###
################################################################################

### Unified print Function for all Output Operations ###
print() {

	$debug && debug --info "${FUNCNAME[0]}" "($*)" 2 "call print()" ### Debug Function to show Variables and Status ###

	### Local variables with optimized defaults ###
	local output_buffer=""
	local current_color="${NC}"
	local current_alignment="left"
	local current_position=""
	local current_row=""
	local suppress_newline=false
	local has_output=false
	local output_file=""
	local file_append=true
	local cursor_row=1
	local cursor_col=1
	local relative_position=1
	local debug_mode=false
	local cursor_cached=false

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_create_file_path() {
		### Create directory path for output file with error handling ###
		local file_path="$1"
		local dir_path

		[ -z "$file_path" ] && return 1

		dir_path=$(dirname "$file_path")

		if [ ! -d "$dir_path" ]; then

			if ! mkdir -p "$dir_path" 2>/dev/null; then

				printf "${RD}${SYMBOL_ERROR} Cannot create directory: %s${NC}\n" "$dir_path" >&2
				return 1

			fi

		fi

		### Test file write permissions ###
		if ! touch "$file_path" 2>/dev/null; then

			printf "${RD}${SYMBOL_ERROR} Cannot write to file: %s${NC}\n" "$file_path" >&2
			return 1

		fi

		return 0
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_format_and_output_line() {
		### Format and output a single line with positioning ###
		local line="$1"
		local line_index="$2"

		if [ -n "$current_position" ]; then

			if [ "$current_alignment" = "right" ]; then

				_output_router "$(printf "%${current_position}s" "$line")" true

			else

				_output_router "$(printf "%$((current_position - 1))s%s" '' "$line")" true

			fi

		else

			_output_router "$line" true

		fi

		_output_router "\n" false
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_get_cursor_position() {
		### Get current cursor position with caching ###
		if [ -z "$output_file" ] && [ "$cursor_cached" = false ]; then

			if IFS=';' read -sdR -p $'\033[6n' cursor_row cursor_col 2>/dev/null; then

				cursor_row="${cursor_row#*[}"
				cursor_cached=true

			else

				### Fallback values if cursor query fails ###
				cursor_row=1
				cursor_col=1

			fi

		fi
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_handle_positioning() {
		### Handle cursor positioning and alignment with validation ###
		local pos="$1"
		local row="$2"

		### Validate numeric inputs ###
		if [[ -n "$pos" ]] && [[ ! "$pos" =~ ^[0-9]+$ ]]; then

			printf "${RD}${SYMBOL_ERROR} Invalid position: %s (must be numeric)${NC}\n" "$pos" >&2
			return 1

		fi

		if [[ -n "$row" ]] && [[ ! "$row" =~ ^[0-9]+$ ]]; then

			printf "${RD}${SYMBOL_ERROR} Invalid row: %s (must be numeric)${NC}\n" "$row" >&2
			return 1

		fi

		### Skip positioning for file output ###
		[ -n "$output_file" ] && return 0

		### Update cursor position if not cached ###
		_get_cursor_position

		### Set position variables ###
		if [[ "$pos" =~ ^[0-9]+$ ]]; then

			current_position="$pos"

			if [[ "$row" =~ ^[0-9]+$ ]]; then

				current_row="$row"

			fi

			### Move cursor to position with bounds checking ###
			if [ -n "$current_row" ] && [ "$current_row" -gt 0 ] && [ "$current_position" -gt 0 ]; then

				### Limit to reasonable screen bounds ###
				[ "$current_row" -gt 200 ] && current_row=200
				[ "$current_position" -gt 200 ] && current_position=200

				tput cup $((current_row - 1)) $((current_position - 1)) 2>/dev/null

			elif [ "$current_position" -gt 0 ]; then

				[ "$current_position" -gt 200 ] && current_position=200
				tput cup $((cursor_row - 1)) $((current_position - 1)) 2>/dev/null

			fi

		fi

		### Calculate relative position ###
		if [[ "$current_position" =~ ^[0-9]+$ ]] && [[ "$cursor_col" =~ ^[0-9]+$ ]]; then

			relative_position=$((current_position - cursor_col + 1))

		fi

		return 0
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_invalid_operation() {
		### Handle invalid operations with standardized error messages ###
		local function="$1"
		local invalid_param="$2"

		print -l 4 --error "Unknown Operation in $function: Invalid Parameter: $invalid_param" -cr
		print -l 4 "Usage: $function [option] [Parameter]  (-h or --help for Help) for more Information."
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_output_router() {
		### Route output to console or file with optimized handling ###
		local text="$1"
		local use_color="${2:-false}"

		if [ -n "$output_file" ]; then

			### File output without ANSI codes ###
			if [ "$file_append" = true ]; then

				printf "%s" "$text" >> "$output_file" 2>/dev/null || {
					printf "${RD}${SYMBOL_ERROR} Write failed: %s${NC}\n" "$output_file" >&2
					return 1
				}

			else

				printf "%s" "$text" > "$output_file" 2>/dev/null || {
					printf "${RD}${SYMBOL_ERROR} Write failed: %s${NC}\n" "$output_file" >&2
					return 1
				}
				file_append=true	### Switch to append after first write ###

			fi

		else

			### Console Output with Formatting ###
			if [ "$use_color" = true ] && [ -n "$current_color" ]; then

				printf "${current_color}%s${NC}" "$text"

			else

				printf "%s" "$text"

			fi

		fi

		return 0
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_process_array() {
		### Process array output with enhanced buffer management and error handling ###
		local items=()
		local delay_time=0
		local max_lines=0
		local max_chars=0
		local line
		local i=0

		### Parse array-specific parameters with validation ###
		while [[ $# -gt 0 ]]; do

			case $1 in
				-delay)
					if [[ "$2" =~ ^[0-9]*\.?[0-9]+$ ]] && (( $(printf "%.0f" $(echo "$2 * 100" | bc -l 2>/dev/null || echo "0")) >= 0 )); then

						delay_time="$2"
						shift 2

					else

						printf "${RD}${SYMBOL_ERROR} Invalid delay time: %s${NC}\n" "$2" >&2
						shift 2

					fi
					;;
				-max)
					if [[ "$2" =~ ^[0-9]+$ ]] && [ "$2" -gt 0 ]; then

						max_lines="$2"
						shift 2

					else

						printf "${RD}${SYMBOL_ERROR} Invalid max lines: %s${NC}\n" "$2" >&2
						shift 2

					fi
					;;
				--)
					shift
					break
					;;
				*)
					items+=("$1")
					### Update max_chars for alignment ###
					if ((${#1} > max_chars)); then
						max_chars=${#1}
					fi
					shift
					;;
			esac

		done

		### Add remaining parameters to items ###
		while [[ $# -gt 0 ]]; do

			items+=("$1")
			### Update max_chars for remaining items ###
			if ((${#1} > max_chars)); then
				max_chars=${#1}
			fi
			shift

		done

		### Validate items array ###
		if [ ${#items[@]} -eq 0 ]; then

			printf "${YE}${SYMBOL_WARNING} No items provided for array output${NC}\n" >&2
			return 1

		fi

		### Initialize output buffer array if needed ###
		if [ "$max_lines" -gt 0 ]; then
			declare -a arr_lines_output
		fi

		### Process each item with optimized output ###
		for item in "${items[@]}"; do

			### Apply alignment formatting ###
			if [ "$current_alignment" = "left" ]; then

				line=$(printf "%-${max_chars}s" "$item")

			else

				line=$(printf "%${max_chars}s" "$item")

			fi

			### Buffer management for limited display ###
			if [ "$max_lines" -gt 0 ]; then

				arr_lines_output+=("$line")

				### Limit buffer size ###
				if [ ${#arr_lines_output[@]} -gt "$max_lines" ]; then
					arr_lines_output=("${arr_lines_output[@]:1}")
				fi

				### Clear display area and redraw all lines (only for console) ###
				if [ -z "$output_file" ]; then

					_get_cursor_position
					tput cup $((cursor_row - 1)) $((cursor_col - 1)) 2>/dev/null
					tput ed 2>/dev/null

				fi

				### Output all buffered lines ###
				for ((i=0; i<${#arr_lines_output[@]}; i++)); do

					_format_and_output_line "${arr_lines_output[$i]}" "$i"

				done

				### Handle cursor position for single line ###
				if [ ${#items[@]} -eq 1 ] && [ -z "$output_file" ]; then
					printf "\033[${#arr_lines_output[@]}A" 2>/dev/null
				fi

			else

				### Direct output without buffering ###
				_format_and_output_line "$line" 0

			fi

			### Apply delay between lines with validation ###
			if [ "$delay_time" != "0" ] && [ -n "$delay_time" ]; then

				sleep "$delay_time" 2>/dev/null || printf "${YE}${SYMBOL_WARNING} Sleep command failed${NC}\n" >&2

			fi

		done

		has_output=true
		suppress_newline=true
		return 0
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_process_debug_tools() {
		### Handle debug and ruler display functions ###
		local tool="$1"
		local option="$2"

		case "$tool" in
			ruler)
				### Display position ruler ###
				local ruler=""
				for ((i=1; i<=80; i++)); do
					if ((i % 10 == 0)); then
						ruler="${ruler}+"
					elif ((i % 5 == 0)); then
						ruler="${ruler}|"
					else
						ruler="${ruler}."
					fi
				done
				_output_router "$ruler\n" false
				;;

			ruler2)
				### Display fine ruler ###
				local ruler2=""
				for ((i=1; i<=80; i++)); do
					ruler2="${ruler2}$(( (i-1) % 10 ))"
				done
				_output_router "$ruler2\n" false
				;;

			scale)
				### Display scaling numbers ###
				local scale=""
				for ((i=1; i<=8; i++)); do
					scale="${scale}$(printf "%10d" $((i*10)))"
				done
				_output_router "$scale\n" false
				;;

		esac

		has_output=true
		suppress_newline=true
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_process_movement() {
		### Handle cursor movement commands with validation ###
		local direction="$1"
		local count="${2:-1}"

		### Validate count parameter ###
		if [[ ! "$count" =~ ^[0-9]+$ ]]; then

			printf "${RD}${SYMBOL_ERROR} Invalid count: %s (must be numeric)${NC}\n" "$count" >&2
			return 1

		fi

		### Skip movement for file output ###
		[ -n "$output_file" ] && return 0

		### Limit count to reasonable bounds ###
		[ "$count" -gt 100 ] && count=100

		case "$direction" in
			back)
				printf '\b%.0s' $(seq 1 "$count") 2>/dev/null
				;;
			up)
				printf "\033[${count}A" 2>/dev/null
				;;
			delete)
				printf "\033[K" 2>/dev/null
				;;
			override)
				printf "\r" 2>/dev/null
				;;
			*)
				printf "${RD}${SYMBOL_ERROR} Invalid movement direction: %s${NC}\n" "$direction" >&2
				return 1
				;;
		esac

		return 0
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_reset_output_buffer() {
		### Reset output arrays and variables ###
		unset arr_lines_output 2>/dev/null
		output_buffer=""
		has_output=false
		cursor_cached=false
	}

	# shellcheck disable=SC2317,SC2329	# Function called conditionally within main function
	_validate_parameters() {
		### Validate common parameter types and ranges ###
		local param_type="$1"
		local param_value="$2"
		local param_name="$3"

		case "$param_type" in
			numeric)
				if [[ ! "$param_value" =~ ^[0-9]+$ ]]; then

					printf "${RD}${SYMBOL_ERROR} Invalid %s: %s (must be numeric)${NC}\n" "$param_name" "$param_value" >&2
					return 1

				fi
				;;

			position)
				if [[ ! "$param_value" =~ ^[0-9]+$ ]] || [ "$param_value" -lt 1 ] || [ "$param_value" -gt 200 ]; then

					printf "${RD}${SYMBOL_ERROR} Invalid %s: %s (must be 1-200)${NC}\n" "$param_name" "$param_value" >&2
					return 1

				fi
				;;

			time)
				if [[ ! "$param_value" =~ ^[0-9]*\.?[0-9]+$ ]] || (( $(printf "%.0f" $(echo "$param_value < 0" | bc -l 2>/dev/null || echo "1")) )); then

					printf "${RD}${SYMBOL_ERROR} Invalid %s: %s (must be positive number)${NC}\n" "$param_name" "$param_value" >&2
					return 1

				fi
				;;

			file)
				if [ -z "$param_value" ]; then

					printf "${RD}${SYMBOL_ERROR} Empty %s specified${NC}\n" "$param_name" >&2
					return 1

				fi
				;;

		esac

		return 0
	}

	### Parse & Execute Arguments sequentially ###
	while [[ $# -gt 0 ]]; do

		$debug && debug --info "${FUNCNAME[0]}" "($*)" 3 "Parse & Execute Arguments sequentially" ### Debug Function to show Variables and Status ###

		case $1 in
			### Position and movement with validation ###
			-pos)
				local pos_arg="$2"
				local row_arg="$3"
				
				if _validate_parameters "position" "$pos_arg" "position"; then

					if [[ "$row_arg" =~ ^[0-9]+$ ]] && _validate_parameters "position" "$row_arg" "row"; then

						_handle_positioning "$pos_arg" "$row_arg"
						shift 3

					else

						_handle_positioning "$pos_arg"
						shift 2

					fi

				else

					shift 2

				fi
				;;

			-rel)
				if [[ "$2" =~ ^[+-]?[0-9]+$ ]] && _validate_parameters "numeric" "${2#[-+]}" "relative position"; then

					_get_cursor_position
					relative_position=$((cursor_col + $2))
					current_position="$relative_position"
					shift 2

				else

					printf "${RD}${SYMBOL_ERROR} Invalid relative position: %s${NC}\n" "$2" >&2
					shift 2

				fi
				;;

			-back)
				local count_arg="${2:-1}"
				if _validate_parameters "numeric" "$count_arg" "back count"; then

					_process_movement "back" "$count_arg"
					shift 2

				else

					shift 2

				fi
				;;

			-up)
				local count_arg="${2:-1}"
				if _validate_parameters "numeric" "$count_arg" "up count"; then

					_process_movement "up" "$count_arg"
					shift 2

				else

					shift 2

				fi
				;;

			-delete)
				_process_movement "delete"
				shift
				;;

			-override|-o)
				_process_movement "override"
				shift
				;;

			### File output with validation ###
			-file|-f)
				if _validate_parameters "file" "$2" "file path" && _create_file_path "$2"; then

					output_file="$2"
					shift 2

				else

					shift 2

				fi
				;;

			-append)
				file_append=true
				shift
				;;

			-overwrite)
				file_append=false
				shift
				;;

			### Array processing ###
			-array)
				shift
				_process_array "$@"
				return 0
				;;

			-row)
				shift
				### Parse row-specific options ###
				local row_args=()
				while [[ $# -gt 0 ]] && [[ ! "$1" =~ ^-- ]]; do
					row_args+=("$1")
					shift
				done
				_process_array "${row_args[@]}"
				### Continue processing remaining arguments ###
				;;

			### Debug and tools ###
			-debug)
				debug=true
				$debug && debug --info "${FUNCNAME[0]}" "($*)" 1 "message" ### Debug Function to show Variables and Status ###

				shift


				# debug_mode=true
				# if [ "$2" = "true" ]; then
					### Show debug info ###
				# 	_get_cursor_position
				# 	print --info "Debug: pos($current_position) row($current_row) col($cursor_col) align($current_alignment) rel_pos($relative_position)"
				# 	shift 2
				# else
					shift
				# fi
				;;

			-ruler)
				_process_debug_tools "ruler"
				shift
				;;

			-ruler2)
				_process_debug_tools "ruler2"
				shift
				;;

			-scale)
				_process_debug_tools "scale"
				shift
				;;

			-demo)
				_process_debug_tools "demo"
				shift
				;;

			-reset)
				_reset_output_buffer
				shift
				;;

			### Frame and special formatting ###
			-header)
				local msg="$2"
				local frame_line=$(printf "%80s" | tr ' ' '#')
				local frame_element="###"
				local space_count=2
				local fill_length=$((80 - ${#frame_element} - ${#msg} - space_count - space_count))
				local frame_fill=$(printf "%${fill_length}s" | tr ' ' '#')

				_output_router "${GN}${frame_line}\n" false
				_output_router "${frame_element}$(printf "%${space_count}s")${NC}${msg}${GN}$(printf "%${space_count}s")${frame_fill}\n" false
				_output_router "${frame_line}${NC}\n" false
				
				has_output=true
				suppress_newline=true
				shift 2
				;;

			-line)
				local char="${2:-#}"
				local count="${3:-80}"
				local line=$(printf "%${count}s" | tr ' ' "$char")
				_output_router "${line}\n" false
				has_output=true
				suppress_newline=true
				if [[ "$3" =~ ^[0-9]+$ ]]; then
					shift 3
				else
					shift 2
				fi
				;;

			-msg)
				local msg="$2"
				local frame_element="###"
				local space_count=2
				local fill_length=$((80 - ${#frame_element} - ${#msg} - space_count - space_count))
				local frame_fill=$(printf "%${fill_length}s" | tr ' ' '#')

				_output_router "${current_color}${frame_element}$(printf "%${space_count}s")${NC}${msg}${current_color}$(printf "%${space_count}s")${frame_fill}${NC}\n" false
				
				has_output=true
				suppress_newline=true
				shift 2
				;;

			-txt|-t)
				### Output text without any positioning ###
				local text="$2"
				_output_router "$text" true
				has_output=true
				shift 2
				;;

			### Existing functionality - Special operations ###
			--success)
				_output_router "${GN}${SYMBOL_SUCCESS} $2${NC}\n" false
				has_output=true
				suppress_newline=true
				shift 2
				;;

			--error)
				if [ -n "$output_file" ]; then
					_output_router "${SYMBOL_ERROR} $2\n" false
				else
					printf "${RD}${SYMBOL_ERROR} $2${NC}\n" >&2
				fi
				has_output=true
				suppress_newline=true
				shift 2
				;;

			--invalid)
				local func_name="$2"
				local invalid_param="$3"

				_invalid_operation "$func_name" "$invalid_param"

				shift 3
				;;

			--warning)
				_output_router "${YE}${SYMBOL_WARNING} $2${NC}\n" false
				has_output=true
				suppress_newline=true
				shift 2
				;;

			--info)
				_output_router "${CY}${SYMBOL_INFO} $2${NC}\n" false
				has_output=true
				suppress_newline=true
				shift 2
				;;

			--header)
				local line=$(printf "%80s" | tr ' ' '#')
				_output_router "${BU}${line}\n### $2\n${line}${NC}\n" false
				has_output=true
				suppress_newline=true
				shift 2
				;;

			--line)
				local char="${2:-#}"
				local line=$(printf "%80s" | tr ' ' "$char")
				_output_router "${line}\n" false
				has_output=true
				suppress_newline=true
				shift 2
				;;

			--version)
				local header="$2"
				local version="$3"
				local commit="$4"
				_output_router "${BU}${header}${NC}\n" false
				_output_router "Version: ${GN}${version}${NC}\n" false
				_output_router "Commit:  ${CY}${commit}${NC}\n" false
				has_output=true
				suppress_newline=true
				shift 4
				;;

			### Formatting options ###
			--no-nl|-n)
				suppress_newline=true
				shift
				;;

			--right|-r)
				current_alignment="right"

				if [[ "$2" =~ ^[0-9]+$ ]]; then

					current_position="$2"
					shift 2

				else

					shift

				fi
				;;

			--left|-l)
				current_alignment="left"

				if [[ "$2" =~ ^[0-9]+$ ]]; then

					current_position="$2"
					shift 2

				else

					shift

				fi
				;;

			--cr|-cr)
				if [[ "$2" =~ ^[0-9]+$ ]]; then

					for ((i=0; i<$2; i++)); do
						_output_router "\n" false
					done
					shift 2

				else

					_output_router "\n" false
					shift

				fi
				has_output=true
				suppress_newline=true
				;;

			--help|-h)
				show_help "print"
				return 0
				;;

			### Color detection ###
			NC|RD|GN|YE|BU|CY|WH|MG)
				current_color="${!1}"
				shift
				;;

			### Regular text ###
			*)
				### Check for numeric Position Parameter first ###
				if [[ "$1" =~ ^[0-9]+$ ]]; then
					
					local pos_arg="$1"
					local row_arg=""
					shift
					
					### Check if next Parameter is also numeric (row) ###
					if [[ "$2" =~ ^[0-9]+$ ]]; then

						row_arg="$2"
						shift

					fi
					
					### Handle positioning ###
					if _validate_parameters "position" "$pos_arg" "position"; then
						
						if [ -n "$row_arg" ] && _validate_parameters "position" "$row_arg" "row"; then

							_handle_positioning "$pos_arg" "$row_arg"

						else

							_handle_positioning "$pos_arg"

						fi
						
					fi
					
				else

					### Get current position if not set ###
					if [ -z "$cursor_row" ] || [ "$cursor_cached" = false ]; then

						_get_cursor_position

					fi

					### Apply positioning and alignment for text ###
					if [ -n "$current_position" ]; then

						if [ "$current_alignment" = "right" ]; then

							### Right align: calculate start position ###
							local text_len=${#1}
							local start_pos=$((current_position - text_len + 1))
							[ $start_pos -lt 1 ] && start_pos=1

							if [ -z "$output_file" ]; then

								printf "\033[${start_pos}G" 2>/dev/null

							fi

							_output_router "$1" true

						else

							### Left align: move to position and print ###
							if [ -z "$output_file" ]; then

								printf "\033[${current_position}G" 2>/dev/null

							fi

							_output_router "$1" true

						fi

					else

						### No positioning, just print with color ###
						_output_router "$1" true

					fi

					has_output=true
					shift
				fi
				;;

		esac

	done

	### Add standard newline unless suppressed ###
	if [ "$has_output" = "true" ] && [ "$suppress_newline" = "false" ]; then

		_output_router "\n" false

	fi
}


################################################################################
### === TEST FUNCTIONS === ###
################################################################################

### Run internal Tests for print Function ###
run_print() {

	print --header "Print Function Test Suite"

	### Basic functionality tests ###
	print --info "Testing basic output..."
	print "Basic text output"
	print --success "Success message test"
	print --error "Error message test"
	print --warning "Warning message test"

	### Positioning tests ###
	print --cr 2
	print --info "Testing positioning..."
	print -pos 10 "Position 10"
	print -pos 30 5 "Position 30, Row 5"
	print --cr

	### Color tests ###
	print --info "Testing colors..."
	print GN "Green text"
	print RD "Red text"
	print YE "Yellow text"
	print --cr

	### Array tests ###
	print --info "Testing array output..."
	print -array "Item 1" "Item 2" "Item 3"

	### File output test ###
	print --info "Testing file output..."
	print -file "/tmp/print.log" "Test output to file"

	if [ -f "/tmp/print.log" ]; then

		print --success "File output test passed"
		rm -f "/tmp/print.log"

	else

		print --error "File output test failed"

	fi

	print --cr
	print --success "All tests completed"
}


################################################################################
### === MAIN EXECUTION === ###
################################################################################

### Main Function ###
main() {

	### Check if no arguments provided ###
	if [ $# -eq 0 ]; then

		show_help "print"
		exit 0

	else

		### Parse and execute arguments ###
		parse_arguments "$@"

		### If arguments remain, pass them to print function ###
		if [ $# -gt 0 ]; then

			print "$@"

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
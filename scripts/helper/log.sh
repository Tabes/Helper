#!/bin/bash
################################################################################
### Universal Helper Functions - Logging Library
### Comprehensive Logging Functions for structured File and Console Output
### Provides unified log function for all logging operations with rotation
################################################################################
### Project: Universal Helper Library
### Version: 1.0.0
### Author:  Mawage (Development Team)
### Date:    2025-09-08
### License: MIT
### Usage:   Source this File to load Logging Functions
################################################################################

SCRIPT_VERSION="1.0.0"
COMMIT="Logging functions for structured file and console output"


################################################################################
### Parse Command Line Arguments ###
################################################################################

### Parse all Command Line Arguments ###
parse_arguments() {
    ### Parse Command Line Arguments ###
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
                ### Pass all other Arguments to Secure Function ###
                log "$@"
                exit $?
                ;;
        esac
    done
}


################################################################################
### === STATUS & NOTIFICATION FUNCTIONS, LOGGING === ###
################################################################################

### Unified log Function for all Logging Operations ###
log() {
    ### Local variables ###
    local operation=""
    local message=""
    local script_name="${SCRIPT_NAME:-${0##*/}}"
    local log_file="${LOG_FILE:-${LOG_DIR:-/tmp}/${script_name%.sh}.log}"
    local log_level="${LOG_LEVEL:-INFO}"
    local timestamp=""
    
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _log_write() {
        local level="$1"
        local function_name="$2"
        local parameters="$3"
        local comment="${4:-}"
        local additional="${5:-}"
        local file="${6:-$log_file}"
        
        ### Create log directory if needed ###
        local log_dir=$(dirname "$file")
        [ ! -d "$log_dir" ] && mkdir -p "$log_dir"
        
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
            *)
                timestamp=$(date '+%Y-%m-%d %H:%M:%S')
                ;;
        esac
        
        ### Check log rotation if enabled ###
        if [ "${LOG_ROTATION:-true}" = "true" ]; then
            _log_rotate "$file"
        fi
        
        ### Format log entry with tabs if enabled ###
        local log_entry=""
        
        if [ "${LOG_USE_TABS:-true}" = "true" ]; then
            ### Tab positions from config ###
            local tab1="${LOG_TAB1:-1}"                            ### Position Timestamp ###
            local tab2="${LOG_TAB2:-25}"                           ### Position Script name ###
            local tab3="${LOG_TAB3:-40}"                           ### Position log level ###
            local tab4="${LOG_TAB4:-50}"                           ### Position Parameters ###
            local tab5="${LOG_TAB5:-62}"                           ### Position Comments ###
            local tab6="${LOG_TAB6:-75}"                           ### Position Additional ###
            
            ### Calculate column widths ###
            local col1=$((tab2 - tab1 - 2))                        ### Timestamp width ###
            local col2=$((tab3 - tab2 - 2))                        ### Script width ###
            local col3=$((tab4 - tab3 - 2))                        ### Level width ###
            local col4=$((tab5 - tab4))                            ### Parameters width ###
            local col5=$((tab6 - tab5))                            ### Comments width ###
            
            ### Build formatted entry ###
            if [ -n "$additional" ]; then
                ### Full format with all columns ###
                log_entry=$(printf "[%-*s] [%-*s] [%-*s] %-*s %-*s %s" \
                    "$col1" "$timestamp" \
                    "$col2" "${script_name:-$function_name}" \
                    "$col3" "$level" \
                    "$col4" "$parameters" \
                    "$col5" "$comment" \
                    "$additional")
            elif [ -n "$comment" ]; then
                ### Format without additional column ###
                log_entry=$(printf "[%-*s] [%-*s] [%-*s] %-*s %s" \
                    "$col1" "$timestamp" \
                    "$col2" "${script_name:-$function_name}" \
                    "$col3" "$level" \
                    "$col4" "$parameters" \
                    "$comment")
            else
                ### Minimal format ###
                log_entry=$(printf "[%-*s] [%-*s] [%-*s] %s" \
                    "$col1" "$timestamp" \
                    "$col2" "${script_name:-$function_name}" \
                    "$col3" "$level" \
                    "$parameters")
            fi
        else
            ### Classic format without tabs ###
            log_entry="[$timestamp] [${script_name:-$function_name}] [$level] $parameters $comment $additional"
        fi
        
        ### Write to script-specific log file ###
        echo "$log_entry" >> "$file"
        
        ### Also write to central log if configured ###
        if [ -n "$CENTRAL_LOG" ] && [ "$CENTRAL_LOG" != "$file" ]; then
            echo "$log_entry" >> "$CENTRAL_LOG"
        fi
        
        ### Console output based on level ###
        case "$level" in
            ERROR)
                [ "${VERBOSE:-false}" = "true" ] && print --error "$function_name $parameters $comment"
                ;;
            WARNING)
                [ "${VERBOSE:-false}" = "true" ] && print --warning "$function_name $parameters $comment"
                ;;
            INFO)
                [ "${VERBOSE:-false}" = "true" ] && print --info "$function_name $parameters $comment"
                ;;
            DEBUG)
                [ "${DEBUG:-false}" = "true" ] && print CY "[DEBUG] $function_name $parameters $comment"
                ;;
        esac
    }

    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _log_init() {
        local file="${1:-$log_file}"
        local level="${2:-INFO}"
        
        ### Set global variables ###
        export LOG_FILE="$file"
        export LOG_LEVEL="$level"
        
        ### Create log directory ###
        local log_dir=$(dirname "$file")
        [ ! -d "$log_dir" ] && mkdir -p "$log_dir"
        
        ### Initialize Log File with Header ###
        {
            echo "################################################################################"
            echo "### Universal Helper Functions - Log File"
            echo "### Automated logging for bash scripts and system operations"
            echo "### Provides structured logging with rotation and level support"
            echo "################################################################################"
            echo "### Project: ${PROJECT_NAME:-Universal Helper Library}"
            echo "### Version: ${PROJECT_VERSION:-1.0.0}"
            echo "### Author:  ${PROJECT_AUTHOR:-Mawage (Development Team)}"
            echo "### Date:    $(date '+%Y-%m-%d')"
            echo "### License: ${PROJECT_LICENSE:-MIT}"
            echo "### Usage:   Automated log file for ${script_name}"
            echo "################################################################################"
            echo ""
            echo "SCRIPT_VERSION=\"${SCRIPT_VERSION:-1.0.0}\""
            echo "COMMIT=\"Log session started\""
            echo ""
            echo ""
            echo "################################################################################"
            echo "### === LOG SESSION INFORMATION === ###"
            echo "################################################################################"
            echo ""
            echo "### Started: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "### Script:  ${script_name}"
            echo "### PID:     $$"
            echo "### User:    $(whoami)"
            echo "### Host:    $(hostname)"
            echo "### Dir:     $(pwd)"
            echo "### Level:   $level"
            echo ""
            echo "################################################################################"
        } > "$file"
    
        _log_write "INFO" "Logging initialized - File: $file, Level: $level"
    }
    
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _log_rotate() {
        local file="${1:-$log_file}"
        local max_size="${LOG_MAX_SIZE:-100M}"
        local max_files="${LOG_MAX_FILES:-10}"
        
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
            
            ### Create new log ###
            _log_init "$file" "$LOG_LEVEL"
            _log_write "INFO" "Log rotated - Previous log: ${file}.1 (Size: $current_size bytes)"
        fi
    }
    
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _log_tail() {
        local file="${1:-$log_file}"
        local lines="${2:-20}"
        
        if [ -f "$file" ]; then
            print --header "Last $lines log entries from $(basename "$file")"
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
                    *"###"*)
                        print BU "$line"
                        ;;
                    *)
                        print "$line"
                        ;;
                esac
            done
        else
            print --error "Log file not found: $file"
        fi
    }
    
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _log_search() {
        local pattern="$1"
        local file="${2:-$log_file}"
        
        if [ -f "$file" ]; then
            print --header "Searching for '$pattern' in $(basename "$file")"
            grep -n "$pattern" "$file" | while IFS= read -r line; do
                case "$line" in
                    *"[ERROR]"*)
                        print RD "$line"
                        ;;
                    *"[WARNING]"*)
                        print YE "$line"
                        ;;
                    *)
                        print CY "$line"
                        ;;
                esac
            done
        else
            print --error "Log file not found: $file"
        fi
    }
    
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _log_help() {
        ### Try to load help from markdown file ###
        local help_file="${DOCS_DIR}/help/log.md"
        
        if [ -f "$help_file" ]; then
            ### Parse markdown and display formatted ###
            while IFS= read -r line; do
                case "$line" in
                    "# "*)
                        printf "${BU}${line#\# }${NC}\n"
                        ;;
                    "## "*)
                        printf "${CY}${line#\#\# }${NC}\n"
                        ;;
                    "### "*)
                        printf "${GN}${line#\#\#\# }${NC}\n"
                        ;;
                    "- "*)
                        printf "  ${line}\n"
                        ;;
                    "\`"*"\`"*)
                        printf "${YE}${line}${NC}\n"
                        ;;
                    "")
                        printf "\n"
                        ;;
                    *)
                        printf "${line}\n"
                        ;;
                esac
            done < "$help_file"
        else
            ### Fallback to inline help ###
            local P1="${POS[0]:-4}"   # Position 4
            local P2="${POS[3]:-35}"  # Position 35
            
            print "Usage: log [OPERATION] [OPTIONS]"
            print --cr
            print "Operations:"
            print -l "$P1" "--init [FILE] [LEVEL]" -l "$P2" "Initialize logging"
            print -l "$P1" "--info MESSAGE" -l "$P2" "Log info message"
            print -l "$P1" "--error MESSAGE" -l "$P2" "Log error message"
            print -l "$P1" "--warning MESSAGE" -l "$P2" "Log warning message"
            print -l "$P1" "--debug MESSAGE" -l "$P2" "Log debug message"
            print -l "$P1" "--rotate [FILE]" -l "$P2" "Rotate log files"
            print -l "$P1" "--tail [FILE] [LINES]" -l "$P2" "Show last log entries"
            print -l "$P1" "--search PATTERN [FILE]" -l "$P2" "Search in log file"
            print -l "$P1" "--clear [FILE]" -l "$P2" "Clear log file"
            print -l "$P1" "--help, -h" -l "$P2" "Show this help"
            print --cr
            print "Log Levels: DEBUG, INFO, WARNING, ERROR"
            print "Default log: ${LOG_DIR:-/tmp}/SCRIPTNAME.log"
        fi
    }
    
    ### Parse arguments ###
    while [[ $# -gt 0 ]]; do
        case $1 in
            --init)
                _log_init "${2:-$log_file}" "${3:-INFO}"
                [ $# -ge 3 ] && shift 3 || shift $#
                ;;

            --info)
                ### Extended format: --info function_name parameters comment additional ###
                _log_write "INFO" "$2" "$3" "${4:-}" "${5:-}"
                shift $#
                ;;

            --error)
                _log_write "ERROR" "$2" "$3" "${4:-}" "${5:-}"
                shift $#
                ;;

            --warning)
                _log_write "WARNING" "$2" "$3" "${4:-}" "${5:-}"
                shift $#
                ;;

            --debug)
                _log_write "DEBUG" "$2" "$3" "${4:-}" "${5:-}"
                shift $#
                ;;

            --rotate)
                _log_rotate "${2:-$log_file}"
                shift $#
                ;;

            --tail)
                _log_tail "${2:-$log_file}" "${3:-20}"
                shift $#
                ;;

            --search)
                _log_search "$2" "${3:-$log_file}"
                shift $#
                ;;

            --clear)
                local file="${2:-$log_file}"
                > "$file"
                _log_write "INFO" "log" "" "Log file cleared by user"
                shift $#
                ;;

            --help|-h)
                _log_help
                return 0
                ;;

            *)
                print --error "Unknown log operation: $1"
                _log_help
                return 1
                ;;

        esac

    done

}


################################################################################
### === MAIN EXECUTION === ###
################################################################################

### Main Function ###
main() {
    ### Check if no arguments provided ###
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    else
        ### Parse and execute arguments ###
        parse_arguments "$@"
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

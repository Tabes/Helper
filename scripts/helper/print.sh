#!/bin/bash
################################################################################
### Universal Helper Functions - Print Output Library
### Comprehensive Output Functions for formatted Terminal Display
### Provides unified print Function for all Output Operations and Formatting
################################################################################
### Project: Universal Helper Library
### Version: 1.0.1
### Author:  Mawage (Development Team)
### Date:    2025-09-14
### License: MIT
### Usage:   Source this File to load Print Functions
### Commit:  Print Output Functions for unified Terminal Display
################################################################################


################################################################################
### === STATUS & NOTIFICATION FUNCTIONS, LOGGING === ###
################################################################################

### Unified print Function for all Output Operations ###
print() {
   ### Local variables ###
   local output_buffer=""
   local current_color="${NC}"
   local current_alignment="left"
   local current_position=""
   local newlines=0
   local suppress_newline=false
   local has_output=false
   
   # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
   _apply_formatting() {
       local text="$1"
       local pos="$2"
       local align="$3"
       
       ### Calculate position based on alignment ###
       if [ "$align" = "right" ] && [ -n "$pos" ]; then
           ### Right align: position is where the last character should be ###
           local text_len=${#text}
           local start_pos=$((pos - text_len + 1))
           [ $start_pos -lt 1 ] && start_pos=1
           printf "\033[${start_pos}G%s" "$text"
       elif [ "$align" = "left" ] && [ -n "$pos" ]; then
           ### Left align: position is where the first character should be ###
           printf "\033[${pos}G%s" "$text"
       else
           ### No positioning, just print ###
           printf "%s" "$text"
       fi
   }

   # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _invalid_operation() {
        local function="$1"
        local invalid_param="$2"
        
        print -l 4 --error "Unknown Operation in $function: Invalid Parameter: $invalid_param" -cr
        print -l 4 "Usage: $function [option] [Parameter]  (-h or --help for Help) for more Infomation."
    }

    ### Parse and Execute Arguments sequentially ###
    while [[ $# -gt 0 ]]; do
        case $1 in
            ### Special operations ###
            --success)
                printf "${GN}${SYMBOL_SUCCESS} $2${NC}\n"
                has_output=true
                suppress_newline=true
                shift 2
                ;;

            --error)
                printf "${RD}${SYMBOL_ERROR} $2${NC}\n" >&2
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
                printf "${YE}${SYMBOL_WARNING} $2${NC}\n"
                has_output=true
                suppress_newline=true
                shift 2
                ;;

            --info)
                printf "${CY}${SYMBOL_INFO} $2${NC}\n"
                has_output=true
                suppress_newline=true
                shift 2
                ;;

            --header)
                local line=$(printf "%80s" | tr ' ' '#')
                printf "${BU}${line}\n### $2\n${line}${NC}\n"
                has_output=true
                suppress_newline=true
                shift 2
                ;;

            --line)
                local char="${2:-#}"
                local line=$(printf "%80s" | tr ' ' "$char")
                printf "${line}\n"
                has_output=true
                suppress_newline=true
                shift 2
                ;;
            ### Formatting options ###

            --no-nl|-n)
                suppress_newline=true
                shift
                ;;

            --right|-r)
                current_alignment="right"
                current_position="$2"
                shift 2
                ;;

            --left|-l)
                current_alignment="left"
                current_position="$2"
                shift 2
                ;;

            --cr|-cr)
                if [[ "${2}" =~ ^[0-9]+$ ]]; then
                    for ((i=0; i<$2; i++)); do
                        printf "\n"
                    done
                    shift 2
                else
                    printf "\n"
                    shift
                fi
                has_output=true
                suppress_newline=true
                ;;

            --help|-h)
                show_help
                return 0
                ;;

            ### Color detection ###
            NC|RD|GN|YE|BU|CY|WH|MG)
                current_color="${!1}"
                shift
                ;;

            ### Regular text ###
            *)
                ### Apply color and formatting ###
                printf "${current_color}"
                _apply_formatting "$1" "$current_position" "$current_alignment"
                printf "${NC}"
                has_output=true
                shift
                ;;
        esac
    done
    
    ### Add standard newline unless suppressed ###
    if [ "$has_output" = "true" ] && [ "$suppress_newline" = "false" ]; then
        printf "\n"
    fi
}

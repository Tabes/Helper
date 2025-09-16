#!/bin/bash
################################################################################
### Universal Helper Functions - Interactive Display Library
### Comprehensive Display Functions for Menus, Help, and Interactive Elements
### Provides unified show Functions for interactive Displays and Help System
################################################################################
### Project: Universal Helper Library
### Version: 1.0.1
### Author:  Mawage (Development Team)
### Date:    2025-09-14
### License: MIT
### Usage:   Source this File to load Interactive Display Functions
### Commit:  Interactive Display Functions for Menus, Help, and User Interaction
################################################################################


################################################################################
### === INTERACTIVE DISPLAY FUNCTIONS === ###
################################################################################

### Universal Help Function for all Functions ###
show_help() {
    ### Show help from markdown file ###
    local func_name="${1:-${FUNCNAME[1]}}"
    local help_file="${HELP_FILE_DIR}/${func_name}.md"
    local line=""

    ### Check if help file exists ###
    if [ ! -f "${help_file}" ]; then
        print --error "Help file not found: ${help_file}"
        return 1
    fi

    ### Formats a Line based on Tabs and Alignment Positions ###
    _format_line() {
        local content="$1"
        local has_bullet="$2"
        
        ### Split the Line by Tabs into an Array
        local parts=()
        IFS=$'\t' read -r -a parts <<< "${content}"
        
        ### Prepare the first Part for Printing, with or without a Bullet ###
        local first_part_formatted=""
        if [ "${has_bullet}" = "true" ]; then
            printf -v first_part_formatted "%*s  %s" "${POS[0]}" "•" "${parts[0]}"
        else
            first_part_formatted="${parts[0]}"
        fi

        ### Build the full print Command String ###
        local print_cmd="print \"${first_part_formatted}\""
        for (( i=1; i<${#parts[@]}; i++ )); do
            print_cmd="${print_cmd} -l ${POS[${i}]} \"${parts[${i}]}\""
        done
        
        ### Execute the Command ###
        eval "${print_cmd}"
    }


    ### Read File Line by Line and Format Content ###
    while IFS= read -r line; do
        case "${line}" in
            "# "*)
                print --header "${line#\# }"
                ;;

            "## "*)
                print CY "${line#\#\# }"
                ;;

            "### "*)
                print GN "${line#\#\#\# }"
                ;;
            "- "*)
                ### Bullet Point formated List ###
                local content="${line#- }"
                _format_line "${content}" "true"
                ;;

            "***"*)
                # Recognize bold and italic
                print -l "${POS[0]}" "\033[1;3m${line#***}"     # Bold & Italic
                ;;

            "**"*)
                # Recognize bold
                print -l "${POS[0]}" "\033[1m${line#**}"        # Bold
                ;;

            "*"*)
                # Recognize italic
                print -l "${POS[0]}" "\033[3m${line#*}"         # Italic
                ;;

            "<u>"*)
                # Recognize underline
                print -l "${POS[0]}" "\033[4m${line#<u>}"       # Underline
                ;;

            "<reverse>"*)
                # Recognize reverse colors
                print -l "${POS[0]}" "\033[7m${line#<reverse>}" # Reverse
                ;;

            "\`\`\`"*)
                print YE "${line}"
                ;;

            "")
                print --cr
                ;;

            *)
                ### Fallback for all other Lines, also Tab formated ###
                _format_line "${line}" "false"
                ;;

        esac
    done < "${help_file}"
}

### Unified Show Function for interactive Displays and Menus ###
show() {
   ### Local variables ###
   local operation=""
   local title=""
   local content=""
   local options=()
   local selected=0
   
   # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
   _show_menu() {
       local menu_title="$1"
       shift
       local menu_options=("$@")
       local choice
       
       ### Display menu ###
       print --header "$menu_title"
       print --cr
       
       ### Display options ###
       local i=1
       local P1="${POS[0]:-4}"
       local P2="${POS[1]:-8}"
       
       for option in "${menu_options[@]}"; do
           print -l "$P1" "[$i]" -l "$P2" "$option"
           ((i++))
       done
       print -l "$P1" "[0]" -l "$P2" "Exit"
       print --cr
       
       ### Get user choice ###
       read -p "Please select [0-$((i-1))]: " choice
       echo "$choice"
   }
   
   # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
   _show_spinner() {
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
   
   # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
   _show_progress() {
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
   
   # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
   _show_version() {
       ### Position variables for output ###
       local P1="${POS[0]:-4}"
       local P2="${POS[2]:-21}"
       
       print --header "Universal Helper Functions"
       print -l "$P1" "Version:" -l "$P2" "$SCRIPT_VERSION"
       print -l "$P1" "Commit:" -l "$P2" "$COMMIT"
       print -l "$P1" "Author:" -l "$P2" "Mawage (Development Team)"
       print -l "$P1" "License:" -l "$P2" "MIT"
   }
   
   # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
   _show_doc() {
       local doc_file="$1"
       
       ### Check if path is relative or absolute ###
       if [[ ! "$doc_file" =~ ^/ ]]; then
           doc_file="${DOCS_DIR}/${doc_file}"
       fi
       
       if [ -f "$doc_file" ]; then
           ### Display file with formatting ###
           local P1="${POS[0]:-4}"
           local P2="${POS[1]:-8}"
           local P3="${POS[2]:-21}"
           
           while IFS= read -r line; do
               case "$line" in
                   "# "*)
                       print --header "${line#\# }"
                       ;;
                   "## "*)
                       print CY "${line#\#\# }"
                       print --line "-"
                       ;;
                   "### "*)
                       print GN "${line#\#\#\# }"
                       ;;
                   "- "*)
                       print -l "$P1" "•" -l "$P2" "${line#- }"
                       ;;
                   "  - "*)
                       print -l "$P2" "◦" -l "$P3" "${line#  - }"
                       ;;
                   "\`\`\`"*)
                       ### Code block start/end ###
                       print YE "$line"
                       ;;
                   "")
                       print --cr
                       ;;
                   *)
                       print "$line"
                       ;;
               esac
           done < "$doc_file"
       else
           print --error "Documentation file not found: $doc_file"
       fi
   }
   
   ### Parse arguments ###
   while [[ $# -gt 0 ]]; do
       case $1 in
           --menu)
               shift
               title="$1"
               shift
               while [[ $# -gt 0 ]] && [[ ! "$1" =~ ^-- ]]; do
                   options+=("$1")
                   shift
               done
               _show_menu "$title" "${options[@]}"
               return $?
               ;;
           --spinner)
               _show_spinner "$2" "${3:-0.1}"
               shift $#
               ;;
           --progress)
               _show_progress "$2" "$3" "${4:-Progress}" "${5:-50}"
               shift $#
               ;;
           --version)
               _show_version
               shift
               ;;
           --doc)
               _show_doc "$2"
               shift 2
               ;;
           --help|-h)
               show_help "menu"
               return 0
               ;;
           *)
               print --error "Unknown show operation: $1"
               show_help
               return 1
               ;;
       esac
   done
}

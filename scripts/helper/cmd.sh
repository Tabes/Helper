#!/bin/bash
################################################################################
### Universal Helper Functions - System Integration Library
### Comprehensive System Integration Functions for Command Installation
### Provides unified cmd Function for system-wide Command Installation and Management
################################################################################
### Project: Universal Helper Library
### Version: 1.0.0
### Author:  Mawage (Development Team)
### Date:    2025-09-08
### License: MIT
### Usage:   Source this File to load System Integration Functions
################################################################################

readonly header="System Integration Library"

readonly version="1.0.0"
readonly commit="System Integration Functions for Command Wrappers and bash Completion"


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
                ### Pass all other Arguments to CMD Function ###
                cmd "$@"
                exit $?
                ;;
        esac
    done
}


################################################################################
### === SYSTEM INTEGRATION FUNCTIONS === ###
################################################################################

### Universal Command Integration Function ###
cmd() {
    ### Log startup arguments ###
    log --info "${FUNCNAME[0]} called with Arguments: ($*)"

    ### Local variables ###
    local cmd_name="${PROJECT_NAME:-helper}"
    local install_path="/usr/local/bin"
    local completion_path="/etc/bash_completion.d"


    ################################################################################
    ### === INTERNAL CMD FUNCTIONS === ###
    ################################################################################

    ### Check if command is available (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _check() {
        local commands=("$@")
        local missing_commands=()
        
        print --header "Command Availability Check"
        
        for cmd_check in "${commands[@]}"; do
            if command -v "$cmd_check" >/dev/null 2>&1; then
                print --success "$cmd_check is available: $(which "$cmd_check")"
            else
                print --error "$cmd_check is missing"
                missing_commands+=("$cmd_check")
            fi
        done
        
        if [ ${#missing_commands[@]} -gt 0 ]; then
            print --cr
            print --warning "Missing commands: ${missing_commands[*]}"
            return 1
        else
            print --cr
            print --success "All commands are available"
            return 0
        fi
    }
    
    ### Check and install Dependencies (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _dependencies() {
        local app="$1"
        local required_packages=()
        
        ### Define required packages per Operation ###
        case "$app" in
            --acl)
                required_packages=("acl")
                ;;
            --group)
                ### No additional packages needed - uses system tools ###
                return 0
                ;;
            --sudo)
                ### No additional packages needed ###
                return 0
                ;;
        esac
        
        ### Check if packages are needed ###
        if [ ${#required_packages[@]} -eq 0 ]; then
            return 0
        fi
        
        ### Use cmd function to check and install ###
        if ! cmd --check "${required_packages[@]}" >/dev/null 2>&1; then
            print --warning "Missing packages required for $app Operation"
            
            ### Ask for installation permission ###
            if ask --yes-no "Install missing packages: ${required_packages[*]}?" "yes"; then
                cmd --install "${required_packages[@]}"
            else
                print --error "Cannot proceed without required packages"
                return 1
            fi
        fi
        
        return 0
    }

    ### Install missing packages (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _install() {
        local packages=("$@")
        local package_manager=""
        
        ### Detect package manager ###
        if command -v apt >/dev/null 2>&1; then
            package_manager="apt"
        elif command -v yum >/dev/null 2>&1; then
            package_manager="yum"
        elif command -v dnf >/dev/null 2>&1; then
            package_manager="dnf"
        elif command -v pacman >/dev/null 2>&1; then
            package_manager="pacman"
        elif command -v brew >/dev/null 2>&1; then
            package_manager="brew"
        else
            print --error "No supported package manager found"
            return 1
        fi
        
        print --header "Package Installation"
        print --info "Package manager: $package_manager"
        print --info "Packages to install: ${packages[*]}"
        print --cr
        
        ### Ask for confirmation ###
        if ! ask --yes-no "Install missing packages?" "yes"; then
            print --info "Installation cancelled"
            return 1
        fi
        
        ### Install packages ###
        local install_cmd=""
        case "$package_manager" in
            apt)
                install_cmd="sudo apt update && sudo apt install -y"
                ;;
            yum)
                install_cmd="sudo yum install -y"
                ;;
            dnf)
                install_cmd="sudo dnf install -y"
                ;;
            pacman)
                install_cmd="sudo pacman -S --noconfirm"
                ;;
            brew)
                install_cmd="brew install"
                ;;
        esac
        
        for package in "${packages[@]}"; do
            print --info "Installing: $package"
            if eval "$install_cmd $package"; then
                print --success "Installed: $package"
            else
                print --error "Failed to install: $package"
            fi
        done
    }

    ### Create Wrapper Script (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function

    _wrapper() {
        local name="${1:-$cmd_name}"
        local script="${2:-${BASH_SOURCE[0]}}"
        local target="$install_path/$name"
        local template_file="${WRAPPER_DIR}/wrapper.md"
        local pattern="${3:-\$}"
        
        ### Check if running as root for system-wide installation ###
        if [ "$EUID" -ne 0 ] && [[ "$install_path" == "/usr/local/bin" ]]; then
            print --warning "Need sudo privileges for system-wide installation"
            print --info "Installing to user directory instead: ~/.local/bin"
            install_path="$HOME/.local/bin"
            target="$install_path/$name"
            [ ! -d "$install_path" ] && mkdir -p "$install_path"
        fi
        
        ### Check if template file exists ###
        if [ ! -f "$template_file" ]; then
            print --error "Template file not found: $template_file"
            return 1
        fi
        
        ### Extract content from markdown code block ###
        local template_content=$(sed -n '/```bash/,/```/p' "$template_file" | sed '1d;$d')
        
        ### Build regex pattern dynamically for ANY pattern ###
        local regex_pattern=""
        local start_delimiter=""
        local end_delimiter=""
        
        if [ ${#pattern} -eq 1 ]; then
            ### Single character delimiter (like @ or %) ###
            regex_pattern="${pattern}([^${pattern}]+)${pattern}"
            start_delimiter="$pattern"
            end_delimiter="$pattern"
        elif [ ${#pattern} -eq 2 ]; then
            ### Two characters - treat as start/end pair ###
            start_delimiter="${pattern:0:1}"
            end_delimiter="${pattern:1:1}"
            regex_pattern="${start_delimiter}([^${end_delimiter}]+)${end_delimiter}"
        else
            ### Multi-character - split in half ###
            local half_len=$((${#pattern} / 2))
            start_delimiter="${pattern:0:$half_len}"
            end_delimiter="${pattern:$half_len}"
            regex_pattern="${start_delimiter}([^${end_delimiter}]+)${end_delimiter}"
        fi
        
        ### Replace variables using the constructed pattern ###
        while [[ $template_content =~ $regex_pattern ]]; do
            local var_name="${BASH_REMATCH[1]}"
            local full_match="${BASH_REMATCH[0]}"
            local var_value=""
            
            ### Map known variables ###
            case "$var_name" in
                NAME) var_value="$name" ;;
                SCRIPT_PATH) var_value="$script" ;;
                VERSION) var_value="${version:-1.0.0}" ;;
                *) var_value="${!var_name:-}" ;;
            esac
            
            ### Replace the matched pattern with the value ###
            template_content="${template_content//$full_match/$var_value}"
        done
        
        ### Write processed template to target file ###
        echo "$template_content" > "$target"
        chmod +x "$target"
        
        print --success "Wrapper created: $target"
        
        ### Add to PATH if needed ###
        if [[ ":$PATH:" != *":$install_path:"* ]] && [[ "$install_path" == "$HOME/.local/bin" ]]; then
            print --info "Add to PATH: export PATH=\"\$PATH:$install_path\""
            print --info "Add this line to ~/.bashrc for permanent effect"
        fi
    }

    ### Parse Arguments and validate ###
    case $1 in
        --help|-h)
            show_help
            return 0
            ;;
        
        --check)

            ;;

        --dependencies)

            ;;

        --install)

            ;;

        --wrapper)

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
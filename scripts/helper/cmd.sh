#!/bin/bash
################################################################################
### Universal Helper Functions - System Integration Library
### Comprehensive System Integration Functions for Command Installation
### Provides unified cmd Function for system-wide Command Installation and Management
################################################################################
### Project: Universal Helper Library
### Version: 1.0.2
### Author:  Mawage (Development Team)
### Date:    2025-09-14
### License: MIT
### Usage:   Source this File to load System Integration Functions
### Commit:  System Integration Functions for Command Wrappers and bash Completion
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
    ### Log Startup Arguments ###
    log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"

    ### Local variables ###
    local cmd_name="${PROJECT_NAME:-helper}"
    local install_path="/usr/local/bin"
    local completion_path="/etc/bash_completion.d"


    ################################################################################
    ### === INTERNAL CMD FUNCTIONS === ###
    ################################################################################

    ### Check if Command is available (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _check() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"

        local commands=("$@")
        local check_admin=false
        local check_sudo=false
        local missing_commands=()
        
        ### Parse special flags ###
        local filtered_commands=()
        for arg in "${commands[@]}"; do
            case "$arg" in
                --admin) check_admin=true ;;
                --sudo) check_sudo=true ;;
                *) filtered_commands+=("$arg") ;;
            esac
        done
        commands=("${filtered_commands[@]}")
        
        print --header "Command Availability Check"
        
        ### Check admin status ###
        if [ "$check_admin" = true ]; then
            [ "$EUID" -eq 0 ] && print --success "Running as admin (root)" || print --warning "Not running as admin"
        fi
        
        ### Check sudo availability ###
        if [ "$check_sudo" = true ]; then
            if command -v sudo >/dev/null 2>&1; then
                sudo -n true 2>/dev/null && print --success "sudo available (no password)" || print --warning "sudo available (requires password)"
            else
                print --error "sudo not available"
                missing_commands+=("sudo")
            fi
        fi
        
        ### Check regular commands ###
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
        fi
        
        print --cr
        print --success "All commands are available"
    }

    ### Check and install Dependencies (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _dependencies() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"

        local package="$1"
        local commands=()
        local package_name=""
        
        ### Map package to commands and package names ###
        case "$package" in
            acl) 
                commands=("setfacl" "getfacl")
                package_name="acl"
                ;;
            sudo) 
                commands=("sudo" "visudo")
                package_name="sudo"
                ;;
            group)
                commands=("groupadd" "usermod" "getent")
                package_name="coreutils shadow"
                ;;
            *)
                commands=("$package")
                package_name="$package"
                ;;
        esac
        
        ### Check if all commands are available ###
        local missing_commands=()
        for cmd in "${commands[@]}"; do
            command -v "$cmd" >/dev/null 2>&1 || missing_commands+=("$cmd")
        done
        
        ### Handle missing commands ###
        [ ${#missing_commands[@]} -eq 0 ] && return 0
        
        print --warning "${package^^} tools not available"
        
        if ask --yes-no "Install $package_name package?" "yes"; then
            _install $package_name && print --success "${package^^} package installed successfully" || {
                print --error "Failed to install ${package^^} package"
                return 1
            }
        else
            print --error "Cannot proceed without ${package^^} tools"
            return 1
        fi
    }

    ### Execute Command with or without sudo (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _execute() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"

        [ "$EUID" -eq 0 ] && eval "$*" || { 
            command -v sudo >/dev/null 2>&1 && sudo bash -c "$*" || {
                print --error "Cannot execute: sudo not available"
                return 1
            }
        }
    }

    ### Install missing Packages (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _install() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"

        local packages=("$@")
        local package_manager=""
        
        ### Detect Package Manager ###
        for pm in apt yum dnf pacman brew; do
            command -v "$pm" >/dev/null 2>&1 && { package_manager="$pm"; break; }
        done
        
        [ -z "$package_manager" ] && { print --error "No supported package manager found"; return 1; }
        
        print --header "Package Installation"
        print --info "Package manager: $package_manager"
        print --info "Packages to install: ${packages[*]}"
        print --cr
        
        ask --yes-no "Install missing packages?" "yes" || { print --info "Installation cancelled"; return 1; }
        
        ### Install Packages ###
        local install_cmd=""
        case "$package_manager" in
            apt) install_cmd="apt update && apt install -y" ;;
            yum) install_cmd="yum install -y" ;;
            dnf) install_cmd="dnf install -y" ;;
            pacman) install_cmd="pacman -S --noconfirm" ;;
            brew) install_cmd="brew install" ;;
        esac

        ### Install Packages Section ###
        for package in "${packages[@]}"; do
            print --info "Installing: $package"
            if [ "$package_manager" = "brew" ]; then
                eval "$install_cmd $package" && print --success "Installed: $package" || print --error "Failed to install: $package"
            else
                _execute "$install_cmd $package" && print --success "Installed: $package" || print --error "Failed to install: $package"
            fi
        done
    }

    ### Create Wrapper Script (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _wrapper() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"

        local name="${1:-$cmd_name}"
        local script="${2:-${BASH_SOURCE[0]}}"
        local target="$install_path/$name"
        local template_file="${WRAPPER_DIR}/wrapper.md"
        local pattern="${3:-\$}"
        
        ### Check privileges and adjust path ###
        if [ "$EUID" -ne 0 ] && [[ "$install_path" == "/usr/local/bin" ]]; then
            if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
                print --info "Using sudo for system-wide installation"
            else
                print --warning "Cannot access /usr/local/bin - installing to user directory"
                install_path="$HOME/.local/bin"
                target="$install_path/$name"
                [ ! -d "$install_path" ] && mkdir -p "$install_path"
            fi
        fi
        
        [ ! -f "$template_file" ] && { print --error "Template file not found: $template_file"; return 1; }
        
        ### Extract template content ###
        local template_content=$(sed -n '/```bash/,/```/p' "$template_file" | sed '1d;$d')
        
        ### Build regex pattern ###
        local regex_pattern start_delimiter end_delimiter
        case ${#pattern} in
            1) regex_pattern="${pattern}([^${pattern}]+)${pattern}" ;;
            2) start_delimiter="${pattern:0:1}"; end_delimiter="${pattern:1:1}"
            regex_pattern="${start_delimiter}([^${end_delimiter}]+)${end_delimiter}" ;;
            *) local half_len=$((${#pattern} / 2))
            start_delimiter="${pattern:0:$half_len}"; end_delimiter="${pattern:$half_len}"
            regex_pattern="${start_delimiter}([^${end_delimiter}]+)${end_delimiter}" ;;
        esac
        
        ### Replace variables ###
        while [[ $template_content =~ $regex_pattern ]]; do
            local var_name="${BASH_REMATCH[1]}" full_match="${BASH_REMATCH[0]}" var_value=""
            case "$var_name" in
                NAME) var_value="$name" ;;
                SCRIPT_PATH) var_value="$script" ;;
                VERSION) var_value="${version:-1.0.0}" ;;
                *) var_value="${!var_name:-}" ;;
            esac
            template_content="${template_content//$full_match/$var_value}"
        done
        
        ### Create wrapper ###
        if [ "$EUID" -eq 0 ] || [[ "$install_path" == "$HOME/.local/bin" ]]; then
            echo "$template_content" > "$target"
            chmod +x "$target"
        else
            _execute "echo '$template_content' > '$target' && chmod +x '$target'"
        fi
        
        print --success "Wrapper created: $target"
        
        ### PATH advice ###
        [[ ":$PATH:" != *":$install_path:"* ]] && [[ "$install_path" == "$HOME/.local/bin" ]] && {
            print --info "Add to PATH: export PATH=\"\$PATH:$install_path\""
            print --info "Add this line to ~/.bashrc for permanent effect"
        }
    }

    ### Parse Arguments and validate ###
    case $1 in
    --help|-h)
        show_help
        return 0
        ;;
    
    --check)
        shift
        _check "$@"
        ;;
        
    --dependencies)
        shift
        _dependencies "$@"
        ;;
        
    --install)
        shift
        _install "$@"
        ;;
        
    --wrapper)
        shift
        _wrapper "$@"
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

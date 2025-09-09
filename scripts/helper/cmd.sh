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
                ### Pass all other arguments to cmd function ###
                cmd "$@"
                exit $?
                ;;
        esac
        shift
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

    ### Create wrapper script (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _wrapper() {
        local name="${1:-$cmd_name}"
        local script="${2:-${BASH_SOURCE[0]}}"
        local target="$install_path/$name"
        
        ### Check if running as root for system-wide installation ###
        if [ "$EUID" -ne 0 ] && [[ "$install_path" == "/usr/local/bin" ]]; then
            print --warning "Need sudo privileges for system-wide installation"
            print --info "Installing to user directory instead: ~/.local/bin"
            install_path="$HOME/.local/bin"
            target="$install_path/$name"
            [ ! -d "$install_path" ] && mkdir -p "$install_path"
        fi
        
        ### Create wrapper script ###
        cat > "$target" << EOF
#!/bin/bash
################################################################################
### $name Wrapper - Safe execution wrapper
### Auto-generated by cmd() function
################################################################################

### Configuration ###
HELPER_SCRIPT="$script"

### Check if script exists ###
if [ ! -f "\$HELPER_SCRIPT" ]; then
   echo "ERROR: Script not found: \$HELPER_SCRIPT" >&2
   exit 1
fi

### Source the script to load functions ###
source "\$HELPER_SCRIPT"

### Execute requested function or show menu ###
if [ \$# -eq 0 ]; then
   ### Show interactive menu if available ###
   if declare -f show >/dev/null 2>&1; then
       show --menu "Main Menu" "Functions" "Help" "Exit"
   elif declare -f main >/dev/null 2>&1; then
       main
   else
       echo "Available functions:"
       declare -F | awk '{print "  " \$3}' | grep -v "^_"
   fi
else
   ### Execute function with arguments ###
   if declare -f "\$1" >/dev/null 2>&1; then
       "\$@"
   else
       case "\$1" in
           --version|-V)
               echo "${name} version \${SCRIPT_VERSION:-1.0.0}"
               ;;
           *)
               echo "ERROR: Unknown function: \$1" >&2
               echo "Available functions:"
               declare -F | awk '{print "  " \$3}' | grep -v "^_"
               exit 1
               ;;
       esac
   fi
fi
EOF
        
        chmod +x "$target"
        print --success "Wrapper created: $target"
        
        ### Add to PATH if needed ###
        if [[ ":$PATH:" != *":$install_path:"* ]] && [[ "$install_path" == "$HOME/.local/bin" ]]; then
            print --info "Add to PATH: export PATH=\"\$PATH:$install_path\""
            print --info "Add this line to ~/.bashrc for permanent effect"
        fi
    }
    
    ### Create alias (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _alias() {
        local name="${1:-$cmd_name}"
        local script="${2:-${BASH_SOURCE[0]}}"
        local alias_file="$HOME/.bash_aliases"
        
        ### Create alias entry ###
        local alias_line="alias $name='source $script; '"
        
        ### Check if alias already exists ###
        if grep -q "alias $name=" "$alias_file" 2>/dev/null; then
            print --warning "Alias '$name' already exists in $alias_file"
            return 1
        fi
        
        ### Add alias ###
        echo "$alias_line" >> "$alias_file"
        print --success "Alias added to $alias_file"
        print --info "Reload with: source $alias_file"
    }
    
    ### Create completion (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _completion() {
        local name="${1:-$cmd_name}"
        local script="${2:-${BASH_SOURCE[0]}}"
        local comp_file="$completion_path/${name}"
        
        ### Check permissions ###
        if [ "$EUID" -ne 0 ] && [[ "$completion_path" == "/etc/bash_completion.d" ]]; then
            print --warning "Need sudo privileges for system-wide completion"
            comp_file="$HOME/.bash_completion.d/${name}"
            completion_path="$HOME/.bash_completion.d"
            [ ! -d "$completion_path" ] && mkdir -p "$completion_path"
        fi
        
        ### Create dynamic completion script ###
        cat > "$comp_file" << 'EOF'
# Bash completion for CMDNAME - Auto-generated
_CMDNAME_completion() {
   local cur="${COMP_WORDS[COMP_CWORD]}"
   local prev="${COMP_WORDS[COMP_CWORD-1]}"
   local script="SCRIPTPATH"
   
   ### First level - function names ###
   if [ $COMP_CWORD -eq 1 ]; then
       ### Get functions dynamically from script ###
       local functions=""
       if [ -f "$script" ]; then
           functions=$(bash -c "source '$script' 2>/dev/null && declare -F" | awk '{print $3}' | grep -v "^_")
       fi
       functions="$functions --help --version"
       COMPREPLY=($(compgen -W "$functions" -- "$cur"))
       
   ### Second level - function options ###
   elif [ $COMP_CWORD -eq 2 ]; then
       ### Get options for specific function ###
       local options=""
       
       ### Analyze script for options of this function ###
       if [ -f "$script" ]; then
           options=$(awk -v func="$prev" '
               /^[[:space:]]*(function[[:space:]]+)?'$prev'\(\)/ { in_func=1 }
               in_func && /case.*\$1.*in/ { in_case=1 }
               in_func && in_case && /^[[:space:]]*--?[a-zA-Z]/ {
                   match($0, /--?[a-zA-Z][a-zA-Z0-9-]*/)
                   if (RSTART) print substr($0, RSTART, RLENGTH)
               }
               in_func && /^[[:space:]]*\}/ { in_func=0; in_case=0 }
               in_func && /^[[:space:]]*esac/ { in_case=0 }
           ' "$script" | sort -u | tr '\n' ' ')
       fi
       
       [ -n "$options" ] && COMPREPLY=($(compgen -W "$options" -- "$cur"))
   fi
}

complete -F _CMDNAME_completion CMDNAME
EOF
        
        ### Replace placeholders ###
        sed -i "s|CMDNAME|${name}|g" "$comp_file"
        sed -i "s|SCRIPTPATH|${script}|g" "$comp_file"
        
        chmod +r "$comp_file"
        print --success "Completion created: $comp_file"
        print --info "Reload with: source $comp_file"
    }
    
    ### Remove all integrations (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _remove() {
        local name="${1:-$cmd_name}"
        
        ### Remove wrapper ###
        for path in "/usr/local/bin" "$HOME/.local/bin"; do
            if [ -f "$path/$name" ]; then
                rm -f "$path/$name"
                print --success "Removed wrapper: $path/$name"
            fi
        done
        
        ### Remove completion ###
        for path in "/etc/bash_completion.d" "$HOME/.bash_completion.d"; do
            if [ -f "$path/$name" ]; then
                rm -f "$path/$name"
                print --success "Removed completion: $path/$name"
            fi
        done
        
        ### Remove alias ###
        if grep -q "alias $name=" "$HOME/.bash_aliases" 2>/dev/null; then
            sed -i "/alias $name=/d" "$HOME/.bash_aliases"
            print --success "Removed alias from ~/.bash_aliases"
        fi
    }

    ### Parse Arguments ###
    case "$1" in
        --check|-ck)
            shift
            _check "$@"
            ;;

        --install|-i)
            shift
            _install "$@"
            ;;

        --wrapper|-w)
            shift
            _wrapper "$@"
            ;;

        --alias|-a)
            shift
            _alias "$@"
            ;;

        --completion|-c)
            shift
            _completion "$@"
            ;;

        --all)
            shift
            local name="${1:-$cmd_name}"
            local script="${2:-${BASH_SOURCE[0]}}"
            print --header "Installing $name system integration"
            _wrapper "$name" "$script"
            _completion "$name" "$script"
            print --success "Installation complete!"
            print --info "Restart shell or run: source $completion_path/$name"
            ;;

        --remove|-r)
            shift
            _remove "$@"
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
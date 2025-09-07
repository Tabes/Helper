#!/bin/bash
################################################################################
### Universal Helper Functions - Bootstrap Installation Script
### Initial Setup and Installation for fresh Debian Systems
### Downloads and Configures the Helper Framework from Git Repository
################################################################################
### Project: Universal Helper Library
### Version: 1.0.0
### Author:  Mawage (Development Team)
### Date:    2025-09-06
### License: MIT
### Usage:   bash start.sh [OPTIONS]
################################################################################

SCRIPT_VERSION="1.0.0"
COMMIT="Bootstrap Installation Script for Helper Framework"

################################################################################
### === CONFIGURATION === ###
################################################################################

### Default values - can be overridden with arguments ###
DEFAULT_INSTALL_PATH="$HOME/helper"
DEFAULT_GIT_REPO="https://github.com/Tabes/helper.git"
DEFAULT_BRANCH="main"

### Runtime variables ###
INSTALL_PATH=""
GIT_REPO=""
BRANCH=""
SYSTEM_INSTALL=false
VERBOSE=false

################################################################################
### === BASIC OUTPUT FUNCTIONS (Bootstrap versions) === ###
################################################################################

### Colors for bootstrap ###
readonly NC="\033[0m"
readonly RD="\033[0;31m"
readonly GN="\033[0;32m"
readonly YE="\033[1;33m"
readonly BU="\033[0;34m"
readonly CY="\033[0;36m"
readonly WH="\033[1;37m"
readonly MG="\033[0;35m"

### Unicode symbols ###
readonly SYMBOL_SUCCESS="✓"
readonly SYMBOL_ERROR="✗"
readonly SYMBOL_WARNING="⚠"
readonly SYMBOL_INFO="ℹ"


################################################################################
### === INSTALLATION SETUP === ###
################################################################################

### Setup Function with complete Installation Workflow ###
setup() {
    
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _setup_interactive() {
        
        print --header "Interactive Setup"
        
        ### Get installation path ###
        read -p "Installation path [$DEFAULT_INSTALL_PATH]: " user_path
        INSTALL_PATH="${user_path:-$DEFAULT_INSTALL_PATH}"
        
        ### Get Git repository ###
        read -p "Git repository URL [$DEFAULT_GIT_REPO]: " user_repo
        GIT_REPO="${user_repo:-$DEFAULT_GIT_REPO}"
        
        ### Get branch ###
        read -p "Git branch [$DEFAULT_BRANCH]: " user_branch
        BRANCH="${user_branch:-$DEFAULT_BRANCH}"
        
        ### Confirm settings ###
        echo
        print --info "Installation settings:"
        print --info "  Path: $INSTALL_PATH"
        print --info "  Repository: $GIT_REPO"
        print --info "  Branch: $BRANCH"
        echo
        
        read -p "Continue with installation? [Y/n]: " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Yy]$ ]] && [ -n "$REPLY" ]; then
            print --warning "Installation cancelled"
            exit 0
        fi
        
    }
    
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _check_requirements() {
        
        print --header "System Requirements Check"
        
        local errors=0
        
        ### Check OS ###
        if [ -f /etc/debian_version ]; then
            print --success "Debian system detected: $(cat /etc/debian_version)"
        else
            print --warning "Non-Debian system detected"
        fi
        
        ### Check essential commands ###
        local required_commands=("git" "curl" "wget" "sudo")
        
        for cmd in "${required_commands[@]}"; do
        
            if command -v "$cmd" >/dev/null 2>&1; then
                print --success "Command found: $cmd"
            else
                print --error "Command missing: $cmd"
                ((errors++))
            fi
            
        done
        
        ### Check internet connectivity ###
        if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
            print --success "Internet connection: OK"
        else
            print --error "No internet connection"
            ((errors++))
        fi
        
        ### Check user permissions ###
        if [ "$EUID" -eq 0 ]; then
            print --warning "Running as root - will install system-wide"
            SYSTEM_INSTALL=true
        else
            print --info "Running as user: $USER"
            
            ### Check sudo access ###
            if sudo -n true 2>/dev/null; then
                print --success "Passwordless sudo available"
            elif sudo -v 2>/dev/null; then
                print --success "Sudo access available"
            else
                print --warning "No sudo access - limited installation"
            fi
        fi
        
        return $errors
        
    }
    
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _install_dependencies() {
        
        print --header "Installing Dependencies"
        
        local packages=()
        
        ### Check and collect missing packages ###
        command -v git >/dev/null 2>&1 || packages+=("git")
        command -v curl >/dev/null 2>&1 || packages+=("curl")
        command -v wget >/dev/null 2>&1 || packages+=("wget")
        command -v rsync >/dev/null 2>&1 || packages+=("rsync")
        
        if [ ${#packages[@]} -eq 0 ]; then
            print --success "All dependencies installed"
            return 0
        fi
        
        print --info "Missing packages: ${packages[*]}"
        
        ### Try to install ###
        if [ "$EUID" -eq 0 ]; then
            apt-get update && apt-get install -y "${packages[@]}"
        elif sudo -n true 2>/dev/null; then
            sudo apt-get update && sudo apt-get install -y "${packages[@]}"
        else
            print --error "Cannot install packages - need root or sudo access"
            print --info "Please run: sudo apt-get install ${packages[*]}"
            return 1
        fi
        
        print --success "Dependencies installed"
        
    }
    
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _download_framework() {
        
        print --header "Downloading Framework"
        
        ### Check if directory exists ###
        if [ -d "$INSTALL_PATH" ]; then
            print --warning "Directory exists: $INSTALL_PATH"
            read -p "Remove and reinstall? [y/N]: " -n 1 -r
            echo
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$INSTALL_PATH"
                print --success "Removed existing installation"
            else
                print --info "Keeping existing installation"
                return 1
            fi
        fi
        
        ### Clone repository ###
        print --info "Cloning from: $GIT_REPO"
        
        if git clone -b "$BRANCH" "$GIT_REPO" "$INSTALL_PATH" 2>/dev/null; then
            print --success "Repository cloned successfully"
        else
            print --error "Failed to clone repository"
            print --info "Trying alternative download method..."
            
            ### Try wget as fallback ###
            local archive_url="${GIT_REPO%.git}/archive/refs/heads/${BRANCH}.tar.gz"
            
            if wget -q -O /tmp/helper.tar.gz "$archive_url"; then
                mkdir -p "$INSTALL_PATH"
                tar -xzf /tmp/helper.tar.gz -C "$INSTALL_PATH" --strip-components=1
                rm /tmp/helper.tar.gz
                print --success "Downloaded via wget"
            else
                print --error "All download methods failed"
                return 1
            fi
        fi
        
        ### Set permissions ###
        chmod -R 755 "$INSTALL_PATH"
        print --success "Framework downloaded to: $INSTALL_PATH"
        
    }
    
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _setup_structure() {
        
        print --header "Setting Up Directory Structure"
        
        cd "$INSTALL_PATH" || return 1
        
        ### Create required directories ###
        local dirs=(
            "backup"
            "configs"
            "docs/help"
            "logs"
            "scripts/helper"
            "utilities"
        )
        
        for dir in "${dirs[@]}"; do
        
            if mkdir -p "$dir"; then
                print --success "Created: $dir"
            else
                print --error "Failed to create: $dir"
            fi
            
        done
        
        ### Create default config if not exists ###
        if [ ! -f "configs/project.conf" ]; then
            cat > "configs/project.conf" << 'EOF'
################################################################################
### Project Configuration - Auto-generated
################################################################################
PROJECT_NAME="helper"
PROJECT_VERSION="1.0.0"
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"

### Directories ###
BACKUP_DIR="$PROJECT_ROOT/backup"
CONFIGS_DIR="$PROJECT_ROOT/configs"
DOCS_DIR="$PROJECT_ROOT/docs"
LOG_DIR="$PROJECT_ROOT/logs"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"
UTILITIES_DIR="$PROJECT_ROOT/utilities"

### Source helper configuration ###
[ -f "$CONFIGS_DIR/helper.conf" ] && source "$CONFIGS_DIR/helper.conf"
EOF
            print --success "Created default project.conf"
        fi
        
    }
    
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _configure_system() {
        
        print --header "System Integration"
        
        local helper_script="$INSTALL_PATH/scripts/helper.sh"
        
        ### Check if helper.sh exists ###
        if [ ! -f "$helper_script" ]; then
            print --warning "helper.sh not found - skipping system integration"
            return 0
        fi
        
        ### Source helper to use cmd function ###
        source "$helper_script"
        
        ### Install system integration ###
        if declare -f cmd >/dev/null 2>&1; then
            print --info "Installing system commands..."
            cmd --all "helper" "$helper_script"
        else
            print --warning "cmd function not available"
        fi
        
        ### Add to bashrc for user ###
        local bashrc="$HOME/.bashrc"
        local source_line="[ -f \"$helper_script\" ] && source \"$helper_script\""
        
        if ! grep -q "$helper_script" "$bashrc" 2>/dev/null; then
            echo "" >> "$bashrc"
            echo "### Universal Helper Functions ###" >> "$bashrc"
            echo "$source_line" >> "$bashrc"
            print --success "Added to $bashrc"
        else
            print --info "Already in $bashrc"
        fi
        
    }
    
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _setup_complete() {
        
        ### Run complete installation workflow ###
        _check_requirements || {
            print --error "System requirements not met"
            _install_dependencies || return 1
        }
        
        _download_framework || return 1
        _setup_structure || return 1
        _configure_system || print --warning "System integration incomplete"
        
        return 0
        
    }
    
    ### Parse arguments ###
    while [[ $# -gt 0 ]]; do
        
        case $1 in
            --interactive|-i)
                _setup_interactive
                shift
                ;;
                
            --requirements |-q)
                _check_requirements
                return $?
                ;;
                
            --dependencies|-d)
                _install_dependencies
                shift
                ;;
                
            --download)
                _download_framework
                shift
                ;;
                
            --structure|-s)
                _setup_structure
                shift
                ;;
                
            --configure)
                _configure_system
                shift
                ;;
                
            --complete)
                _setup_complete
                shift
                ;;
                
            --help|-h)
                print --header "Setup Function Help"
                echo "Usage: setup [OPTIONS]"
                echo
                echo "Options:"
                echo "  --interactive, -i     Interactive Setup Mode"
                echo "  --requirements , -q   Check System Requirements"
                echo "  --dependencies, -d    Install missing Dependencies"
                echo "  --download            Download Framework from Repository"
                echo "  --structure, -s       Create Directory Structure"
                echo "  --configure           Configure System Integration"
                echo "  --complete            Run complete Installation"
                echo "  --help, -h            Show this Help"
                return 0
                ;;
                
            *)
                print --error "Unknown setup option: $1"
                return 1
                ;;
        esac
        
    done
    
}


################################################################################
### === STATUS & NOTIFICATION FUNCTIONS, LOGGING === ###
################################################################################

### Bootstrap print function - simplified version of helper.sh print() ###
print() {

	### Local variables ###
	local output_buffer=""
	local current_color="${NC}"
	local suppress_newline=false
	local has_output=false
	
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
				
			--cr)
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
				
			### Color detection ###
			NC|RD|GN|YE|BU|CY|WH|MG)
				current_color="${!1}"
				shift
				;;
				
			### Regular text ###
			*)
				### Apply color ###
				printf "${current_color}$1${NC}"
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


################################################################################
### === INTERACTIVE DISPLAY FUNCTIONS === ###
################################################################################

### Show help ###
show_help() {

	print --header "Universal Helper Functions - Bootstrap Installer"
	echo
	echo "Usage: bash start.sh [OPTIONS]"
	echo
	echo "Options:"
	echo "  -p, --path PATH      Installation path (default: $DEFAULT_INSTALL_PATH)"
	echo "  -r, --repo URL       Git repository URL"
	echo "  -b, --branch NAME    Git branch (default: $DEFAULT_BRANCH)"
	echo "  -s, --system         System-wide installation (/opt/helper)"
	echo "  -v, --verbose        Verbose output"
	echo "  -h, --help           Show this help"
	echo
	echo "Examples:"
	echo "  bash start.sh                    # Interactive installation"
	echo "  bash start.sh --path ~/custom    # Custom path"
	echo "  bash start.sh --system           # System-wide installation"
	echo

}

### Unified show function for interactive displays and menus ###
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
		echo
		
		### Display options ###
		local i=1
		for option in "${menu_options[@]}"; do
			printf "  [%d]  %s\n" "$i" "$option"
			((i++))
		done
		printf "  [0]  Exit\n"
		echo
		
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
		print --header "Universal Helper Functions - Bootstrap Installer"
		printf "  Version:  %s\n" "$SCRIPT_VERSION"
		printf "  Commit:   %s\n" "$COMMIT"
		printf "  Author:   Mawage (Development Team)\n"
		printf "  License:  MIT\n"
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
				
			--help|-h)
				print --header "Show Function Help"
				echo "Usage: show [OPERATION] [OPTIONS]"
				echo
				echo "Operations:"
				echo "  --menu TITLE OPTIONS...  Display interactive menu"
				echo "  --spinner PID [DELAY]    Show progress spinner"
				echo "  --progress CUR TOT [MSG] Show progress bar"
				echo "  --version                Show version info"
				echo "  --help, -h               Show this help"
				return 0
				;;
				
			*)
				print --error "Unknown show operation: $1"
				return 1
				;;
		esac
	done
}


################################################################################
### === MAIN EXECUTION === ###
################################################################################

### Parse command line arguments ###
parse_arguments() {

	while [[ $# -gt 0 ]]; do
	
		case $1 in
			--path|-p)
				INSTALL_PATH="$2"
				shift 2
				;;
				
			--repo|-r)
				GIT_REPO="$2"
				shift 2
				;;
				
			--branch|-b)
				BRANCH="$2"
				shift 2
				;;
				
			--system|-s)
				SYSTEM_INSTALL=true
				INSTALL_PATH="/opt/helper"
				shift
				;;
				
			--verbose|-v)
				VERBOSE=true
				set -x
				shift
				;;
				
			--help|-h)
				show_help
				exit 0
				;;
				
			*)
				print --error "Unknown option: $1"
				show_help
				exit 1
				;;
		esac
		
	done
	
	### Set defaults if not provided ###
	INSTALL_PATH="${INSTALL_PATH:-$DEFAULT_INSTALL_PATH}"
	GIT_REPO="${GIT_REPO:-$DEFAULT_GIT_REPO}"
	BRANCH="${BRANCH:-$DEFAULT_BRANCH}"

}

### Main function ###
main() {

    clear

	print --cr 2 --header "Universal Helper Functions - Installation" -cr
	print --info "Version: $SCRIPT_VERSION"
	echo
	
	### Parse arguments ###
	parse_arguments "$@"
	
	### Interactive Mode if no Repository specified ###
	if [ "$GIT_REPO" = "$DEFAULT_GIT_REPO" ]; then
		setup --interactive
	fi
	
    ### Run complete Setup ###
    if ! setup --complete; then
        print --error "Installation failed"
        exit 1
    fi

	### Success message ###
	echo
	print --header "Installation Complete"
	print --success "Framework installed to: $INSTALL_PATH"
	print --info "To use the helper functions:"
	print --info "  1. Restart your shell or run: source ~/.bashrc"
	print --info "  2. Type: helper --help"
	echo

}

### Cleanup on exit ###
cleanup() {

	if [ "$VERBOSE" = "true" ]; then
		set +x
	fi

}

### Set trap ###
trap cleanup EXIT

### Execute main ###
main "$@"
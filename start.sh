#!/bin/bash
################################################################################
### Universal Helper Functions - Bootstrap Installation Script
### Initial setup and Installation for fresh Debian Sstems
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
COMMIT="Bootstrap installation script for helper framework"

################################################################################
### === CONFIGURATION === ###
################################################################################

### Default values - can be overridden with arguments ###
DEFAULT_INSTALL_PATH="$HOME/helper"
DEFAULT_GIT_REPO="https://github.com/USERNAME/helper-framework.git"
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
### === SYSTEM CHECK FUNCTIONS === ###
################################################################################

### Check system requirements ###
check_requirements() {

	print_header "System Requirements Check"
	
	local errors=0
	
	### Check OS ###
	if [ -f /etc/debian_version ]; then
		print_success "Debian system detected: $(cat /etc/debian_version)"
	else
		print_warning "Non-Debian system detected"
	fi
	
	### Check essential commands ###
	local required_commands=("git" "curl" "wget" "sudo")
	
	for cmd in "${required_commands[@]}"; do
	
		if command -v "$cmd" >/dev/null 2>&1; then
			print_success "Command found: $cmd"
		else
			print_error "Command missing: $cmd"
			((errors++))
		fi
		
	done
	
	### Check internet connectivity ###
	if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
		print_success "Internet connection: OK"
	else
		print_error "No internet connection"
		((errors++))
	fi
	
	### Check user permissions ###
	if [ "$EUID" -eq 0 ]; then
		print_warning "Running as root - will install system-wide"
		SYSTEM_INSTALL=true
	else
		print_info "Running as user: $USER"
		
		### Check sudo access ###
		if sudo -n true 2>/dev/null; then
			print_success "Passwordless sudo available"
		elif sudo -v 2>/dev/null; then
			print_success "Sudo access available"
		else
			print_warning "No sudo access - limited installation"
		fi
	fi
	
	return $errors

}

### Install missing packages ###
install_dependencies() {

	print_header "Installing Dependencies"
	
	local packages=()
	
	### Check and collect missing packages ###
	command -v git >/dev/null 2>&1 || packages+=("git")
	command -v curl >/dev/null 2>&1 || packages+=("curl")
	command -v wget >/dev/null 2>&1 || packages+=("wget")
	command -v rsync >/dev/null 2>&1 || packages+=("rsync")
	
	if [ ${#packages[@]} -eq 0 ]; then
		print_success "All dependencies installed"
		return 0
	fi
	
	print_info "Missing packages: ${packages[*]}"
	
	### Try to install ###
	if [ "$EUID" -eq 0 ]; then
		apt-get update && apt-get install -y "${packages[@]}"
	elif sudo -n true 2>/dev/null; then
		sudo apt-get update && sudo apt-get install -y "${packages[@]}"
	else
		print_error "Cannot install packages - need root or sudo access"
		print_info "Please run: sudo apt-get install ${packages[*]}"
		return 1
	fi
	
	print_success "Dependencies installed"

}


################################################################################
### === INSTALLATION FUNCTIONS === ###
################################################################################

### Download framework from Git ###
download_framework() {

	print_header "Downloading Framework"
	
	### Check if directory exists ###
	if [ -d "$INSTALL_PATH" ]; then
		print_warning "Directory exists: $INSTALL_PATH"
		read -p "Remove and reinstall? [y/N]: " -n 1 -r
		echo
		
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			rm -rf "$INSTALL_PATH"
			print_success "Removed existing installation"
		else
			print_info "Keeping existing installation"
			return 1
		fi
	fi
	
	### Clone repository ###
	print_info "Cloning from: $GIT_REPO"
	
	if git clone -b "$BRANCH" "$GIT_REPO" "$INSTALL_PATH" 2>/dev/null; then
		print_success "Repository cloned successfully"
	else
		print_error "Failed to clone repository"
		print_info "Trying alternative download method..."
		
		### Try wget as fallback ###
		local archive_url="${GIT_REPO%.git}/archive/refs/heads/${BRANCH}.tar.gz"
		
		if wget -q -O /tmp/helper.tar.gz "$archive_url"; then
			mkdir -p "$INSTALL_PATH"
			tar -xzf /tmp/helper.tar.gz -C "$INSTALL_PATH" --strip-components=1
			rm /tmp/helper.tar.gz
			print_success "Downloaded via wget"
		else
			print_error "All download methods failed"
			return 1
		fi
	fi
	
	### Set permissions ###
	chmod -R 755 "$INSTALL_PATH"
	print_success "Framework downloaded to: $INSTALL_PATH"

}

### Setup directory structure ###
setup_structure() {

	print_header "Setting Up Directory Structure"
	
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
			print_success "Created: $dir"
		else
			print_error "Failed to create: $dir"
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
		print_success "Created default project.conf"
	fi

}

### Configure system integration ###
configure_system() {

	print_header "System Integration"
	
	local helper_script="$INSTALL_PATH/scripts/helper.sh"
	
	### Check if helper.sh exists ###
	if [ ! -f "$helper_script" ]; then
		print_warning "helper.sh not found - skipping system integration"
		return 0
	fi
	
	### Source helper to use cmd function ###
	source "$helper_script"
	
	### Install system integration ###
	if declare -f cmd >/dev/null 2>&1; then
		print_info "Installing system commands..."
		cmd --all "helper" "$helper_script"
	else
		print_warning "cmd function not available"
	fi
	
	### Add to bashrc for user ###
	local bashrc="$HOME/.bashrc"
	local source_line="[ -f \"$helper_script\" ] && source \"$helper_script\""
	
	if ! grep -q "$helper_script" "$bashrc" 2>/dev/null; then
		echo "" >> "$bashrc"
		echo "### Universal Helper Functions ###" >> "$bashrc"
		echo "$source_line" >> "$bashrc"
		print_success "Added to $bashrc"
	else
		print_info "Already in $bashrc"
	fi

}


################################################################################
### === INTERACTIVE SETUP === ###
################################################################################

### Interactive configuration ###
interactive_setup() {

	print_header "Interactive Setup"
	
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
	print_info "Installation settings:"
	print_info "  Path: $INSTALL_PATH"
	print_info "  Repository: $GIT_REPO"
	print_info "  Branch: $BRANCH"
	echo
	
	read -p "Continue with installation? [Y/n]: " -n 1 -r
	echo
	
	if [[ ! $REPLY =~ ^[Yy]$ ]] && [ -n "$REPLY" ]; then
		print_warning "Installation cancelled"
		exit 0
	fi

}


################################################################################
### === STATUS & NOTIFICATION FUNCTIONS, LOGGING === ###
################################################################################

### Bootstrap Print Function - simplified Version of helper.sh print() ###
print() {

	### Local variables ###
	local output_buffer=""
	local current_color="${NC}"
	local suppress_newline=false
	local has_output=false
	
    ### Compatibility wrapper functions ###
    print_info() {
        print --info "$1"
    }

    print_success() {
        print --success "$1"
    }

    print_error() {
        print --error "$1"
    }

    print_warning() {
        print --warning "$1"
    }

    print_header() {
        print --header "$1"
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
				print_error "Unknown option: $1"
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

### Show help ###
show_help() {

	print_header "Universal Helper Functions - Bootstrap Installer"
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

### Main function ###
main() {

	print_header "Universal Helper Functions - Installation"
	print_info "Version: $SCRIPT_VERSION"
	echo
	
	### Parse arguments ###
	parse_arguments "$@"
	
	### Interactive mode if no repo specified ###
	if [ "$GIT_REPO" = "$DEFAULT_GIT_REPO" ]; then
		interactive_setup
	fi
	
	### Check requirements ###
	if ! check_requirements; then
		print_error "System requirements not met"
		install_dependencies || exit 1
	fi
	
	### Download framework ###
	if ! download_framework; then
		print_error "Failed to download framework"
		exit 1
	fi
	
	### Setup structure ###
	if ! setup_structure; then
		print_error "Failed to setup directory structure"
		exit 1
	fi
	
	### Configure system ###
	if ! configure_system; then
		print_warning "System integration incomplete"
	fi
	
	### Success message ###
	echo
	print_header "Installation Complete"
	print_success "Framework installed to: $INSTALL_PATH"
	print_info "To use the helper functions:"
	print_info "  1. Restart your shell or run: source ~/.bashrc"
	print_info "  2. Type: helper --help"
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
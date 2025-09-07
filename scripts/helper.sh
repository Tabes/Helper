#!/bin/bash
################################################################################
### Universal Helper Functions - Complete Utility Library
### Comprehensive Collection of Helper Functions for bash Scripts
### Provides Output, Logging, Validation, System, Network and Utility Functions
################################################################################
### Project: Universal Helper Library
### Version: 2.1.0
### Author:  Mawage (Development Team)
### Date:    2025-08-31
### License: MIT
### Usage:   Source this File to Load Helper Functions
################################################################################

SCRIPT_VERSION="1.0.0"
COMMIT="Initial helper functions library structure"


################################################################################
### === INITIALIZATION === ###
################################################################################

### Load Configuration and Dependencies ###
load_config() {
   ### Determine Project root dynamically ###
   local script_path="$(realpath "${BASH_SOURCE[0]}")"
   local script_dir="$(dirname "$script_path")"
   local project_root="$(dirname "$script_dir")"
   
   ### Look for project.conf in standard Locations ###
   local config_file=""
   if [ -f "$project_root/configs/project.conf" ]; then
       config_file="$project_root/configs/project.conf"
   elif [ -f "$project_root/project.conf" ]; then
       config_file="$project_root/project.conf"
   else
       print --error "Project configuration not found"
       return 1
   fi
   
   ### Source main configuration if found ###
   if [ -f "$config_file" ]; then
       source "$config_file"
   fi
   
   ### Load additional configuration files from configs/ ###
   if [ -d "$project_root/configs" ]; then
       for conf in "$project_root/configs"/*.conf; do
           ### Skip files starting with underscore and project.conf (already loaded) ###
           local basename=$(basename "$conf")
           if [[ ! "$basename" =~ ^_ ]] && [ "$conf" != "$config_file" ] && [ -f "$conf" ]; then
               source "$conf"
           fi
       done
   fi
   
   ### Load helper scripts from scripts/helper/ ###
   if [ -d "$project_root/scripts/helper" ]; then
       for script in "$project_root/scripts/helper"/*.sh; do
           ### Skip files starting with underscore ###
           local basename=$(basename "$script")
           if [[ ! "$basename" =~ ^_ ]] && [ -f "$script" ]; then
               source "$script"
           fi
       done
   fi
   
   ### Load additional scripts from scripts/ ###
   if [ -d "$project_root/scripts" ]; then
       for script in "$project_root/scripts"/*.sh; do
           ### Skip files starting with underscore and helper.sh (avoid self-sourcing) ###
           local basename=$(basename "$script")
           if [[ ! "$basename" =~ ^_ ]] && [ "$script" != "$script_path" ] && [ -f "$script" ]; then
               source "$script"
           fi
       done
   fi
   
   return 0
}


################################################################################
### === GLOBAL VARIABLES === ###
################################################################################

### Color definitions - can be overridden in project.conf ###
readonly NC="${COLOR_NC:-\033[0m}"
readonly RD="${COLOR_RD:-\033[0;31m}"
readonly GN="${COLOR_GN:-\033[0;32m}"
readonly YE="${COLOR_YE:-\033[1;33m}"
readonly BU="${COLOR_BU:-\033[0;34m}"
readonly CY="${COLOR_CY:-\033[0;36m}"
readonly WH="${COLOR_WH:-\033[1;37m}"
readonly MG="${COLOR_MG:-\033[0;35m}"

### Unicode symbols - can be overridden in project.conf ###
readonly SYMBOL_SUCCESS="${SYMBOL_SUCCESS:-✓}"
readonly SYMBOL_ERROR="${SYMBOL_ERROR:-✗}"
readonly SYMBOL_WARNING="${SYMBOL_WARNING:-⚠}"
readonly SYMBOL_INFO="${SYMBOL_INFO:-ℹ}"


################################################################################
### === SYSTEM INTEGRATION FUNCTIONS === ###
################################################################################

### Universal command integration function ###
cmd() {
   ### Local variables ###
   local operation=""
   local cmd_name="${PROJECT_NAME:-helper}"
   local install_path="/usr/local/bin"
   local completion_path="/etc/bash_completion.d"
   
   # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
   _cmd_create_wrapper() {
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
   
   # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
   _cmd_create_alias() {
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
   
   # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
   _cmd_create_completion() {
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
   
   # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
   _cmd_remove() {
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
   
   ### Parse arguments ###
   while [[ $# -gt 0 ]]; do
       case $1 in
           --wrapper|-w)
               _cmd_create_wrapper "${2:-$cmd_name}" "${3:-${BASH_SOURCE[0]}}"
               shift $#
               ;;
           --alias|-a)
               _cmd_create_alias "${2:-$cmd_name}" "${3:-${BASH_SOURCE[0]}}"
               shift $#
               ;;
           --completion|-c)
               _cmd_create_completion "${2:-$cmd_name}" "${3:-${BASH_SOURCE[0]}}"
               shift $#
               ;;
           --all)
               local name="${2:-$cmd_name}"
               local script="${3:-${BASH_SOURCE[0]}}"
               print --header "Installing $name system integration"
               _cmd_create_wrapper "$name" "$script"
               _cmd_create_completion "$name" "$script"
               print --success "Installation complete!"
               print --info "Restart shell or run: source $completion_path/$name"
               shift $#
               ;;
           --remove|-r)
               _cmd_remove "${2:-$cmd_name}"
               shift $#
               ;;
           *)
               print --error "Unknown operation: $1"
               print "Usage: cmd [OPERATION] [NAME] [SCRIPT]"
               print "Operations: --wrapper, --alias, --completion, --all, --remove"
               return 1
               ;;
       esac
   done
}


################################################################################
### === SECURITY & PERMISSION MANAGEMENT === ###
################################################################################

### Universal Permission Management Function ###
secure() {
   ### Local variables ###
   local operation="$1"
   local target_path="${2:-$(pwd)}"
   local target_user="${3:-$USER}"
   
   # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
   _secure_setup_acl() {
       local path="$1"
       local user="$2"
       
       ### Check if path exists ###
       if [ ! -e "$path" ]; then
           print --error "Path does not exist: $path"
           return 1
       fi
       
       ### Apply ACL ###
       sudo setfacl -R -m u:${user}:rwx "$path" 2>/dev/null
       sudo setfacl -d -R -m u:${user}:rwx "$path" 2>/dev/null
       
       print --success "ACL set for user '$user' on: $path"
       print --info "Verify with: getfacl $path"
   }
   
   # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
   _secure_setup_group() {
       local path="$1"
       local user="$2"
       local group="${4:-$(basename $path)-admin}"
       
       ### Create group if not exists ###
       if ! getent group "$group" >/dev/null 2>&1; then
           sudo groupadd "$group"
           print --success "Created group: $group"
       fi
       
       ### Add user to group ###
       sudo usermod -a -G "$group" "$user"
       
       ### Set permissions ###
       sudo chown -R root:"$group" "$path"
       sudo chmod -R 775 "$path"
       sudo chmod g+s "$path"
       
       print --success "Group permissions set for '$user' via group '$group'"
       print --info "Re-login required for group changes"
   }
   
   # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
   _secure_setup_sudo() {
       local user="$1"
       local commands="${2:-/usr/bin/rsync,/usr/bin/cp,/usr/bin/mv,/usr/bin/mkdir,/usr/bin/rm}"
       local sudoers_file="/etc/sudoers.d/secure-${user}"
       
       ### Build sudoers line ###
       local sudo_line="$user ALL=(ALL) NOPASSWD: ${commands// /,}"
       sudo_line="${sudo_line//,/, }"  ### Format with spaces after commas ###
       
       ### Write sudoers file ###
       echo "$sudo_line" | sudo tee "$sudoers_file" > /dev/null
       sudo chmod 440 "$sudoers_file"
       
       ### Validate ###
       if sudo visudo -c -f "$sudoers_file" >/dev/null 2>&1; then
           print --success "sudo NOPASSWD configured for: $user"
           print --warning "Security: Only specified commands allowed"
       else
           sudo rm -f "$sudoers_file"
           print --error "sudoers validation failed"
           return 1
       fi
   }
   
   # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
   _secure_check_permissions() {
       local path="${1:-$(pwd)}"
       local user="${2:-$USER}"
       
       print --header "Permission Analysis"
       print "User: $user"
       print "Path: $path"
       print --line "-"
       
       ### Check basic permissions ###
       if [ -r "$path" ]; then
           print --success "Read: Yes"
       else
           print --error "Read: No"
       fi
       
       if [ -w "$path" ]; then
           print --success "Write: Yes"
       else
           print --error "Write: No"
       fi
       
       if [ -x "$path" ]; then
           print --success "Execute: Yes"
       else
           print --warning "Execute: No"
       fi
       
       ### Check ACL if available ###
       if command -v getfacl >/dev/null 2>&1; then
           print --line "-"
           print "ACL Status:"
           local acl_output=$(getfacl "$path" 2>/dev/null | grep "user:$user")
           if [ -n "$acl_output" ]; then
               print --success "$acl_output"
           else
               print --info "No ACL for user $user"
           fi
       fi
       
       ### Check groups ###
       print --line "-"
       print "Groups: $(groups $user)"
       
       ### Check sudo permissions ###
       if sudo -l -U "$user" 2>/dev/null | grep -q NOPASSWD; then
           print --warning "sudo NOPASSWD entries found"
       fi
   }
   
   # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
   _secure_interactive_setup() {
       local path="$1"
       local user="$2"
       
       print --header "Permission Setup Wizard"
       print "Target Path: $path"
       print "Target User: $user"
       print --line "-"
       print "Select method:"
       print "  1) ACL - File Access Control Lists (recommended)"
       print "  2) Group - Unix group permissions"
       print "  3) sudo - NOPASSWD for commands (least secure)"
       print "  4) Check - Analyze current permissions"
       print "  0) Cancel"
       print --line "-"
       
       read -p "Choice [0-4]: " choice
       
       case "$choice" in
           1)
               _secure_setup_acl "$path" "$user"
               ;;
           2)
               read -p "Group name [$(basename $path)-admin]: " group_name
               group_name="${group_name:-$(basename $path)-admin}"
               _secure_setup_group "$path" "$user" "$group_name"
               ;;
           3)
               print --warning "Enter commands (comma-separated)"
               print "Default: /usr/bin/rsync,/usr/bin/cp,/usr/bin/mv"
               read -p "Commands: " commands
               _secure_setup_sudo "$user" "${commands:-/usr/bin/rsync,/usr/bin/cp,/usr/bin/mv}"
               ;;
           4)
               _secure_check_permissions "$path" "$user"
               ;;
           0)
               print --info "Cancelled"
               ;;
           *)
               print --error "Invalid choice"
               ;;
       esac
   }
   
   ### Parse arguments ###
   case "$operation" in
       --acl)
           _secure_setup_acl "$target_path" "$target_user"
           ;;
       --group)
           _secure_setup_group "$target_path" "$target_user" "${4:-}"
           ;;
       --sudo)
           _secure_setup_sudo "$target_user" "${2:-}"
           ;;
       --check)
           _secure_check_permissions "$target_path" "$target_user"
           ;;
       --wizard)
           _secure_interactive_setup "$target_path" "$target_user"
           ;;
       --remove)
           ### Remove all permission enhancements ###
           sudo setfacl -R -x u:${target_user} "$target_path" 2>/dev/null
           sudo rm -f "/etc/sudoers.d/secure-${target_user}"
           print --success "Removed enhanced permissions for $target_user"
           ;;
       *)
           print --error "Unknown operation: $operation"
           print "Usage: secure [OPERATION] [PATH] [USER]"
           print "Operations:"
           print "  --acl PATH [USER]      Setup ACL permissions"
           print "  --group PATH [USER]    Setup group permissions"
           print "  --sudo USER [COMMANDS] Setup sudo NOPASSWD"
           print "  --check [PATH] [USER]  Check permissions"
           print "  --wizard [PATH] [USER] Interactive setup"
           print "  --remove PATH [USER]   Remove permissions"
           return 1
           ;;
   esac
}


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
   _print_apply_formatting() {
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
    _print_help() {
        ### Try to load Help from MarkDown File ###
        local help_file="${DOCS_DIR}/help/print.md"
        
        if [ -f "$help_file" ]; then
            ### Parse markdown and display formatted ###
            local P1="${POS[0]:-4}"
            local P2="${POS[1]:-8}"
            
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
                        printf "\033[${P1}G•\033[${P2}G${line#- }\n"
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
            ### Fallback error message ###
            printf "${RD}Error: Help documentation not found${NC}\n" >&2
            printf "Expected location: ${help_file}\n" >&2
            printf "Please ensure the documentation is properly installed.\n" >&2
            return 1
        fi
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
           ### Help ###
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
               _print_apply_formatting "$1" "$current_position" "$current_alignment"
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
        local msg="$2"
        local file="${3:-$log_file}"
        
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
        
        ### Write to script-specific log file ###
        echo "[$timestamp] [$level] $msg" >> "$file"
        
        ### Also write to central log if configured ###
        if [ -n "$CENTRAL_LOG" ] && [ "$CENTRAL_LOG" != "$file" ]; then
            echo "[$timestamp] [${script_name}] [$level] $msg" >> "$CENTRAL_LOG"
        fi
        
        ### Console output based on level ###
        case "$level" in
            ERROR)
                [ "${VERBOSE:-false}" = "true" ] && print --error "$msg"
                ;;
            WARNING)
                [ "${VERBOSE:-false}" = "true" ] && print --warning "$msg"
                ;;
            INFO)
                [ "${VERBOSE:-false}" = "true" ] && print --info "$msg"
                ;;
            DEBUG)
                [ "${DEBUG:-false}" = "true" ] && print CY "[DEBUG] $msg"
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
                _log_write "INFO" "$2"
                shift 2
                ;;
            --error)
                _log_write "ERROR" "$2"
                shift 2
                ;;
            --warning)
                _log_write "WARNING" "$2"
                shift 2
                ;;
            --debug)
                _log_write "DEBUG" "$2"
                shift 2
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
                _log_write "INFO" "Log file cleared by user"
                shift $#
                ;;
            --help|-h)
                show_help
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
               _show_help
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
   ### Store original arguments for logging ###
   local ORIGINAL_ARGS=("$@")
   
   ### Parse arguments ###
   while [[ $# -gt 0 ]]; do
       case $1 in
           -h|--help)
               show --help
               exit 0
               ;;
           -V|--version)
               show --version
               exit 0
               ;;
           *)
               shift
               ;;
       esac
   done
}

### Main function ###
main() {

    Clear

    ### Load configuration and dependencies ###
    load_config
    
    ### Initialize logging ###
    log --init "${LOG_DIR}/${PROJECT_NAME}.log" "${LOG_LEVEL:-INFO}"
    
    ### Log startup ###
    log --info "Helper Functions startup: $*"
    
    ### Check if no arguments provided ###
    if [ $# -eq 0 ]; then
        show --header "Universal Helper Functions v${SCRIPT_VERSION}"
        show --doc --help
        exit 0
    else
        ### Parse and execute arguments ###
        parse_arguments "$@"
    fi
}

### Cleanup function ###
cleanup() {
    log --info "Helper Functions cleanup"
}

### Initialize when run directly ###
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
   ### Running directly ###
   main "$@"
else
   ### Being sourced ###
   load_config
   print --success "Helper functions loaded. Type 'show --menu' for an interactive menu."
fi

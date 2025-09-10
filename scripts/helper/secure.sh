#!/bin/bash
################################################################################
### Universal Helper Functions - Security & Permission Management Library
### Comprehensive Security Functions for ACL, Group, and sudo Permission Management
### Provides unified Secure Function for Permission Setup and Security Configuration
################################################################################
### Project: Universal Helper Library
### Version: 1.0.0
### Author:  Mawage (Development Team)
### Date:    2025-09-08
### License: MIT
### Usage:   Source this File to load Security and Permission Management Functions
################################################################################

readonly header="Security & Permission Management"

readonly version="1.0.0"
readonly commit="Security & Permission Management Functions for ACL and sudo Configuration"


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
                secure "$@"
                exit $?
                ;;
        esac
    done
}


################################################################################
### === SECURITY & PERMISSION MANAGEMENT === ###
################################################################################

### Universal Permission Management Function ###
secure() {
    ### Log Startup Arguments ###
    log --info "${FUNCNAME[0]} called with Arguments: ($*)"

    local target_path="${2:-$(pwd)}"
    local target_user="${3:-$USER}"
    
    local recursive=false
    local operation=""

    ### Apply ACL Permissions (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within Main Function
    _acl() {
        local path="$1"
        local user="$2"
        local recursive_flag="$3"
        
        ### Check if ACL commands are available ###
        if ! command -v setfacl >/dev/null 2>&1 || ! command -v getfacl >/dev/null 2>&1; then
            print --warning "ACL tools not available"
            
            ### Attempt to install ACL package ###
            if ask --yes-no "Install ACL package (acl)?" "yes"; then
                if cmd --install acl; then
                    print --success "ACL package installed successfully"
                else
                    print --error "Failed to install ACL package"
                    return 1
                fi
            else
                print --error "Cannot proceed without ACL tools"
                return 1
            fi
        fi
        
        ### Validate path ###
        if [ ! -e "$path" ]; then
            print --error "Path does not exist: $path"
            return 1
        fi
        
        ### Validate user ###
        if ! id "$user" >/dev/null 2>&1; then
            print --error "User does not exist: $user"
            return 1
        fi
        
        ### Build ACL command ###
        local acl_cmd="setfacl"
        local default_acl_cmd="setfacl -d"
        
        if [ "$recursive_flag" = "true" ]; then
            acl_cmd="$acl_cmd -R"
            default_acl_cmd="$default_acl_cmd -R"
        fi
        
        ### Apply ACL permissions ###
        print --info "Setting ACL for user '$user' on: $path"
        
        if sudo $acl_cmd -m "u:${user}:rwx" "$path" 2>/dev/null; then
            print --success "User ACL set successfully"
        else
            print --error "Failed to set user ACL"
            return 1
        fi
        
        ### Apply default ACL for directories ###
        if [ -d "$path" ]; then
            if sudo $default_acl_cmd -m "u:${user}:rwx" "$path" 2>/dev/null; then
                print --success "Default ACL set successfully"
            else
                print --warning "Failed to set default ACL (not critical)"
            fi
        fi
        
        ### Verify ACL ###
        local verification=$(getfacl "$path" 2>/dev/null | grep "user:$user")
        if [ -n "$verification" ]; then
            print --success "ACL verification: $verification"
        else
            print --warning "Could not verify ACL settings"
        fi
        
        print --info "Verify manually with: getfacl $path"
        return 0
    }

    ### Check current Permissions (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _check() {
        local path="${1:-$(pwd)}"
        local user="${2:-$USER}"
        local recursive_flag="$3"
        
        print --header "Permission Analysis"
        print "User: $user"
        print "Path: $path"
        print --line "-"
        
        ### Check if path exists ###
        if [ ! -e "$path" ]; then
            print --error "Path does not exist: $path"
            return 1
        fi
        
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
        
        ### Show traditional permissions ###
        print --line "-"
        print "Traditional permissions:"
        ls -ld "$path"
        
        ### Check ACL if available ###
        if command -v getfacl >/dev/null 2>&1; then
            print --line "-"
            print "ACL Status:"
            local acl_output=$(getfacl "$path" 2>/dev/null | grep "user:$user")
            if [ -n "$acl_output" ]; then
                print --success "$acl_output"
            else
                print --info "No specific ACL for user $user"
                ### Show all ACL entries ###
                local all_acl=$(getfacl "$path" 2>/dev/null | grep "^user:" | grep -v "user::") 
                if [ -n "$all_acl" ]; then
                    print --info "Other user ACL entries:"
                    echo "$all_acl"
                fi
            fi
        else
            print --info "ACL tools not available"
        fi
        
        ### Check groups ###
        print --line "-"
        print "User groups: $(groups "$user" 2>/dev/null || echo "User not found")"
        
        ### Check file/directory group ###
        local file_group=$(stat -c %G "$path" 2>/dev/null)
        if [ -n "$file_group" ]; then
            print "Path group: $file_group"
            
            ### Check if user is in file group ###
            if groups "$user" 2>/dev/null | grep -q "\b$file_group\b"; then
                print --success "User is member of path group"
            else
                print --warning "User is NOT member of path group"
            fi
        fi
        
        ### Check sudo permissions ###
        print --line "-"
        if command -v sudo >/dev/null 2>&1; then
            local sudo_entries=$(sudo -l -U "$user" 2>/dev/null | grep "NOPASSWD")
            if [ -n "$sudo_entries" ]; then
                print --warning "sudo NOPASSWD entries found:"
                echo "$sudo_entries"
            else
                print --info "No sudo NOPASSWD entries for user"
            fi
        else
            print --info "sudo not available"
        fi
        
        ### Recursive check for directories ###
        if [ "$recursive_flag" = "true" ] && [ -d "$path" ]; then
            print --line "-"
            print --info "Checking subdirectories recursively..."
            
            local issue_count=0
            while IFS= read -r -d '' subpath; do
                if [ ! -r "$subpath" ] || [ ! -w "$subpath" ]; then
                    if [ $issue_count -eq 0 ]; then
                        print --warning "Permission issues found in subdirectories:"
                    fi
                    print --error "  $(ls -ld "$subpath")"
                    ((issue_count++))
                fi
            done < <(find "$path" -type d -print0 2>/dev/null)
            
            if [ $issue_count -eq 0 ]; then
                print --success "All subdirectories accessible"
            else
                print --warning "Found $issue_count subdirectories with permission issues"
            fi
        fi
        
        return 0
    }

    ### Check and install Dependencies (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _dependencies() {
        local operation="$1"
        local required_packages=()
        
        ### Define required packages per operation ###
        case "$operation" in
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
            print --warning "Missing packages required for $operation operation"
            
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

    ### Apply Group Permissions (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _group() {
        local path="$1"
        local user="$2"
        local recursive_flag="$3"
        local group="${4:-$(basename "$path")-admin}"
        
        ### Check dependencies ###
        if ! _check_group; then
            return 1
        fi
        
        ### Validate path ###
        if [ ! -e "$path" ]; then
            print --error "Path does not exist: $path"
            return 1
        fi
        
        ### Validate user ###
        if ! id "$user" >/dev/null 2>&1; then
            print --error "User does not exist: $user"
            return 1
        fi
        
        ### Create group if not exists ###
        if ! getent group "$group" >/dev/null 2>&1; then
            if sudo groupadd "$group"; then
                print --success "Created group: $group"
            else
                print --error "Failed to create group: $group"
                return 1
            fi
        else
            print --info "Group already exists: $group"
        fi
        
        ### Add user to group ###
        if sudo usermod -a -G "$group" "$user"; then
            print --success "Added user '$user' to group '$group'"
        else
            print --error "Failed to add user to group"
            return 1
        fi
        
        ### Set ownership and permissions ###
        local chown_cmd="chown"
        local chmod_cmd="chmod"
        
        if [ "$recursive_flag" = "true" ]; then
            chown_cmd="$chown_cmd -R"
            chmod_cmd="$chmod_cmd -R"
        fi
        
        if sudo $chown_cmd "root:$group" "$path"; then
            print --success "Ownership set to root:$group"
        else
            print --error "Failed to set ownership"
            return 1
        fi
        
        if sudo $chmod_cmd 775 "$path"; then
            print --success "Permissions set to 775"
        else
            print --error "Failed to set permissions"
            return 1
        fi
        
        ### Set SGID bit for directories ###
        if [ -d "$path" ]; then
            if sudo chmod g+s "$path"; then
                print --success "SGID bit set on directory"
            else
                print --warning "Failed to set SGID bit"
            fi
        fi
        
        print --info "User needs to re-login for group changes to take effect"
        print --info "Check with: groups $user"
        return 0
    }
    
    ### Interactive Wizard (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _interactive() {
        local path="$1"
        local user="$2"
        local recursive_flag="$3"
        
        print --header "Permission Setup Wizard"
        print "Target Path: $path"
        print "Target User: $user"
        print "Recursive: $recursive_flag"
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
                _acl "$path" "$user" "$recursive_flag"
                ;;
            2)
                read -p "Group name [$(basename "$path")-admin]: " group_name
                group_name="${group_name:-$(basename "$path")-admin}"
                _group "$path" "$user" "$recursive_flag" "$group_name"
                ;;
            3)
                print --warning "Enter commands (comma-separated)"
                print "Default: /usr/bin/rsync,/usr/bin/cp,/usr/bin/mv"
                read -p "Commands: " commands
                _sudo "$user" "${commands:-/usr/bin/rsync,/usr/bin/cp,/usr/bin/mv}"
                ;;
            4)
                _check "$path" "$user" "$recursive_flag"
                ;;
            0)
                print --info "Cancelled"
                return 1
                ;;
            *)
                print --error "Invalid choice"
                return 1
                ;;
        esac
    }
    
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _permissions() {
        local path="${1:-$(pwd)}"
        local user="${2:-$USER}"
        
        print --header "Permission Analysis"
        print "User: $user"
        print "Path: $path"
        print --line "-"
        
        ### Check basic permissions ###
        if [ -r "$path" ]; then
            print -cr --success "Read: Yes"
        else
            print --error "Read: No"
        fi
        
        if [ -w "$path" ]; then
            print -cr --success "Write: Yes"
        else
            print --error "Write: No"
        fi
        
        if [ -x "$path" ]; then
            print -cr --success "Execute: Yes"
        else
            print --warning "Execute: No"
        fi
        
        ### Check ACL if available ###
        if command -v getfacl >/dev/null 2>&1; then
            print --line "-"
            print "ACL Status:"
            local acl_output=$(getfacl "$path" 2>/dev/null | grep "user:$user")
            if [ -n "$acl_output" ]; then
                print -cr --success "$acl_output"
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
    
    ### Remove Permissions (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _remove() {
        local path="$1"
        local user="$2"
        local recursive_flag="$3"
        
        print --header "Removing Enhanced Permissions"
        print --warning "This will remove ACL and sudo entries for user: $user"
        
        if ! ask --confirm "remove all enhanced permissions for $user" "true"; then
            print --info "Cancelled"
            return 1
        fi
        
        local success_count=0
        local total_count=0
        
        ### Remove ACL if available ###
        if command -v setfacl >/dev/null 2>&1 && [ -e "$path" ]; then
            ((total_count++))
            local setfacl_cmd="setfacl"
            if [ "$recursive_flag" = "true" ]; then
                setfacl_cmd="$setfacl_cmd -R"
            fi
            
            if sudo $setfacl_cmd -x "u:${user}" "$path" 2>/dev/null; then
                print --success "ACL entries removed"
                ((success_count++))
            else
                print --info "No ACL entries found or failed to remove"
            fi
        fi
        
        ### Remove sudoers file ###
        local sudoers_file="/etc/sudoers.d/secure-${user}"
        if [ -f "$sudoers_file" ]; then
            ((total_count++))
            if sudo rm -f "$sudoers_file"; then
                print --success "Sudoers file removed: $sudoers_file"
                ((success_count++))
            else
                print --error "Failed to remove sudoers file"
            fi
        fi
        
        if [ $total_count -eq 0 ]; then
            print --info "No enhanced permissions found to remove"
        else
            print --info "Completed: $success_count/$total_count operations successful"
        fi
        
        return 0
    }

    ### Configure sudo Permissions (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
     _sudo() {
        local user="$1"
        local commands="${2:-/usr/bin/rsync,/usr/bin/cp,/usr/bin/mv,/usr/bin/mkdir,/usr/bin/rm}"
        local sudoers_file="/etc/sudoers.d/secure-${user}"
        
        ### Check dependencies ###
        if ! _check_sudo; then
            return 1
        fi
        
        ### Validate user ###
        if ! id "$user" >/dev/null 2>&1; then
            print --error "User does not exist: $user"
            return 1
        fi
        
        ### Validate commands ###
        IFS=',' read -ra cmd_array <<< "$commands"
        local validated_commands=()
        
        for cmd_path in "${cmd_array[@]}"; do
            cmd_path=$(echo "$cmd_path" | xargs)  ### Trim whitespace ###
            
            if [ -x "$cmd_path" ]; then
                validated_commands+=("$cmd_path")
            else
                print --warning "Command not found or not executable: $cmd_path"
                if ask --yes-no "Include anyway?" "no"; then
                    validated_commands+=("$cmd_path")
                fi
            fi
        done
        
        if [ ${#validated_commands[@]} -eq 0 ]; then
            print --error "No valid commands specified"
            return 1
        fi
        
        ### Build sudoers line ###
        local sudo_line="$user ALL=(ALL) NOPASSWD: $(IFS=','; echo "${validated_commands[*]}")"
        
        ### Create sudoers file ###
        print --info "Creating sudoers configuration for user: $user"
        
        if echo "$sudo_line" | sudo tee "$sudoers_file" > /dev/null; then
            print --success "Sudoers file created: $sudoers_file"
        else
            print --error "Failed to create sudoers file"
            return 1
        fi
        
        ### Set proper permissions ###
        if sudo chmod 440 "$sudoers_file"; then
            print --success "Sudoers file permissions set"
        else
            print --warning "Could not set sudoers file permissions"
        fi
        
        ### Validate sudoers syntax ###
        if sudo visudo -c -f "$sudoers_file" >/dev/null 2>&1; then
            print --success "Sudoers syntax validation passed"
            print --info "sudo NOPASSWD configured for commands: ${validated_commands[*]}"
        else
            print --error "Sudoers syntax validation failed - removing file"
            sudo rm -f "$sudoers_file"
            return 1
        fi
        
        ### Test sudo access ###
        if sudo -l -U "$user" 2>/dev/null | grep -q "NOPASSWD"; then
            print --success "sudo configuration verified"
        else
            print --warning "Could not verify sudo configuration"
        fi
        
        return 0
    }
   
    ### Parse Arguments ###
    case "$1" in
        --acl)
            _acl "$target_path" "$target_user"
            ;;

        --check)
            _permissions "$target_path" "$target_user"
            ;;

        --group)
            _group "$target_path" "$target_user" "${4:-}"
            ;;

        --remove)
            ### Remove all permission enhancements ###
            sudo setfacl -R -x u:${target_user} "$target_path" 2>/dev/null
            sudo rm -f "/etc/sudoers.d/secure-${target_user}"
            print -cr --success "Removed enhanced permissions for $target_user"
           ;;

        --sudo)
            _sudo "$target_user" "${2:-}"
            ;;

        --wizard)
            _interactive "$target_path" "$target_user"
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
    ### Check if no Arguments provided ###
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    else
        ### Parse and execute Arguments ###
        parse_arguments "$@"
    fi
}

### Initialize when run directly ###
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    ### Running directly as script ###
    main "$@"
else
    ### Being sourced as Library ###
    ### Functions loaded and ready for use ###
    :
fi

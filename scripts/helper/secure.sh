#!/bin/bash
################################################################################
### Universal Helper Functions - Security & Permission Management Library
### Comprehensive Security Functions for ACL, Group, and sudo Permission Management
### Provides unified Secure Function for Permission Setup and Security Configuration
################################################################################
### Project: Universal Helper Library
### Version: 1.0.1
### Author:  Mawage (Development Team)
### Date:    2025-09-14
### License: MIT
### Usage:   Source this File to load Security and Permission Management Functions
### Commit:  Security & Permission Management Functions for ACL and sudo Configuration
################################################################################


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
    log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"

    local target_path=""
    local target_user=""
    local target_group=""
    
    local recursive=false
    local app=""


    ### Parse Arguments and validate ###
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                return 0
                ;;
            
            --group|-g)
                target_group="$2"
                shift 2
                ;;

            --recursive|-R)
                recursive=true
                shift
                ;;

            --user|-u)
                target_user="$2"
                shift 2
                ;;

            --*|-*)
                [[ "$1" == --* ]] && set -- "${1#--}" "${@:2}" || [[ "$1" == -* ]] && set -- "${1#-}" "${@:2}"
                ;;

            acl|check|group|remove|sudo|wizard)
                app="$1"
                shift
                ;;
            
            *)

                if [[ -e "$1" ]]; then
                    target_path="$1"

                elif id "$1" &>/dev/null; then
                    target_user="$1"

                else
                    print --invalid "${FUNCNAME[0]}" "$1"
                    return 1

                fi
                shift
                ;;

        esac
    done


    ################################################################################
    ### === INTERNAL SECURITY FUNCTIONS === ###
    ################################################################################

    ### Apply ACL Permissions (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within Main Function
    _acl() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"

        ### Check if ACL Commands are available ###
        cmd --dependencies "acl" || return 1
        
        ### Validate target_path ###
        if [ ! -e "$target_path" ]; then
            print --error "path does not exist: $target_path"
            return 1
        fi
        
        ### Validate target_user ###
        if ! id "$target_user" >/dev/null 2>&1; then
            print --error "user does not exist: $target_user"
            return 1
        fi
        
        ### Build ACL command ###
        local acl_cmd="setfacl"
        local default_acl_cmd="setfacl -d"
        
        if [ "$recursive" = "true" ]; then
            acl_cmd="$acl_cmd -R"
            default_acl_cmd="$default_acl_cmd -R"
        fi
        
        ### Apply ACL permissions ###
        print --info "Setting ACL for target_user '$target_user' on: $target_path"
        
        if sudo $acl_cmd -m "u:${target_user}:rwx" "$target_path" 2>/dev/null; then
            print --success "user ACL set successfully"
        else
            print --error "Failed to set user ACL"
            return 1
        fi
        
        ### Apply default ACL for directories ###
        if [ -d "$target_path" ]; then
            if sudo $default_acl_cmd -m "u:${target_user}:rwx" "$target_path" 2>/dev/null; then
                print --success "Default ACL set successfully"
            else
                print --warning "Failed to set default ACL (not critical)"
            fi
        fi
        
        ### Verify ACL ###
        local verification=$(getfacl "$target_path" 2>/dev/null | grep "user:$target_user")
        if [ -n "$verification" ]; then
            print --success "ACL verification: $verification"
        else
            print --warning "Could not verify ACL settings"
        fi
        
        print --info "Verify manually with: getfacl $target_path"
        return 0
    }

    ### Check current Permissions (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _check() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"

        print --header "Permission Analysis"
        print "user: $target_user"
        print "path: $target_path"
        print --line "-"
        
        ### Check if target_path exists ###
        if [ ! -e "$target_path" ]; then
            print --error "path does not exist: $target_path"
            return 1
        fi
        
        ### Check basic permissions ###
        if [ -r "$target_path" ]; then
            print --success "Read: Yes"
        else
            print --error "Read: No"
        fi
        
        if [ -w "$target_path" ]; then
            print --success "Write: Yes"
        else
            print --error "Write: No"
        fi
        
        if [ -x "$target_path" ]; then
            print --success "Execute: Yes"
        else
            print --warning "Execute: No"
        fi
        
        ### Show traditional permissions ###
        print --line "-"
        print "Traditional permissions:"
        ls -ld "$target_path"
        
        ### Check ACL if available ###
        if command -v getfacl >/dev/null 2>&1; then
            print --line "-"
            print "ACL Status:"
            local acl_output=$(getfacl "$target_path" 2>/dev/null | grep "user:$target_user")
            if [ -n "$acl_output" ]; then
                print --success "$acl_output"
            else
                print --info "No specific ACL for user $target_user"
                ### Show all ACL entries ###
                local all_acl=$(getfacl "$target_path" 2>/dev/null | grep "^user:" | grep -v "user::") 
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
        print "user groups: $(groups "$target_user" 2>/dev/null || echo "user not found")"
        
        ### Check file/directory group ###
        local file_group=$(stat -c %G "$target_path" 2>/dev/null)
        if [ -n "$file_group" ]; then
            print "path group: $file_group"
            
            ### Check if target_user is in file group ###
            if groups "$target_user" 2>/dev/null | grep -q "\b$file_group\b"; then
                print --success "user is member of path group"
            else
                print --warning "user is NOT member of path group"
            fi
        fi
        
        ### Check sudo permissions ###
        print --line "-"
        if command -v sudo >/dev/null 2>&1; then
            local sudo_entries=$(sudo -l -U "$target_user" 2>/dev/null | grep "NOPASSWD")
            if [ -n "$sudo_entries" ]; then
                print --warning "sudo NOPASSWD entries found:"
                echo "$sudo_entries"
            else
                print --info "No sudo NOPASSWD entries for target_user"
            fi
        else
            print --info "sudo not available"
        fi
        
        ### Recursive check for directories ###
        if [ "$recursive" = "true" ] && [ -d "$target_path" ]; then
            print --line "-"
            print --info "Checking subdirectories recursively..."
            
            local issue_count=0
            while IFS= read -r -d '' subtarget_path; do
                if [ ! -r "$subtarget_path" ] || [ ! -w "$subtarget_path" ]; then
                    if [ $issue_count -eq 0 ]; then
                        print --warning "Permission issues found in subdirectories:"
                    fi
                    print --error "  $(ls -ld "$subtarget_path")"
                    ((issue_count++))
                fi
            done < <(find "$target_path" -type d -print0 2>/dev/null)
            
            if [ $issue_count -eq 0 ]; then
                print --success "All subdirectories accessible"
            else
                print --warning "Found $issue_count subdirectories with permission issues"
            fi
        fi
        
        return 0
    }

    ### Apply Group Permissions (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _group() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"

        ### Check if necessary Packages are available ###
        cmd --dependencies "coreutils" "shadow" || return 1
        
        ### Validate target_path ###
        if [ ! -e "$target_path" ]; then
            print --error "path does not exist: $target_path"
            return 1
        fi
        
        ### Validate target_user ###
        if ! id "$target_user" >/dev/null 2>&1; then
            print --error "user does not exist: $target_user"
            return 1
        fi
        
        ### Create group if not exists ###
        if ! getent group "$target_group" >/dev/null 2>&1; then
            if sudo groupadd "$target_group"; then
                print --success "Created group: $target_group"
            else
                print --error "Failed to create group: $target_group"
                return 1
            fi
        else
            print --info "Group already exists: $target_group"
        fi
        
        ### Add target_user to group ###
        if sudo usermod -a -G "$target_group" "$target_user"; then
            print --success "Added user '$target_user' to group '$target_group'"
        else
            print --error "Failed to add target_user to group"
            return 1
        fi
        
        ### Set ownership and permissions ###
        local chown_cmd="chown"
        local chmod_cmd="chmod"
        
        if [ "$recursive" = "true" ]; then
            chown_cmd="$chown_cmd -R"
            chmod_cmd="$chmod_cmd -R"
        fi
        
        if sudo $chown_cmd "root:$target_group" "$target_path"; then
            print --success "Ownership set to root:$target_group"
        else
            print --error "Failed to set ownership"
            return 1
        fi
        
        if sudo $chmod_cmd 775 "$target_path"; then
            print --success "Permissions set to 775"
        else
            print --error "Failed to set permissions"
            return 1
        fi
        
        ### Set SGID bit for directories ###
        if [ -d "$target_path" ]; then
            if sudo chmod g+s "$target_path"; then
                print --success "SGID bit set on directory"
            else
                print --warning "Failed to set SGID bit"
            fi
        fi
        
        print --info "user needs to re-login for group changes to take effect"
        print --info "Check with: groups $target_user"
        return 0
    }
    
    ### Interactive Wizard (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _interactive() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"

        print --header "Permission Setup Wizard"
        print "Target path: $target_path"
        print "Target user: $target_user"
        print "Recursive: $recursive"
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
                _acl
                ;;
            2)
                read -p "Group name [$(basename "$target_path")${DEFAULT_GROUP_SUFFIX}]: " group_name
                group_name="${group_name:-$(basename "$target_path")${DEFAULT_GROUP_SUFFIX}}"
                target_group="$group_name"
                _group
                ;;
            3)
                print --warning "Enter commands (comma-separated)"
                print "Default: $DEFAULT_SUDO_COMMANDS"
                read -p "Commands: " commands
                _sudo
                ;;
            4)
                _check
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
    
    ### Remove Permissions (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _remove() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"

        print --header "Removing Enhanced Permissions"
        print --warning "This will remove ACL and sudo entries for user: $target_user"
        
        if ! ask --confirm "remove all enhanced permissions for $target_user" "true"; then
            print --info "Cancelled"
            return 1
        fi
        
        local success_count=0
        local total_count=0
        
        ### Remove ACL if available ###
        if command -v setfacl >/dev/null 2>&1 && [ -e "$target_path" ]; then
            ((total_count++))
            local setfacl_cmd="setfacl"
            if [ "$recursive" = "true" ]; then
                setfacl_cmd="$setfacl_cmd -R"
            fi
            
            if sudo $setfacl_cmd -x "u:${target_user}" "$target_path" 2>/dev/null; then
                print --success "ACL entries removed"
                ((success_count++))
            else
                print --info "No ACL entries found or failed to remove"
            fi
        fi
        
        ### Remove sudoers file ###
        local sudoers_file="${SUDOERS_PATH}/secure-${target_user}"
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
            print --info "Completed: $success_count/$total_count Operations successful"
        fi
        
        return 0
    }

    ### Configure sudo Permissions (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
     _sudo() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"

        ### Check if necessary Packages are available ###
        cmd --dependencies "sudo" || return 1

        local commands="${DEFAULT_SUDO_COMMANDS}"
        local sudoers_file="${SUDOERS_PATH}/secure-${target_user}"
        
        ### Validate target_user ###
        if ! id "$target_user" >/dev/null 2>&1; then
            print --error "user does not exist: $target_user"
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
        local sudo_line="$target_user ALL=(ALL) NOPASSWD: $(IFS=','; echo "${validated_commands[*]}")"
        
        ### Create sudoers file ###
        print --info "Creating sudoers configuration for target_user: $target_user"
        
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
        if sudo -l -U "$target_user" 2>/dev/null | grep -q "NOPASSWD"; then
            print --success "sudo configuration verified"
        else
            print --warning "Could not verify sudo configuration"
        fi
        
        return 0
    }

    ### Call Function by Parameters ###
    declare -f "_$app" > /dev/null && "_$app" || { print --invalid "${FUNCNAME[0]}" "_$app"; return 1; }

}


################################################################################
### === MAIN EXECUTION === ###
################################################################################

### Main Function ###
main() {
    ### Log Startup Arguments ###
    log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"
    log --info "${FUNCNAME[1]}" "($*)" "Called with Arguments: 1"
    log --info "${FUNCNAME[2]}" "($*)" "Called with Arguments: 2"


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

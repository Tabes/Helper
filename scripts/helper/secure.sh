#!/bin/bash
################################################################################
### Universal Helper Functions - Security & Permission Management Library
### Comprehensive Security Functions for ACL, Group, and sudo Permission Management
### Provides unified Secure Function for Permission Setup and Security Configuration
################################################################################
### Project: Universal Helper Library
### Version: 1.0.6
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
    log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments: 0"
    log --info "${FUNCNAME[1]}" "($*)" "Called with Arguments: 1"
    log --info "${FUNCNAME[2]}" "($*)" "Called with Arguments: 2"

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
    # shellcheck disable=SC2317,SC2329,SC2120  # Function called conditionally within Main Function
    _acl() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]} called with Arguments: ($*)"

        ### Check Dependencies ###
        if ! cmd --dependencies "acl"; then					### Dependency validation ###
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "ACL dependencies check failed"
            return 1
        fi

        ### Validate target_path ###
        if [[ ! -e "$target_path" ]]; then					### Path existence check ###
            print --error "Path does not exist: $target_path"
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Path validation failed: $target_path"
            return 1
        fi

        ### Validate target_user ###
        if ! id "$target_user" >/dev/null 2>&1; then				### User existence check ###
            print --error "User does not exist: $target_user"
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "User validation failed: $target_user"
            return 1
        fi

        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Validation completed successfully" "path=$target_path, user=$target_user, recursive=$recursive"

        ### Check filesystem ACL support ###
        local mount_opts
        mount_opts=$(findmnt -n -o OPTIONS -T "$target_path" 2>/dev/null)

        if [[ "$mount_opts" != *"acl"* ]]; then				### Filesystem ACL support check ###
            print --warning "Filesystem may not support ACL. Current mount options: $mount_opts"
            log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Filesystem ACL support questionable" "mount_opts=$mount_opts"
            
            if ! ask --yes-no "Continue anyway?" "no"; then
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "User cancelled due to ACL support concerns"
                return 1
            fi
        fi

        ### Build ACL commands ###
        local acl_cmd="setfacl"
        local default_acl_cmd="setfacl -d"

        ### Add recursive flag only to main command ###
        if [[ "$recursive" == "true" ]]; then					### Recursive flag handling ###
            acl_cmd="$acl_cmd -R"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Recursive mode enabled" "acl_cmd=$acl_cmd"
        fi

        ### Apply user ACL permissions ###
        print --info "Setting ACL for user '$target_user' on: $target_path"
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Starting ACL application" "command=sudo $acl_cmd -m u:${target_user}:rwx $target_path"

        if sudo $acl_cmd -m "u:${target_user}:rwx" "$target_path" 2>/dev/null; then	### Main ACL application ###
            print --success "User ACL set successfully"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "User ACL applied successfully"
        else
            print --error "Failed to set user ACL"
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "User ACL application failed" "command_failed=sudo $acl_cmd -m u:${target_user}:rwx $target_path"
            return 1
        fi

        ### Apply default ACL only for directories ###
        if [[ -d "$target_path" ]]; then					### Directory-specific ACL handling ###
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Applying default ACL for directory"
            
            if sudo $default_acl_cmd -m "u:${target_user}:rwx" "$target_path" 2>/dev/null; then
                print --success "Default ACL set successfully"
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Default ACL applied successfully"
            else
                print --warning "Failed to set default ACL (non-critical)"
                log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Default ACL application failed" "non_critical_error"
            fi

            ### For recursive: apply default ACL to subdirectories ###
            if [[ "$recursive" == "true" ]]; then				### Recursive default ACL ###
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Starting recursive default ACL application"
                local subdir_count=0
                local subdir_errors=0
                
                while IFS= read -r -d '' subdir; do
                    ((subdir_count++))
                    if sudo $default_acl_cmd -m "u:${target_user}:rwx" "$subdir" 2>/dev/null; then
                        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Default ACL applied to subdirectory" "subdir=$subdir"
                    else
                        ((subdir_errors++))
                        print --warning "Failed to set default ACL on: $subdir"
                        log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Default ACL failed for subdirectory" "subdir=$subdir"
                    fi
                done < <(find "$target_path" -type d -print0 2>/dev/null)
                
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Recursive default ACL completed" "processed=$subdir_count, errors=$subdir_errors"
            fi
        fi

        ### Verify ACL ###
        local verification
        verification=$(getfacl "$target_path" 2>/dev/null | grep "user:$target_user")
        
        if [[ -n "$verification" ]]; then					### ACL verification ###
            print --success "ACL verification: $verification"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "ACL verification successful" "verification=$verification"
        else
            print --warning "Could not verify ACL settings"
            log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "ACL verification failed" "no_verification_output"
        fi

        print --info "Verify manually with: getfacl $target_path"
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "ACL operation completed successfully" "manual_verification_command=getfacl $target_path"
        
        return 0
    }

    ### Check current Permissions (internal) ###
    # shellcheck disable=SC2317,SC2329,SC2120  # Function called conditionally within main function
    _check() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]} called with Arguments: ($*)"

        ### Validate target_path ###
        if [[ ! -e "$target_path" ]]; then					### Path existence check ###
            print --error "Path does not exist: $target_path"
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Path validation failed" "path: $target_path"
            return 1
        fi

        ### Validate target_user ###
        if ! id "$target_user" >/dev/null 2>&1; then				### User existence check ###
            print --error "User does not exist: $target_user"
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "User validation failed" "user: $target_user"
            return 1
        fi

        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Starting permission analysis" "user: $target_user, path: $target_path, recursive=$recursive"

        ### Display analysis header ###
        print --header "Permission Analysis"
        print "User: $target_user"
        print "Path: $target_path"
        print --line "-"

        ### Check basic permissions ###
        local read_status="No"
        local write_status="No"
        local execute_status="No"

        if [[ -r "$target_path" ]]; then					### Read permission check ###
            print --success "Read: Yes"
            read_status="Yes"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Read permission check" "status=success"
        else
            print --error "Read: No"
            log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Read permission check" "status=failed"
        fi

        if [[ -w "$target_path" ]]; then					### Write permission check ###
            print --success "Write: Yes"
            write_status="Yes"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Write permission check" "status=success"
        else
            print --error "Write: No"
            log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Write permission check" "status=failed"
        fi

        if [[ -x "$target_path" ]]; then					### Execute permission check ###
            print --success "Execute: Yes"
            execute_status="Yes"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Execute permission check" "status=success"
        else
            print --warning "Execute: No"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Execute permission check" "status=no_execute_normal_for_files"
        fi

        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Basic permissions summary" "read=$read_status, write=$write_status, execute=$execute_status"

        ### Show traditional permissions ###
        print --line "-"
        print "Traditional permissions:"
        local traditional_perms
        traditional_perms=$(ls -ld "$target_path")
        print "$traditional_perms"
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Traditional permissions" "ls_output=$traditional_perms"

        ### Check ACL if available ###
        print --line "-"
        print "ACL Status:"

        if command -v getfacl >/dev/null 2>&1; then				### ACL availability check ###
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "ACL tools available" "checking_user_specific_acl"
            
            local acl_output
            acl_output=$(getfacl "$target_path" 2>/dev/null | grep "user:$target_user")
            
            if [[ -n "$acl_output" ]]; then					### User-specific ACL check ###
                print --success "$acl_output"
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "User-specific ACL found" "acl=$acl_output"
            else
                print --info "No specific ACL for user $target_user"
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "No user-specific ACL found"
                
                ### Show all ACL entries ###
                local all_acl
                all_acl=$(getfacl "$target_path" 2>/dev/null | grep "^user:" | grep -v "user::")
                
                if [[ -n "$all_acl" ]]; then				### Other user ACL entries ###
                    print --info "Other user ACL entries:"
                    echo "$all_acl"
                    log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Other user ACL entries found" "other_acl_count=$(echo "$all_acl" | wc -l)"
                else
                    log --info "${FUNCNAME[0]} called with Arguments: ($*)" "No ACL entries found"
                fi
            fi
        else
            print --info "ACL tools not available"
            log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "ACL tools not available" "getfacl_command_missing"
        fi

        ### Check groups ###
        print --line "-"
        local user_groups
        user_groups=$(groups "$target_user" 2>/dev/null || echo "user not found")
        print "User groups: $user_groups"
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "User groups retrieved" "groups=$user_groups"

        ### Check file/directory group ###
        local file_group
        file_group=$(stat -c %G "$target_path" 2>/dev/null)
        
        if [[ -n "$file_group" ]]; then					### File group membership check ###
            print "Path group: $file_group"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Path group identified" "file_group=$file_group"
            
            ### Check if target_user is in file group ###
            if groups "$target_user" 2>/dev/null | grep -q "\b$file_group\b"; then
                print --success "User is member of path group"
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Group membership verified" "user_in_group=true"
            else
                print --warning "User is NOT member of path group"
                log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Group membership check failed" "user_in_group=false, file_group=$file_group"
            fi
        else
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Could not determine file group" "stat_command_failed"
        fi

        ### Check sudo permissions ###
        print --line "-"
        
        if command -v sudo >/dev/null 2>&1; then				### Sudo availability check ###
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Checking sudo permissions"
            
            local sudo_entries
            sudo_entries=$(sudo -l -U "$target_user" 2>/dev/null | grep "NOPASSWD")
            
            if [[ -n "$sudo_entries" ]]; then				### Sudo NOPASSWD entries ###
                print --warning "Sudo NOPASSWD entries found:"
                echo "$sudo_entries"
                log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Sudo NOPASSWD entries found" "sudo_entry_count=$(echo "$sudo_entries" | wc -l)"
            else
                print --info "No sudo NOPASSWD entries for user"
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "No sudo NOPASSWD entries found"
            fi
        else
            print --info "Sudo not available"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Sudo not available" "sudo_command_missing"
        fi

        ### Recursive check for directories ###
        if [[ "$recursive" == "true" && -d "$target_path" ]]; then		### Recursive permission check ###
            print --line "-"
            print --info "Checking subdirectories recursively..."
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Starting recursive permission check"
            
            local issue_count=0
            local total_dirs=0
            
            while IFS= read -r -d '' subtarget_path; do
                ((total_dirs++))
                
                if [[ ! -r "$subtarget_path" || ! -w "$subtarget_path" ]]; then
                    if [[ $issue_count -eq 0 ]]; then		### First issue found ###
                        print --warning "Permission issues found in subdirectories:"
                        log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Permission issues detected in subdirectories"
                    fi
                    
                    local subdir_perms
                    subdir_perms=$(ls -ld "$subtarget_path")
                    print --error "  $subdir_perms"
                    log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Permission issue in subdirectory" "subdir=$subtarget_path, perms=$subdir_perms"
                    ((issue_count++))
                fi
            done < <(find "$target_path" -type d -print0 2>/dev/null)
            
            if [[ $issue_count -eq 0 ]]; then				### No issues found ###
                print --success "All subdirectories accessible"
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Recursive check completed successfully" "total_dirs=$total_dirs, issues=0"
            else
                print --warning "Found $issue_count subdirectories with permission issues"
                log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Recursive check completed with issues" "total_dirs=$total_dirs, issues=$issue_count"
            fi
        fi

        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Permission analysis completed" "read=$read_status, write=$write_status, execute=$execute_status"
        return 0
    }

    ### Apply Group Permissions (internal) ###
    # shellcheck disable=SC2317,SC2329,SC2120  # Function called conditionally within main function
    _group() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]} called with Arguments: ($*)"

        ### Check Dependencies ###
        if ! cmd --dependencies "group"; then					### Group management dependencies ###
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Group dependencies check failed"
            return 1
        fi

        ### Validate target_path ###
        if [[ ! -e "$target_path" ]]; then					### Path existence check ###
            print --error "Path does not exist: $target_path"
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Path validation failed" "path: $target_path"
            return 1
        fi

        ### Validate target_user ###
        if ! id "$target_user" >/dev/null 2>&1; then				### User existence check ###
            print --error "User does not exist: $target_user"
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "User validation failed" "user: $target_user"
            return 1
        fi

        ### Validate or set target_group ###
        if [[ -z "$target_group" ]]; then					### Auto-generate group name ###
            target_group="$(basename "$target_path")${DEFAULT_GROUP_SUFFIX:-"-admin"}"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Auto-generated group name" "target_group=$target_group"
        fi

        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Validation completed" "path: $target_path, user: $target_user, target_group=$target_group, recursive=$recursive"

        ### Create group if not exists ###
        if ! getent group "$target_group" >/dev/null 2>&1; then		### Group existence check ###
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Group does not exist, creating" "target_group=$target_group"
            
            if sudo groupadd "$target_group"; then				### Group creation ###
                print --success "Created group: $target_group"
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Group created successfully" "target_group=$target_group"
            else
                print --error "Failed to create group: $target_group"
                log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Group creation failed" "target_group=$target_group, command_failed=sudo groupadd $target_group"
                return 1
            fi
        else
            print --info "Group already exists: $target_group"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Group already exists" "target_group=$target_group"
        fi

        ### Check if user is already in group ###
        if groups "$target_user" 2>/dev/null | grep -q "\b$target_group\b"; then	### Current group membership check ###
            print --info "User '$target_user' is already member of group '$target_group'"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "User already in group" "no_usermod_needed"
        else
            ### Add target_user to group ###
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Adding user to group" "command=sudo usermod -a -G $target_group $target_user"
            
            if sudo usermod -a -G "$target_group" "$target_user"; then	### User group addition ###
                print --success "Added user '$target_user' to group '$target_group'"
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "User added to group successfully"
            else
                print --error "Failed to add user to group"
                log --error "${FUNCNAME[0]} called with Arguments: ($*)" "User group addition failed" "command_failed=sudo usermod -a -G $target_group $target_user"
                return 1
            fi
        fi

        ### Set ownership and permissions ###
        local chown_cmd="chown"
        local chmod_cmd="chmod"

        ### Add recursive flag if requested ###
        if [[ "$recursive" == "true" ]]; then					### Recursive flag handling ###
            chown_cmd="$chown_cmd -R"
            chmod_cmd="$chmod_cmd -R"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Recursive mode enabled" "chown_cmd=$chown_cmd, chmod_cmd=$chmod_cmd"
        fi

        ### Apply ownership changes ###
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Setting ownership" "command=sudo $chown_cmd root:$target_group $target_path"
        
        if sudo $chown_cmd "root:$target_group" "$target_path"; then		### Ownership change ###
            print --success "Ownership set to root:$target_group"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Ownership changed successfully" "new_ownership=root:$target_group"
        else
            print --error "Failed to set ownership"
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Ownership change failed" "command_failed=sudo $chown_cmd root:$target_group $target_path"
            return 1
        fi

        ### Apply permission changes ###
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Setting permissions" "command=sudo $chmod_cmd 775 $target_path"
        
        if sudo $chmod_cmd 775 "$target_path"; then				### Permission change ###
            print --success "Permissions set to 775"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Permissions changed successfully" "new_permissions=775"
        else
            print --error "Failed to set permissions"
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Permission change failed" "command_failed=sudo $chmod_cmd 775 $target_path"
            return 1
        fi

        ### Set SGID bit for directories ###
        if [[ -d "$target_path" ]]; then					### SGID bit for directories ###
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Setting SGID bit for directory" "command=sudo chmod g+s $target_path"
            
            if sudo chmod g+s "$target_path"; then				### SGID bit application ###
                print --success "SGID bit set on directory"
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "SGID bit set successfully"
            else
                print --warning "Failed to set SGID bit"
                log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "SGID bit setting failed" "command_failed=sudo chmod g+s $target_path"
            fi
        else
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Target is file, SGID bit not applicable"
        fi

        ### Verify final permissions ###
        local final_perms
        final_perms=$(ls -ld "$target_path" 2>/dev/null)
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Final permissions verification" "ls_output=$final_perms"

        ### Verify group membership ###
        local current_groups
        current_groups=$(groups "$target_user" 2>/dev/null)
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Final group membership" "user_groups=$current_groups"

        ### User guidance ###
        print --info "User needs to re-login for group changes to take effect"
        print --info "Check with: groups $target_user"
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Group permission setup completed successfully" "verification_commands=groups $target_user; ls -ld $target_path"

        return 0
    }

    ### Interactive Wizard (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _interactive() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]} called with Arguments: ($*)"

        ### Validate target_path ###
        if [[ ! -e "$target_path" ]]; then					### Path existence check ###
            print --error "Path does not exist: $target_path"
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Path validation failed" "path: $target_path"
            return 1
        fi

        ### Validate target_user ###
        if ! id "$target_user" >/dev/null 2>&1; then				### User existence check ###
            print --error "User does not exist: $target_user"
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "User validation failed" "user: $target_user"
            return 1
        fi

        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Starting interactive wizard" "path: $target_path, user: $target_user, recursive=$recursive"

        ### Display wizard header ###
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

        ### Get user choice ###
        local choice
        read -p "Choice [0-4]: " choice
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "User selected option" "choice=$choice"

        ### Execute based on choice ###
        case "$choice" in

            1)								### ACL Method ###
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Executing ACL method"
                print --info "Selected: ACL (File Access Control Lists)"
                
                if _acl; then						### ACL execution ###
                    log --info "${FUNCNAME[0]} called with Arguments: ($*)" "ACL method completed successfully"
                    return 0
                else
                    log --error "${FUNCNAME[0]} called with Arguments: ($*)" "ACL method failed"
                    return 1
                fi
                ;;

            2)								### Group Method ###
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Executing Group method"
                print --info "Selected: Group (Unix group permissions)"
                
                ### Get group name ###
                local group_name
                local default_group="$(basename "$target_path")${DEFAULT_GROUP_SUFFIX:-"-admin"}"
                read -p "Group name [$default_group]: " group_name
                group_name="${group_name:-$default_group}"
                target_group="$group_name"
                
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Group method configuration" "target_group=$target_group"
                
                if _group; then						### Group execution ###
                    log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Group method completed successfully"
                    return 0
                else
                    log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Group method failed"
                    return 1
                fi
                ;;

            3)								### Sudo Method ###
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Executing sudo method"
                print --info "Selected: sudo (NOPASSWD for commands)"
                print --warning "Enter commands (comma-separated)"
                print "Default: ${DEFAULT_SUDO_COMMANDS:-/usr/bin/rsync,/usr/bin/cp,/usr/bin/mv,/usr/bin/mkdir,/usr/bin/rm}"
                
                ### Get commands ###
                local commands
                read -p "Commands: " commands
                
                if [[ -n "$commands" ]]; then				### Custom commands provided ###
                    log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Custom sudo commands specified" "commands=$commands"
                    ### Note: _sudo should handle the commands parameter ###
                else
                    log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Using default sudo commands" "commands=${DEFAULT_SUDO_COMMANDS}"
                fi
                
                if _sudo; then						### Sudo execution ###
                    log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Sudo method completed successfully"
                    return 0
                else
                    log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Sudo method failed"
                    return 1
                fi
                ;;

            4)								### Check Method ###
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Executing permission check"
                print --info "Selected: Check (Analyze current permissions)"
                
                if _check; then						### Check execution ###
                    log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Permission check completed successfully"
                    return 0
                else
                    log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Permission check failed"
                    return 1
                fi
                ;;

            0)								### Cancel ###
                print --info "Cancelled"
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "User cancelled wizard"
                return 1
                ;;

            "")								### Empty input ###
                print --warning "No choice selected"
                log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Empty input received"
                return 1
                ;;

            *)								### Invalid choice ###
                print --error "Invalid choice: $choice"
                log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Invalid user choice" "invalid_choice=$choice"
                return 1
                ;;

        esac
    }

    ### Remove Permissions (internal) ###
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _remove() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]} called with Arguments: ($*)"

        ### Validate target_user ###
        if ! id "$target_user" >/dev/null 2>&1; then				### User existence check ###
            print --error "User does not exist: $target_user"
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "User validation failed" "user: $target_user"
            return 1
        fi

        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Starting permission removal" "user: $target_user, path${target_path:-not_specified}, recursive=$recursive"

        ### Display removal header ###
        print --header "Removing Enhanced Permissions"
        print --warning "This will remove ACL and sudo entries for user: $target_user"
        
        ### Get user confirmation ###
        if ! ask --confirm "remove all enhanced permissions for $target_user" "true"; then
            print --info "Cancelled"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "User cancelled permission removal"
            return 1
        fi

        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "User confirmed permission removal"

        ### Initialize counters ###
        local success_count=0
        local total_count=0
        local operations_log=""

        ### Remove ACL if available and target_path specified ###
        if command -v setfacl >/dev/null 2>&1 && [[ -n "$target_path" && -e "$target_path" ]]; then
            ((total_count++))
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Attempting ACL removal" "path: $target_path"
            
            ### Build setfacl command ###
            local setfacl_cmd="setfacl"
            if [[ "$recursive" == "true" ]]; then				### Recursive ACL removal ###
                setfacl_cmd="$setfacl_cmd -R"
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Using recursive ACL removal" "command=sudo $setfacl_cmd -x u:${target_user} $target_path"
            fi

            ### Execute ACL removal ###
            if sudo $setfacl_cmd -x "u:${target_user}" "$target_path" 2>/dev/null; then
                print --success "ACL entries removed"
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "ACL removal successful" "path=$target_path"
                operations_log="$operations_log ACL_REMOVED:$target_path"
                ((success_count++))
            else
                print --info "No ACL entries found or failed to remove"
                log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "ACL removal failed or no entries found" "path=$target_path"
                operations_log="$operations_log ACL_FAILED:$target_path"
            fi

            ### Remove default ACL for directories ###
            if [[ -d "$target_path" ]]; then				### Default ACL removal ###
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Removing default ACL for directory"
                
                if sudo setfacl -d -x "u:${target_user}" "$target_path" 2>/dev/null; then
                    log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Default ACL removal successful"
                    operations_log="$operations_log DEFAULT_ACL_REMOVED:$target_path"
                else
                    log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Default ACL removal failed or no entries found"
                    operations_log="$operations_log DEFAULT_ACL_FAILED:$target_path"
                fi
            fi

        elif [[ -z "$target_path" ]]; then					### No target_path provided ###
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "No target_path specified, skipping ACL removal"
            
        elif [[ ! -e "$target_path" ]]; then					### target_path doesn't exist ###
            log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Target path does not exist, skipping ACL removal" "path: $target_path"
            
        else									### setfacl not available ###
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "setfacl command not available, skipping ACL removal"
        fi

        ### Remove sudoers file ###
        local sudoers_file="${SUDOERS_PATH}/secure-${target_user}"
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Checking sudoers file" "sudoers_file=$sudoers_file"
        
        if [[ -f "$sudoers_file" ]]; then					### Sudoers file exists ###
            ((total_count++))
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Attempting sudoers file removal" "file=$sudoers_file"
            
            if sudo rm -f "$sudoers_file"; then				### Sudoers file removal ###
                print --success "Sudoers file removed: $sudoers_file"
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Sudoers file removal successful" "file=$sudoers_file"
                operations_log="$operations_log SUDOERS_REMOVED:$sudoers_file"
                ((success_count++))
            else
                print --error "Failed to remove sudoers file"
                log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Sudoers file removal failed" "file=$sudoers_file"
                operations_log="$operations_log SUDOERS_FAILED:$sudoers_file"
            fi
        else
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "No sudoers file found to remove" "expected_file=$sudoers_file"
        fi

        ### Check for additional sudoers files ###
        local additional_sudoers
        additional_sudoers=$(find "${SUDOERS_PATH}" -name "*${target_user}*" 2>/dev/null)
        
        if [[ -n "$additional_sudoers" ]]; then				### Additional sudoers files found ###
            log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Additional sudoers files found" "files=$additional_sudoers"
            print --warning "Additional sudoers files found containing '$target_user':"
            echo "$additional_sudoers"
            
            if ask --yes-no "Remove these files as well?" "no"; then	### Remove additional files ###
                while IFS= read -r additional_file; do
                    if sudo rm -f "$additional_file"; then
                        print --success "Removed: $additional_file"
                        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Additional sudoers file removed" "file=$additional_file"
                        operations_log="$operations_log ADDITIONAL_SUDOERS_REMOVED:$additional_file"
                        ((success_count++))
                        ((total_count++))
                    else
                        print --error "Failed to remove: $additional_file"
                        log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Additional sudoers file removal failed" "file=$additional_file"
                        operations_log="$operations_log ADDITIONAL_SUDOERS_FAILED:$additional_file"
                        ((total_count++))
                    fi
                done <<< "$additional_sudoers"
            else
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "User declined to remove additional sudoers files"
            fi
        fi

        ### Final summary ###
        if [[ $total_count -eq 0 ]]; then					### No operations performed ###
            print --info "No enhanced permissions found to remove"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "No permissions to remove" "reason=no_enhanced_permissions_found"
        else
            print --info "Completed: $success_count/$total_count operations successful"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Permission removal completed" "success_count=$success_count, total_count=$total_count, operations=$operations_log"
        fi

        ### Verify removal ###
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Starting verification of removal"
        
        ### Verify ACL removal ###
        if [[ -n "$target_path" && -e "$target_path" ]] && command -v getfacl >/dev/null 2>&1; then
            local remaining_acl
            remaining_acl=$(getfacl "$target_path" 2>/dev/null | grep "user:$target_user")
            
            if [[ -n "$remaining_acl" ]]; then				### ACL entries still exist ###
                log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "ACL entries still found after removal" "remaining_acl=$remaining_acl"
            else
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "ACL verification successful, no entries found"
            fi
        fi

        ### Verify sudo removal ###
        local remaining_sudo
        remaining_sudo=$(sudo -l -U "$target_user" 2>/dev/null | grep "NOPASSWD")
        
        if [[ -n "$remaining_sudo" ]]; then					### Sudo entries still exist ###
            log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Sudo NOPASSWD entries still found" "remaining_sudo=$remaining_sudo"
        else
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Sudo verification successful, no NOPASSWD entries found"
        fi

        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Permission removal process completed" "final_status=success_count=$success_count,total_count=$total_count"
        return 0
    }

    ### Configure sudo Permissions (internal) ###
    # shellcheck disable=SC2317,SC2329,SC2120  # Function called conditionally within main function
    _sudo() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]} called with Arguments: ($*)"

        ### Check Dependencies ###
        if ! cmd --dependencies "sudo"; then					### Sudo availability check ###
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Sudo dependencies check failed"
            return 1
        fi

        ### Validate target_user ###
        if ! id "$target_user" >/dev/null 2>&1; then				### User existence check ###
            print --error "User does not exist: $target_user"
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "User validation failed" "user: $target_user"
            return 1
        fi

        ### Set default commands ###
        local commands="${DEFAULT_SUDO_COMMANDS:-/usr/bin/rsync,/usr/bin/cp,/usr/bin/mv,/usr/bin/mkdir,/usr/bin/rm}"
        local sudoers_file="${SUDOERS_PATH}/secure-${target_user}"
        
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Starting sudo configuration" "user: $target_user, sudoers_file=$sudoers_file, default_commands=$commands"

        ### Security warning ###
        print --warning "Configuring sudo NOPASSWD access - security implications:"
        print --warning "- User will execute commands without password"
        print --warning "- Commands will run with root privileges"
        print --warning "- Misconfiguration can compromise system security"
        
        log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Security warning displayed to user"

        ### Ask for confirmation ###
        if ! ask --confirm "proceed with sudo NOPASSWD configuration" "true"; then
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "User cancelled sudo configuration"
            return 1
        fi

        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "User confirmed sudo configuration"

        ### Validate commands ###
        IFS=',' read -ra cmd_array <<< "$commands"
        local validated_commands=()
        local invalid_commands=()
        local missing_commands=()

        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Starting command validation" "command_count=${#cmd_array[@]}"

        for cmd_path in "${cmd_array[@]}"; do
            cmd_path=$(echo "$cmd_path" | xargs)				### Trim whitespace ###
            
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Validating command" "command=$cmd_path"

            if [[ -x "$cmd_path" ]]; then					### Command is executable ###
                validated_commands+=("$cmd_path")
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Command validation successful" "command=$cmd_path"
            else
                missing_commands+=("$cmd_path")
                print --warning "Command not found or not executable: $cmd_path"
                log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Command validation failed" "command=$cmd_path, reason=not_executable"
                
                if ask --yes-no "Include anyway?" "no"; then		### Include non-executable command ###
                    validated_commands+=("$cmd_path")
                    log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Non-executable command included by user choice" "command=$cmd_path"
                else
                    invalid_commands+=("$cmd_path")
                    log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Non-executable command excluded" "command=$cmd_path"
                fi
            fi
        done

        ### Check if any commands remain ###
        if [[ ${#validated_commands[@]} -eq 0 ]]; then			### No valid commands ###
            print --error "No valid commands specified"
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "No valid commands after validation" "rejected_commands=${invalid_commands[*]}"
            return 1
        fi

        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Command validation completed" "valid_count=${#validated_commands[@]}, invalid_count=${#invalid_commands[@]}, missing_count=${#missing_commands[@]}"

        ### Build sudoers line ###
        local sudo_line="$target_user ALL=(ALL) NOPASSWD: $(IFS=','; echo "${validated_commands[*]}")"
        
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Building sudoers configuration" "sudo_line=$sudo_line"

        ### Check if sudoers file already exists ###
        if [[ -f "$sudoers_file" ]]; then					### Existing sudoers file ###
            print --warning "Existing sudoers file found: $sudoers_file"
            log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Existing sudoers file detected" "file=$sudoers_file"
            
            local existing_content
            existing_content=$(cat "$sudoers_file")
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Existing sudoers content" "content=$existing_content"
            
            if ask --yes-no "Overwrite existing configuration?" "yes"; then
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "User chose to overwrite existing sudoers file"
            else
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "User cancelled due to existing sudoers file"
                return 1
            fi
        fi

        ### Create sudoers file ###
        print --info "Creating sudoers configuration for user: $target_user"
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Creating sudoers file" "file=$sudoers_file"

        if echo "$sudo_line" | sudo tee "$sudoers_file" > /dev/null; then	### Sudoers file creation ###
            print --success "Sudoers file created: $sudoers_file"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Sudoers file created successfully" "file=$sudoers_file"
        else
            print --error "Failed to create sudoers file"
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Sudoers file creation failed" "file=$sudoers_file, command_failed=echo sudo_line | sudo tee sudoers_file"
            return 1
        fi

        ### Set proper permissions ###
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Setting sudoers file permissions" "target_permissions=440"

        if sudo chmod 440 "$sudoers_file"; then				### Sudoers file permissions ###
            print --success "Sudoers file permissions set"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Sudoers file permissions set successfully" "permissions=440"
        else
            print --warning "Could not set sudoers file permissions"
            log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Sudoers file permissions setting failed" "target_permissions=440"
        fi

        ### Validate sudoers syntax ###
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Validating sudoers syntax" "command=sudo visudo -c -f $sudoers_file"

        if sudo visudo -c -f "$sudoers_file" >/dev/null 2>&1; then		### Syntax validation ###
            print --success "Sudoers syntax validation passed"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Sudoers syntax validation successful"
        else
            print --error "Sudoers syntax validation failed - removing file"
            log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Sudoers syntax validation failed" "action=removing_file"
            
            if sudo rm -f "$sudoers_file"; then				### Cleanup failed file ###
                log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Failed sudoers file removed successfully"
            else
                log --error "${FUNCNAME[0]} called with Arguments: ($*)" "Failed to remove invalid sudoers file" "file=$sudoers_file"
            fi
            return 1
        fi

        ### Test sudo access ###
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Testing sudo configuration" "command=sudo -l -U $target_user"

        local sudo_test_output
        sudo_test_output=$(sudo -l -U "$target_user" 2>/dev/null)
        
        if echo "$sudo_test_output" | grep -q "NOPASSWD"; then			### Sudo access verification ###
            print --success "Sudo configuration verified"
            log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Sudo configuration verification successful" "nopasswd_entries_found=true"
        else
            print --warning "Could not verify sudo configuration"
            log --warning "${FUNCNAME[0]} called with Arguments: ($*)" "Sudo configuration verification failed" "sudo_output=$sudo_test_output"
        fi

        ### Final summary ###
        print --info "Sudo NOPASSWD configured for commands: ${validated_commands[*]}"
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Sudo configuration completed successfully" "configured_commands=${validated_commands[*]}, sudoers_file=$sudoers_file"

        ### Security reminder ###
        print --warning "Security reminder:"
        print --warning "- Review commands regularly for necessity"
        print --warning "- Monitor system logs for unusual activity"
        print --warning "- Use 'secure --remove' to revoke access when no longer needed"
        
        log --info "${FUNCNAME[0]} called with Arguments: ($*)" "Security reminder displayed to user"

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

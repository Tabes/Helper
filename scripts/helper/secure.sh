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
    ### Log startup arguments ###
    log --info "${FUNCNAME[0]} called with Arguments: ($*)"

    local target_path="${2:-$(pwd)}"
    local target_user="${3:-$USER}"
    
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _acl() {
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
        
        print -cr --success "ACL set for user '$user' on: $path"
        print --info "Verify with: getfacl $path"
    }
    
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _group() {
        local path="$1"
        local user="$2"
        local group="${4:-$(basename $path)-admin}"
        
        ### Create group if not exists ###
        if ! getent group "$group" >/dev/null 2>&1; then
            sudo groupadd "$group"
            print -cr --success "Created group: $group"
        fi
        
        ### Add user to group ###
        sudo usermod -a -G "$group" "$user"
        
        ### Set permissions ###
        sudo chown -R root:"$group" "$path"
        sudo chmod -R 775 "$path"
        sudo chmod g+s "$path"
        
        print -cr --success "Group permissions set for '$user' via group '$group'"
        print --info "Re-login required for group changes"
    }
    
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _sudo() {
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
            print -cr --success "sudo NOPASSWD configured for: $user"
            print --warning "Security: Only specified commands allowed"
        else
            sudo rm -f "$sudoers_file"
            print --error "sudoers validation failed"
            return 1
        fi
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
    
    # shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
    _interactive() {
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
                _acl "$path" "$user"
                ;;
            2)
                read -p "Group name [$(basename $path)-admin]: " group_name
                group_name="${group_name:-$(basename $path)-admin}"
                _group "$path" "$user" "$group_name"
                ;;
            3)
                print --warning "Enter commands (comma-separated)"
                print "Default: /usr/bin/rsync,/usr/bin/cp,/usr/bin/mv"
                read -p "Commands: " commands
                _sudo "$user" "${commands:-/usr/bin/rsync,/usr/bin/cp,/usr/bin/mv}"
                ;;
            4)
                _permissions "$path" "$user"
                ;;
            0)
                print --info "Cancelled"
                ;;
            *)
                print --error "Invalid choice"
                ;;
        esac
    }
    
    ### Parse Arguments ###
    case "$1" in
        --acl)
            _acl "$target_path" "$target_user"
            ;;

        --group)
            _group "$target_path" "$target_user" "${4:-}"
            ;;

        --sudo)
            _sudo "$target_user" "${2:-}"
            ;;

        --check)
            _permissions "$target_path" "$target_user"
            ;;

        --wizard)
            _interactive "$target_path" "$target_user"
            ;;

        --remove)
            ### Remove all permission enhancements ###
            sudo setfacl -R -x u:${target_user} "$target_path" 2>/dev/null
            sudo rm -f "/etc/sudoers.d/secure-${target_user}"
            print -cr --success "Removed enhanced permissions for $target_user"
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

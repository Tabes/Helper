#!/bin/bash
################################################################################
### Git Workflow Manager - Complete Git Repository Management System
### Manages version control, branching, releases, and automated workflows
### Integrates with Project Configuration and Helper Functions
################################################################################
### Project: Git Workflow Manager
### Version: 1.0.0
### Author:  Mawage (Development Team)
### Date:    2025-09-12
### License: MIT
### Usage:   ./gitclone.sh [OPTIONS] or Source for Functions
################################################################################

local readonly header="Git Workflow Manager"

readonly version="1.0.0"
readonly commit="Complete Git Repository Management System"


################################################################################
### Parse Command Line Arguments ###
################################################################################

### Parse all Command Line Arguments ###
parse_arguments() {
    ### Log Startup Arguments ###
    log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"

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
                ### Pass all other Arguments to gitclone Function ###
                gitclone "$@"
                exit $?
                ;;
        esac
    done
}


################################################################################
### === GIT CLONE AND MANAGEMENT FUNCTION === ###
################################################################################

### Complete Git Repository Management with Enhanced Logging ###
gitclone() {

	### Log Startup Arguments ###
	log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"

	# shellcheck disable=SC2317,SC2329 # Function called conditionally within main function
    _check() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"
        
        ### Check if git is available ###
        cmd --dependencies "git" || return 1
        
        ### Check git version against remote ###
        local repo_dir="${1:-$PROJECT_ROOT}"
        local branch="${2:-$REPO_BRANCH}"
        
        validate_directory "$repo_dir" false
        
        if [ ! -d "$repo_dir/.git" ]; then
            print --error "Not a git repository: $repo_dir"
            log --error "${FUNCNAME[0]}" "($repo_dir)" "Not a git repository"
            return 3
        fi
        
        cd "$repo_dir" || return 3
        
        ### Quick network check ###
        if ! git ls-remote origin >/dev/null 2>&1; then
            print --warning "Cannot reach remote repository"
            log --warning "${FUNCNAME[0]}" "($repo_dir)" "Remote unreachable"
            return 3
        fi
        
        ### Fetch latest changes ###
        log --info "${FUNCNAME[0]}" "($repo_dir)" "Fetching remote changes"
        git fetch origin "$branch" >/dev/null 2>&1 || {
            print --warning "Cannot fetch branch $branch"
            log --warning "${FUNCNAME[0]}" "($branch)" "Fetch failed"
            return 3
        }
        
        ### Compare local and remote ###
        local local_hash=$(git rev-parse HEAD 2>/dev/null)
        local remote_hash=$(git rev-parse "origin/$branch" 2>/dev/null)
        
        if [ -z "$local_hash" ] || [ -z "$remote_hash" ]; then
            print --error "Cannot determine commit hashes"
            log --error "${FUNCNAME[0]}" "($repo_dir)" "Hash comparison failed"
            return 3
        fi
        
        if [ "$local_hash" != "$remote_hash" ]; then
            local commits_behind=$(git rev-list --count HEAD..origin/$branch 2>/dev/null || echo "unknown")
            print --info "Updates available: $commits_behind commits behind"
            print --info "Local:  ${local_hash:0:8}"
            print --info "Remote: ${remote_hash:0:8}"
            log --info "${FUNCNAME[0]}" "($commits_behind commits)" "Updates available"
            return 0
        else
            print --success "Repository is up to date"
            print --info "Hash: ${local_hash:0:8}"
            log --info "${FUNCNAME[0]}" "(up-to-date)" "Repository current"
            return 1
        fi
    }

	# shellcheck disable=SC2317,SC2329 # Function called conditionally within main function
    _clone() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"
        
        ### Check if git is available ###
        cmd --dependencies "git" || return 1
        
        ### Clone repository with enhanced features ###
        local repo_url="${1:-$REPO_URL}"
        local target_dir="${2:-$PROJECT_ROOT}"
        local branch="${3:-$REPO_BRANCH}"
        
        if [ -z "$repo_url" ]; then
            print --error "Repository URL not provided"
            log --error "${FUNCNAME[0]}" "(empty)" "No repository URL"
            return 1
        fi
        
        print --header "Cloning Repository"
        print --info "URL: $repo_url"
        print --info "Target: $target_dir"
        print --info "Branch: $branch"
        
        ### Check target directory status ###
        local dir_status=$(check_target_directory "$target_dir")
        log --info "${FUNCNAME[0]}" "($target_dir)" "Directory status: $dir_status"
        
        case "$dir_status" in
            INVALID|WRONG_REPO)
                if ! ask_yes_no "Remove existing directory and continue?" "no"; then
                    print --error "Cannot clone to existing directory"
                    log --error "${FUNCNAME[0]}" "(cancelled)" "User cancelled removal"
                    return 1
                fi
                safe_delete "$target_dir" true
                log --info "${FUNCNAME[0]}" "($target_dir)" "Directory removed"
                ;;
            VALID)
                print --info "Valid repository exists, updating instead..."
                log --info "${FUNCNAME[0]}" "($target_dir)" "Updating existing repo"
                cd "$target_dir"
                git fetch origin "$branch"
                git reset --hard "origin/$branch"
                print --success "Repository updated successfully"
                log --info "${FUNCNAME[0]}" "($target_dir)" "Repository updated"
                return 0
                ;;
        esac
        
        ### Create parent directory ###
        mkdir -p "$(dirname "$target_dir")"
        
        ### Clone with progress ###
        log --info "${FUNCNAME[0]}" "($repo_url)" "Starting git clone"
        if git clone --progress --branch "$branch" "$repo_url" "$target_dir"; then
            cd "$target_dir"
            print --success "Repository cloned successfully"
            log --info "${FUNCNAME[0]}" "($repo_url)" "Clone successful"
            
            ### Configure git user ###
            if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
                git config user.name "$GIT_USER_NAME"
                git config user.email "$GIT_USER_EMAIL"
                print --info "Configured git user"
                log --info "${FUNCNAME[0]}" "($GIT_USER_NAME)" "Git user configured"
            fi
            
            return 0
        else
            print --error "Failed to clone repository"
            log --error "${FUNCNAME[0]}" "($repo_url)" "Clone failed"
            
            ### Cleanup failed attempt ###
            if [ -d "$target_dir" ]; then
                print --info "Cleaning up failed installation..."
                safe_delete "$target_dir" true
                log --info "${FUNCNAME[0]}" "($target_dir)" "Cleanup completed"
            fi
            
            return 1
        fi
    }

	# shellcheck disable=SC2317,SC2329 # Function called conditionally within main function
    _init() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"
        
        ### Check if git is available ###
        cmd --dependencies "git" || return 1

        ### Initialize git repository if needed ###
        local repo_dir="${1:-$PROJECT_ROOT}"
        
        if [ ! -d "$repo_dir/.git" ]; then
            print --info "Initializing git repository in $repo_dir"
            
            cd "$repo_dir" || {
                print --error "Cannot access directory: $repo_dir"
                log --error "${FUNCNAME[0]}" "($repo_dir)" "Access denied"
                return 1
            }
            
            ### Initialize repository ###
            if git init; then
                log --info "${FUNCNAME[0]}" "($repo_dir)" "Git init successful"
            else
                print --error "Failed to initialize git repository"
                log --error "${FUNCNAME[0]}" "($repo_dir)" "Git init failed"
                return 1
            fi
            
            ### Configure git user if from project config ###
            if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
                git config user.name "$GIT_USER_NAME"
                git config user.email "$GIT_USER_EMAIL"
                print --success "Configured git user: $GIT_USER_NAME <$GIT_USER_EMAIL>"
                log --info "${FUNCNAME[0]}" "($GIT_USER_NAME)" "Git user set"
            fi
            
            ### Add remote if configured ###
            if [ -n "$REPO_URL" ]; then
                git remote add "$REPO_REMOTE_NAME" "$REPO_URL" 2>/dev/null || true
                print --info "Added remote: $REPO_URL"
                log --info "${FUNCNAME[0]}" "($REPO_REMOTE_NAME)" "Remote added"
            fi
            
            ### Create initial commit ###
            git add .
            if git commit -m "Initial commit"; then
                log --info "${FUNCNAME[0]}" "(initial)" "Initial commit created"
            else
                print --warning "No files to commit"
                log --warning "${FUNCNAME[0]}" "(empty)" "No files for initial commit"
            fi
            
            print --success "Git repository initialized"
            log --info "${FUNCNAME[0]}" "($repo_dir)" "Repository initialized"
        else
            print --info "Git repository already exists"
            log --info "${FUNCNAME[0]}" "($repo_dir)" "Repository exists"
        fi
    }

	# shellcheck disable=SC2317,SC2329 # Function called conditionally within main function
    _push() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"
        
        ### Check if git is available ###
        cmd --dependencies "git" || return 1

        ### Push changes to remote ###
        local push_tags="${1:-false}"
        local branch=$(git branch --show-current)
        
        print --header "Pushing to Remote Repository"
        
        ### Check if remote exists ###
        if ! git remote get-url origin >/dev/null 2>&1; then
            print --warning "No remote repository configured"
            log --warning "${FUNCNAME[0]}" "(no-remote)" "No remote configured"
            return 1
        fi
        
        ### Push current branch ###
        print --info "Pushing $branch branch..."
        
        if git push origin "$branch" 2>/dev/null; then
            print --success "Pushed $branch branch"
            log --info "${FUNCNAME[0]}" "($branch)" "Branch pushed"
        else
            print --warning "Failed to push $branch branch"
            log --warning "${FUNCNAME[0]}" "($branch)" "Push failed"
            return 1
        fi
        
        ### Push tags if requested ###
        if [ "$push_tags" = "true" ] || [ "$push_tags" = "yes" ]; then
            print --info "Pushing tags..."
            
            if git push origin --tags 2>/dev/null; then
                print --success "Pushed tags"
                log --info "${FUNCNAME[0]}" "(tags)" "Tags pushed"
            else
                print --warning "Failed to push tags"
                log --warning "${FUNCNAME[0]}" "(tags)" "Tag push failed"
            fi
        fi
        
        return 0
    }

	# shellcheck disable=SC2317,SC2329 # Function called conditionally within main function
    _pull() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"
        
        ### Check if git is available ###
        cmd --dependencies "git" || return 1

        ### Pull changes from remote ###
        local branch="${1:-$(git branch --show-current)}"
        
        print --header "Pulling from Remote Repository"
        
        ### Check if remote exists ###
        if ! git remote get-url origin >/dev/null 2>&1; then
            print --warning "No remote repository configured"
            log --warning "${FUNCNAME[0]}" "(no-remote)" "No remote configured"
            return 1
        fi
        
        ### Fetch latest changes ###
        print --info "Fetching latest changes..."
        
        if git fetch origin 2>/dev/null; then
            print --success "Fetched latest changes"
            log --info "${FUNCNAME[0]}" "(fetch)" "Fetch successful"
        else
            print --warning "Failed to fetch changes"
            log --warning "${FUNCNAME[0]}" "(fetch)" "Fetch failed"
            return 1
        fi
        
        ### Pull changes ###
        print --info "Pulling $branch branch..."
        
        if git pull origin "$branch" 2>/dev/null; then
            print --success "Pulled latest changes for $branch"
            log --info "${FUNCNAME[0]}" "($branch)" "Pull successful"
            return 0
        else
            print --warning "Failed to pull changes"
            log --warning "${FUNCNAME[0]}" "($branch)" "Pull failed"
            return 1
        fi
    }

	# shellcheck disable=SC2317,SC2329 # Function called conditionally within main function
    _sync() {
        ### Log Startup Arguments ###
        log --info "${FUNCNAME[0]}" "($*)" "Called with Arguments:"
        
        ### Full Synchronization ###
        local push_after_pull="${1:-true}"
        
        print --header "Synchronizing with Remote Repository"
        
        ### Pull latest changes ###
        if _pull; then
            print --info "Pull completed successfully"
            log --info "${FUNCNAME[0]}" "(pull)" "Pull phase completed"
        else
            print --warning "Pull failed, continuing..."
            log --warning "${FUNCNAME[0]}" "(pull)" "Pull phase failed"
        fi
        
        ### Push local changes if requested ###
        if [ "$push_after_pull" = "true" ]; then
            echo ""
            if _push; then
                print --info "Push completed successfully"
                log --info "${FUNCNAME[0]}" "(push)" "Push phase completed"
            else
                print --warning "Push failed"
                log --warning "${FUNCNAME[0]}" "(push)" "Push phase failed"
            fi
        fi
        
        print --success "Synchronization completed"
        log --info "${FUNCNAME[0]}" "(complete)" "Synchronization finished"
    }

    ### Parse Arguments ###
    while [[ $# -gt 0 ]]; do
        case $1 in
            --check|-c)
                _check "$2" "$3"
                return $?
                ;;

            --clone)
                _clone "$2" "$3" "$4"
                return $?
                ;;

            --help|-h)
                show_help "gitclone"
                return 0
                ;;

            --init|-i)
                _init "$2"
                return $?
                ;;

            --pull)
                _pull "$2"
                return $?
                ;;

            --push)
                _push "$2"
                return $?
                ;;

            --sync|-s)
                _sync "$2"
                return $?
                ;;

            --version|-V)
                print --version "$header" "$version" "$commit"
                return 0
                ;;

            *)
                print --invalid "${FUNCNAME[0]}" "$1"
                return 1
                ;;

        esac

        shift

    done

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
#!/bin/bash
################################################################################
### Git Workflow Manager - Complete Git Repository Management System
### Manages version control, branching, releases, and automated workflows
### Integrates with project configuration and helper functions
################################################################################
### Project: Git Workflow Manager
### Version: 1.0.0
### Author:  Mawage (Workflow Team)
### Date:    2025-08-23
### License: MIT
### Usage:   ./git.sh [OPTIONS] or source for functions
################################################################################

SCRIPT_VERSION="1.0.0"
COMMIT="Complete Git Workflow and Version Management System"


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
                ### Pass all other Arguments to CMD Function ###
                gitclone "$@"
                exit $?
                ;;
        esac
    done
}


################################################################################
### === GIT REPOSITORY SETUP === ###
################################################################################

### Initialize git repository if needed ###
init_git_repo() {
    local repo_dir="${1:-$PROJECT_ROOT}"
    
    if [ ! -d "$repo_dir/.git" ]; then
        print_info "Initializing git repository in $repo_dir"
        
        cd "$repo_dir" || error_exit "Cannot access directory: $repo_dir"
        
        ### Initialize repository ###
        git init || error_exit "Failed to initialize git repository"
        
        ### Configure git user if from project config ###
        if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
            git config user.name "$GIT_USER_NAME"
            git config user.email "$GIT_USER_EMAIL"
            print_success "Configured git user: $GIT_USER_NAME <$GIT_USER_EMAIL>"
        fi
        
        ### Add remote if configured ###
        if [ -n "$REPO_URL" ]; then
            git remote add "$REPO_REMOTE_NAME" "$REPO_URL" 2>/dev/null || true
            print_info "Added remote: $REPO_URL"
        fi
        
        ### Create initial commit ###
        git add .
        git commit -m "Initial commit" || print_warning "No files to commit"
        
        print_success "Git repository initialized"
    else
        print_info "Git repository already exists"
    fi
}

### Professional Git version checking ###
check_git_version() {
    local repo_dir="${1:-$PROJECT_ROOT}"
    local branch="${2:-$REPO_BRANCH}"
    local check_type="${3:-commits}"
    
    validate_directory "$repo_dir" false
    
    if [ ! -d "$repo_dir/.git" ]; then
        print_error "Not a git repository: $repo_dir"
        return 3
    fi
    
    cd "$repo_dir"
    
    ### Quick network check ###
    if ! git ls-remote origin >/dev/null 2>&1; then
        print_warning "Cannot reach remote repository"
        return 3
    fi
    
    ### Fetch latest changes ###
    git fetch origin "$branch" >/dev/null 2>&1 || {
        print_warning "Cannot fetch branch $branch"
        return 3
    }
    
    ### Compare local and remote ###
    local local_hash=$(git rev-parse HEAD 2>/dev/null)
    local remote_hash=$(git rev-parse "origin/$branch" 2>/dev/null)
    
    if [ -z "$local_hash" ] || [ -z "$remote_hash" ]; then
        print_error "Cannot determine commit hashes"
        return 3
    fi
    
    if [ "$local_hash" != "$remote_hash" ]; then
        local commits_behind=$(git rev-list --count HEAD..origin/$branch 2>/dev/null || echo "unknown")
        print_info "Updates available: $commits_behind commits behind"
        print_info "Local:  ${local_hash:0:8}"
        print_info "Remote: ${remote_hash:0:8}"
        return 0
    else
        print_success "Repository is up to date"
        print_info "Hash: ${local_hash:0:8}"
        return 1
    fi
}

### Clone repository with enhanced features ###
clone_repository() {
    local repo_url="${1:-$REPO_URL}"
    local target_dir="${2:-$PROJECT_ROOT}"
    local branch="${3:-$REPO_BRANCH}"
    
    if [ -z "$repo_url" ]; then
        error_exit "Repository URL not provided"
    fi
    
    print_header "Cloning Repository"
    print_info "URL: $repo_url"
    print_info "Target: $target_dir"
    print_info "Branch: $branch"
    
    ### Check target directory status ###
    local dir_status=$(check_target_directory "$target_dir")
    
    case "$dir_status" in
        INVALID|WRONG_REPO)
            if ! ask_yes_no "Remove existing directory and continue?" "no"; then
                error_exit "Cannot clone to existing directory"
            fi
            safe_delete "$target_dir" true
            ;;
        VALID)
            print_info "Valid repository exists, updating instead..."
            cd "$target_dir"
            git fetch origin "$branch"
            git reset --hard "origin/$branch"
            print_success "Repository updated successfully"
            return 0
            ;;
    esac
    
    ### Create parent directory ###
    mkdir -p "$(dirname "$target_dir")"
    
    ### Clone with progress ###
    if git clone --progress --branch "$branch" "$repo_url" "$target_dir"; then
        cd "$target_dir"
        print_success "Repository cloned successfully"
        
        ### Configure git user ###
        if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
            git config user.name "$GIT_USER_NAME"
            git config user.email "$GIT_USER_EMAIL"
            print_info "Configured git user"
        fi
        
        ### Set permissions if we have root access ###
        if is_root; then
            set_repository_permissions "$target_dir"
        fi
        
        return 0
    else
        print_error "Failed to clone repository"
        
        ### Cleanup failed attempt ###
        if [ -d "$target_dir" ]; then
            print_info "Cleaning up failed installation..."
            safe_delete "$target_dir" true
        fi
        
        error_exit "Git clone failed - installation aborted"
    fi
}

### Set repository permissions ###
set_repository_permissions() {
    local repo_dir="${1:-$PROJECT_ROOT}"
    
    print_info "Setting repository permissions..."
    
    ### Set ownership to current user or root ###
    local owner=$(whoami)
    if is_root && [ -n "$SUDO_USER" ]; then
        owner="$SUDO_USER"
    fi
    
    chown -R "$owner:$owner" "$repo_dir" 2>/dev/null || true
    print_success "Set ownership to $owner"
    
    ### Set directory permissions ###
    find "$repo_dir" -type d -exec chmod 755 {} \; 2>/dev/null
    print_success "Set directory permissions (755)"
    
    ### Set file permissions ###
    find "$repo_dir" -type f -exec chmod 644 {} \; 2>/dev/null
    print_success "Set file permissions (644)"
    
    ### Make scripts executable ###
    find "$repo_dir" -name "*.sh" -exec chmod +x {} \; 2>/dev/null
    print_success "Made shell scripts executable"
}

### Validate repository installation ###
validate_installation() {
    local repo_dir="${1:-$PROJECT_ROOT}"
    
    print_header "Validating Installation"
    
    ### Check if directory exists ###
    validate_directory "$repo_dir" true
    
    ### Check if it's a git repository ###
    if [ ! -d "$repo_dir/.git" ]; then
        print_error "Not a git repository"
        return 1
    fi
    print_check "Valid git repository"
    
    ### Check remote configuration ###
    cd "$repo_dir"
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$remote_url" ]; then
        print_check "Remote configured: $remote_url"
    else
        print_cross "No remote configured"
    fi
    
    ### Check current branch ###
    local current_branch=$(git branch --show-current 2>/dev/null || echo "")
    if [ -n "$current_branch" ]; then
        print_check "Current branch: $current_branch"
    else
        print_cross "No current branch"
    fi
    
    ### Check for required files from project.conf ###
    if [ -n "${REQUIRED_FILES[*]}" ]; then
        print_info "Checking required files..."
        for file in "${REQUIRED_FILES[@]}"; do
            if validate_file "$repo_dir/$file" false; then
                print_check "$(basename "$file")"
            else
                print_cross "Missing: $(basename "$file")"
                return 1
            fi
        done
    fi
    
    ### Check for required directories ###
    if [ -n "${REQUIRED_DIRS[*]}" ]; then
        print_info "Checking required directories..."
        for dir in "${REQUIRED_DIRS[@]}"; do
            if [ -d "$repo_dir/$dir" ]; then
                print_check "$(basename "$dir")"
            else
                print_cross "Missing: $(basename "$dir")"
                return 1
            fi
        done
    fi
    
    print_success "Installation validation passed"
    return 0
}

### Show installation summary ###
show_installation_summary() {
    local repo_dir="${1:-$PROJECT_ROOT}"
    
    print_header "Installation Summary"
    
    ### Project information ###
    print_section "Project Details"
    echo "  Repository: ${REPO_URL:-Unknown}"
    echo "  Branch:     ${REPO_BRANCH:-Unknown}"
    echo "  Location:   $repo_dir"
    echo ""
    
    ### Git information ###
    if [ -d "$repo_dir/.git" ]; then
        cd "$repo_dir"
        local commit_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        local commit_date=$(git log -1 --format="%cd" --date=short 2>/dev/null || echo "unknown")
        local commit_msg=$(git log -1 --format="%s" 2>/dev/null || echo "unknown")
        
        print_section "Git Information"
        echo "  Commit:  $commit_hash"
        echo "  Date:    $commit_date"
        echo "  Message: $commit_msg"
        echo ""
    fi
    
    ### Repository status ###
    print_section "Repository Status"
    local status_output=$(cd "$repo_dir" && git status --porcelain 2>/dev/null)
    if [ -z "$status_output" ]; then
        print_success "Working tree is clean"
    else
        local modified=$(echo "$status_output" | grep -c "^ M" || echo "0")
        local untracked=$(echo "$status_output" | grep -c "^??" || echo "0")
        echo "  Modified files:  $modified"
        echo "  Untracked files: $untracked"
    fi
    
    print_success "Repository installation completed successfully!"
}


################################################################################
### === GIT COMMIT OPERATIONS === ###
################################################################################

### Commit File with updated Header ###
commit_with_update() {
    local file="$1"
    local commit_message="$2"
    local increment_type="${3:-patch}"
    
    if [ -z "$file" ] || [ -z "$commit_message" ]; then
        print_error "Usage: commit_with_update <file> <commit_message> [increment_type]"
        print_info "increment_type: major, minor, patch (default: patch)"
        return 1
    fi
    
    print_header "Commit with Header Update"
    
    ### Update header using helper function ###
    if ! header --update "$file" "$commit_message" "$increment_type" >/dev/null; then
        error_exit "Header update failed"
    fi
    
    ### Get actual commit message from file ###
    local actual_commit_message
    if grep -q "^COMMIT=" "$file"; then
        actual_commit_message=$(grep "^COMMIT=" "$file" | cut -d'"' -f2)
    else
        actual_commit_message="$commit_message"
    fi
    
    ### Stage and commit ###
    git add "$file" || error_exit "Failed to stage file"
    
    if git commit -m "$actual_commit_message"; then
        local new_version=$(header --get-version "$file")
        print_success "Committed $(basename "$file") v$new_version"
        print_info "Message: $actual_commit_message"
        return 0
    else
        error_exit "Git commit failed"
    fi
}

### Batch commit multiple files ###
batch_commit() {
    local commit_message="$1"
    local increment_type="${2:-patch}"
    shift 2
    local files=("$@")
    
    if [ ${#files[@]} -eq 0 ]; then
        print_error "No files specified for batch commit"
        return 1
    fi
    
    print_header "Batch Commit: ${#files[@]} files"
    
    ### Update all files using helper function ###
    if ! header --batch-update "$commit_message" "$increment_type" "${files[@]}"; then
        print_warning "Some files failed to update"
    fi
    
    ### Get successfully updated files ###
    local updated_files=()
    for file in "${files[@]}"; do
        if git diff --name-only "$file" 2>/dev/null | grep -q "$file"; then
            updated_files+=("$file")
        fi
    done
    
    if [ ${#updated_files[@]} -eq 0 ]; then
        print_warning "No files were updated"
        return 1
    fi
    
    ### Stage all updated files ###
    git add "${updated_files[@]}" || error_exit "Failed to stage files"
    
    ### Commit all files ###
    if git commit -m "$commit_message"; then
        print_success "Batch commit successful: ${#updated_files[@]} files"
        
        for file in "${updated_files[@]}"; do
            local version=$(header --get-version "$file")
            print_check "$(basename "$file") v$version"
        done
        
        return 0
    else
        error_exit "Batch commit failed"
    fi
}

################################################################################
### === BRANCH MANAGEMENT === ###
################################################################################

### Setup standard branch structure ###
setup_branch_structure() {
    print_header "Setting up Branch Structure"
    
    local main_branch="${REPO_BRANCH:-main}"
    local develop_branch="${REPO_DEVELOP_BRANCH:-develop}"
    
    ### Ensure we're in a git repository ###
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        error_exit "Not in a git repository"
    fi
    
    ### Create or switch to main branch ###
    if ! git show-ref --verify --quiet "refs/heads/$main_branch"; then
        git checkout -b "$main_branch" || error_exit "Failed to create $main_branch branch"
        print_success "Created $main_branch branch"
    else
        git checkout "$main_branch" || error_exit "Failed to switch to $main_branch"
        print_info "Switched to $main_branch branch"
    fi
    
    ### Create develop branch if needed ###
    if ! git show-ref --verify --quiet "refs/heads/$develop_branch"; then
        git checkout -b "$develop_branch" || error_exit "Failed to create $develop_branch branch"
        print_success "Created $develop_branch branch"
    else
        print_info "$develop_branch branch already exists"
    fi
    
    ### Set upstream tracking if remote exists ###
    if git remote get-url origin >/dev/null 2>&1; then
        git branch --set-upstream-to="origin/$main_branch" "$main_branch" 2>/dev/null || true
        git branch --set-upstream-to="origin/$develop_branch" "$develop_branch" 2>/dev/null || true
        print_info "Set upstream tracking"
    fi
    
    ### Switch back to develop ###
    git checkout "$develop_branch"
    print_success "Branch structure setup complete"
}

### Create feature branch ###
create_feature_branch() {
    local feature_name="$1"
    
    if [ -z "$feature_name" ]; then
        print_error "Usage: create_feature_branch <feature_name>"
        print_info "Example: create_feature_branch user-authentication"
        return 1
    fi
    
    local develop_branch="${REPO_DEVELOP_BRANCH:-develop}"
    local feature_prefix="${FEATURE_BRANCH_PREFIX:-feature/}"
    local branch_name="${feature_prefix}${feature_name}"
    
    print_header "Creating Feature Branch: $branch_name"
    
    ### Ensure develop branch exists ###
    if ! git show-ref --verify --quiet "refs/heads/$develop_branch"; then
        print_warning "$develop_branch branch not found, creating it"
        git checkout -b "$develop_branch"
    else
        git checkout "$develop_branch"
        
        ### Update develop if remote exists ###
        if git remote get-url origin >/dev/null 2>&1; then
            print_info "Updating $develop_branch branch"
            git pull origin "$develop_branch" 2>/dev/null || print_warning "Could not pull latest changes"
        fi
    fi
    
    ### Create feature branch ###
    git checkout -b "$branch_name" || error_exit "Failed to create feature branch"
    
    print_success "Created and switched to feature branch: $branch_name"
    print_info "Work on your feature, then run: finish_feature_branch $feature_name"
}

### Merge feature branch back ###
finish_feature_branch() {
    local feature_name="$1"
    
    if [ -z "$feature_name" ]; then
        print_error "Usage: finish_feature_branch <feature_name>"
        return 1
    fi
    
    local develop_branch="${REPO_DEVELOP_BRANCH:-develop}"
    local feature_prefix="${FEATURE_BRANCH_PREFIX:-feature/}"
    local branch_name="${feature_prefix}${feature_name}"
    local current_branch=$(git branch --show-current)
    
    print_header "Finishing Feature Branch: $branch_name"
    
    ### Ensure we're on the feature branch or switch to it ###
    if [ "$current_branch" != "$branch_name" ]; then
        if ! git show-ref --verify --quiet "refs/heads/$branch_name"; then
            error_exit "Feature branch $branch_name not found"
        fi
        git checkout "$branch_name" || error_exit "Failed to switch to feature branch"
    fi
    
    ### Switch to develop ###
    git checkout "$develop_branch" || error_exit "Failed to switch to $develop_branch"
    
    ### Merge feature branch ###
    if git merge "$branch_name" --no-ff -m "Merge feature: $feature_name"; then
        print_success "Feature $feature_name merged into $develop_branch"
        
        ### Delete feature branch ###
        if ask_yes_no "Delete feature branch $branch_name?" "yes"; then
            git branch -d "$branch_name"
            print_success "Deleted feature branch: $branch_name"
        fi
        
        return 0
    else
        error_exit "Failed to merge feature branch"
    fi
}


################################################################################
### === RELEASE MANAGEMENT === ###
################################################################################

### Create version tag ###
create_version_tag() {
    local version="$1"
    local message="$2"
    
    if [ -z "$version" ]; then
        print_error "Usage: create_version_tag <version> [message]"
        print_info "Example: create_version_tag v1.2.3 'Release with new features'"
        return 1
    fi
    
    ### Add version prefix if needed ###
    local version_prefix="${VERSION_PREFIX:-v}"
    if [[ ! "$version" =~ ^$version_prefix[0-9] ]]; then
        version="${version_prefix}$version"
    fi
    
    ### Validate version format ###
    if [[ ! "$version" =~ ^$version_prefix[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid version format. Use ${version_prefix}X.Y.Z (e.g., ${version_prefix}1.2.3)"
        return 1
    fi
    
    ### Check if tag exists ###
    if git tag -l | grep -q "^$version$"; then
        print_error "Tag $version already exists"
        return 1
    fi
    
    ### Create annotated tag ###
    local tag_message="${message:-Release $version}"
    
    if git tag -a "$version" -m "$tag_message"; then
        print_success "Created tag: $version"
        print_info "Message: $tag_message"
        return 0
    else
        error_exit "Failed to create tag"
    fi
}

### Create full release ###
create_release() {
    local version="$1"
    local message="$2"
    
    if [ -z "$version" ]; then
        print_error "Usage: create_release <version> [message]"
        print_info "Example: create_release 1.2.3 'Major feature release'"
        return 1
    fi
    
    local main_branch="${REPO_BRANCH:-main}"
    local develop_branch="${REPO_DEVELOP_BRANCH:-develop}"
    
    print_header "Creating Release: $version"
    
    ### Ensure branches exist ###
    if ! git show-ref --verify --quiet "refs/heads/$develop_branch"; then
        error_exit "$develop_branch branch not found"
    fi
    
    if ! git show-ref --verify --quiet "refs/heads/$main_branch"; then
        git checkout -b "$main_branch"
        print_info "Created $main_branch branch"
    fi
    
    ### Switch to develop and ensure it's clean ###
    git checkout "$develop_branch"
    
    if ! git diff --quiet; then
        print_warning "Uncommitted changes in $develop_branch"
        if ! ask_yes_no "Continue with release anyway?" "no"; then
            print_info "Release cancelled"
            return 1
        fi
    fi
    
    ### Merge develop to main ###
    git checkout "$main_branch"
    
    if git merge "$develop_branch" --no-ff -m "Release $version"; then
        print_success "Merged $develop_branch to $main_branch"
    else
        error_exit "Failed to merge for release"
    fi
    
    ### Create version tag ###
    create_version_tag "$version" "$message"
    
    ### Switch back to develop ###
    git checkout "$develop_branch"
    
    print_success "Release $version created successfully!"
    
    ### Ask to push ###
    if ask_yes_no "Push release to remote repository?" "yes"; then
        push_to_remote true
    fi
}


################################################################################
### === REMOTE SYNCHRONIZATION === ###
################################################################################

### Push changes to remote ###
push_to_remote() {
    local push_tags="${1:-false}"
    local branch=$(git branch --show-current)
    
    print_header "Pushing to Remote Repository"
    
    ### Check if remote exists ###
    if ! git remote get-url origin >/dev/null 2>&1; then
        print_warning "No remote repository configured"
        return 1
    fi
    
    ### Push current branch ###
    print_info "Pushing $branch branch..."
    
    if git push origin "$branch" 2>/dev/null; then
        print_success "Pushed $branch branch"
    else
        print_warning "Failed to push $branch branch"
        return 1
    fi
    
    ### Push tags if requested ###
    if [ "$push_tags" = "true" ] || [ "$push_tags" = "yes" ]; then
        print_info "Pushing tags..."
        
        if git push origin --tags 2>/dev/null; then
            print_success "Pushed tags"
        else
            print_warning "Failed to push tags"
        fi
    fi
    
    return 0
}

### Pull changes from remote ###
pull_from_remote() {
    local branch="${1:-$(git branch --show-current)}"
    
    print_header "Pulling from Remote Repository"
    
    ### Check if remote exists ###
    if ! git remote get-url origin >/dev/null 2>&1; then
        print_warning "No remote repository configured"
        return 1
    fi
    
    ### Fetch latest changes ###
    print_info "Fetching latest changes..."
    
    if git fetch origin 2>/dev/null; then
        print_success "Fetched latest changes"
    else
        print_warning "Failed to fetch changes"
        return 1
    fi
    
    ### Pull changes ###
    print_info "Pulling $branch branch..."
    
    if git pull origin "$branch" 2>/dev/null; then
        print_success "Pulled latest changes for $branch"
        return 0
    else
        print_warning "Failed to pull changes"
        return 1
    fi
}

### Full synchronization ###
sync_with_remote() {
    local push_after_pull="${1:-true}"
    
    print_header "Synchronizing with Remote Repository"
    
    ### Pull latest changes ###
    if pull_from_remote; then
        print_info "Pull completed successfully"
    else
        print_warning "Pull failed, continuing..."
    fi
    
    ### Push local changes if requested ###
    if [ "$push_after_pull" = "true" ]; then
        echo ""
        if push_to_remote; then
            print_info "Push completed successfully"
        else
            print_warning "Push failed"
        fi
    fi
    
    print_success "Synchronization completed"
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
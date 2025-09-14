#!/bin/bash
################################################################################
### Standalone Update System - Complete Update Management
### Downloads and validates individual Files from Repository without Git
### Provides Checksums validation, Rollback Mechanism and Version Migration
################################################################################
### Project: Universal Helper Library
### Version: 1.0.3
### Author:  Mawage (Development Team)
### Date:    2025-09-14
### License: MIT
### Usage:   ./update.sh [OPTIONS]
### Commit:  Initial Update System with rollback and validation Support
################################################################################


################################################################################
### === PARSE COMMAND LINE ARGUMENTS === ###
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
                ### Pass all other Arguments to UPDATE Function ###
                update "$@"
                exit $?
                ;;

        esac
    done
}


################################################################################
### === UPDATE SYSTEM FUNCTIONS === ###
################################################################################

### Universal Update Function with multiple Operation Modes ###
update() {
	
	### Log Startup Arguments ###
	log --info "${FUNCNAME[0]} called with Arguments: ($*)"
	
	################################################################################
	### === INTERNAL UPDATE FUNCTIONS === ###
	################################################################################
	
	### Create backup of current installation (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_create_backup() {
		
		print --info "Creating backup in: ${UPDATE_BACKUP_DIR}"
		
		if ! mkdir -p "${UPDATE_BACKUP_DIR}"; then			### Create backup directory ###
			print --error "Failed to create backup directory"
			return 1
		fi
		
		### Backup critical files ###
		local backup_files=(
			"${PROJECT_CONFIG}"
			"${HELPER_CONFIG}"
			"${HELPER_SCRIPT}"
			"${START_SCRIPT}"
		)
		
		for file in "${backup_files[@]}"; do
			
			if [[ -f "$file" ]]; then				### File exists ###
				
				local relative_path="${file#${PROJECT_ROOT}/}"
				local backup_file="${UPDATE_BACKUP_DIR}/${relative_path}"
				local backup_dir
				backup_dir="$(dirname "$backup_file")"
				
				mkdir -p "$backup_dir" || {
					print --error "Failed to create backup directory: $backup_dir"
					return 1
				}
				
				if ! cp "$file" "$backup_file"; then		### Copy failed ###
					print --error "Failed to backup: $file"
					return 1
				fi
				
			fi
			
		done
		
		### Create backup manifest ###
		{
			echo "# Backup created: $(date)"
			echo "# Project version: ${PROJECT_VERSION}"
			echo "# Backup directory: ${UPDATE_BACKUP_DIR}"
		} > "${UPDATE_BACKUP_DIR}/backup-info.txt"
		
		log --info "Backup created successfully: ${UPDATE_BACKUP_DIR}"
		return 0
	}
	
	### Download update manifest (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_download_manifest() {
		
		local manifest_url="${UPDATE_BASE_URL}/${UPDATE_MANIFEST}"
		local manifest_file="${UPDATE_TMP_DIR}/${UPDATE_MANIFEST}"
		
		print --info "Downloading update manifest..."
		
		if ! _download_file "$manifest_url" "$manifest_file"; then	### Download failed ###
			print --error "Failed to download update manifest"
			return 1
		fi
		
		if [[ ! -s "$manifest_file" ]]; then				### Empty manifest ###
			print --error "Update manifest is empty or corrupted"
			return 1
		fi
		
		log --info "Update manifest downloaded successfully"
		return 0
	}
	
	### Download checksums file (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_download_checksums() {
		
		local checksum_url="${UPDATE_BASE_URL}/${CHECKSUM_FILE}"
		local checksum_file="${UPDATE_TMP_DIR}/${CHECKSUM_FILE}"
		
		print --info "Downloading checksums..."
		
		if ! _download_file "$checksum_url" "$checksum_file"; then	### Download failed ###
			print --warning "Failed to download checksums - validation disabled"
			return 1
		fi
		
		log --info "Checksums downloaded successfully"
		return 0
	}
	
	### Download single file with retries (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_download_file() {
		local url="$1"
		local output_file="$2"
		local retry_count=0
		
		while [[ $retry_count -lt $MAX_DOWNLOAD_RETRIES ]]; do
			
			if command -v curl >/dev/null 2>&1; then		### Use curl ###
				
				if curl -L --connect-timeout "$DOWNLOAD_TIMEOUT" \
					--max-time $((DOWNLOAD_TIMEOUT * 2)) \
					--retry 2 --retry-delay 1 \
					-o "$output_file" "$url" 2>/dev/null; then
					
					return 0
				fi
				
			elif command -v wget >/dev/null 2>&1; then		### Use wget ###
				
				if wget --timeout="$DOWNLOAD_TIMEOUT" \
					--tries=2 --wait=1 \
					-O "$output_file" "$url" 2>/dev/null; then
					
					return 0
				fi
				
			else							### No download tool ###
				
				print --error "Neither curl nor wget available"
				return 1
				
			fi
			
			((retry_count++))
			[[ $retry_count -lt $MAX_DOWNLOAD_RETRIES ]] && sleep 2
			
		done
		
		return 1
	}
	
	### Parse manifest and download files (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_process_manifest() {
		
		local manifest_file="${UPDATE_TMP_DIR}/${UPDATE_MANIFEST}"
		local downloaded_files=0
		local failed_downloads=0
		
		if [[ ! -f "$manifest_file" ]]; then				### Manifest missing ###
			print --error "Update manifest not found"
			return 1
		fi
		
		print --info "Processing update manifest..."
		
		while IFS='|' read -r file_path version checksum description; do
			
			### Skip comments and empty lines ###
			[[ "$file_path" =~ ^#.*$ ]] && continue
			[[ -z "$file_path" ]] && continue
			
			local remote_url="${UPDATE_BASE_URL}/${file_path}"
			local local_file="${PROJECT_ROOT}/${file_path}"
			local temp_file="${UPDATE_TMP_DIR}/${file_path}"
			local temp_dir
			temp_dir="$(dirname "$temp_file")"
			
			### Create temporary directory ###
			mkdir -p "$temp_dir" || {
				print --error "Failed to create temp directory: $temp_dir"
				((failed_downloads++))
				continue
			}
			
			print --info "Downloading: $file_path"
			
			if _download_file "$remote_url" "$temp_file"; then	### Download successful ###
				
				### Verify checksum if available ###
				if [[ -n "$checksum" ]] && [[ "$checksum" != "-" ]]; then
					
					if _verify_checksum "$temp_file" "$checksum"; then
						((downloaded_files++))
						log --info "Downloaded and verified: $file_path"
					else
						print --warning "Checksum verification failed: $file_path"
						rm -f "$temp_file"
						((failed_downloads++))
					fi
					
				else
					
					((downloaded_files++))
					log --info "Downloaded (no checksum): $file_path"
					
				fi
				
			else							### Download failed ###
				
				print --warning "Failed to download: $file_path"
				((failed_downloads++))
				
			fi
			
		done < "$manifest_file"
		
		print --info "Download complete: $downloaded_files files, $failed_downloads failures"
		
		[[ $failed_downloads -eq 0 ]]
	}
	
	### Verify file checksum (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_verify_checksum() {
		local file="$1"
		local expected_checksum="$2"
		
		if ! command -v sha256sum >/dev/null 2>&1; then		### No sha256sum ###
			return 0  # Skip verification
		fi
		
		local actual_checksum
		actual_checksum="$(sha256sum "$file" | cut -d' ' -f1)"
		
		[[ "$actual_checksum" == "$expected_checksum" ]]
	}
	
	### Install downloaded files (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_install_files() {
		
		local manifest_file="${UPDATE_TMP_DIR}/${UPDATE_MANIFEST}"
		local installed_files=0
		local failed_installs=0
		
		print --info "Installing downloaded files..."
		
		while IFS='|' read -r file_path version checksum description; do
			
			### Skip comments and empty lines ###
			[[ "$file_path" =~ ^#.*$ ]] && continue
			[[ -z "$file_path" ]] && continue
			
			local temp_file="${UPDATE_TMP_DIR}/${file_path}"
			local target_file="${PROJECT_ROOT}/${file_path}"
			local target_dir
			target_dir="$(dirname "$target_file")"
			
			if [[ ! -f "$temp_file" ]]; then			### Temp file missing ###
				print --warning "Skipping missing file: $file_path"
				continue
			fi
			
			### Create target directory ###
			mkdir -p "$target_dir" || {
				print --error "Failed to create directory: $target_dir"
				((failed_installs++))
				continue
			}
			
			### Install file ###
			if cp "$temp_file" "$target_file"; then			### Install successful ###
				
				### Set executable permissions for scripts ###
				if [[ "$file_path" =~ \.sh$ ]]; then
					chmod +x "$target_file"
				fi
				
				((installed_files++))
				print --info "Installed: $file_path"
				
			else						### Install failed ###
				
				print --error "Failed to install: $file_path"
				((failed_installs++))
				
			fi
			
		done < "$manifest_file"
		
		print --info "Installation complete: $installed_files files, $failed_installs failures"
		
		[[ $failed_installs -eq 0 ]]
	}
	
	### Clean up temporary files (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_cleanup() {
		
		if [[ -d "$UPDATE_TMP_DIR" ]]; then				### Remove temp directory ###
			
			rm -rf "$UPDATE_TMP_DIR"
			log --info "Cleaned up temporary files"
			
		fi
		
	}
	
	### Clean old backups (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_cleanup_old_backups() {
		
		if [[ ! -d "$BACKUP_DIR" ]]; then				### No backup directory ###
			return 0
		fi
		
		print --info "Cleaning old backups (older than ${BACKUP_RETENTION_DAYS} days)..."
		
		### Find and remove old backups ###
		find "$BACKUP_DIR" -maxdepth 1 -type d -name "update-*" \
			-mtime +$BACKUP_RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null
		
		log --info "Old backup cleanup completed"
	}
	
	### Check for available updates (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_check_updates() {
		
		print --info "Checking for available updates..."
		
		### Create temporary directory ###
		mkdir -p "$UPDATE_TMP_DIR" || {
			print --error "Failed to create temporary directory"
			return 1
		}
		
		### Download manifest ###
		local manifest_url="${UPDATE_BASE_URL}/${UPDATE_MANIFEST}"
		local manifest_file="${UPDATE_TMP_DIR}/${UPDATE_MANIFEST}"
		
		if ! _download_file "$manifest_url" "$manifest_file"; then	### Download failed ###
			print --error "Failed to check for updates"
			rm -rf "$UPDATE_TMP_DIR"
			return 1
		fi
		
		### Compare versions ###
		local updates_available=0
		local current_version="${PROJECT_VERSION:-unknown}"
		
		print --info "Current version: $current_version"
		print --cr
		
		while IFS='|' read -r file_path version checksum description; do
			
			### Skip comments and empty lines ###
			[[ "$file_path" =~ ^#.*$ ]] && continue
			[[ -z "$file_path" ]] && continue
			
			local local_file="${PROJECT_ROOT}/${file_path}"
			
			if [[ ! -f "$local_file" ]]; then			### New file ###
				
				print --info "New file available: $file_path (v$version)"
				[[ -n "$description" ]] && print "  Description: $description"
				((updates_available++))
				
			elif [[ "$version" != "$current_version" ]]; then	### Version mismatch ###
				
				print --info "Update available: $file_path (v$version)"
				[[ -n "$description" ]] && print "  Description: $description"
				((updates_available++))
				
			fi
			
		done < "$manifest_file"
		
		### Cleanup ###
		rm -rf "$UPDATE_TMP_DIR"
		
		if [[ $updates_available -gt 0 ]]; then			### Updates available ###
			
			print --cr
			print --info "Found $updates_available available updates"
			print --info "Run 'update --install' to install updates"
			return 0
			
		else							### No updates ###
			
			print --success "System is up to date"
			return 1
			
		fi
	}
	
	### Rollback to previous version (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_rollback_update() {
		local backup_name="$1"
		
		if [[ -z "$backup_name" ]]; then				### No backup specified ###
			
			print --info "Available backups:"
			
			if [[ -d "$BACKUP_DIR" ]]; then
				
				find "$BACKUP_DIR" -maxdepth 1 -type d -name "update-*" \
					-printf "%f\n" | sort -r | head -10
					
			fi
			
			print --cr
			print --info "Usage: update --rollback <backup-name>"
			return 1
			
		fi
		
		local backup_path="${BACKUP_DIR}/${backup_name}"
		
		if [[ ! -d "$backup_path" ]]; then				### Backup not found ###
			print --error "Backup not found: $backup_name"
			return 1
		fi
		
		print --warning "Rolling back to backup: $backup_name"
		
		### Confirm rollback ###
		if ! ask --confirm "rollback to backup $backup_name" "true"; then ### User cancelled ###
			print --info "Rollback cancelled"
			return 1
		fi
		
		### Restore files ###
		local restored_files=0
		local failed_restores=0
		
		find "$backup_path" -type f -name "*.sh" -o -name "*.conf" | while read -r backup_file; do
			
			local relative_path="${backup_file#${backup_path}/}"
			local target_file="${PROJECT_ROOT}/${relative_path}"
			local target_dir
			target_dir="$(dirname "$target_file")"
			
			### Create target directory ###
			mkdir -p "$target_dir" || {
				print --error "Failed to create directory: $target_dir"
				continue
			}
			
			### Restore file ###
			if cp "$backup_file" "$target_file"; then		### Restore successful ###
				
				### Set executable permissions for scripts ###
				[[ "$relative_path" =~ \.sh$ ]] && chmod +x "$target_file"
				
				print --info "Restored: $relative_path"
				((restored_files++))
				
			else						### Restore failed ###
				
				print --error "Failed to restore: $relative_path"
				((failed_restores++))
				
			fi
			
		done
		
		if [[ $failed_restores -eq 0 ]]; then				### Rollback successful ###
			
			print --success "Rollback completed successfully"
			print --info "Restored $restored_files files"
			log --info "Rollback completed: $backup_name"
			return 0
			
		else							### Rollback failed ###
			
			print --error "Rollback completed with $failed_restores errors"
			return 1
			
		fi
	}
	
	### Full update installation (internal) ###
	# shellcheck disable=SC2317,SC2329  # Function called conditionally within main function
	_install_update() {
		
		### Initialize update process ###
		print --header "Starting system update..."
		log --info "Update process started"
		
		### Create temporary directory ###
		if ! mkdir -p "$UPDATE_TMP_DIR"; then				### Temp dir creation failed ###
			print --error "Failed to create temporary directory"
			return 1
		fi
		
		### Create backup ###
		if ! _create_backup; then					### Backup failed ###
			print --error "Backup creation failed - aborting update"
			_cleanup
			return 1
		fi
		
		### Download manifest ###
		if ! _download_manifest; then					### Manifest download failed ###
			print --error "Failed to download update manifest"
			_cleanup
			return 1
		fi
		
		### Download checksums (optional) ###
		_download_checksums  # Non-critical
		
		### Process manifest and download files ###
		if ! _process_manifest; then					### Download failed ###
			
			if [[ "${force_update:-false}" == "true" ]]; then	### Force update ###
				print --warning "Some downloads failed, but continuing due to --force"
			else
				print --error "Download failures detected - aborting update"
				_cleanup
				return 1
			fi
			
		fi
		
		### Install files if not download ###
		if [[ "${download_updates_only:-false}" != "true" ]]; then	### Install files ###
			
			if ! _install_files; then				### Installation failed ###
				
				print --error "Installation failed - attempting rollback"
				_rollback_update "$(basename "$UPDATE_BACKUP_DIR")"
				_cleanup
				return 1
				
			fi
			
			print --success "Update completed successfully"
			print --info "Backup created at: $UPDATE_BACKUP_DIR"
			
		else							### Download only ###
			
			print --info "Download completed - files ready in: $UPDATE_TMP_DIR"
			print --info "Run 'update --install' to install"
			
		fi
		
		### Cleanup ###
		if [[ "${download_updates_only:-false}" != "true" ]]; then
			_cleanup
			_cleanup_old_backups
		fi
		
		log --info "Update process completed successfully"
		return 0
	}
	
	################################################################################
	### === MAIN UPDATE LOGIC === ###
	################################################################################
	
	### Parse Arguments ###
	while [[ $# -gt 0 ]]; do
		case $1 in
			--check|-c)
				_check_updates
				return $?
				;;
			
			--download|-d)
				download_updates_only="true"
				_install_update
				return $?
				;;
			
			--force|-f)
				force_update="true"
				;;
			
			--install|-i)
				_install_update
				return $?
				;;
			
			--rollback|-r)
				shift
				_rollback_update "$1"
				return $?
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
		shift
	done
	
	### Default action if no parameters ###
	_check_updates
}


################################################################################
### === MAIN EXECUTION === ###
################################################################################

### Main Function ###
main() {
	
	### Initialize logging ###
	log --init "${LOG_DIR}/${PROJECT_NAME:-update}.log" "${LOG_LEVEL:-INFO}"
	
	### Log startup ###
	log --info "${header} v${version} startup: $*"
	
	### Check if no arguments provided ###
	if [ $# -eq 0 ]; then
		
		show --header "${header} v${version}"
		print --info "Use --help for usage information"
		print --info "Use --check to check for updates"
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
	### Being sourced as library ###
	### Functions loaded and ready for use ###
	:
fi


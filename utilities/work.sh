#!/bin/bash
################################################################################
### Universal Helper Functions - 
### Loads Project Configuration Files with circular dependency Detection
### Provides comprehensive Configuration loading for bash Framework Projects
################################################################################
### Project: Universal Helper Library
### Version: 1.0.0
### Author:  Mawage (Development Team)
### Date:    2025-09-14
### License: MIT
### Usage:   Source this Function to load Project Configurations with Dependencies
### Commit:  Complete Configuration Loader with Dependency Tracking and Project Compliance"
################################################################################


################################################################################

path="/opt/helper"

curl -sSfL "$REPO_RAW_URL/start.sh" -o /opt/start.sh
curl -sSfL "$REPO_RAW_URL/scripts/helper.sh" -o "$path"/scripts/helper.sh



files=(cmd.sh log.sh print.sh secure.sh show.sh update.sh)

for file in "${files[@]}"; do
    curl -sSfL "$REPO_RAW_URL/scripts/plugins/$file" -o "$path/scripts/plugins/$file"
done

files=(gitclone.sh work.sh)

for file in "${files[@]}"; do
    curl -sSfL "$REPO_RAW_URL/utilities/$file" -o "$path/utilities/$file"
done


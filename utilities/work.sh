#!/bin/bash
################################################################################
### Universal Helper Functions - 
### Loads Project Configuration Files with circular dependency Detection
### Provides comprehensive Configuration loading for bash Framework Projects
################################################################################
### Project: Universal Helper Library
### Version: 1.0.9
### Author:  Mawage (Development Team)
### Date:    2025-09-16
### License: MIT
### Usage:   Source this Function to load Project Configurations with Dependencies
### Commit:  Complete Configuration Loader with Dependency Tracking and Project Compliance"
################################################################################


################################################################################

version=$(grep -oP '^### Version:\s*\K[0-9]+\.[0-9]+\.[0-9]+' ./helper/scripts/print.sh)
echo "Version: $version"


REPO_RAW_URL="https://raw.githubusercontent.com/Tabes/Helper/refs/heads/main"
path="/opt/helper"

echo
echo "Download URL: $REPO_RAW_URL"
echo "Target Path:  $path"
echo

curl -sSfL "$REPO_RAW_URL/start.sh" -o /opt/start.sh
curl -sSfL "$REPO_RAW_URL/scripts/helper.sh" -o "$path"/scripts/helper.sh



files=(cmd.sh log.sh print.sh secure.sh show.sh update.sh)
echo "Download...  ${files[*]}"; echo

for file in "${files[@]}"; do

    rm "$path/scripts/plugins/$file"
    curl -sSfL "$REPO_RAW_URL/scripts/plugins/$file" -o "$path/scripts/plugins/$file"
    chmod +x "$path/scripts/plugins/$file"

    printf "  %-20s v %s\n" "$file" "$(grep -oP '^### Version:\s*\K[0-9]+\.[0-9]+\.[0-9]+' "$path/scripts/plugins/$file")"
done
echo

files=(gitclone.sh work.sh)
echo "Download...  ${files[*]}"; echo

for file in "${files[@]}"; do

    rm "$path/utilities/$file"
    curl -sSfL "$REPO_RAW_URL/utilities/$file" -o "$path/utilities/$file"
    chmod +x "$path/utilities/$file"

    printf "  %-20s v %s\n" "$file" "$(grep -oP '^### Version:\s*\K[0-9]+\.[0-9]+\.[0-9]+' "$path/utilities/$file")"
done
echo

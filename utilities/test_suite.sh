#!/bin/bash
################################################################################
### Universal Helper Functions - Test Suite
### Comprehensive Testing Framework for Helper Library Functions
### Provides automated testing capabilities for all framework components
################################################################################
### Project: Universal Helper Library
### Version: 1.0.35
### Author:  Mawage (Development Team)
### Date:    2025-09-20
### License: MIT
### Usage:   Source this File to load Test Functions or run directly for Testing
### Commit:  Initial Test Suite with cursor_pos testing capabilities
################################################################################

# shellcheck disable=SC2015,SC2317,SC2329

################################################################################
### Parse Command Line Arguments ###
################################################################################

### Parse Command Line Arguments ###
parse_arguments() {
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

            test)
                shift
                test "$@"
                exit 0
                ;;

            *)
                ### Pass all other Arguments to main Processing ###
                shift
                return 0
                ;;

        esac

    done
}

################################################################################
### === TEST FRAMEWORK CORE === ###
################################################################################

### Test Framework Variables ###
test_count=0
pass_count=0
fail_count=0
current_suite=""

### Test helper functions ###
test_start() {
    # cursor_pos --set "${POS[P5]}"
    ((test_count++));   printf "${CY}%s %02d:${NC} %s" "Test" "$test_count" "$1"
}

test_pass() {
    cursor_pos --set "${POS[P6]}"
    ((pass_count++));   printf "${GN}%s${NC}\n" "pass"
}

test_fail() {
    cursor_pos --set "${POS[P6]}"
    ((fail_count++));   printf "${RD}FAIL${NC} - %s\n\n" "$1"
}

test_info() {
    printf "  ${YE}result:${NC} %s\n\n" "$1"
}

test_summary() {
    printf "\n"
    printf "Test Results Summary for %s:\n" "$current_suite"
    printf "================================\n"
    printf "Total Tests: %d\n" "$test_count"
    printf "${GN}Passed:      %d${NC}\n" "$pass_count"
    printf "${RD}Failed:      %d${NC}\n" "$fail_count"
    
    if [[ "$fail_count" -eq 0 ]]; then
        printf "\n${GN}All tests passed! %s function is working correctly.${NC}\n" "$current_suite"
        return 0
    else
        printf "\n${YE}Some tests failed. Check %s implementation.${NC}\n" "$current_suite"
        return 1
    fi
}

test_reset() {
    test_count=0;   pass_count=0;   fail_count=0
}

################################################################################
### === CURSOR_POS TEST SUITE === ###
################################################################################

### Test cursor_pos function with all parameter combinations ###
test_cursor_pos() {
    current_suite="cursor_pos"
    local cur_row=25
    test_reset
    
    printf "Testing this Function with all it's Parameter in Combinations...\n\n"

    ### Auto-load framework dependencies if not available ###
    if ! declare -f cursor_pos >/dev/null 2>&1; then
        printf "%s\n" "Loading framework dependencies..."
        
        ### Try to source helper.conf first ###
        local helper_conf_locations=(
            "/opt/helper/configs/helper.conf"
            "./configs/helper.conf"
            "../configs/helper.conf"
        )
        
        for conf_location in "${helper_conf_locations[@]}"; do
            if [[ -f "$conf_location" ]]; then
                # shellcheck source=/dev/null
                source "$conf_location"
                printf "  ✓ Loaded: %s\n" "$conf_location"
                break
            fi
        done
        
        ### Try to source helper.sh ###
        local helper_locations=(
            "/opt/helper/scripts/helper.sh"
            "./scripts/helper.sh"
            "../scripts/helper.sh"
        )
        
        for helper_location in "${helper_locations[@]}"; do
            if [[ -f "$helper_location" ]]; then
                # shellcheck source=/dev/null
                source "$helper_location"
                printf "  ✓ Loaded: %s\n" "$helper_location"
                break
            fi
        done
        
        printf "\n"
    fi

    ### Verify function exists ###
    if ! declare -f cursor_pos >/dev/null 2>&1; then
        printf "${RD}%s${NC}\n" "ERROR: cursor_pos function not found."
        printf "%s\n" "Please ensure helper.sh is sourced first."
        return 1
    fi

    ### Test 1: Basic --get functionality ###
    test_start "--get (basic position query)"
    result=$(cursor_pos --get)
    [[ $result =~ ^[0-9]+\ [0-9]+$ ]] && { test_pass; test_info "Current Position (Col / Row): $result"; } || test_fail "Invalid format: '$result'"


    ### Test 2: --get --col ###
    test_start "--get --col (Column only)"
    result=$(cursor_pos --get --col)
    [[ $result =~ ^[0-9]+$ ]] && { test_pass; test_info "Current Column: $result"; } || test_fail "Invalid format: '$result'"

    ### Test 3: --get --row ###
    test_start "--get --row (Row only)"
    result=$(cursor_pos --get --row)
    [[ $result =~ ^[0-9]+$ ]] && { test_pass; test_info "Current Row: $result"; } || test_fail "Invalid format: '$result'"

    ### Test 4: --get --col --row ###
    test_start "--get --col --row (both Values)"
    result=$(cursor_pos --get --col --row)
    [[ $result =~ ^[0-9]+\ [0-9]+$ ]] && { test_pass; test_info "Position: $result"; } || test_fail "Invalid format: '$result'"
    
    printf "\n--- Position Setting Tests ---\n\n"
    
    ### Test 5: --set absolute Column only ###
    test_start "--set ${POS[P6]} ${cur_row} (absolute Column, Col & Row)"
    cursor_pos --set "${POS[P6]}" "${cur_row}"; printf ">%s<" ">$SYMBOL_ERROR<"
    result=$(cursor_pos --get --col)
    echo "$result, ${POS[P6]}"

    # [[ $result == "${POS[P6]}" ]] && test_pass || test_fail "Expected ${POS[P6]}, got $result"

    return 0

    ### Test 6: --set absolute Column and Row ###
    test_start "--set ${POS[P4]} ${POS[P2]} (absolute Column & Row)"
    cursor_pos --set "${POS[P4]}" "${POS[P2]}"
    result=$(cursor_pos --get)
    [[ $result == "${POS[P4]} ${POS[P2]}" ]] && test_pass || test_fail "Expected '${POS[P4]} ${POS[P2]}', got '$result'"

    ### Test 7: --set relative column ###
    test_start "--set +5 (relative Column)"
    cursor_pos --set "${POS[P2]}"  # Set known Position first
    cursor_pos --set +5
    expected=$((POS[P2] + 5))
    result=$(cursor_pos --get --col)
    [[ $result == "$expected" ]] && test_pass || test_fail "Expected $expected, got $result"

    ### Test 8: --set relative Column and Row ###
    test_start "--set +3 -2 (relative column & row)"
    cursor_pos --set "${POS[P3]}" "${POS[P2]}"  # Set known Position
    cursor_pos --set +3 -2
    expected_col=$((POS[P3] + 3))
    expected_row=$((POS[P2] - 2))
    result=$(cursor_pos --get)
    [[ $result == "$expected_col $expected_row" ]] && test_pass || test_fail "Expected '$expected_col $expected_row', got '$result'"

    printf "\n--- Save/Restore Tests ---\n\n"
    
    ### Test 9: --Save functionality ###
    test_start "--save (save current Position)"
    cursor_pos --set "${POS[P5]}" "${POS[P3]}"
    cursor_pos --save
    [[ ${POS[col]} == ${POS[P5]} && ${POS[row]} == ${POS[P3]} ]] && test_pass || test_fail "POS Array not updated: col=${POS[col]}, row=${POS[row]}"

    ### Test 10: --restore Functionality ###
    test_start "--restore (restore saved Position)"
    cursor_pos --set "${POS[P6]}" "${POS[P4]}"  # Move somewhere else
    cursor_pos --restore    # Should go back to saved Position
    result=$(cursor_pos --get)
    [[ $result == "${POS[P5]} ${POS[P3]}" ]] && test_pass || test_fail "Expected '${POS[P5]} ${POS[P3]}', got '$result'"

    ### Test 11: --set with --save ###
    test_start "--set ${POS[P6]} ${POS[P4]} --save (set and save)"
    cursor_pos --set "${POS[P6]}" "${POS[P4]}" --save
    [[ ${POS[col]} == ${POS[P6]} && ${POS[row]} == ${POS[P4]} ]] && test_pass || test_fail "POS not saved: col=${POS[col]}, row=${POS[row]}"

    ### Test 12: --restore --set (combined) ###
    test_start "--restore --set +10 (restore then move)"
    cursor_pos --set "${POS[P2]}" "${POS[P2]}" --save  # Save known position
    cursor_pos --set "${POS[P6]}" "${POS[P6]}"         # Move elsewhere
    cursor_pos --restore --set +10                     # Should restore then move
    expected_col=$((POS[P2] + 10))
    result=$(cursor_pos --get)
    [[ $result == "$expected_col ${POS[P2]}" ]] && test_pass || test_fail "Expected '$expected_col ${POS[P2]}', got '$result'"

    printf "\n--- Error Handling Tests ---\n\n"
    
    ### Test 13: Invalid Parameters ###
    test_start "--set (no Parameters)"
    cursor_pos --set >/dev/null 2>&1
    ret_code=$?
    [[ $ret_code -ne 0 ]] && test_pass || test_fail "Should return Rrror for missing Parameters"

    ### Test 14: Invalid Numbers ###
    test_start "--set abc (invalid Number)"
    cursor_pos --set abc >/dev/null 2>&1
    ret_code=$?
    [[ $ret_code -ne 0 ]] && test_pass || test_fail "Should return Error for invalid Number"

    ### Test 15: Unknown Parameter ###
    test_start "--unknown (invalid Parameter)"
    cursor_pos --unknown >/dev/null 2>&1
    ret_code=$?
    [[ $ret_code -ne 0 ]] && test_pass || test_fail "Should return Error for unknown Parameter"

    printf "\n--- Bounds Testing ---\n\n"
    
    ### Test 16: Negative Bounds ###
    test_start "--set -5 -3 (negative Values)"
    cursor_pos --set -5 -3
    result=$(cursor_pos --get)
    [[ $result == "1 1" ]] && { test_pass; test_info "Correctly bounded to minimum Values"; } || test_fail "Expected '1 1', got '$result'"
    
    ### Test 17: Large bounds ###
    test_start "--set 300 250 (large Values)"
    cursor_pos --set 300 250
    result=$(cursor_pos --get)
    [[ $result == "200 200" ]] && { test_pass; test_info "Correctly bounded to maximum Values"; } || test_fail "Expected '200 200', got '$result'"

    ### Restore to a reasonable Position ###
    cursor_pos --set 1 $((test_count + 10))
    
    test_summary
}

################################################################################
### === MAIN TEST FUNCTION === ###
################################################################################

### Universal Test Function ###
test() {
    ### Parse Arguments ###
    local test_suite=""
    local test_mode="auto"
    local verbose=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --cursor_pos)
                test_suite="cursor_pos"
                shift
                ;;
            --auto)
                test_mode="auto"
                shift
                ;;
            --interactive)
                test_mode="interactive"
                shift
                ;;
            --verbose|-v)
                verbose=true
                shift
                ;;
            --help|-h)
                printf "Usage: test [--test_suite] [--mode] [options]\n"
                printf "\nTest Suites:\n"
                printf "  --cursor_pos    Test cursor positioning functions\n"
                printf "\nModes:\n"
                printf "  --auto          Run automated tests (default)\n"
                printf "  --interactive   Run interactive tests\n"
                printf "\nOptions:\n"
                printf "  --verbose|-v    Show detailed output\n"
                printf "  --help|-h       Show this help\n"
                return 0
                ;;
            *)
                printf "${RD}ERROR: Unknown parameter: $1${NC}\n"
                return 1
                ;;
        esac
    done
    
    ### Validate test suite ###
    if [[ -z "$test_suite" ]]; then
        printf "${RD}ERROR: No test suite specified${NC}\n"
        printf "Use --help to see available test suites\n"
        return 1
    fi
    
    ### Clear screen and show header ###
    clear
    printf "${BU}%s${NC}\n" "Universal Helper Library - Test Suite"
    printf "────────────────────────────────────────────────────────────────────\n\n"
    printf "Suite: %s | Mode: %s\n\n" "$test_suite" "$test_mode"
    
    ### Execute test suite ###
    case "$test_suite" in
        cursor_pos)
            if [[ "$test_mode" == "auto" ]]; then
                test_cursor_pos
            else
                printf "\n${YE}%s${NC}\n\n" "Interactive mode not yet implemented for cursor_pos()"
                return 1
            fi
            ;;

        *)
            printf "${RD}%s$test_suite${NC}\n" "ERROR: Unknown Funcrion for Test Suite: "
            return 1
            ;;

    esac
}

################################################################################
### === MAIN EXECUTION === ###
################################################################################

### Main Function ###
main() {
    ### Check if no arguments provided ###
    if [ $# -eq 0 ]; then
        printf "${BU}Universal Helper Library - Test Suite${NC}\n"
        printf "====================================\n\n"
        printf "Usage: %s test [options]\n\n" "$0"
        printf "Available commands:\n"
        printf "  test --cursor_pos --auto    Run cursor positioning tests\n"
        printf "  test --help                 Show detailed help\n\n"
        printf "Example:\n"
        printf "  %s test --cursor_pos --auto\n\n" "$0"
        exit 0
    else
        ### Parse and execute arguments ###
        parse_arguments "$@"
        
        ### If Arguments remain, pass them to test Function ###
        if [ $# -gt 0 ]; then
            test "$@"
        fi
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
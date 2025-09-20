#!/bin/bash
################################################################################
### Universal Helper Functions - Test Suite
### Comprehensive Testing Framework for Helper Library Functions
### Provides automated testing capabilities for all framework components
################################################################################
### Project: Universal Helper Library
### Version: 1.0.9
### Author:  Mawage (Development Team)
### Date:    2025-09-20
### License: MIT
### Usage:   Source this File to load Test Functions or run directly for Testing
### Commit:  Initial Test Suite with cursor_pos testing capabilities
################################################################################

# shellcheck disable=SC2317,SC2329

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
    local pos="$(cursor_pos --set)"
    ((test_count++));   printf "${CY}%s %02d:${NC} %-${pos}s " "Test" "$test_count" "$1"
}

test_pass() {
    cursor_pos --set "${POS[P5]}"
    ((pass_count++));   printf "${GN}%s${NC}\n" "pass"
}

test_fail() {
    ((fail_count++))
    printf "${RD}FAIL${NC} - %s\n" "$1"
}

test_info() {
    printf "${YE}INFO:${NC} %s\n" "$1"
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
    test_count=0
    pass_count=0
    fail_count=0
}

################################################################################
### === CURSOR_POS TEST SUITE === ###
################################################################################

### Test cursor_pos function with all parameter combinations ###
test_cursor_pos() {
    current_suite="cursor_pos"
    test_reset
    
    printf "\nTesting cursor_pos() Function with all Parameter Combinations...\n\n"

    ### Auto-load framework dependencies if not available ###
    if ! declare -f cursor_pos >/dev/null 2>&1; then
        printf "Loading framework dependencies...\n"
        
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
        printf "${RD}ERROR: cursor_pos function not found.${NC}\n"
        printf "Please ensure helper.sh is sourced first.\n"
        return 1
    fi
    
    ### Test 1: Basic --get functionality ###
    test_start "--get (Basic Position Query)"
    result=$(cursor_pos --get)
    if [[ "$result" =~ ^[0-9]+\ [0-9]+$ ]]; then
        test_pass
        test_info "Current position: $result"
    else
        test_fail "Invalid format: '$result'"
    fi

    [[ $result =~ ^[0-9]+\ [0-9]+$ ]] && { test_pass; test_info "Current Position (Col / Row): $result"; } || test_fail "Invalid format: '$result'"


    return 0

    ### Test 2: --get --col ###
    test_start "--get --col (column only)"
    result=$(cursor_pos --get --col)
    if [[ "$result" =~ ^[0-9]+$ ]]; then
        test_pass
        test_info "Current column: $result"
    else
        test_fail "Invalid format: '$result'"
    fi
    
    ### Test 3: --get --row ###
    test_start "--get --row (row only)"
    result=$(cursor_pos --get --row)
    if [[ "$result" =~ ^[0-9]+$ ]]; then
        test_pass
        test_info "Current row: $result"
    else
        test_fail "Invalid format: '$result'"
    fi
    
    ### Test 4: --get --col --row ###
    test_start "--get --col --row (both values)"
    result=$(cursor_pos --get --col --row)
    if [[ "$result" =~ ^[0-9]+\ [0-9]+$ ]]; then
        test_pass
        test_info "Position: $result"
    else
        test_fail "Invalid format: '$result'"
    fi
    
    printf "\n--- Position Setting Tests ---\n\n"
    
    ### Test 5: --set absolute column only ###
    test_start "--set ${POS[P3]} (absolute column)"
    cursor_pos --set "${POS[P3]}"
    result=$(cursor_pos --get --col)
    if [[ "$result" == "${POS[P3]}" ]]; then
        test_pass
    else
        test_fail "Expected ${POS[P3]}, got $result"
    fi
    
    ### Test 6: --set absolute column and row ###
    test_start "--set ${POS[P4]} ${POS[P2]} (absolute column & row)"
    cursor_pos --set "${POS[P4]}" "${POS[P2]}"
    result=$(cursor_pos --get)
    if [[ "$result" == "${POS[P4]} ${POS[P2]}" ]]; then
        test_pass
    else
        test_fail "Expected '${POS[P4]} ${POS[P2]}', got '$result'"
    fi
    
    ### Test 7: --set relative column ###
    test_start "--set +5 (relative column)"
    cursor_pos --set "${POS[P2]}"  # Set known position first
    cursor_pos --set +5
    expected=$((POS[P2] + 5))
    result=$(cursor_pos --get --col)
    if [[ "$result" == "$expected" ]]; then
        test_pass
    else
        test_fail "Expected $expected, got $result"
    fi
    
    ### Test 8: --set relative column and row ###
    test_start "--set +3 -2 (relative column & row)"
    cursor_pos --set "${POS[P3]}" "${POS[P2]}"  # Set known position
    cursor_pos --set +3 -2
    expected_col=$((POS[P3] + 3))
    expected_row=$((POS[P2] - 2))
    result=$(cursor_pos --get)
    if [[ "$result" == "$expected_col $expected_row" ]]; then
        test_pass
    else
        test_fail "Expected '$expected_col $expected_row', got '$result'"
    fi
    
    printf "\n--- Save/Restore Tests ---\n\n"
    
    ### Test 9: --save functionality ###
    test_start "--save (save current position)"
    cursor_pos --set "${POS[P5]}" "${POS[P3]}"
    cursor_pos --save
    if [[ "${POS[col]}" == "${POS[P5]}" && "${POS[row]}" == "${POS[P3]}" ]]; then
        test_pass
    else
        test_fail "POS array not updated: col=${POS[col]}, row=${POS[row]}"
    fi
    
    ### Test 10: --restore functionality ###
    test_start "--restore (restore saved position)"
    cursor_pos --set "${POS[P6]}" "${POS[P4]}"  # Move somewhere else
    cursor_pos --restore    # Should go back to saved position
    result=$(cursor_pos --get)
    if [[ "$result" == "${POS[P5]} ${POS[P3]}" ]]; then
        test_pass
    else
        test_fail "Expected '${POS[P5]} ${POS[P3]}', got '$result'"
    fi
    
    ### Test 11: --set with --save ###
    test_start "--set ${POS[P6]} ${POS[P4]} --save (set and save)"
    cursor_pos --set "${POS[P6]}" "${POS[P4]}" --save
    if [[ "${POS[col]}" == "${POS[P6]}" && "${POS[row]}" == "${POS[P4]}" ]]; then
        test_pass
    else
        test_fail "POS not saved: col=${POS[col]}, row=${POS[row]}"
    fi
    
    ### Test 12: --restore --set (combined) ###
    test_start "--restore --set +10 (restore then move)"
    cursor_pos --set "${POS[P2]}" "${POS[P2]}" --save  # Save known position
    cursor_pos --set "${POS[P6]}" "${POS[P6]}"         # Move elsewhere
    cursor_pos --restore --set +10                     # Should restore then move
    expected_col=$((POS[P2] + 10))
    result=$(cursor_pos --get)
    if [[ "$result" == "$expected_col ${POS[P2]}" ]]; then
        test_pass
    else
        test_fail "Expected '$expected_col ${POS[P2]}', got '$result'"
    fi
    
    printf "\n--- Error Handling Tests ---\n\n"
    
    ### Test 13: Invalid parameters ###
    test_start "--set (no parameters)"
    cursor_pos --set >/dev/null 2>&1
    ret_code=$?
    if [[ "$ret_code" -ne 0 ]]; then
        test_pass
    else
        test_fail "Should return error for missing parameters"
    fi
    
    ### Test 14: Invalid numbers ###
    test_start "--set abc (invalid number)"
    cursor_pos --set abc >/dev/null 2>&1
    ret_code=$?
    if [[ "$ret_code" -ne 0 ]]; then
        test_pass
    else
        test_fail "Should return error for invalid number"
    fi
    
    ### Test 15: Unknown parameter ###
    test_start "--unknown (invalid parameter)"
    cursor_pos --unknown >/dev/null 2>&1
    ret_code=$?
    if [[ "$ret_code" -ne 0 ]]; then
        test_pass
    else
        test_fail "Should return error for unknown parameter"
    fi
    
    printf "\n--- Bounds Testing ---\n\n"
    
    ### Test 16: Negative bounds ###
    test_start "--set -5 -3 (negative values)"
    cursor_pos --set -5 -3
    result=$(cursor_pos --get)
    if [[ "$result" == "1 1" ]]; then
        test_pass
        test_info "Correctly bounded to minimum values"
    else
        test_fail "Expected '1 1', got '$result'"
    fi
    
    ### Test 17: Large bounds ###
    test_start "--set 300 250 (large values)"
    cursor_pos --set 300 250
    result=$(cursor_pos --get)
    if [[ "$result" == "200 200" ]]; then
        test_pass
        test_info "Correctly bounded to maximum values"
    else
        test_fail "Expected '200 200', got '$result'"
    fi
    
    ### Restore to a reasonable position ###
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
    printf "${BU}Universal Helper Library - Test Suite${NC}\n"
    printf "────────────────────────────────────────────────────────────────────\n\n"
    printf "Suite: %s | Mode: %s\n\n" "$test_suite" "$test_mode"
    
    return 0
    ### Execute test suite ###
    case "$test_suite" in
        cursor_pos)
            if [[ "$test_mode" == "auto" ]]; then
                test_cursor_pos
            else
                printf "\n${YE}Interactive mode not yet implemented for cursor_pos()${NC}\n\n"
                return 1
            fi
            ;;
        *)
            printf "${RD}ERROR: Unknown Funcrion for Test Suite: $test_suite${NC}\n"
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
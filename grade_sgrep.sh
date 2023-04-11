#!/bin/bash

# Safer execution
# -e: exit immediately if a command fails
# -E: Safer -e option for traps
# -u: fail if a variable is used unset
# -o pipefail: exit immediately if command in a pipe fails
#set -eEuo pipefail
# -x: print each command before executing (great for debugging)
#set -x

# Convenient values
SCRIPT_NAME=$(basename $BASH_SOURCE)

# Default program values
EXEC="${PWD}/sgrep"
TEST_CASE="all"

#
# Logging helpers
#
log() {
    echo -e "${*}"
}
info() {
    log "Info: ${*}"
}
warning() {
    log "Warning: ${*}"
}
error() {
    log "Error: ${*}"
}
die() {
    error "${*}"
    exit 1
}

#
# Line comparison
#
select_line() {
    # 1: string
    # 2: line to select
    echo "$(echo "${1}" | sed "${2}q;d")"
}

fail() {
    # 1: got
    # 2: expected
    log "Fail: got '${1}' but expected '${2}'"
}

pass() {
    # got
    log "Pass: ${1}"
}

compare_lines() {
    # 1: output
    # 2: expected
    # 3: score (output)
    declare -a output_lines=("${!1}")
    declare -a expect_lines=("${!2}")
    local __score=$3
    local partial="0"

    # Amount of partial credit for each correct output line
    local step=$(bc -l <<< "1.0 / ${#expect_lines[@]}")

    # Compare lines, two by two
    for i in ${!output_lines[*]}; do
        if [[ "${output_lines[${i}]}" == "${expect_lines[${i}]}" ]]; then
            pass "${output_lines[${i}]}"
            partial=$(bc <<< "${partial} + ${step}")
        else
            fail "${output_lines[${i}]}" "${expect_lines[${i}]}" ]]
        fi
    done

    # Return final score
    eval ${__score}="'${partial}'"
}

#
# Run generic test case
#
run_test_case () {
    # 1: program arguments
    local _args=("${@}")
    local args="${_args[@]}"

    # These are global variables after the test has run so clear them out now
    unset STDOUT STDERR RET

    # Create temp files for getting stdout and stderr
    local outfile=$(mktemp)
    local errfile=$(mktemp)

    bash -c "${EXEC} ${args[@]}" >${outfile} 2>${errfile}

    # Get the return status, stdout and stderr of the test case
    RET="${?}"
    STDOUT=$(cat "${outfile}")
    STDERR=$(cat "${errfile}")

    # Clean up temp files
    rm -f "${outfile}"
    rm -f "${errfile}"
}

#
# Test cases
#
TEST_CASES=()

## One pattern
TEST_CASES+=("one_pattern")
one_pattern() {
    log "--- Running test case: ${FUNCNAME} ---"
    run_test_case "-p" "education" "../udhr_art26.txt"

    local line_array=()
    line_array+=("$(select_line "${STDOUT}" "1")")
    line_array+=("$(select_line "${STDOUT}" "2")")
    line_array+=("$(select_line "${STDOUT}" "4")")
    line_array+=("$(select_line "${STDOUT}" "5")")
    local corr_array=()
    corr_array+=("(1) Everyone has the right to education. Education shall be")
    corr_array+=("Elementary education shall be compulsory.  Technical and")
    corr_array+=("higher education shall be equally accessible to all on the")
    corr_array+=("education that shall be given to their children.")

    local score
    compare_lines line_array[@] corr_array[@] score
    log "${score}"
}

## Line numbering
TEST_CASES+=("line_numbering")
line_numbering() {
    log "--- Running test case: ${FUNCNAME} ---"
    run_test_case "-n" "-p" "education" "../udhr_art26.txt"

    local line_array=()
    line_array+=("$(select_line "${STDOUT}" "1")")
    line_array+=("$(select_line "${STDOUT}" "2")")
    line_array+=("$(select_line "${STDOUT}" "4")")
    line_array+=("$(select_line "${STDOUT}" "5")")
    local corr_array=()
    corr_array+=("1: (1) Everyone has the right to education. Education shall be")
    corr_array+=("3: Elementary education shall be compulsory.  Technical and")
    corr_array+=("5: higher education shall be equally accessible to all on the")
    corr_array+=("14: education that shall be given to their children.")

    local score
    compare_lines line_array[@] corr_array[@] score
    log "${score}"
}

## Coloring
TEST_CASES+=("coloring")
coloring() {
    log "--- Running test case: ${FUNCNAME} ---"
    run_test_case "-c" "-p" "education" "../udhr_art26.txt"

    local line_array=()
    line_array+=("$(select_line "${STDOUT}" "1")")
    line_array+=("$(select_line "${STDOUT}" "2")")
    line_array+=("$(select_line "${STDOUT}" "4")")
    line_array+=("$(select_line "${STDOUT}" "5")")
    local corr_array=()
    corr_array+=("(1) Everyone has the right to [0;31meducation[0;0m. Education shall be")
    corr_array+=("Elementary [0;31meducation[0;0m shall be compulsory.  Technical and")
    corr_array+=("higher [0;31meducation[0;0m shall be equally accessible to all on the")
    corr_array+=("[0;31meducation[0;0m that shall be given to their children.")

    local score
    compare_lines line_array[@] corr_array[@] score
    log "${score}"
}

## Multiple files and all options
TEST_CASES+=("multifiles")
multifiles() {
    log "--- Running test case: ${FUNCNAME} ---"
    run_test_case "-n" "-c" "-p" "Everyone" "../udhr_art26.txt" "../udhr.txt"

    local line_array=()
    line_array+=("$(select_line "${STDOUT}" "1")")
    line_array+=("$(select_line "${STDOUT}" "2")")
    line_array+=("$(select_line "${STDOUT}" "7")")
    line_array+=("$(select_line "${STDOUT}" "8")")
    local corr_array=()
    corr_array+=("1: (1) [0;31mEveryone[0;0m has the right to education. Education shall be")
    corr_array+=("55: [0;31mEveryone[0;0m is entitled to all the rights and freedoms set forth in this")
    corr_array+=("107: (1) [0;31mEveryone[0;0m charged with a penal offence has the right to be presumed innocent")
    corr_array+=("120: home or correspondence, nor to attacks upon his honour and reputation. [0;31mEveryone[0;0m")

    local score
    compare_lines line_array[@] corr_array[@] score
    log "${score}"
}

## Multiple patterns, files and all options
TEST_CASES+=("multipatterns")
multipatterns() {
    log "--- Running test case: ${FUNCNAME} ---"
    run_test_case "-n" "-c" "-p" "Everyone" "-p" "education" "../udhr_art26.txt" "../udhr.txt"

    local line_array=()
    line_array+=("$(select_line "${STDOUT}" "1")")
    line_array+=("$(select_line "${STDOUT}" "2")")
    line_array+=("$(select_line "${STDOUT}" "36")")
    line_array+=("$(select_line "${STDOUT}" "40")")
    local corr_array=()
    corr_array+=("1: (1) [0;31mEveryone[0;0m has the right to education. Education shall be")
    corr_array+=("1: (1) Everyone has the right to [0;31meducation[0;0m. Education shall be")
    corr_array+=("242: higher [0;31meducation[0;0m shall be equally accessible to all on the basis of merit.")
    corr_array+=("265: [0;31mEveryone[0;0m is entitled to a social and international order in which the rights and")

    local score
    compare_lines line_array[@] corr_array[@] score
    log "${score}"
}

#
# Main functions
#
parse_argvs() {
    local OPTIND opt

    while getopts "h?s:t:" opt; do
        case "$opt" in
        h|\?)
            echo "${SCRIPT_NAME}: [-s <exec_path>] [-t <test_case>]" 1>&2
            exit 0
            ;;
        s)  EXEC="$(readlink -f ${OPTARG})"
            ;;
        t)  TEST_CASE="${OPTARG}"
            ;;
        esac
    done
}

check_vals() {
    # Check sshell path
    [[ -x ${EXEC} ]] || \
        die "Cannot find executable '${EXEC}'"

    # Check test case
    [[ " ${TEST_CASES[@]} all " =~ " ${TEST_CASE} " ]] || \
        die "Cannot find test case '${TEST_CASE}'"
}

grade() {
    # Make testing directory
    local tmpdir=$(mktemp -d --tmpdir=.)
    cd ${tmpdir}

    # Run test case(s)
    if [[ "${TEST_CASE}" == "all" ]]; then
        # Run all test cases
        for t in "${TEST_CASES[@]}"; do
            ${t}
            log "\n"
        done
    else
        # Run specific test case
        ${TEST_CASE}
    fi

    # Cleanup testing directory
    cd ..
    rm -rf "${tmpdir}"
}

parse_argvs "$@"
check_vals
grade

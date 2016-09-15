#!/bin/bash

# Script for running all integration tests.  The first argument is a path to a file containing LSF options specific to the system that the test is being run on
DATETIME=`date +%Y%m%d_%H%M%S`
FILE_LSF_COMMON=$(readlink -e "$1")
TEST_OUTPUT_LOG=$(pwd)/integration_test_run.log
DIR_ORIGIN=$(pwd)

# Check if the last line of the log corresponds to all tests passing
function check_success {
  local last=$(tail -n1 "$1")
  local start="all "  
  local middle=" tests passed in "
  if [[ "$last" == "$start"*"$middle"* ]]; then
    echo "All tests passed in: ""$2"
    echo "$last"
  else
    echo " - FAILED tests in: ""$2"
    echo "$last"
  fi
}

function run_test {
  echo "Running: ""$1" "$FILE_LSF_COMMON"
  cd $(dirname "$1")
  bash $(basename "$1") "$FILE_LSF_COMMON" >>"$TEST_OUTPUT_LOG" 2>&1
  check_success "$TEST_OUTPUT_LOG" "$1"
  cd "$DIR_ORIGIN"
}

# Clear log file
echo "Running all integration tests and writing output and errors to log file: ""$TEST_OUTPUT_LOG"
echo "Using local LSF options from: ""$FILE_LSF_COMMON"
echo "Runnign integration tests on ""$DATETIME" > "$TEST_OUTPUT_LOG"

run_test basic/it_basic.sh
run_test basic/it_basic_zip.sh
run_test basic/it_basic_unzip.sh

run_test fvars/it_fvars.sh
run_test fvars/it_fvars_prefixes.sh

run_test vars_fvars/it_fvars_vars.sh

run_test jgroup/it_jgroup.sh.sh

# EOF

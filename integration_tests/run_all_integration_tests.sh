#!/bin/bash

# Script for running all integration tests.  The first argument is a path to a file containing LSF options specific to the system that the test is being run on
DATETIME=`date +%Y%m%d_%H%M%S`
FILE_LSF_COMMON=$(readlink -e "$1")
TEST_OUTPUT_LOG=integration_test_run.log

# Clear log file
echo "Runnign integration tests on ""$DATETIME" > "$TEST_OUTPUT_LOG"

## Tests in the basic directory
cd basic
echo "In directory: "$(pwd)
echo "Running: "bash it_basic.sh "$FILE_LSF_COMMON"
bash it_basic.sh "$FILE_LSF_COMMON" >> "$TEST_OUTPUT_LOG"
bash it_basic_zip.sh "$FILE_LSF_COMMON" >> "$TEST_OUTPUT_LOG"
bash it_basic_unzip.sh "$FILE_LSF_COMMON" >> "$TEST_OUTPUT_LOG"
cd ..

## Run tests in fvars directory
cd fvars
echo "In directory: "$(pwd)
bash it_fvars.sh >> "$TEST_OUTPUT_LOG"
bash it_fvars_prefixes.sh >> "$TEST_OUTPUT_LOG"
cd ..

## Read log and check for failures

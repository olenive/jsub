#!/bin/bash
set -e

# Unit tests for bash functions using the lehmannro/assert.sh framework
. assert.sh
echo ""
echo "Running unit tests of bash functions..."

### FUNCTIONS ###
function file_exists {
  if [ -f "$1" ]; then echo "yes"; else echo "no"; fi
}
#################

## EXAMPLES ##
# assert "echo test" "test"
# # `seq 3` is expected to print "1", "2" and "3" on different lines
# assert "seq 3" "1\n2\n3"
# # exit code of `true` is expected to be 0
# assert_raises "true"
# # exit code of `false` is expected to be 1
# assert_raises "false" 1
# # expect `exit 127` to terminate with code 128
# assert_raises "exit 127" 128
##############

#### Unit tests for the job_processing function ####
## A successful job that leaves no summary.incomplete file
# Declare paths to mock files and test output files
DIR_EXPECTEDS="bash_function_test_files/job_mocks"
FILE_EXPECTED_LOG=${DIR_EXPECTEDS}/"ut_job_processing_01.log"
FILE_EXPECTED_COMPLETED=${DIR_EXPECTEDS}/"ut_job_processing_01.summary.completed"
FILE_EXPECTED_INCOMPLETE=${DIR_EXPECTEDS}/"ut_job_processing_01.summary.incomplete"
DIR_OUT="bash_function_test_files/test_outputs/job_processing"
FILE_TEST_JOB=${DIR_OUT}/"ut_job_processing_01.lsf"
FILE_LOG=${DIR_OUT}/"test_01.log"
FILE_COMPLETED=${DIR_OUT}/"summary_01.completed"
FILE_INCOMPLETE=${DIR_OUT}/"summary_01.incomplete"
# Remove output files produced by previous test runs
rm -f ${FILE_TEST_JOB} ${FILE_LOG} ${FILE_COMPLETED} ${FILE_INCOMPLETE}
# Concatenate test job file header, job_processing function and tail.
cat ${DIR_EXPECTEDS}/"ut_job_processing_head.sh" \
  "../../common_functions/job_processing.sh" \
  ${DIR_EXPECTEDS}/"ut_job_processing_tail_01.sh" > ${FILE_TEST_JOB}
# Run the test file and check that output files contain expected results.
bash ${FILE_TEST_JOB} ${FILE_LOG} ${FILE_COMPLETED} ${FILE_INCOMPLETE}
assert "file_exists ${FILE_LOG}" "yes"
assert "file_exists ${FILE_EXPECTED_LOG}" "yes"
assert "diff ${FILE_LOG} ${FILE_EXPECTED_LOG}" ""
assert "file_exists ${FILE_COMPLETED}" "yes"
assert "file_exists ${FILE_EXPECTED_COMPLETED}" "yes"
assert "diff ${FILE_COMPLETED} ${FILE_EXPECTED_COMPLETED}" ""
assert "file_exists ${FILE_INCOMPLETE}" "no" # assert $(diff ${FILE_INCOMPLETE} ${FILE_EXPECTED_INCOMPLETE}) "" # The incomplete file should not exist for this example

## A job that is terminated in the middle leaving a summary.incomplete file
# Declare paths to mock files and test output files
DIR_EXPECTEDS="bash_function_test_files/job_mocks"
FILE_EXPECTED_LOG=${DIR_EXPECTEDS}/"ut_job_processing_02.log"
FILE_EXPECTED_COMPLETED=${DIR_EXPECTEDS}/"ut_job_processing_02.summary.completed"
FILE_EXPECTED_INCOMPLETE=${DIR_EXPECTEDS}/"ut_job_processing_02.summary.incomplete"
DIR_OUT="bash_function_test_files/test_outputs/job_processing"
FILE_TEST_JOB=${DIR_OUT}/"ut_job_processing_02.lsf"
FILE_LOG=${DIR_OUT}/"test_02.log"
FILE_COMPLETED=${DIR_OUT}/"summary_02.completed"
FILE_INCOMPLETE=${DIR_OUT}/"summary_02.incomplete"
# Remove output files produced by previous test runs
rm -f ${FILE_TEST_JOB} ${FILE_LOG} ${FILE_COMPLETED} ${FILE_INCOMPLETE}
# Concatenate test job file header, job_processing function and tail.
cat ${DIR_EXPECTEDS}/"ut_job_processing_head.sh" \
  "../../common_functions/job_processing.sh" \
  ${DIR_EXPECTEDS}/"ut_job_processing_tail_02.sh" > ${FILE_TEST_JOB}
# Run the test file and check that output files contain expected results.
bash ${FILE_TEST_JOB} ${FILE_LOG} ${FILE_COMPLETED} ${FILE_INCOMPLETE}
assert "file_exists ${FILE_LOG}" "yes"
assert "file_exists ${FILE_EXPECTED_LOG}" "yes"
assert "diff ${FILE_LOG} ${FILE_EXPECTED_LOG}" ""
assert "file_exists ${FILE_COMPLETED}" "yes"
assert "file_exists ${FILE_EXPECTED_COMPLETED}" "yes"
assert "diff ${FILE_COMPLETED} ${FILE_EXPECTED_COMPLETED}" ""
assert "file_exists ${FILE_INCOMPLETE}" "yes" # assert $(diff ${FILE_INCOMPLETE} ${FILE_EXPECTED_INCOMPLETE}) "" # The incomplete file should not exist for this example
####################################################

## Unit tests for functions from the submit_lsf_jobs.sh files
# Include functions form the job submission script
source "../../common_functions/job_submission_functions.sh"
## isAbsolutePath
assert "isAbsolutePath /hello/abs" "absolute"
assert "isAbsolutePath hello/rel" "relative"
## checkForDuplicateLines "path to file" "suppress warnings" "strict"
assert "checkForDuplicateLines ../data/list_without_duplicate_lines.txt true false" ""
assert "checkForDuplicateLines ../data/list_without_duplicate_lines.txt false false" "Checking for duplicates in  ../data/list_without_duplicate_lines.txt"
assert "checkForDuplicateLines ../data/list_with_duplicate_lines.txt false false" "Checking for duplicates in  ../data/list_with_duplicate_lines.txt\nWARNING (in checkForDuplicateLines): Found duplicate entries in list of job files to be submitted:\n   4 \n   2 this is the second line\n   3 this is the third line"
assert "checkForDuplicateLines ../data/list_with_duplicate_lines.txt true false" ""
assert "checkForDuplicateLines ../data/list_with_duplicate_lines.txt true true" "TERMINATING (in checkForDuplicateLines) after finding duplicate entries in list of job files to be submitted:\n   4 \n   2 this is the second line\n   3 this is the third line"
## linePresentInFile "path to file" "text string"
assert "isLineInFile '../data/list_with_duplicate_lines.txt' ''" "yes"
assert "isLineInFile '../data/list_with_duplicate_lines.txt' '    '" "no"
assert "isLineInFile '../data/list_with_duplicate_lines.txt' 'asdf'" "no"
assert "isLineInFile '../data/list_with_duplicate_lines.txt' 'asdf VS this is the first line'\n'asdf VS this is the second line'" "no"
assert "isLineInFile '../data/list_with_duplicate_lines.txt' 'this is the second line'" "yes"

# end of test suite
assert_end

echo ""
# EOF

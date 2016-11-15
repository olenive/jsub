#!/bin/bash
# set -e

# Unit tests for bash functions using the lehmannro/assert.sh framework
. assert.sh
echo ""
echo "Running unit tests of bash functions..."

### FUNCTIONS ###
function file_exists {
  if [ -f "$1" ]; then echo "yes"; else echo "no"; fi
}
function compare_contents { # Calls diff but if one of the input files does not exit returns an error string
  if ! [ -f "$1" ] || ! [ -f "$2" ] ; then
    ! [ -f "$1" ] && echo "Failed contents comparison due to missing file: $1"
    ! [ -f "$2" ] && echo "Failed contents comparison due to missing file: $2"
  else # pass remaining arguments as options to diff
    diff "$1" "$2" "${@:3}"
  fi
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

#### Unit tests for the process_job function ####
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
assert "compare_contents ${FILE_LOG} ${FILE_EXPECTED_LOG}" ""
assert "file_exists ${FILE_COMPLETED}" "yes"
assert "file_exists ${FILE_EXPECTED_COMPLETED}" "yes"
assert "compare_contents ${FILE_COMPLETED} ${FILE_EXPECTED_COMPLETED}" ""
assert "file_exists ${FILE_INCOMPLETE}" "no" # assert $(diff ${FILE_INCOMPLETE} ${FILE_EXPECTED_INCOMPLETE}) "" # The incomplete file should not exist for this example
# 7
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
assert "compare_contents ${FILE_LOG} ${FILE_EXPECTED_LOG}" ""
assert "file_exists ${FILE_COMPLETED}" "yes"
assert "file_exists ${FILE_EXPECTED_COMPLETED}" "yes"
assert "compare_contents ${FILE_COMPLETED} ${FILE_EXPECTED_COMPLETED}" ""
assert "file_exists ${FILE_INCOMPLETE}" "yes" # assert $(diff ${FILE_INCOMPLETE} ${FILE_EXPECTED_INCOMPLETE}) "" # The incomplete file should not exist for this example
# 14
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
# 26
## Unit tests for checkpoint functions
source "../../common_functions/jcheck_file_not_empty.sh"
NON_EXISTANT_FILE="path/to/non/existant/file"
EMPTY_FILE="bash_function_test_files/empty_file"
WHITESPACE_FILE="bash_function_test_files/jcheck_file_not_empty/whitespace_only.txt"
NONWHITESPACE_FILE="bash_function_test_files/jcheck_file_not_empty/non_whitespace.txt"
EXPECTED_EMPTY_FAIL="bash_function_test_files/jcheck_file_not_empty/expected_empty_fail.log"
EXPECTED_WHITESPACE_FAIL="bash_function_test_files/jcheck_file_not_empty/expected_whitespace_fail.log"
EXPECTED_SUCCESS="bash_function_test_files/jcheck_file_not_empty/expected_success.log"
EXPECTED_MULTIPLE="bash_function_test_files/jcheck_file_not_empty/expected_multiple.log"
JSUB_JOB_TIMESTAMP=false
JSUB_JOB_ID="jcheck_file_not_empty_jobID"
JSUB_LOG_FILE="bash_function_test_files/test_outputs/jcheck_file_not_empty/checkpoint.log"
assert "file_exists ${NON_EXISTANT_FILE}" "no"
assert "file_exists ${EMPTY_FILE}" "yes"
assert "file_contains_nonwhitespace ${WHITESPACE_FILE}" "no"
assert "file_contains_nonwhitespace ${NONWHITESPACE_FILE}" "yes"
rm "$JSUB_LOG_FILE" # Clear log file
assert "file_exists ${JSUB_LOG_FILE}" "no"
assert "jcheck_file_not_empty ${EMPTY_FILE}" " jcheck_file_not_empty_jobID - Failed checkpoint jcheck_file_not_empty due to empty (or whitespace) file: ""$EMPTY_FILE"
assert "compare_contents ${JSUB_LOG_FILE} ${EXPECTED_EMPTY_FAIL}" ""
rm "$JSUB_LOG_FILE" # Clear log file
assert "file_exists ${JSUB_LOG_FILE}" "no"
assert "jcheck_file_not_empty ${WHITESPACE_FILE}" " jcheck_file_not_empty_jobID - Failed checkpoint jcheck_file_not_empty due to empty (or whitespace) file: ""$WHITESPACE_FILE"
assert "compare_contents ${JSUB_LOG_FILE} ${EXPECTED_WHITESPACE_FAIL}" ""
rm "$JSUB_LOG_FILE" # Clear log file
assert "file_exists ${JSUB_LOG_FILE}" "no"
assert "jcheck_file_not_empty ${NONWHITESPACE_FILE}" ""
assert "compare_contents ${JSUB_LOG_FILE} ${EXPECTED_SUCCESS}" ""
# 39
# Test cases with multiple arguments
rm "$JSUB_LOG_FILE" # Clear log file
assert "file_exists ${JSUB_LOG_FILE}" "no"
assert "jcheck_file_not_empty ${EMPTY_FILE} ${WHITESPACE_FILE} ${NONWHITESPACE_FILE}" " jcheck_file_not_empty_jobID - Failed checkpoint jcheck_file_not_empty due to empty (or whitespace) file: ""$EMPTY_FILE""\n"" jcheck_file_not_empty_jobID - Failed checkpoint jcheck_file_not_empty due to empty (or whitespace) file: ""$WHITESPACE_FILE"
assert "compare_contents ${JSUB_LOG_FILE} ${EXPECTED_MULTIPLE}" ""
# 42

## check_completion
source "../../common_functions/job_processing.sh"
JSUB_SUCCESSFUL_COMPLETION="This is a string saything that stuff worked: "
TEST_STRING_PASS="This is a string saything that stuff worked: and then some"
TEST_STRING_FAIL="#this is a string saything that stuff worked: "
JSUB_PATH_TO_THIS_JOB="not used in this test but should be declared"
function kill_this_job {
  echo "executing mock function kill_this_job"
}
assert "check_completion bash_function_test_files/check_completion/test_pass_01.txt" ""
assert "check_completion bash_function_test_files/check_completion/test_fail_01.txt" " jcheck_file_not_empty_jobID Terminating job due to lack of line indicating successful parent job completion at the end of the file: bash_function_test_files/check_completion/test_fail_01.txt\nexecuting mock function kill_this_job"
assert "check_completion bash_function_test_files/check_completion/test_pass_02.txt" ""
assert "check_completion bash_function_test_files/check_completion/test_fail_02.txt" " jcheck_file_not_empty_jobID Terminating job due to lack of line indicating successful parent job completion at the end of the file: bash_function_test_files/check_completion/test_fail_02.txt\nexecuting mock function kill_this_job"
assert "check_completion bash_function_test_files/check_completion/test_pass_03.txt" ""
assert "check_completion bash_function_test_files/check_completion/test_fail_03.txt" " jcheck_file_not_empty_jobID Terminating job due to lack of line indicating successful parent job completion at the end of the file: bash_function_test_files/check_completion/test_fail_03.txt\nexecuting mock function kill_this_job"
assert "check_completion bash_function_test_files/check_completion/test_pass_04.txt" ""
assert "check_completion bash_function_test_files/check_completion/test_fail_04.txt" " jcheck_file_not_empty_jobID Terminating job due to lack of line indicating successful parent job completion at the end of the file: bash_function_test_files/check_completion/test_fail_04.txt\nexecuting mock function kill_this_job"
# 50

## Unit tests to make sure that process_job writes all the completed steps to the .completed file when jcheck_file_not_empty is used.
DIR_EXPECTEDS="bash_function_test_files/job_mocks//based_on_integration_tests/jgroups/"
FILE_EXPECTED_LOG=${DIR_EXPECTEDS}/"jobPrefix_summaryPrefix_sample0001A_first.log"
FILE_EXPECTED_COMPLETED=${DIR_EXPECTEDS}/"jobPrefix_summaryPrefix_sample0001A_first.completed"
FILE_EXPECTED_INCOMPLETE=${DIR_EXPECTEDS}/"jobPrefix_summaryPrefix_sample0001A_first.incomplete"
DIR_OUT="bash_function_test_files/test_outputs/job_processing/based_on_integration_tests/jgroups/"
mkdir -p ${DIR_OUT}/results
mkdir -p ${DIR_OUT}/jobs
FILE_TEST_JOB=${DIR_EXPECTEDS}/"jobPrefix_summaryPrefix_sample0001A_first.lsf"
RESULTS="bash_function_test_files/test_outputs/job_processing/based_on_integration_tests/jgroups/results"
FILE_JOB_RESULT=${RESULTS}/"outPrefix_"sample0001A_first.txt
FILE_LOG=${DIR_OUT}/"jobPrefix_summaryPrefix_sample0001A.log"
FILE_COMPLETED=${DIR_OUT}/"jobPrefix_summaryPrefix_sample0001A_first.completed"
FILE_INCOMPLETE=${DIR_OUT}/"jobPrefix_summaryPrefix_sample0001A_first.incomplete"
# Remove output files produced by previous test runs
rm -f ${FILE_TEST_JOB} ${FILE_JOB_RESULT} ${FILE_LOG} ${FILE_COMPLETED} ${FILE_INCOMPLETE}
# Concatenate test job file header, job_processing function and tail.
cat ${DIR_EXPECTEDS}/"jobPrefix_summaryPrefix_sample0001A_first.head" \
  "../../common_functions/jcheck_file_not_empty.sh" \
  "../../common_functions/job_processing.sh" \
  ${DIR_EXPECTEDS}/"jobPrefix_summaryPrefix_sample0001A_first.tail" > ${FILE_TEST_JOB}
# Change to the job directory and run the job
bash ${FILE_TEST_JOB}
# Check that files produced by the mock job match expected files.
assert "file_exists ${FILE_LOG}" "yes"
assert "file_exists ${FILE_EXPECTED_LOG}" "yes"
assert "compare_contents ${FILE_LOG} ${FILE_EXPECTED_LOG}" ""
assert "file_exists ${FILE_COMPLETED}" "yes"
assert "file_exists ${FILE_EXPECTED_COMPLETED}" "yes"
assert "compare_contents ${FILE_COMPLETED} ${FILE_EXPECTED_COMPLETED}" ""
assert "file_exists ${FILE_INCOMPLETE}" "no"
# 57

## Unit test that tries to reproduce the problem of repeated entries in the *.complete and missing entries in *.incomplete file that was found in the initial implementation of example 6
DIR_EXPECTEDS="bash_function_test_files/job_mocks//based_on_example_06/"
FILE_EXPECTED_LOG=${DIR_EXPECTEDS}/"echo06_vars06_fvars06_1.log"
mkdir -p ${DIR_EXPECTEDS}/"progress"/completed
mkdir -p ${DIR_EXPECTEDS}/"progress"/incomplete
FILE_EXPECTED_COMPLETED_01=${DIR_EXPECTEDS}/"progress"/"completed"/echo06_vars06_fvars06_1_1.completed
FILE_EXPECTED_COMPLETED_02=${DIR_EXPECTEDS}/"progress"/"completed"/echo06_vars06_fvars06_2_2.completed
FILE_EXPECTED_INCOMPLETE_01=${DIR_EXPECTEDS}/"progress"/"incomplete"/echo06_vars06_fvars06_1_1.incomplete
FILE_EXPECTED_INCOMPLETE_02=${DIR_EXPECTEDS}/"progress"/"incomplete"/echo06_vars06_fvars06_2_2.incomplete
DIR_OUT="bash_function_test_files/test_outputs/job_processing/based_on_example_06/"
mkdir -p ${DIR_OUT}"/results"
mkdir -p ${DIR_OUT}"/jobs"
mkdir -p ${DIR_OUT}"/progress/completed"
mkdir -p ${DIR_OUT}"/progress/incomplete"
FILE_TEST_JOB_01=${DIR_EXPECTEDS}/"echo06_vars06_fvars06_1_1.lsf"
PRE_FILE_TEST_JOB_02=${DIR_EXPECTEDS}/"echo06_vars06_fvars06_2_2.lsf.with_kill"
FILE_TEST_JOB_02=${DIR_EXPECTEDS}/"echo06_vars06_fvars06_2_2.lsf"
RESULTS=${DIR_OUT}/"results"
FILE_JOB_RESULT_A1=${DIR_OUT}/"results_A1.txt"
FILE_JOB_RESULT_B1=${DIR_OUT}/"results_B1.txt"
FILE_JOB_RESULT_A2=${DIR_OUT}/"results_A2.txt"
FILE_JOB_RESULT_B2=${DIR_OUT}/"results_B2.txt"
FILE_LOG_01=${DIR_OUT}/jobs/"echo06_vars06_fvars06_1.log"
FILE_LOG_02=${DIR_OUT}/jobs/"echo06_vars06_fvars06_2.log"
FILE_COMPLETED_01=${DIR_OUT}"/progress/completed"/"echo06_vars06_fvars06_1_1.completed"
FILE_COMPLETED_02=${DIR_OUT}"/progress/completed"/"echo06_vars06_fvars06_2_2.completed"
FILE_INCOMPLETE_01=${DIR_OUT}"/progress/completed"/"echo06_vars06_fvars06_1_1.incomplete"
FILE_INCOMPLETE_02=${DIR_OUT}"/progress/completed"/"echo06_vars06_fvars06_2_2.incomplete"
# Remove output files produced by previous test runs
rm -f ${FILE_TEST_JOB_01} ${FILE_TEST_JOB_02} ${PRE_FILE_TEST_JOB_02} \
      ${FILE_JOB_RESULT_A1} ${FILE_JOB_RESULT_A2} ${FILE_JOB_RESULT_B1} ${FILE_JOB_RESULT_B2} \
      ${FILE_LOG_01} ${FILE_LOG_02} \
      ${FILE_COMPLETED_01} ${FILE_COMPLETED_02} \
      ${FILE_INCOMPLETE_01} ${FILE_INCOMPLETE_02}
# Concatenate test job file header, job_processing function and tail.
cat ${DIR_EXPECTEDS}/"echo06_vars06_fvars06_1_1.head" \
  "../../common_functions/jcheck_file_not_empty.sh" \
  "../../common_functions/job_processing.sh" \
  ${DIR_EXPECTEDS}/"echo06_vars06_fvars06_1_1.tail" > ${FILE_TEST_JOB_01}
# Run
bash ${FILE_TEST_JOB_01}
## Now again for job 2
# Concatenate test job file header, job_processing function and tail.
cat ${DIR_EXPECTEDS}/"echo06_vars06_fvars06_2_2.head" \
  "../../common_functions/jcheck_file_not_empty.sh" \
  "../../common_functions/job_processing.sh" \
  ${DIR_EXPECTEDS}/"echo06_vars06_fvars06_2_2.tail" > ${FILE_TEST_JOB_02}
# Run
bash ${FILE_TEST_JOB_02} > ${FILE_TEST_JOB_02}.run-log
# Make sure that $FILE_COMPLETED_01 only contains two lines with "After going past jcheck_file_not_empty..."
assert "file_exists ${FILE_COMPLETED_01}" "yes"
assert "compare_contents ${FILE_COMPLETED_01} ${FILE_EXPECTED_COMPLETED_01}" ""
assert "file_exists ${FILE_INCOMPLETE_01}" "no" # Should completed 01 exist??
# 59
# Make sure that $FILE_INCOMPLETE_02 contains commands before jcheck_file_not_empty as well as after
assert "file_exists ${FILE_COMPLETED_02}" "no"
# assert "compare_contents ${FILE_COMPLETED_02} ${FILE_EXPECTED_COMPLETED_02}" ""
assert "file_exists ${FILE_INCOMPLETE_02}" "yes"
assert "compare_contents ${FILE_INCOMPLETE_02} ${FILE_EXPECTED_INCOMPLETE_02}" ""


## Test to see if initialise_job populates a *.incomplete file as expected
DIR_EXPECTEDS="bash_function_test_files/job_mocks/"
DIR_OUT="bash_function_test_files/test_outputs/"
FILE_TEST_JOB=${DIR_OUT}/"ut_initialise_job_01.sh"
# FILE_COMPLETED=${DIR_OUT}/"ut_initialise_job_01.completed"
FILE_INCOMPLETE=${DIR_OUT}/"ut_initialise_job_01.incomplete"
FILE_EXPECTED_INCOMPLETE=${DIR_EXPECTEDS}/"ut_initialise_job_01.incomplete"
# Remove previous test job
rm -f ${FILE_TEST_JOB} ${FILE_INCOMPLETE}
# Create a new test job using the current job_processing.sh file
cat ${DIR_EXPECTEDS}/"ut_job_processing_head.sh" \
    "../../common_functions/job_processing.sh" \
    ${DIR_EXPECTEDS}/"ut_initialise_job_01_tail.sh" > ${FILE_TEST_JOB}
# Run test job
bash ${FILE_TEST_JOB} "dummy.log" "dummy.completed" ${FILE_INCOMPLETE}
assert "compare_contents ${FILE_INCOMPLETE} ${FILE_EXPECTED_INCOMPLETE}" ""

## Test version_control.sh functions
source "../../common_functions/version_control.sh"
## Test is_special_word function
assert "is_special_word \#" "yes"
assert "is_special_word [" "yes"
assert "is_special_word done" "yes"
assert "is_special_word bob" "no"


####################################################
## end of test suite
assert_end
echo ""
# EOF












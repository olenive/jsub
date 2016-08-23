#!/bin/bash
set -e

### Integration test 1: basic test

####### INPUTS ########

PROTOCOL_FILE="../basic.protocol"

EXPECTED_SUMMARY="../expected_files/basic_0001.summary"
EXPECTED_SUMMARY_LIST="../expected_files/basic.list-summaries"
EXPECTED_JOB_IN="../expected_files/basic_0001.lsf"
EXPECTED_JOB_LIST="../expected/basic.list-jobs"
EXPECTED_JOB_OUT="../expected_files/basic.txt"

GENERATED_SUMMARY="basic_0001.summary"
GENERATED_SUMMARY_LIST="basic.list-summaries"
GENERATED_JOB_IN="basic_0001.lsf"
GENERATED_JOB_LIST="basic.list-jobs"
GENERATED_JOB_OUT="basic.txt"

CALL_JSUB="julia ../../../jsub.jl -v "

#######################

# Unit tests for bash functions using the lehmannro/assert.sh framework
. assert.sh
echo ""
echo "Running integration test: basic..."

### FUNCTIONS ###
function file_exists {
  if [ -f "$1" ]; then echo "yes"; else echo "no"; fi
}
function clear_generated {
  rm -f ${GENERATED_SUMMARY}
  rm -f ${GENERATED_SUMMARY_LIST}
  rm -f ${GENERATED_JOB_IN}
  rm -f ${GENERATED_JOB_LIST}
  rm -f ${GENERATED_JOB_OUT}
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

# Change to generated_files directory
cd generated_files

# Run jsub - only create summary file
clear_generated # Remove existing output from previous tests
${CALL_JSUB} -s -p ${PROTOCOL_FILE}
# Check that a summary file and a summary listing file are generated from the protocol
assert "file_exists ${GENERATED_SUMMARY}" "yes"
assert "diff ${GENERATED_SUMMARY} ${EXPECTED_SUMMARY}" ""
assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
assert "diff ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""

# Run jsub - create job file from previously generated summary
${CALL_JSUB} -j -u ${GENERATED_SUMMARY_LIST}
# Check that a job file is generated from the summary file
assert "file_exists ${GENERATED_JOB_IN}" "yes"
assert "diff ${GENERATED_JOB_IN} ${EXPECTED_JOB_IN}" ""
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "diff ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""

# Run jsub - submit jobs from list to LSF queue
# ${CALL_JSUB} -b -o ${GENERATED_JOB_LIST}
# Check that a job file is generated from the protocol


# end of test suite
assert_end

# EOF

########################################################################################
########################################################################################
########################################################################################


# #### Unit tests for the job_processing function ####
# ## A successful job that leaves no summary.incomplete file
# # Declare paths to mock files and test output files
# DIR_EXPECTEDS="bash_function_test_files/job_mocks"
# FILE_EXPECTED_LOG=${DIR_EXPECTEDS}/"ut_job_processing_01.log"
# FILE_EXPECTED_COMPLETED=${DIR_EXPECTEDS}/"ut_job_processing_01.summary.completed"
# FILE_EXPECTED_INCOMPLETE=${DIR_EXPECTEDS}/"ut_job_processing_01.summary.incomplete"
# DIR_OUT="bash_function_test_files/test_outputs/job_processing"
# FILE_TEST_JOB=${DIR_OUT}/"ut_job_processing_01.lsf"
# FILE_LOG=${DIR_OUT}/"test_01.log"
# FILE_COMPLETED=${DIR_OUT}/"summary_01.completed"
# FILE_INCOMPLETE=${DIR_OUT}/"summary_01.incomplete"
# # Remove output files produced by previous test runs
# rm -f ${FILE_TEST_JOB} ${FILE_LOG} ${FILE_COMPLETED} ${FILE_INCOMPLETE}
# # Concatenate test job file header, job_processing function and tail.
# cat ${DIR_EXPECTEDS}/"ut_job_processing_head.sh" \
#   "../../common_functions/job_processing.sh" \
#   ${DIR_EXPECTEDS}/"ut_job_processing_tail_01.sh" > ${FILE_TEST_JOB}
# # Run the test file and check that output files contain expected results.
# bash ${FILE_TEST_JOB} ${FILE_LOG} ${FILE_COMPLETED} ${FILE_INCOMPLETE}
# assert "file_exists ${FILE_LOG}" "yes"
# assert "file_exists ${FILE_EXPECTED_LOG}" "yes"
# assert "diff ${FILE_LOG} ${FILE_EXPECTED_LOG}" ""
# assert "file_exists ${FILE_COMPLETED}" "yes"
# assert "file_exists ${FILE_EXPECTED_COMPLETED}" "yes"
# assert "diff ${FILE_COMPLETED} ${FILE_EXPECTED_COMPLETED}" ""
# assert "file_exists ${FILE_INCOMPLETE}" "no" # assert $(diff ${FILE_INCOMPLETE} ${FILE_EXPECTED_INCOMPLETE}) "" # The incomplete file should not exist for this example

# ## A job that is terminated in the middle leaving a summary.incomplete file
# # Declare paths to mock files and test output files
# DIR_EXPECTEDS="bash_function_test_files/job_mocks"
# FILE_EXPECTED_LOG=${DIR_EXPECTEDS}/"ut_job_processing_02.log"
# FILE_EXPECTED_COMPLETED=${DIR_EXPECTEDS}/"ut_job_processing_02.summary.completed"
# FILE_EXPECTED_INCOMPLETE=${DIR_EXPECTEDS}/"ut_job_processing_02.summary.incomplete"
# DIR_OUT="bash_function_test_files/test_outputs/job_processing"
# FILE_TEST_JOB=${DIR_OUT}/"ut_job_processing_02.lsf"
# FILE_LOG=${DIR_OUT}/"test_02.log"
# FILE_COMPLETED=${DIR_OUT}/"summary_02.completed"
# FILE_INCOMPLETE=${DIR_OUT}/"summary_02.incomplete"
# # Remove output files produced by previous test runs
# rm -f ${FILE_TEST_JOB} ${FILE_LOG} ${FILE_COMPLETED} ${FILE_INCOMPLETE}
# # Concatenate test job file header, job_processing function and tail.
# cat ${DIR_EXPECTEDS}/"ut_job_processing_head.sh" \
#   "../../common_functions/job_processing.sh" \
#   ${DIR_EXPECTEDS}/"ut_job_processing_tail_02.sh" > ${FILE_TEST_JOB}
# # Run the test file and check that output files contain expected results.
# bash ${FILE_TEST_JOB} ${FILE_LOG} ${FILE_COMPLETED} ${FILE_INCOMPLETE}
# assert "file_exists ${FILE_LOG}" "yes"
# assert "file_exists ${FILE_EXPECTED_LOG}" "yes"
# assert "diff ${FILE_LOG} ${FILE_EXPECTED_LOG}" ""
# assert "file_exists ${FILE_COMPLETED}" "yes"
# assert "file_exists ${FILE_EXPECTED_COMPLETED}" "yes"
# assert "diff ${FILE_COMPLETED} ${FILE_EXPECTED_COMPLETED}" ""
# assert "file_exists ${FILE_INCOMPLETE}" "yes" # assert $(diff ${FILE_INCOMPLETE} ${FILE_EXPECTED_INCOMPLETE}) "" # The incomplete file should not exist for this example
# ####################################################



# # end of test suite
# assert_end examples

# # EOF

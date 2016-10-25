#!/bin/bash
set -e

### Integration test 1: basic test

####### INPUTS ########
JOB_HEADER="$1"

PROTOCOL_FILE="../basic.protocol"
LSF_JOB_NAME="basic_1_1"

EXPECTED_SUMMARY="../expected_files/basic_1.summary"
EXPECTED_SUMMARY_LIST="../expected_files/basic.list-summaries"
EXPECTED_JOB_IN="../expected_files/${LSF_JOB_NAME}.lsf"
EXPECTED_JOB_LIST="../expected_files/basic.list-jobs"
EXPECTED_JOB_DATA="../expected_files/it1_basic.txt"
EXPECTED_COMPLETED="../expected_files/${LSF_JOB_NAME}.completed"

GENERATED_DIR="generated_files"
GENERATED_SUMMARY="basic_1.summary"
GENERATED_SUMMARY_LIST="basic.list-summaries"
GENERATED_JOB_IN="${LSF_JOB_NAME}.lsf"
GENERATED_JOB_LIST="basic.list-jobs"
GENERATED_JOB_DATA="it1_basic.txt"
GENERATED_JOB_OUTPUT="${LSF_JOB_NAME}.error"
GENERATED_JOB_ERROR="${LSF_JOB_NAME}.output"
GENERATED_SUBMITTED_JOBS_LIST="basic.list-jobs.submitted"
GENERATED_COMPLETED="${LSF_JOB_NAME}.completed"
GENERATED_INCOMPLETE="${LSF_JOB_NAME}.incomplete"

CALL_JSUB="julia ../../../jsub.jl -d -v "

#######################

# Unit tests for bash functions using the lehmannro/assert.sh framework
. ../assert.sh
echo ""
echo "Running integration test: basic..."

### FUNCTIONS ###
source "../common_it_functions.sh"
function clear_generated {
  rm -f ${GENERATED_SUMMARY}
  rm -f ${GENERATED_SUMMARY_LIST}
  rm -f ${GENERATED_JOB_IN}
  rm -f ${GENERATED_JOB_LIST}
  rm -f ${GENERATED_JOB_DATA}
  rm -f ${GENERATED_JOB_OUTPUT}
  rm -f ${GENERATED_JOB_ERROR}
  rm -f ${GENERATED_SUBMITTED_JOBS_LIST}
  rm -f ${GENERATED_COMPLETED}
  rm -f ${GENERATED_INCOMPLETE}
}
#################

# Change to generated_files directory
mkdir -p ${GENERATED_DIR}
cd ${GENERATED_DIR}

clear_generated # Remove existing output from previous tests

# Run jsub - only create summary file
${CALL_JSUB} -s -p ${PROTOCOL_FILE}
# Check that a summary file and a summary listing file are generated from the protocol
assert "file_exists ${GENERATED_SUMMARY}" "yes"
assert "compare_contents ${GENERATED_SUMMARY} ${EXPECTED_SUMMARY}" ""
assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
assert "compare_contents ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""
echo ""
echo "##################################################"
echo ""
# Run jsub - create job file from previously generated summary
# OPTION_HEADER=$(getCommonHeaderOptionString "$JOB_HEADER")
${CALL_JSUB} -j -u ${GENERATED_SUMMARY_LIST} $(getCommonHeaderOptionString "$JOB_HEADER")
# Check that a job file is generated from the summary file
assert "file_exists ${GENERATED_JOB_IN}" "yes"
assert "compare_contents ${GENERATED_JOB_IN} ${EXPECTED_JOB_IN} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^#BSUB -q*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix -P option.
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "compare_contents ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
echo ""
echo "##################################################"
echo ""
# Run jsub - submit jobs from list to LSF queue
${CALL_JSUB} -b -o ${GENERATED_JOB_LIST}
bjobs
awaitJobNameCompletion "$LSF_JOB_NAME"
assert "file_exists ${GENERATED_JOB_DATA}" "yes"
assert "compare_contents ${GENERATED_JOB_DATA} ${EXPECTED_JOB_DATA}" ""
assert "file_exists ${GENERATED_JOB_OUTPUT}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR}" "yes"
assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"
#13
clear_generated # Remove existing output from previous tests
echo ""
echo "##################################################"
echo ""
## Create summary file(s) from protocol
${CALL_JSUB} -sj -p ${PROTOCOL_FILE}
# Check that a summary file and a summary listing file are generated from the protocol
assert "file_exists ${GENERATED_SUMMARY}" "yes"
assert "compare_contents ${GENERATED_SUMMARY} ${EXPECTED_SUMMARY}" ""
assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
assert "compare_contents ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""
# Check that a job file is generated from the summary file
assert "file_exists ${GENERATED_JOB_IN}" "yes"
assert "compare_contents ${GENERATED_JOB_IN} ${EXPECTED_JOB_IN} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^#BSUB -q*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix -P option.
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "compare_contents ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
#21
echo ""
echo "##################################################"
echo ""

clear_generated # Remove existing output from previous tests
${CALL_JSUB} -s -p ${PROTOCOL_FILE} # Create summary files

## Create job file(s) from summary and submit
# Run jsub - create job file from previously generated summary
# OPTION_HEADER=$(getCommonHeaderOptionString "$JOB_HEADER")
${CALL_JSUB} -jb -u ${GENERATED_SUMMARY_LIST} $(getCommonHeaderOptionString "$JOB_HEADER")
bjobs
# Check that a job file is generated from the summary file
assert "file_exists ${GENERATED_JOB_IN}" "yes"
assert "compare_contents ${GENERATED_JOB_IN} ${EXPECTED_JOB_IN} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^#BSUB -q*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix -P option.
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "compare_contents ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
awaitJobNameCompletion "$LSF_JOB_NAME"
assert "file_exists ${GENERATED_JOB_DATA}" "yes"
assert "compare_contents ${GENERATED_JOB_DATA} ${EXPECTED_JOB_DATA}" ""
assert "file_exists ${GENERATED_JOB_OUTPUT}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR}" "yes"
assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"
# 30
echo ""
echo "##################################################"
echo ""
clear_generated # Remove existing output from previous tests
## Start with a protocol and end by submitting job(s)
${CALL_JSUB} -p ${PROTOCOL_FILE} $(getCommonHeaderOptionString "$JOB_HEADER")
bjobs
# Check that a summary file and a summary listing file are generated from the protocol
assert "file_exists ${GENERATED_SUMMARY}" "yes"
assert "compare_contents ${GENERATED_SUMMARY} ${EXPECTED_SUMMARY}" ""
assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
assert "compare_contents ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""
# Check that a job file is generated from the summary file
assert "file_exists ${GENERATED_JOB_IN}" "yes"
assert "compare_contents ${GENERATED_JOB_IN} ${EXPECTED_JOB_IN} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^#BSUB -q*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix -P option.
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "compare_contents ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
awaitJobNameCompletion "$LSF_JOB_NAME"
assert "file_exists ${GENERATED_JOB_DATA}" "yes"
assert "compare_contents ${GENERATED_JOB_DATA} ${EXPECTED_JOB_DATA}" ""
assert "file_exists ${GENERATED_JOB_OUTPUT}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR}" "yes"
assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"
assert "file_exists ${GENERATED_COMPLETED}" "yes"
assert "compare_contents ${GENERATED_COMPLETED} ${EXPECTED_COMPLETED} -I '^#JSUB Successfully ran job on: *'  " ""
echo ""
echo "##################################################"
echo ""

## end of test suite
assert_end



# EOF

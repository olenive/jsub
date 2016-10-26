#!/bin/bash
set -e

### Integration test 1: fvars test

####### INPUTS ########
JOB_HEADER="$1"

PROTOCOL_DIR="../"
PROTOCOL_FILE="$PROTOCOL_DIR"/"protocolFV.protocol"
VARS_FILE="$PROTOCOL_DIR"/"varsFV.vars"
FVARS_FILE="$PROTOCOL_DIR"/"fvarsFV.fvars"
LONG_NAME="protocolFV_varsFV_fvarsFV"

GENERATED_DIR="generated_files/"
SUMMARY_PREFIX="summaries/summaryPrefix_"
SUMMARY_BASE_PREFIX=$(basename $SUMMARY_PREFIX)
JOB_PREFIX="jobs/jobPrefix_"
OUT_PREFIX="outPrefix_"

GENERATED_SUMMARY_01="$SUMMARY_PREFIX""sample0001A.summary"
GENERATED_SUMMARY_02="$SUMMARY_PREFIX""sample0002A.summary"
GENERATED_SUMMARY_03="$SUMMARY_PREFIX""sample0003A.summary"
GENERATED_SUMMARY_LIST="$SUMMARY_PREFIX""$LONG_NAME"".list-summaries"
GENERATED_JOB_IN_01="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0001A_1.lsf"
GENERATED_JOB_IN_02="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0002A_2.lsf"
GENERATED_JOB_IN_03="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0003A_3.lsf"
GENERATED_JOB_LIST="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""$LONG_NAME"".list-jobs"
GENERATED_JOB_DATA_01="outPrefix_""sample0001A.txt"
GENERATED_JOB_DATA_02="outPrefix_""sample0002A.txt"
GENERATED_JOB_DATA_03="outPrefix_""sample0003A.txt"
GENERATED_JOB_OUTPUT_01="$SUMMARY_BASE_PREFIX""sample0001A_1.error"
GENERATED_JOB_OUTPUT_02="$SUMMARY_BASE_PREFIX""sample0002A_2.error"
GENERATED_JOB_OUTPUT_03="$SUMMARY_BASE_PREFIX""sample0003A_3.error"
GENERATED_JOB_ERROR_01="$SUMMARY_BASE_PREFIX""sample0001A_1.output"
GENERATED_JOB_ERROR_02="$SUMMARY_BASE_PREFIX""sample0002A_2.output"
GENERATED_JOB_ERROR_03="$SUMMARY_BASE_PREFIX""sample0003A_3.output"
GENERATED_JOB_LOG_01="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0001A_1.log"
GENERATED_JOB_LOG_02="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0002A_2.log"
GENERATED_JOB_LOG_03="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0003A_3.log"
GENERATED_SUBMITTED_JOBS_LIST="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""$LONG_NAME"".list-jobs.submitted"
GENERATED_COMPLETED_01="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0001A_1.summary.completed"
GENERATED_COMPLETED_02="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0002A_2.summary.completed"
GENERATED_COMPLETED_03="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0003A_3.summary.completed"
GENERATED_INCOMPLETE_01="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0001A_1.summary.incomplete"
GENERATED_INCOMPLETE_02="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0002A_2.summary.incomplete"
GENERATED_INCOMPLETE_03="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0003A_3.summary.incomplete"

DIR_EXPECTED_FILES="../expected_files/"
EXPECTED_SUMMARY_01=${DIR_EXPECTED_FILES}/${GENERATED_SUMMARY_01}
EXPECTED_SUMMARY_02=${DIR_EXPECTED_FILES}/${GENERATED_SUMMARY_02}
EXPECTED_SUMMARY_03=${DIR_EXPECTED_FILES}/${GENERATED_SUMMARY_03}
EXPECTED_SUMMARY_LIST=${DIR_EXPECTED_FILES}/${GENERATED_SUMMARY_LIST}
EXPECTED_JOB_IN_01=${DIR_EXPECTED_FILES}/${GENERATED_JOB_IN_01}
EXPECTED_JOB_IN_02=${DIR_EXPECTED_FILES}/${GENERATED_JOB_IN_02}
EXPECTED_JOB_IN_03=${DIR_EXPECTED_FILES}/${GENERATED_JOB_IN_03}
EXPECTED_JOB_LIST=${DIR_EXPECTED_FILES}/${GENERATED_JOB_LIST}
EXPECTED_JOB_DATA_01=${DIR_EXPECTED_FILES}/${GENERATED_JOB_DATA_01}
EXPECTED_JOB_DATA_02=${DIR_EXPECTED_FILES}/${GENERATED_JOB_DATA_02}
EXPECTED_JOB_DATA_03=${DIR_EXPECTED_FILES}/${GENERATED_JOB_DATA_03}
EXPECTED_JOB_OUTPUT_01=${DIR_EXPECTED_FILES}/${GENERATED_JOB_OUTPUT_01}
EXPECTED_JOB_OUTPUT_02=${DIR_EXPECTED_FILES}/${GENERATED_JOB_OUTPUT_02}
EXPECTED_JOB_OUTPUT_03=${DIR_EXPECTED_FILES}/${GENERATED_JOB_OUTPUT_03}
EXPECTED_JOB_ERROR_01=${DIR_EXPECTED_FILES}/${GENERATED_JOB_ERROR_01}
EXPECTED_JOB_ERROR_02=${DIR_EXPECTED_FILES}/${GENERATED_JOB_ERROR_02}
EXPECTED_JOB_ERROR_03=${DIR_EXPECTED_FILES}/${GENERATED_JOB_ERROR_03}
EXPECTED_JOB_LOG_01=${DIR_EXPECTED_FILES}/${GENERATED_JOB_LOG_01}
EXPECTED_JOB_LOG_02=${DIR_EXPECTED_FILES}/${GENERATED_JOB_LOG_02}
EXPECTED_JOB_LOG_03=${DIR_EXPECTED_FILES}/${GENERATED_JOB_LOG_03}
EXPECTED_SUBMITTED_JOBS_LIST=${DIR_EXPECTED_FILES}/${GENERATED_SUBMITTED_JOBS_LIST}
EXPECTED_COMPLETED_01=${DIR_EXPECTED_FILES}/${GENERATED_COMPLETED_01}
EXPECTED_COMPLETED_02=${DIR_EXPECTED_FILES}/${GENERATED_COMPLETED_02}
EXPECTED_COMPLETED_03=${DIR_EXPECTED_FILES}/${GENERATED_COMPLETED_03}
EXPECTED_INCOMPLETE_01=${DIR_EXPECTED_FILES}/${GENERATED_INCOMPLETE_01}
EXPECTED_INCOMPLETE_02=${DIR_EXPECTED_FILES}/${GENERATED_INCOMPLETE_02}
EXPECTED_INCOMPLETE_03=${DIR_EXPECTED_FILES}/${GENERATED_INCOMPLETE_03}

LSF_JOB_NAME_01="summaryPrefix_sample0001A_1"
LSF_JOB_NAME_02="summaryPrefix_sample0002A_2"
LSF_JOB_NAME_03="summaryPrefix_sample0003A_3"

CALL_JSUB="julia ../../../jsub.jl -d -v "

#######################

# Unit tests for bash functions using the lehmannro/assert.sh framework
. ../assert.sh
echo ""
echo "Running integration test: ""$0""..."

### FUNCTIONS ###
source "../common_it_functions.sh"
function clear_generated {
  rm -f ${GENERATED_SUMMARY_01} ${GENERATED_SUMMARY_02} ${GENERATED_SUMMARY_03}
  rm -f ${GENERATED_SUMMARY_LIST}
  rm -f ${GENERATED_JOB_IN_01} ${GENERATED_JOB_IN_02} ${GENERATED_JOB_IN_03}
  rm -f ${GENERATED_JOB_LIST}
  rm -f ${GENERATED_JOB_DATA}
  rm -f ${GENERATED_JOB_OUTPUT_01} ${GENERATED_JOB_OUTPUT_02} ${GENERATED_JOB_OUTPUT_03}
  rm -f ${GENERATED_JOB_ERROR_01} ${GENERATED_JOB_ERROR_02} ${GENERATED_JOB_ERROR_03}
  rm -f ${GENERATED_JOB_DATA_01} ${GENERATED_JOB_DATA_02} ${GENERATED_JOB_DATA_03}
  rm -f ${GENERATED_JOB_LOG_01} ${GENERATED_JOB_LOG_02} ${GENERATED_JOB_LOG_03}
  rm -f ${GENERATED_SUBMITTED_JOBS_LIST}
  rm -f ${GENERATED_COMPLETED_01} ${GENERATED_COMPLETED_02} ${GENERATED_COMPLETED_03}
  rm -f ${GENERATED_INCOMPLETE_01} ${GENERATED_INCOMPLETE_02} ${GENERATED_INCOMPLETE_03}
  rm -rf "lsf_output"
  rm -rf "summaries"
  rm -rf "jobs"
  rm -rf "results"
  rm -f *".error"
  rm -f *".output"
  rm -f ${GENERATED_JOB_DATA_01}
  rm -f ${GENERATED_JOB_DATA_02}
  rm -f ${GENERATED_JOB_DATA_03}
}
#################

# Change to generated_files directory
mkdir -p ${GENERATED_DIR}
cd ${GENERATED_DIR}

clear_generated # Remove existing output from previous tests

# Run jsub - only create summary file
${CALL_JSUB} -s -p ${PROTOCOL_FILE} --vars ${VARS_FILE} --fvars ${FVARS_FILE} --summary-prefix ${SUMMARY_PREFIX}
# Check that a summary file and a summary listing file are generated from the protocol
assert "file_exists ${GENERATED_SUMMARY_01}" "yes"
assert "file_exists ${GENERATED_SUMMARY_02}" "yes"
assert "file_exists ${GENERATED_SUMMARY_03}" "yes"
assert "compare_contents ${GENERATED_SUMMARY_01} ${EXPECTED_SUMMARY_01}" ""
assert "compare_contents ${GENERATED_SUMMARY_02} ${EXPECTED_SUMMARY_02}" ""
assert "compare_contents ${GENERATED_SUMMARY_03} ${EXPECTED_SUMMARY_03}" ""
assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
assert "compare_contents ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""
#8
# Run jsub - create job file from previously generated summary
${CALL_JSUB} -j -u ${GENERATED_SUMMARY_LIST} $(getCommonHeaderOptionString "$JOB_HEADER") --job-prefix ${JOB_PREFIX}
# Check that a job file is generated from the summary file
assert "file_exists ${GENERATED_JOB_IN_01}" "yes"
assert "file_exists ${GENERATED_JOB_IN_02}" "yes"
assert "file_exists ${GENERATED_JOB_IN_03}" "yes"
assert "compare_contents  ${GENERATED_JOB_IN_01} ${EXPECTED_JOB_IN_01} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix
assert "compare_contents  ${GENERATED_JOB_IN_02} ${EXPECTED_JOB_IN_02} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix
assert "compare_contents  ${GENERATED_JOB_IN_03} ${EXPECTED_JOB_IN_03} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "compare_contents ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
# # 16
# Run jsub - submit jobs from list to LSF queue
${CALL_JSUB} -b -o ${GENERATED_JOB_LIST}
awaitJobNameCompletion "$LSF_JOB_NAME_01"
awaitJobNameCompletion "$LSF_JOB_NAME_02"
awaitJobNameCompletion "$LSF_JOB_NAME_03"
assert "file_exists ${GENERATED_JOB_DATA_01}" "yes"
assert "file_exists ${GENERATED_JOB_DATA_02}" "yes"
assert "file_exists ${GENERATED_JOB_DATA_03}" "yes"
assert "compare_contents ${GENERATED_JOB_DATA_01} ${EXPECTED_JOB_DATA_01}" ""
assert "compare_contents ${GENERATED_JOB_DATA_02} ${EXPECTED_JOB_DATA_02}" ""
assert "compare_contents ${GENERATED_JOB_DATA_03} ${EXPECTED_JOB_DATA_03}" ""
assert "file_exists ${GENERATED_JOB_OUTPUT_01}" "yes"
assert "file_exists ${GENERATED_JOB_OUTPUT_02}" "yes"
assert "file_exists ${GENERATED_JOB_OUTPUT_03}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR_01}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR_02}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR_03}" "yes"
assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"
# 29
clear_generated # Remove existing output from previous tests

## Create summary and job file(s) from protocol
${CALL_JSUB} -sj -p ${PROTOCOL_FILE} --vars ${VARS_FILE} --fvars ${FVARS_FILE} $(getCommonHeaderOptionString "$JOB_HEADER") --summary-prefix ${SUMMARY_PREFIX} --job-prefix ${JOB_PREFIX}
# Check that a summary file and a summary listing file are generated from the protocol
assert "file_exists ${GENERATED_SUMMARY_01}" "yes"
assert "file_exists ${GENERATED_SUMMARY_02}" "yes"
assert "file_exists ${GENERATED_SUMMARY_03}" "yes"
assert "compare_contents ${GENERATED_SUMMARY_01} ${EXPECTED_SUMMARY_01}" ""
assert "compare_contents ${GENERATED_SUMMARY_02} ${EXPECTED_SUMMARY_02}" ""
assert "compare_contents ${GENERATED_SUMMARY_03} ${EXPECTED_SUMMARY_03}" ""
assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
assert "compare_contents ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""
# 37
# Check that a job file is generated from the summary file
assert "file_exists ${GENERATED_JOB_IN_01}" "yes"
assert "file_exists ${GENERATED_JOB_IN_02}" "yes"
assert "file_exists ${GENERATED_JOB_IN_03}" "yes"
assert "compare_contents  ${GENERATED_JOB_IN_01} ${EXPECTED_JOB_IN_01} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix
assert "compare_contents  ${GENERATED_JOB_IN_02} ${EXPECTED_JOB_IN_02} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix
assert "compare_contents  ${GENERATED_JOB_IN_03} ${EXPECTED_JOB_IN_03} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "compare_contents ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
# 45
clear_generated # Remove existing output from previous tests
${CALL_JSUB} -s -p ${PROTOCOL_FILE} --vars ${VARS_FILE} --fvars ${FVARS_FILE} --summary-prefix ${SUMMARY_PREFIX} # Create summary files

## Create job file(s) from summary and submit
# Run jsub - create job file from previously generated summary
# OPTION_HEADER=$(getCommonHeaderOptionString "$JOB_HEADER")
${CALL_JSUB} -jb -u ${GENERATED_SUMMARY_LIST} $(getCommonHeaderOptionString "$JOB_HEADER") --job-prefix ${JOB_PREFIX}
# Check that a job file is generated from the summary file
assert "file_exists ${GENERATED_JOB_IN_01}" "yes"
assert "file_exists ${GENERATED_JOB_IN_02}" "yes"
assert "file_exists ${GENERATED_JOB_IN_03}" "yes"
assert "compare_contents  ${GENERATED_JOB_IN_01} ${EXPECTED_JOB_IN_01} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix
assert "compare_contents  ${GENERATED_JOB_IN_02} ${EXPECTED_JOB_IN_02} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix
assert "compare_contents  ${GENERATED_JOB_IN_03} ${EXPECTED_JOB_IN_03} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "compare_contents ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
awaitJobNameCompletion "$LSF_JOB_NAME_01"
awaitJobNameCompletion "$LSF_JOB_NAME_02"
awaitJobNameCompletion "$LSF_JOB_NAME_03"
assert "file_exists ${GENERATED_JOB_DATA_01}" "yes"
assert "file_exists ${GENERATED_JOB_DATA_02}" "yes"
assert "file_exists ${GENERATED_JOB_DATA_03}" "yes"
assert "compare_contents ${GENERATED_JOB_DATA_01} ${EXPECTED_JOB_DATA_01}" ""
assert "compare_contents ${GENERATED_JOB_DATA_02} ${EXPECTED_JOB_DATA_02}" ""
assert "compare_contents ${GENERATED_JOB_DATA_03} ${EXPECTED_JOB_DATA_03}" ""
assert "file_exists ${GENERATED_JOB_OUTPUT_01}" "yes"
assert "file_exists ${GENERATED_JOB_OUTPUT_02}" "yes"
assert "file_exists ${GENERATED_JOB_OUTPUT_03}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR_01}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR_02}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR_03}" "yes"
assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"

clear_generated # Remove existing output from previous tests

## Start with a protocol and end by submitting job(s)
${CALL_JSUB} -p ${PROTOCOL_FILE} $(getCommonHeaderOptionString "$JOB_HEADER") --vars ${VARS_FILE} --fvars ${FVARS_FILE} --summary-prefix ${SUMMARY_PREFIX} --job-prefix ${JOB_PREFIX}
# Check that a summary file and a summary listing file are generated from the protocol
assert "file_exists ${GENERATED_SUMMARY_01}" "yes"
assert "file_exists ${GENERATED_SUMMARY_02}" "yes"
assert "file_exists ${GENERATED_SUMMARY_03}" "yes"
assert "compare_contents ${GENERATED_SUMMARY_01} ${EXPECTED_SUMMARY_01}" ""
assert "compare_contents ${GENERATED_SUMMARY_02} ${EXPECTED_SUMMARY_02}" ""
assert "compare_contents ${GENERATED_SUMMARY_03} ${EXPECTED_SUMMARY_03}" ""
assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
assert "compare_contents ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""
# Check that a job file is generated from the summary file
assert "file_exists ${GENERATED_JOB_IN_01}" "yes"
assert "file_exists ${GENERATED_JOB_IN_02}" "yes"
assert "file_exists ${GENERATED_JOB_IN_03}" "yes"
assert "compare_contents  ${GENERATED_JOB_IN_01} ${EXPECTED_JOB_IN_01} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix
assert "compare_contents  ${GENERATED_JOB_IN_02} ${EXPECTED_JOB_IN_02} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix
assert "compare_contents  ${GENERATED_JOB_IN_03} ${EXPECTED_JOB_IN_03} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "compare_contents ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
awaitJobNameCompletion "$LSF_JOB_NAME_01"
awaitJobNameCompletion "$LSF_JOB_NAME_02"
awaitJobNameCompletion "$LSF_JOB_NAME_03"
assert "file_exists ${GENERATED_JOB_DATA_01}" "yes"
assert "file_exists ${GENERATED_JOB_DATA_02}" "yes"
assert "file_exists ${GENERATED_JOB_DATA_03}" "yes"
assert "compare_contents ${GENERATED_JOB_DATA_01} ${EXPECTED_JOB_DATA_01}" ""
assert "compare_contents ${GENERATED_JOB_DATA_02} ${EXPECTED_JOB_DATA_02}" ""
assert "compare_contents ${GENERATED_JOB_DATA_03} ${EXPECTED_JOB_DATA_03}" ""
assert "file_exists ${GENERATED_JOB_OUTPUT_01}" "yes"
assert "file_exists ${GENERATED_JOB_OUTPUT_02}" "yes"
assert "file_exists ${GENERATED_JOB_OUTPUT_03}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR_01}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR_02}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR_03}" "yes"
assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"

## end of test suite
assert_end

# EOF

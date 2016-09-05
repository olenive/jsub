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

EXPECTED_SUMMARY_01="../expected_files/sample0001A.summary"
EXPECTED_SUMMARY_02="../expected_files/sample0002A.summary"
EXPECTED_SUMMARY_03="../expected_files/sample0003A.summary"
EXPECTED_SUMMARY_LIST="../expected_files/""$LONG_NAME"".list-summaries"
EXPECTED_JOB_IN_01="../expected_files/sample0001A.lsf"
EXPECTED_JOB_IN_02="../expected_files/sample0002A.lsf"
EXPECTED_JOB_IN_03="../expected_files/sample0003A.lsf"
EXPECTED_JOB_LIST="../expected/""$LONG_NAME"".list-jobs"
EXPECTED_JOB_DATA="../expected_files/it1_fvars.txt"
EXPECTED_COMPLETED_01="../expected_files/sample001A.summary.completed"
EXPECTED_COMPLETED_02="../expected_files/sample002A.summary.completed"
EXPECTED_COMPLETED_03="../expected_files/sample003A.summary.completed"

GENERATED_DIR="generated_files/"
SUMMARY_PREFIX="summaries/summaryPrefix_"
SUMMARY_BASE_PREFIX=$(basename $SUMMARY_PREFIX)
JOB_PREFIX="jobs/jobPrefix_"
OUT_PREFIX="outPrefix_"
GENERATED_SUMMARY_01="$SUMMARY_PREFIX""sample0001A.summary"
GENERATED_SUMMARY_02="$SUMMARY_PREFIX""sample0002A.summary"
GENERATED_SUMMARY_03="$SUMMARY_PREFIX""sample0003A.summary"
GENERATED_SUMMARY_LIST="$SUMMARY_PREFIX""$LONG_NAME"".list-summaries"
GENERATED_JOB_IN_01="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0001A.lsf"
GENERATED_JOB_IN_02="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0002A.lsf"
GENERATED_JOB_IN_03="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0003A.lsf"
GENERATED_JOB_LIST="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""$LONG_NAME"".list-jobs"
GENERATED_JOB_DATA_01="$OUT_PREFIX""sample0001A.txt"
GENERATED_JOB_DATA_02="$OUT_PREFIX""sample0002A.txt"
GENERATED_JOB_DATA_03="$OUT_PREFIX""sample0003A.txt"
GENERATED_JOB_OUTPUT_01="$SUMMARY_BASE_PREFIX""sample0001A.error"
GENERATED_JOB_OUTPUT_02="$SUMMARY_BASE_PREFIX""sample0002A.error"
GENERATED_JOB_OUTPUT_03="$SUMMARY_BASE_PREFIX""sample0003A.error"
GENERATED_JOB_ERROR_01="$SUMMARY_BASE_PREFIX""sample0001A.output"
GENERATED_JOB_ERROR_02="$SUMMARY_BASE_PREFIX""sample0002A.output"
GENERATED_JOB_ERROR_03="$SUMMARY_BASE_PREFIX""sample0003A.output"
GENERATED_JOB_LOG_01="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0001A.log"
GENERATED_JOB_LOG_02="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0002A.log"
GENERATED_JOB_LOG_03="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0003A.log"
GENERATED_SUBMITTED_JOBS_LIST="$GENERATED_JOB_LIST".submitted
GENERATED_COMPLETED_01="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0001A.summary.completed"
GENERATED_COMPLETED_02="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0002A.summary.completed"
GENERATED_COMPLETED_03="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0003A.summary.completed"
GENERATED_INCOMPLETE_01="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0001A.summary.incomplete"
GENERATED_INCOMPLETE_02="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0002A.summary.incomplete"
GENERATED_INCOMPLETE_03="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""sample0003A.summary.incomplete"

LSF_JOB_NAME_01="summaryPrefix_sample0001A"
LSF_JOB_NAME_02="summaryPrefix_sample0002A"
LSF_JOB_NAME_03="summaryPrefix_sample0003A"

CALL_JSUB="julia ../../../../jsub.jl -d -v "

#######################

# Unit tests for bash functions using the lehmannro/assert.sh framework
. ../assert.sh
echo ""
echo "Running integration test: ""$0""..."

### FUNCTIONS ###
function file_exists {
  if [ -f "$1" ]; then echo "yes"; else echo "no"; fi
}
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
}
function isAbsolutePath {
  local DIR="$1"
  [[ ${DIR:0:1} == '/' ]] && echo "absolute" || echo "relative"
}
function isJobNameInQueue {
  local jobName="$1"
  local res=$(bjobs -J ${jobName})
  if [ "$res" = "" ]; then
    echo "no"
  else
    echo "yes"
  fi
}
function awaitJobNameCompletion {
  while [ $(isJobNameInQueue "$1") == "yes" ]; do
    sleep 1
  done
}
# Function used to determine the require option (-c) and file path for the header file containing text included in all jobs
function getCommonHeaderOptionString {
  if [ "$1" == "" ]; then
    echo ""
  elif [ $(isAbsolutePath "$1") == "relative" ]; then
    echo " -c ../""$1"
  else
    echo " -c ""$1"
  fi
}
#################

# Change to generated_files directory
mkdir -p ${GENERATED_DIR}
cd ${GENERATED_DIR}

clear_generated # Remove existing output from previous tests

# Run jsub - only create summary file
${CALL_JSUB} -s -p ${PROTOCOL_FILE} --fvars ${FVARS_FILE} --summary-prefix ${SUMMARY_PREFIX}
# Check that a summary file and a summary listing file are generated from the protocol
assert "file_exists ${GENERATED_SUMMARY_01}" "yes"
assert "file_exists ${GENERATED_SUMMARY_02}" "yes"
assert "file_exists ${GENERATED_SUMMARY_03}" "yes"
assert "diff ${GENERATED_SUMMARY_01} ${EXPECTED_SUMMARY_01}" ""
assert "diff ${GENERATED_SUMMARY_02} ${EXPECTED_SUMMARY_02}" ""
assert "diff ${GENERATED_SUMMARY_03} ${EXPECTED_SUMMARY_03}" ""
assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
assert "diff ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""
#8
# Run jsub - create job file from previously generated summary
${CALL_JSUB} -j -u ${GENERATED_SUMMARY_LIST} $(getCommonHeaderOptionString "$JOB_HEADER") --job-prefix ${JOB_PREFIX}
# Check that a job file is generated from the summary file
assert "file_exists ${GENERATED_JOB_IN_01}" "yes"
assert "file_exists ${GENERATED_JOB_IN_02}" "yes"
assert "file_exists ${GENERATED_JOB_IN_03}" "yes"
assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_01} ${EXPECTED_JOB_IN_01}" "" # Ignore the line that contain absolute paths or the job header prefix
assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_02} ${EXPECTED_JOB_IN_02}" "" # Ignore the line that contain absolute paths or the job header prefix
assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_03} ${EXPECTED_JOB_IN_03}" "" # Ignore the line that contain absolute paths or the job header prefix
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "diff ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
# 16
# Run jsub - submit jobs from list to LSF queue
${CALL_JSUB} -b -o ${GENERATED_JOB_LIST}
awaitJobNameCompletion "$LSF_JOB_NAME_01"
awaitJobNameCompletion "$LSF_JOB_NAME_02"
awaitJobNameCompletion "$LSF_JOB_NAME_03"
assert "file_exists ${GENERATED_JOB_DATA_01}" "yes"
assert "file_exists ${GENERATED_JOB_DATA_02}" "yes"
assert "file_exists ${GENERATED_JOB_DATA_03}" "yes"
assert "diff ${GENERATED_JOB_DATA_01} ${EXPECTED_JOB_DATA_01}" ""
assert "diff ${GENERATED_JOB_DATA_02} ${EXPECTED_JOB_DATA_02}" ""
assert "diff ${GENERATED_JOB_DATA_03} ${EXPECTED_JOB_DATA_03}" ""
assert "file_exists ${GENERATED_JOB_OUTPUT_01}" "yes"
assert "file_exists ${GENERATED_JOB_OUTPUT_02}" "yes"
assert "file_exists ${GENERATED_JOB_OUTPUT_03}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR_01}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR_02}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR_03}" "yes"
assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"

clear_generated # Remove existing output from previous tests

## Create summary and job file(s) from protocol
${CALL_JSUB} -sj -p ${PROTOCOL_FILE} --fvars ${FVARS_FILE} $(getCommonHeaderOptionString "$JOB_HEADER") --summary-prefix ${SUMMARY_PREFIX} --job-prefix ${JOB_PREFIX}
# Check that a summary file and a summary listing file are generated from the protocol
assert "file_exists ${GENERATED_SUMMARY_01}" "yes"
assert "file_exists ${GENERATED_SUMMARY_02}" "yes"
assert "file_exists ${GENERATED_SUMMARY_03}" "yes"
assert "diff ${GENERATED_SUMMARY_01} ${EXPECTED_SUMMARY_01}" ""
assert "diff ${GENERATED_SUMMARY_02} ${EXPECTED_SUMMARY_02}" ""
assert "diff ${GENERATED_SUMMARY_03} ${EXPECTED_SUMMARY_03}" ""
assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
assert "diff ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""
# Check that a job file is generated from the summary file
assert "file_exists ${GENERATED_JOB_IN_01}" "yes"
assert "file_exists ${GENERATED_JOB_IN_02}" "yes"
assert "file_exists ${GENERATED_JOB_IN_03}" "yes"
assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_01} ${EXPECTED_JOB_IN_01}" "" # Ignore the line that contain absolute paths or the job header prefix
assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_02} ${EXPECTED_JOB_IN_02}" "" # Ignore the line that contain absolute paths or the job header prefix
assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_03} ${EXPECTED_JOB_IN_03}" "" # Ignore the line that contain absolute paths or the job header prefix
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "diff ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""

clear_generated # Remove existing output from previous tests
${CALL_JSUB} -s -p ${PROTOCOL_FILE} --fvars ${FVARS_FILE} --summary-prefix ${SUMMARY_PREFIX} # Create summary files

## Create job file(s) from summary and submit
# Run jsub - create job file from previously generated summary
# OPTION_HEADER=$(getCommonHeaderOptionString "$JOB_HEADER")
${CALL_JSUB} -jb -u ${GENERATED_SUMMARY_LIST} $(getCommonHeaderOptionString "$JOB_HEADER") --job-prefix ${JOB_PREFIX}
# Check that a job file is generated from the summary file
assert "file_exists ${GENERATED_JOB_IN_01}" "yes"
assert "file_exists ${GENERATED_JOB_IN_02}" "yes"
assert "file_exists ${GENERATED_JOB_IN_03}" "yes"
assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_01} ${EXPECTED_JOB_IN_01}" "" # Ignore the line that contain absolute paths or the job header prefix
assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_02} ${EXPECTED_JOB_IN_02}" "" # Ignore the line that contain absolute paths or the job header prefix
assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_03} ${EXPECTED_JOB_IN_03}" "" # Ignore the line that contain absolute paths or the job header prefix
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "diff ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
awaitJobNameCompletion "$LSF_JOB_NAME_01"
awaitJobNameCompletion "$LSF_JOB_NAME_02"
awaitJobNameCompletion "$LSF_JOB_NAME_03"
assert "file_exists ${GENERATED_JOB_DATA_01}" "yes"
assert "file_exists ${GENERATED_JOB_DATA_02}" "yes"]
assert "file_exists ${GENERATED_JOB_DATA_03}" "yes"
assert "diff ${GENERATED_JOB_DATA_01} ${EXPECTED_JOB_DATA_01}" ""
assert "diff ${GENERATED_JOB_DATA_02} ${EXPECTED_JOB_DATA_02}" ""
assert "diff ${GENERATED_JOB_DATA_03} ${EXPECTED_JOB_DATA_03}" ""
assert "file_exists ${GENERATED_JOB_OUTPUT_01}" "yes"
assert "file_exists ${GENERATED_JOB_OUTPUT_02}" "yes"
assert "file_exists ${GENERATED_JOB_OUTPUT_03}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR_01}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR_02}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR_03}" "yes"
assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"

clear_generated # Remove existing output from previous tests

## Start with a protocol and end by submitting job(s)
${CALL_JSUB} -p ${PROTOCOL_FILE} $(getCommonHeaderOptionString "$JOB_HEADER") --fvars ${FVARS_FILE} --summary-prefix ${SUMMARY_PREFIX} --job-prefix ${JOB_PREFIX}
# Check that a summary file and a summary listing file are generated from the protocol
assert "file_exists ${GENERATED_SUMMARY_01}" "yes"
assert "file_exists ${GENERATED_SUMMARY_02}" "yes"
assert "file_exists ${GENERATED_SUMMARY_03}" "yes"
assert "diff ${GENERATED_SUMMARY_01} ${EXPECTED_SUMMARY_01}" ""
assert "diff ${GENERATED_SUMMARY_02} ${EXPECTED_SUMMARY_02}" ""
assert "diff ${GENERATED_SUMMARY_03} ${EXPECTED_SUMMARY_03}" ""
assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
assert "diff ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""
# Check that a job file is generated from the summary file
assert "file_exists ${GENERATED_JOB_IN_01}" "yes"
assert "file_exists ${GENERATED_JOB_IN_02}" "yes"
assert "file_exists ${GENERATED_JOB_IN_03}" "yes"
assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_01} ${EXPECTED_JOB_IN_01}" "" # Ignore the line that contain absolute paths or the job header prefix
assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_02} ${EXPECTED_JOB_IN_02}" "" # Ignore the line that contain absolute paths or the job header prefix
assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_03} ${EXPECTED_JOB_IN_03}" "" # Ignore the line that contain absolute paths or the job header prefix
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "diff ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
awaitJobNameCompletion "$LSF_JOB_NAME_01"
awaitJobNameCompletion "$LSF_JOB_NAME_02"
awaitJobNameCompletion "$LSF_JOB_NAME_03"
assert "file_exists ${GENERATED_JOB_DATA_01}" "yes"
assert "file_exists ${GENERATED_JOB_DATA_02}" "yes"
assert "file_exists ${GENERATED_JOB_DATA_03}" "yes"
assert "diff ${GENERATED_JOB_DATA_01} ${EXPECTED_JOB_DATA_01}" ""
assert "diff ${GENERATED_JOB_DATA_02} ${EXPECTED_JOB_DATA_02}" ""
assert "diff ${GENERATED_JOB_DATA_03} ${EXPECTED_JOB_DATA_03}" ""
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

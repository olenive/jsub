#!/bin/bash
set -e

### Integration test 1: basic test

####### INPUTS ########
JOB_HEADER="$1"

PROTOCOL_FILE="../basic.protocol"
LSF_JOB_NAME="basic_0001"

EXPECTED_SUMMARY="../expected_files/basic_0001.summary"
EXPECTED_SUMMARY_LIST="../expected_files/basic.list-summaries"
EXPECTED_JOB_IN="../expected_files/basic_0001.lsf"
EXPECTED_JOB_LIST="../expected/basic.list-jobs"
EXPECTED_JOB_DATA="../expected_files/it1_basic.txt"

GENERATED_SUMMARY="basic_0001.summary"
GENERATED_SUMMARY_LIST="basic.list-summaries"
GENERATED_JOB_IN="basic_0001.lsf"
GENERATED_JOB_LIST="basic.list-jobs"
GENERATED_JOB_DATA="it1_basic.txt"
GENERATED_JOB_OUTPUT="basic_0001.error"
GENERATED_JOB_ERROR="basic_0001.output"
GENERATED_SUBMITTED_JOBS_LIST="basic.list-jobs.submitted"

CALL_JSUB="julia ../../../jsub.jl "

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
  rm -f ${GENERATED_JOB_DATA}
  rm -f ${GENERATED_JOB_OUTPUT}
  rm -f ${GENERATED_JOB_ERROR}
  rm -f ${GENERATED_SUBMITTED_JOBS_LIST}
}
function isAbsolutePath {
  local DIR="$1"
  [[ ${DIR:0:1} == '/' ]] && echo "absolute" || echo "relative"
}
function isJobNameInQueue {
  local jobName="$1"
  local res=$(bjobs | grep -w ${jobName})
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
mkdir -p generated_files
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
# OPTION_HEADER=$(getCommonHeaderOptionString "$JOB_HEADER")
${CALL_JSUB} -j -u ${GENERATED_SUMMARY_LIST} $(getCommonHeaderOptionString "$JOB_HEADER")
# Check that a job file is generated from the summary file
assert "file_exists ${GENERATED_JOB_IN}" "yes"
assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN} ${EXPECTED_JOB_IN}" "" # Ignore the line that contain absolute paths or the job header prefix
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "diff ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""

# Run jsub - submit jobs from list to LSF queue
${CALL_JSUB} -b -o ${GENERATED_JOB_LIST}
awaitJobNameCompletion "$LSF_JOB_NAME"
assert "file_exists ${GENERATED_JOB_DATA}" "yes"
assert "diff ${GENERATED_JOB_DATA} ${EXPECTED_JOB_DATA}" ""
assert "file_exists ${GENERATED_JOB_OUTPUT}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR}" "yes"
assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"

clear_generated # Remove existing output from previous tests

## Create job files from protocol
${CALL_JSUB} -sj -p ${PROTOCOL_FILE}
# Check that a summary file and a summary listing file are generated from the protocol
assert "file_exists ${GENERATED_SUMMARY}" "yes"
assert "diff ${GENERATED_SUMMARY} ${EXPECTED_SUMMARY}" ""
assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
assert "diff ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""
# Check that a job file is generated from the summary file
assert "file_exists ${GENERATED_JOB_IN}" "yes"
assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN} ${EXPECTED_JOB_IN}" "" # Ignore the line that contain absolute paths or the job header prefix
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "diff ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""

clear_generated # Remove existing output from previous tests
${CALL_JSUB} -s -p ${PROTOCOL_FILE} # Create summary files

## Create job files from summary and submit
# Run jsub - create job file from previously generated summary
# OPTION_HEADER=$(getCommonHeaderOptionString "$JOB_HEADER")
${CALL_JSUB} -jb -u ${GENERATED_SUMMARY_LIST} $(getCommonHeaderOptionString "$JOB_HEADER")
# Check that a job file is generated from the summary file
assert "file_exists ${GENERATED_JOB_IN}" "yes"
assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN} ${EXPECTED_JOB_IN}" "" # Ignore the line that contain absolute paths or the job header prefix
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "diff ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
awaitJobNameCompletion "$LSF_JOB_NAME"
assert "file_exists ${GENERATED_JOB_DATA}" "yes"
assert "diff ${GENERATED_JOB_DATA} ${EXPECTED_JOB_DATA}" ""
assert "file_exists ${GENERATED_JOB_OUTPUT}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR}" "yes"
assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"

clear_generated # Remove existing output from previous tests

## Start with a protocol and end by submitting job(s)
${CALL_JSUB} -p ${PROTOCOL_FILE} $(getCommonHeaderOptionString "$JOB_HEADER")
# Check that a summary file and a summary listing file are generated from the protocol
assert "file_exists ${GENERATED_SUMMARY}" "yes"
assert "diff ${GENERATED_SUMMARY} ${EXPECTED_SUMMARY}" ""
assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
assert "diff ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""
# Check that a job file is generated from the summary file
assert "file_exists ${GENERATED_JOB_IN}" "yes"
assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN} ${EXPECTED_JOB_IN}" "" # Ignore the line that contain absolute paths or the job header prefix
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "diff ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
awaitJobNameCompletion "$LSF_JOB_NAME"
assert "file_exists ${GENERATED_JOB_DATA}" "yes"
assert "diff ${GENERATED_JOB_DATA} ${EXPECTED_JOB_DATA}" ""
assert "file_exists ${GENERATED_JOB_OUTPUT}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR}" "yes"
assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"

## end of test suite
assert_end

# EOF

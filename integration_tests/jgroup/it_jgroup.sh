#!/bin/bash
set -e

### Integration test 1: fvars test

####### INPUTS ########
JOB_HEADER="$1"

GENERATED_DIR="generated_files/"
PROTOCOL_DIR="../"
PROTOCOL_FILE="$PROTOCOL_DIR"/"jgroupP.protocol"
VARS_FILE="$PROTOCOL_DIR"/"jgroupV.vars"
FVARS_FILE="$PROTOCOL_DIR"/"jgroupFV.fvars"
LONG_NAME="jgroupP_jgroupV_jgroupFV"
SUMMARY_PREFIX="summaries/summaryPrefix_"
SUMMARY_BASE_PREFIX=$(basename $SUMMARY_PREFIX)

declare -a SAMPELS=("sample0001A" "sample0002A" "sample0003A" "sample0004A" "sample0005A" "sample0006A" "sample0007A" "sample0008A" "sample0009A" "sample0010A" "sample0011A")
declare -a JGROUPS=("root" "first" "second" "third" "last")

EXPECTED_SUMMARY_LIST="../expected_files/""$SUMMARY_BASE_PREFIX""$LONG_NAME"".list-summaries"
EXPECTED_JOB_LIST="../expected/""$LONG_NAME"".list-jobs"
EXPECTED_JOB_DATA="../expected_files/it1_fvars.txt"

JOB_PREFIX="jobs/jobPrefix_"
OUT_PREFIX="results/outPrefix_"
GENERATED_SUMMARY_LIST="$SUMMARY_PREFIX""$LONG_NAME"".list-summaries"
GENERATED_JOB_LIST="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""$LONG_NAME"".list-jobs"
GENERATED_SUBMITTED_JOBS_LIST="$GENERATED_JOB_LIST".submitted

LSF_JOB_NAME_01="summaryPrefix_sample0001A"
LSF_JOB_NAME_02="summaryPrefix_sample0002A"
LSF_JOB_NAME_03="summaryPrefix_sample0003A"

CALL_JSUB="julia ../../../jsub.jl -d -v "

#######################

# Unit tests for bash functions using the lehmannro/assert.sh framework
. ../assert.sh
echo ""
echo "Running integration test: ""$0""..."

### FUNCTIONS ###
source ../common_it_functions.sh
#################

# Change to generated_files directory
mkdir -p ${GENERATED_DIR}
cd ${GENERATED_DIR}

clear_generated # Remove existing output from previous tests
mkdir -p results

# Run jsub - only create summary file
${CALL_JSUB} -s -p ${PROTOCOL_FILE} --vars ${VARS_FILE} --fvars ${FVARS_FILE} --summary-prefix ${SUMMARY_PREFIX}
# Check that a summary file and a summary listing file are generated from the protocol
for sample in "${SAMPELS[@]}"; do
  assert "file_exists $SUMMARY_PREFIX""$sample"".summary" "yes"
  assert "diff ${SUMMARY_PREFIX}${sample}.summary ../expected_files/${SUMMARY_PREFIX}${sample}.summary" ""
done
#6
assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
assert "diff ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""
#8
# Run jsub - create job file from previously generated summary
${CALL_JSUB} -j -u ${GENERATED_SUMMARY_LIST} $(getCommonHeaderOptionString "$JOB_HEADER") --job-prefix ${JOB_PREFIX}
# Check that a job file is generated from the summary file
for sample in "${SAMPELS[@]}"; do
  for jgroup in "${JGROUPS[@]}"; do
    GENERATED_JOB=${JOB_PREFIX}${SUMMARY_BASE_PREFIX}${sample}_${jgroup}.lsf
    EXPECTED_JOB="../expected_files/"${GENERATED_JOB}
    assert "file_exists ${GENERATED_JOB}" "yes"
    assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB} ${EXPECTED_JOB}" "" # Ignore the line that contain absolute paths or the job header prefix
  done
done
# 38
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "diff ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
# 40
# Run jsub - submit jobs from list to LSF queue
${CALL_JSUB} -b -o ${GENERATED_JOB_LIST}
for sample in "${SAMPELS[@]}"; do
  GENERATED_JOB_DATA_00="${OUT_PREFIX}${sample}.txt"
  GENERATED_JOB_DATA_01="${OUT_PREFIX}${sample}_first.txt"
  GENERATED_JOB_DATA_02="${OUT_PREFIX}${sample}_second.txt"
  GENERATED_JOB_DATA_03="${OUT_PREFIX}${sample}_third.txt"
  for jgroup in "${JGROUPS[@]}"; do
    awaitJobNameCompletion ${SUMMARY_BASE_PREFIX}${sample}_${jgroup}
  done
  sleep 1
  assert "file_exists ${GENERATED_JOB_DATA_00}" "yes"
  assert "file_exists ${GENERATED_JOB_DATA_01}" "yes"
  assert "file_exists ${GENERATED_JOB_DATA_02}" "yes"
  assert "file_exists ${GENERATED_JOB_DATA_03}" "yes"
  assert "diff ${GENERATED_JOB_DATA_00} ../expected_files/${GENERATED_JOB_DATA_00}" ""
  assert "diff ${GENERATED_JOB_DATA_01} ../expected_files/${GENERATED_JOB_DATA_01}" ""
  assert "diff ${GENERATED_JOB_DATA_02} ../expected_files/${GENERATED_JOB_DATA_02}" ""
  assert "diff ${GENERATED_JOB_DATA_03} ../expected_files/${GENERATED_JOB_DATA_03}" ""
  for jgroup in "${JGROUPS[@]}"; do
    GENERATED_JOB_OUTPUT="${SUMMARY_BASE_PREFIX}${sample}_${jgroup}.output"
    GENERATED_JOB_ERROR="${SUMMARY_BASE_PREFIX}${sample}_${jgroup}.error"
    assert "file_exists ${GENERATED_JOB_OUTPUT}" "yes"
    assert "file_exists ${GENERATED_JOB_ERROR}" "yes"
  done
done
assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"
# 101



# clear_generated # Remove existing output from previous tests

# ## Create summary and job file(s) from protocol
# ${CALL_JSUB} -sj -p ${PROTOCOL_FILE} --vars ${VARS_FILE} --fvars ${FVARS_FILE} $(getCommonHeaderOptionString "$JOB_HEADER") --summary-prefix ${SUMMARY_PREFIX} --job-prefix ${JOB_PREFIX}
# # Check that a summary file and a summary listing file are generated from the protocol
# assert "file_exists ${GENERATED_SUMMARY_01}" "yes"
# assert "file_exists ${GENERATED_SUMMARY_02}" "yes"
# assert "file_exists ${GENERATED_SUMMARY_03}" "yes"
# assert "diff ${GENERATED_SUMMARY_01} ${EXPECTED_SUMMARY_01}" ""
# assert "diff ${GENERATED_SUMMARY_02} ${EXPECTED_SUMMARY_02}" ""
# assert "diff ${GENERATED_SUMMARY_03} ${EXPECTED_SUMMARY_03}" ""
# assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
# assert "diff ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""
# # 37
# # Check that a job file is generated from the summary file
# assert "file_exists ${GENERATED_JOB_IN_01}" "yes"
# assert "file_exists ${GENERATED_JOB_IN_02}" "yes"
# assert "file_exists ${GENERATED_JOB_IN_03}" "yes"
# assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_01} ${EXPECTED_JOB_IN_01}" "" # Ignore the line that contain absolute paths or the job header prefix
# assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_02} ${EXPECTED_JOB_IN_02}" "" # Ignore the line that contain absolute paths or the job header prefix
# assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_03} ${EXPECTED_JOB_IN_03}" "" # Ignore the line that contain absolute paths or the job header prefix
# assert "file_exists ${GENERATED_JOB_LIST}" "yes"
# assert "diff ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
# # 45
# clear_generated # Remove existing output from previous tests
# ${CALL_JSUB} -s -p ${PROTOCOL_FILE} --vars ${VARS_FILE} --fvars ${FVARS_FILE} --summary-prefix ${SUMMARY_PREFIX} # Create summary files

# ## Create job file(s) from summary and submit
# # Run jsub - create job file from previously generated summary
# # OPTION_HEADER=$(getCommonHeaderOptionString "$JOB_HEADER")
# ${CALL_JSUB} -jb -u ${GENERATED_SUMMARY_LIST} $(getCommonHeaderOptionString "$JOB_HEADER") --job-prefix ${JOB_PREFIX}
# # Check that a job file is generated from the summary file
# assert "file_exists ${GENERATED_JOB_IN_01}" "yes"
# assert "file_exists ${GENERATED_JOB_IN_02}" "yes"
# assert "file_exists ${GENERATED_JOB_IN_03}" "yes"
# assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_01} ${EXPECTED_JOB_IN_01}" "" # Ignore the line that contain absolute paths or the job header prefix
# assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_02} ${EXPECTED_JOB_IN_02}" "" # Ignore the line that contain absolute paths or the job header prefix
# assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_03} ${EXPECTED_JOB_IN_03}" "" # Ignore the line that contain absolute paths or the job header prefix
# assert "file_exists ${GENERATED_JOB_LIST}" "yes"
# assert "diff ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
# awaitJobNameCompletion "$LSF_JOB_NAME_01"
# awaitJobNameCompletion "$LSF_JOB_NAME_02"
# awaitJobNameCompletion "$LSF_JOB_NAME_03"
# assert "file_exists ${GENERATED_JOB_DATA_01}" "yes"
# assert "file_exists ${GENERATED_JOB_DATA_02}" "yes"
# assert "file_exists ${GENERATED_JOB_DATA_03}" "yes"
# assert "diff ${GENERATED_JOB_DATA_01} ${EXPECTED_JOB_DATA_01}" ""
# assert "diff ${GENERATED_JOB_DATA_02} ${EXPECTED_JOB_DATA_02}" ""
# assert "diff ${GENERATED_JOB_DATA_03} ${EXPECTED_JOB_DATA_03}" ""
# assert "file_exists ${GENERATED_JOB_OUTPUT_01}" "yes"
# assert "file_exists ${GENERATED_JOB_OUTPUT_02}" "yes"
# assert "file_exists ${GENERATED_JOB_OUTPUT_03}" "yes"
# assert "file_exists ${GENERATED_JOB_ERROR_01}" "yes"
# assert "file_exists ${GENERATED_JOB_ERROR_02}" "yes"
# assert "file_exists ${GENERATED_JOB_ERROR_03}" "yes"
# assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"

# clear_generated # Remove existing output from previous tests

# ## Start with a protocol and end by submitting job(s)
# ${CALL_JSUB} -p ${PROTOCOL_FILE} $(getCommonHeaderOptionString "$JOB_HEADER") --vars ${VARS_FILE} --fvars ${FVARS_FILE} --summary-prefix ${SUMMARY_PREFIX} --job-prefix ${JOB_PREFIX}
# # Check that a summary file and a summary listing file are generated from the protocol
# assert "file_exists ${GENERATED_SUMMARY_01}" "yes"
# assert "file_exists ${GENERATED_SUMMARY_02}" "yes"
# assert "file_exists ${GENERATED_SUMMARY_03}" "yes"
# assert "diff ${GENERATED_SUMMARY_01} ${EXPECTED_SUMMARY_01}" ""
# assert "diff ${GENERATED_SUMMARY_02} ${EXPECTED_SUMMARY_02}" ""
# assert "diff ${GENERATED_SUMMARY_03} ${EXPECTED_SUMMARY_03}" ""
# assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
# assert "diff ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""
# # Check that a job file is generated from the summary file
# assert "file_exists ${GENERATED_JOB_IN_01}" "yes"
# assert "file_exists ${GENERATED_JOB_IN_02}" "yes"
# assert "file_exists ${GENERATED_JOB_IN_03}" "yes"
# assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_01} ${EXPECTED_JOB_IN_01}" "" # Ignore the line that contain absolute paths or the job header prefix
# assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_02} ${EXPECTED_JOB_IN_02}" "" # Ignore the line that contain absolute paths or the job header prefix
# assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN_03} ${EXPECTED_JOB_IN_03}" "" # Ignore the line that contain absolute paths or the job header prefix
# assert "file_exists ${GENERATED_JOB_LIST}" "yes"
# assert "diff ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
# awaitJobNameCompletion "$LSF_JOB_NAME_01"
# awaitJobNameCompletion "$LSF_JOB_NAME_02"
# awaitJobNameCompletion "$LSF_JOB_NAME_03"
# assert "file_exists ${GENERATED_JOB_DATA_01}" "yes"
# assert "file_exists ${GENERATED_JOB_DATA_02}" "yes"
# assert "file_exists ${GENERATED_JOB_DATA_03}" "yes"
# assert "diff ${GENERATED_JOB_DATA_01} ${EXPECTED_JOB_DATA_01}" ""
# assert "diff ${GENERATED_JOB_DATA_02} ${EXPECTED_JOB_DATA_02}" ""
# assert "diff ${GENERATED_JOB_DATA_03} ${EXPECTED_JOB_DATA_03}" ""
# assert "file_exists ${GENERATED_JOB_OUTPUT_01}" "yes"
# assert "file_exists ${GENERATED_JOB_OUTPUT_02}" "yes"
# assert "file_exists ${GENERATED_JOB_OUTPUT_03}" "yes"
# assert "file_exists ${GENERATED_JOB_ERROR_01}" "yes"
# assert "file_exists ${GENERATED_JOB_ERROR_02}" "yes"
# assert "file_exists ${GENERATED_JOB_ERROR_03}" "yes"
# assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"

## end of test suite
assert_end

# EOF

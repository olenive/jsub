#!/bin/bash
set -e

### Integration test 1: fvars test

####### INPUTS ########
JOB_HEADER="$1"

GENERATED_DIR="generated_files/"
PROTOCOL_DIR="../../examples/example_04/"
PROTOCOL_FILE="$PROTOCOL_DIR"/"echo03.protocol"
VARS_FILE="$PROTOCOL_DIR"/"vars02.vars"
FVARS_FILE="$PROTOCOL_DIR"/"fvars03.fvars"
LONG_NAME="echo03_vars02_fvars03"
SUMMARY_PREFIX="summaries/sumpre_"
SUMMARY_BASE_PREFIX=$(basename $SUMMARY_PREFIX)
JOB_PREFIX="jobs/jobpre_"
OUT_PREFIX="results/outPrefix_"
LSF_OUTPUT_PREFIX="lsf_out/lsf_"
COMPLETED_PREFIX="progoress/completed/"
INCOMPLETE_PREFIX="progoress/incomplete/"
DIR_EXPECTED_FILES="../expected_files/"

## list_file.txt 
# row1col1        row1col2        outfile1
# row2col1        row2col2        outfile2
# row3col1        row3col2        outfile3
declare -a SAMPLES_COL01=("row1col1" "row2col1" "row3col1")
declare -a SAMPLES_COL02=("row1col2" "row2col2" "row3col2")
declare -a SAMPLES_COL03=("outfile1" "outfile2" "outfile3")
JOBID_PREFIX=""
declare -a JOBIDS=("$JOBID_PREFIX""1" "$JOBID_PREFIX""2" "$JOBID_PREFIX""3")
# declare -a JGROUPS=("root" "first" "second" "third" "last")
declare -a JGROUPS=("")

GENERATED_SUMMARY_LIST="$SUMMARY_PREFIX""$LONG_NAME"".list-summaries"
GENERATED_JOB_LIST="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""$LONG_NAME"".list-jobs"
GENERATED_SUBMITTED_JOBS_LIST="$GENERATED_JOB_LIST".submitted

EXPECTED_SUMMARY_LIST=${DIR_EXPECTED_FILES}/${GENERATED_SUMMARY_LIST}
EXPECTED_JOB_LIST=${DIR_EXPECTED_FILES}/${GENERATED_JOB_LIST}

CALL_JSUB="julia ../../../jsub.jl --no-logging-timestamp --verbose "

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
echo "Running integration test from directory: "$(pwd)

clear_generated # Remove existing output from previous tests
mkdir -p $(dirname "$OUT_PREFIX")
mkdir -p $(dirname "$LSF_OUTPUT_PREFIX")

## Run (code similar to) example 
${CALL_JSUB} --protocol "PROTOCOL_FILE" \
     --header-from-file "$JOB_HEADER" \
     --vars "$VARS_FILE" \
     --fvars "$FVARS_FILE" \
     --summary-prefix "$SUMMARY_PREFIX" \
     --job-prefix "$JOB_PREFIX" \
     --prefix-lsf-out "$LSF_OUTPUT_PREFIX" \
     --prefix-completed "$COMPLETED_PREFIX" \
     --prefix-incomplete "$INCOMPLETE_PREFIX"
#     --timestamp-files

# Check that summary files are generated
# Check that a summary file and a summary listing file are generated from the protocol
for sample in "${SAMPLES[@]}"; do
  GENERATED_SUMMARY="$SUMMARY_PREFIX""$LONG_NAME".summary
  EXPECTED_SUMMARY="$DIR_EXPECTED_FILES"/"$GENERATED_SUMMARY"
  assert "file_exists ${GENERATED_SUMMARY}" "yes"
  assert "compare_contents ${GENERATED_SUMMARY} ${EXPECTED_SUMMARY}" ""
done
assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
assert "compare_contents ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""

# Check that job files are generated # Check that files generated by jobs are as expected
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "compare_contents ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
idx=0
for sample in "${SAMPLES[@]}"; do
  for jgroup in "${JGROUPS[@]}"; do
    awaitJobNameCompletion ${SUMMARY_BASE_PREFIX}${sample}_${JOBIDS[idx]}_${jgroup}
  done
  sleep 2 # to make sure output files have been written
  for jgroup in "${JGROUPS[@]}"; do

    # Check that job called the required commands
    GENERATED_JOB_DATA_00="${OUT_PREFIX}${sample}.txt"
    assert "file_exists ${GENERATED_JOB_DATA_00}" "yes"
    assert "compare_contents ${GENERATED_JOB_DATA_00} ${DIR_EXPECTED_FILES}/${GENERATED_JOB_DATA_00}" ""

    # Check that the .output and .error files exist
    GENERATED_JOB_OUTPUT="${LSF_OUTPUT_PREFIX}${SUMMARY_BASE_PREFIX}${sample}_${JOBIDS[idx]}_${jgroup}.output"
    GENERATED_JOB_ERROR="${LSF_OUTPUT_PREFIX}${SUMMARY_BASE_PREFIX}${sample}_${JOBIDS[idx]}_${jgroup}.error"
    assert "file_exists ${GENERATED_JOB_OUTPUT}" "yes"
    assert "file_exists ${GENERATED_JOB_ERROR}" "yes"
    # Check the .completed and incomplete files
    GENERATED_COMPLETED=${JOB_PREFIX}${SUMMARY_BASE_PREFIX}${sample}_${JOBIDS[idx]}_${jgroup}".completed"
    assert "file_exists ${GENERATED_COMPLETED}" "yes"
    # GENERATED_INCOMPLETE=${JOB_PREFIX}${SUMMARY_BASE_PREFIX}${sample}_${JOBIDS[idx]}_${jgroup}".incomplete"
    # assert "file_exists ${GENERATED_INCOMPLETE}" "yes"
  done
  idx=$((idx+1))
done
assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"

## end of test suite
assert_end

# EOF

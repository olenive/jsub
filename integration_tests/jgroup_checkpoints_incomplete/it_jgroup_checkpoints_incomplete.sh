#!/bin/bash
set -e

### Integration test 1: fvars test

####### INPUTS ########
JOB_HEADER="$1"

GENERATED_DIR="generated_files/"
PROTOCOL_DIR="../"
PROTOCOL_FILE="$PROTOCOL_DIR"/"jgroup_incomplete.protocol"
VARS_FILE="$PROTOCOL_DIR"/"jgroupV.vars"
FVARS_FILE="$PROTOCOL_DIR"/"jgroupFV.fvars"
LONG_NAME="jgroup_incomplete_jgroupV_jgroupFV"
SUMMARY_PREFIX="summaries/summaryPrefix_"
SUMMARY_BASE_PREFIX=$(basename $SUMMARY_PREFIX)
LSF_OUTPUT_PREFIX="lsf_output/lsf_"
DIR_EXPECTED_FILES="../expected_files/"

declare -a SAMPLES=("sample0001A" "sample0002A" "sample0003A")
JOBID_PREFIX=""
declare -a JOBIDS=("$JOBID_PREFIX""1" "$JOBID_PREFIX""2" "$JOBID_PREFIX""3")
declare -a JGROUPS=("root" "first" "second" "third" "last")

JOB_PREFIX="jobs/jobPrefix_"
OUT_PREFIX="results/outPrefix_"
GENERATED_SUMMARY_LIST="$SUMMARY_PREFIX""$LONG_NAME"".list-summaries"
GENERATED_JOB_LIST="$JOB_PREFIX""$SUMMARY_BASE_PREFIX""$LONG_NAME"".list-jobs"
GENERATED_SUBMITTED_JOBS_LIST="$GENERATED_JOB_LIST".submitted

EXPECTED_SUMMARY_LIST=${DIR_EXPECTED_FILES}/${GENERATED_SUMMARY_LIST}
EXPECTED_JOB_LIST=${DIR_EXPECTED_FILES}/${GENERATED_JOB_LIST}

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
mkdir -p $(dirname "$OUT_PREFIX")
mkdir -p $(dirname "$LSF_OUTPUT_PREFIX")

# Run jsub - only create summary file
${CALL_JSUB} -s -p ${PROTOCOL_FILE} --vars ${VARS_FILE} --fvars ${FVARS_FILE} --summary-prefix ${SUMMARY_PREFIX}
# Check that a summary file and a summary listing file are generated from the protocol
for sample in "${SAMPLES[@]}"; do
  assert "file_exists $SUMMARY_PREFIX""$sample"".summary" "yes"
  assert "compare_contents ${SUMMARY_PREFIX}${sample}.summary $DIR_EXPECTED_FILES${SUMMARY_PREFIX}${sample}.summary" ""
done
#6
assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
assert "compare_contents ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""
#8
# Run jsub - create job file from previously generated summary
${CALL_JSUB} -j -u ${GENERATED_SUMMARY_LIST} $(getCommonHeaderOptionString "$JOB_HEADER") --job-prefix ${JOB_PREFIX} -e "lsf_output/lsf_"
# Check that a job file is generated from the summary file
idx=0
for sample in "${SAMPLES[@]}"; do
  for jgroup in "${JGROUPS[@]}"; do
    GENERATED_JOB=${JOB_PREFIX}${SUMMARY_BASE_PREFIX}$_${sample}_${JOBIDS[idx]}_${jgroup}".lsf"
    echo "it_jgroup.sh GENERATED_JOB = : "$GENERATED_JOB
    EXPECTED_JOB="$DIR_EXPECTED_FILES"${GENERATED_JOB}
    assert "file_exists ${GENERATED_JOB}" "yes"
    assert "compare_contents  ${GENERATED_JOB} ${EXPECTED_JOB} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix
  done
  idx=$((idx+1))
done
# 38
assert "file_exists ${GENERATED_JOB_LIST}" "yes"
assert "compare_contents ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
# 40
# Run jsub - submit jobs from list to LSF queue
${CALL_JSUB} -b -o ${GENERATED_JOB_LIST}
bjobs
idx=0
for sample in "${SAMPLES[@]}"; do
  GENERATED_JOB_DATA_00="${OUT_PREFIX}${sample}.txt"
  GENERATED_JOB_DATA_01="${OUT_PREFIX}${sample}_first.txt"
  GENERATED_JOB_DATA_02="${OUT_PREFIX}${sample}_second.txt"
  GENERATED_JOB_DATA_03="${OUT_PREFIX}${sample}_third.txt"
  for jgroup in "${JGROUPS[@]}"; do
    awaitJobNameCompletion ${SUMMARY_BASE_PREFIX}${sample}_${JOBIDS[idx]}_${jgroup}
  done
  sleep 2 # to make sure output files have been written
  # Check job output
  assert "file_exists ${GENERATED_JOB_DATA_00}" "yes"
  assert "file_exists ${GENERATED_JOB_DATA_01}" "yes"
  assert "file_exists ${GENERATED_JOB_DATA_02}" "yes"
  assert "file_exists ${GENERATED_JOB_DATA_03}" "yes"
  assert "compare_contents ${GENERATED_JOB_DATA_00} $DIR_EXPECTED_FILES${GENERATED_JOB_DATA_00}" ""
  assert "compare_contents ${GENERATED_JOB_DATA_01} $DIR_EXPECTED_FILES${GENERATED_JOB_DATA_01}" ""
  assert "compare_contents ${GENERATED_JOB_DATA_02} $DIR_EXPECTED_FILES${GENERATED_JOB_DATA_02}" ""
  assert "compare_contents ${GENERATED_JOB_DATA_03} $DIR_EXPECTED_FILES${GENERATED_JOB_DATA_03}" ""
  for jgroup in "${JGROUPS[@]}"; do
    GENERATED_JOB_OUTPUT="${LSF_OUTPUT_PREFIX}${SUMMARY_BASE_PREFIX}${sample}_${JOBIDS[idx]}_${jgroup}.output"
    GENERATED_JOB_ERROR="${LSF_OUTPUT_PREFIX}${SUMMARY_BASE_PREFIX}${sample}_${JOBIDS[idx]}_${jgroup}.error"
    assert "file_exists ${GENERATED_JOB_OUTPUT}" "yes"
    assert "file_exists ${GENERATED_JOB_ERROR}" "yes"
    # Check the .completed and incomplete files
    echo ${JOB_PREFIX}
    echo 
    if [ "$jgroup" == "last" ]; then
      : # Jobs in the "last" group are not started because jobs they depend on are not completed.
    elif [ "$jgroup" == "second" ] || [ "$jgroup" == "third" ]; then
      GENERATED_INCOMPLETE=${SUMMARY_BASE_PREFIX}${sample}_${JOBIDS[idx]}_${jgroup}".incomplete"
      assert "file_exists ${GENERATED_INCOMPLETE}" "yes"
    else
      GENERATED_COMPLETED=${SUMMARY_BASE_PREFIX}${sample}_${JOBIDS[idx]}_${jgroup}".completed"
      assert "file_exists ${GENERATED_COMPLETED}" "yes"
    fi
  done
  idx=$((idx+1))
done
assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"

## end of test suite
assert_end

# EOF


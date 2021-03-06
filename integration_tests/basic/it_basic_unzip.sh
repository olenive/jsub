#!/bin/bash
set -e

# Based on it_basic.sh but instead of submitting jobs, zipped portable directories are created

####### INPUTS ########
JOB_HEADER="$1"

PROTOCOL_FILE="../basic.protocol"
LSF_JOB_NAME="basic_1_1"

EXPECTED_SUMMARY="../expected_files/basic_1.summary"
EXPECTED_SUMMARY_LIST="../expected_files/basic.list-summaries"
EXPECTED_JOB_IN="../expected_files/${LSF_JOB_NAME}.lsf"
EXPECTED_JOB_LIST="../expected_files/basic.list-jobs"
EXPECTED_JOB_DATA="../expected_files/it1_basic.txt"
EXPECTED_COMPLETED="../expected_files/basic_1.completed"
EXPECTED_PORTABLE_DIR="../expected_files/portable"
EXPECTED_PORTABLE_ZIP="$EXPECTED_PORTABLE_DIR".tar.gz

GENERATED_DIR="generated_files_zip"
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
GENERATED_PORTABLE_DIR="portable"
GENERATED_PORTABLE_ZIP="$GENERATED_PORTABLE_DIR".tar.gz

CALL_JSUB="julia ../../../jsub.jl -d -v "

#######################

# Unit tests for bash functions using the lehmannro/assert.sh framework
. ../assert.sh
echo ""
echo "Running integration test: basic_zip..."

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
  rm -fr ${GENERATED_PORTABLE_DIR}
  rm -fr ${GENERATED_PORTABLE_ZIP}
}
#################

# Determien header location from where the script is being run
ABSOLUTE_HEADER_PATH=$(forcePathAbsolute "$JOB_HEADER") 

# Change to generated_files directory
mkdir -p ${GENERATED_DIR}
cd ${GENERATED_DIR}

# clear_generated # Remove existing output from previous tests

# # Run jsub - only create summary file©
# ${CALL_JSUB} -s -p ${PROTOCOL_FILE}
# # Check that a summary file and a summary listing file are generated from the protocol
# assert "file_exists ${GENERATED_SUMMARY}" "yes"
# assert "compare_contents ${GENERATED_SUMMARY} ${EXPECTED_SUMMARY}" ""
# assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
# assert "compare_contents ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""
# echo ""
# echo "##################################################"
# echo ""
# # Run jsub - create job file from previously generated summary
# # OPTION_HEADER=$(getCommonHeaderOptionString "$JOB_HEADER")
# echo "${CALL_JSUB} -j -u ${GENERATED_SUMMARY_LIST} $(getCommonHeaderOptionString "$JOB_HEADER")"
# ${CALL_JSUB} -j -u ${GENERATED_SUMMARY_LIST} $(getCommonHeaderOptionString "$JOB_HEADER")
# # Check that a job file is generated from the summary file
# assert "file_exists ${GENERATED_JOB_IN}" "yes"
# assert "compare_contents ${GENERATED_JOB_IN} ${EXPECTED_JOB_IN} -I '^# --- From file:*' -I '^#BSUB -P*' -I '^#BSUB -q*' -I '^JSUB_PATH_TO_THIS_JOB=*' " "" # Ignore the line that contain absolute paths or the job header prefix -P option.
# assert "file_exists ${GENERATED_JOB_LIST}" "yes"
# assert "compare_contents ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""
# echo ""
# echo "##################################################"
# echo ""
# # Run jsub - stage 3 but instead of submitting copy jobs to a directory and zip it
# rm -fr ${GENERATED_PORTABLE_ZIP}
# ${CALL_JSUB} -b -z -a ${GENERATED_PORTABLE_DIR} -o ${GENERATED_JOB_LIST}
# awaitJobNameCompletion "$LSF_JOB_NAME"
# assert "file_exists ${GENERATED_PORTABLE_DIR}/${GENERATED_JOB_IN}" "yes"
# assert "file_exists ${GENERATED_PORTABLE_DIR}/${GENERATED_JOB_LIST}" "yes"
# assert "file_exists ${GENERATED_PORTABLE_DIR}/submit_lsf_jobs.sh" "yes"
# assert "file_exists ${GENERATED_PORTABLE_DIR}/job_submission_functions.sh" "yes"
# assert "file_exists ${GENERATED_PORTABLE_ZIP}" "yes"
# echo ""
# echo "##################################################"
# echo ""

# clear_generated # Remove existing output from previous tests

# Extract zipped jobs and submit them
tar -zxvf ${GENERATED_PORTABLE_ZIP}
rm -rf ../${GENERATED_PORTABLE_DIR}
mv ${GENERATED_PORTABLE_DIR} .. # So as not to change the relative path in the protocol for this test alone
cd ../${GENERATED_PORTABLE_DIR}
# Manually combine the generated job and the rquired local system header information
if [[ ${ABSOLUTE_HEADER_PATH} != "" ]] && [[ ${GENERATED_JOB_IN} != "" ]]; then
  cat ${ABSOLUTE_HEADER_PATH} >> ${GENERATED_JOB_IN}
else
  echo "Warning, there are unset headers variables, job submission may fail..."
  echo "  ABSOLUTE_HEADER_PATH = "${ABSOLUTE_HEADER_PATH}
  echo "  GENERATED_JOB_IN = "${GENERATED_JOB_IN}
fi
bash submit_lsf_jobs.sh ${GENERATED_JOB_LIST}
bjobs
awaitJobNameCompletion "$LSF_JOB_NAME"
sleep 2 # To let the system catch up with the job output being created
assert "file_exists ${GENERATED_JOB_DATA}" "yes"
assert "diff ${GENERATED_JOB_DATA} ${EXPECTED_JOB_DATA}" ""
assert "file_exists ${GENERATED_JOB_OUTPUT}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR}" "yes"
assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"
assert "file_exists ${GENERATED_COMPLETED}" "yes"
assert "diff ${GENERATED_COMPLETED} ${EXPECTED_COMPLETED}" ""

## end of test suite
echo ""
assert_end

# EOF

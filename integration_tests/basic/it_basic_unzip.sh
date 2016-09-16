#!/bin/bash
set -e

# Based on it_basic.sh but instead of submitting jobs, zipped portable directories are created

####### INPUTS ########
JOB_HEADER="$1"

PROTOCOL_FILE="../basic.protocol"
LSF_JOB_NAME="basic_0001"

EXPECTED_SUMMARY="../expected_files/basic_0001.summary"
EXPECTED_SUMMARY_LIST="../expected_files/basic.list-summaries"
EXPECTED_JOB_IN="../expected_files/basic_0001.lsf"
EXPECTED_JOB_LIST="../expected/basic.list-jobs"
EXPECTED_JOB_DATA="../expected_files/it1_basic.txt"
EXPECTED_COMPLETED="../expected_files/basic_0001.summary.completed"
EXPECTED_PROTABLE_DIR="../expected_files/portable"
EXPECTED_PORTABLE_ZIP="$EXPECTED_PROTABLE_DIR".tar.gz

GENERATED_DIR="generated_files_zip"
GENERATED_SUMMARY="basic_0001.summary"
GENERATED_SUMMARY_LIST="basic.list-summaries"
GENERATED_JOB_IN="basic_0001.lsf"
GENERATED_JOB_LIST="basic.list-jobs"
GENERATED_JOB_DATA="it1_basic.txt"
GENERATED_JOB_OUTPUT="basic_0001.error"
GENERATED_JOB_ERROR="basic_0001.output"
GENERATED_SUBMITTED_JOBS_LIST="basic.list-jobs.submitted"
GENERATED_COMPLETED="basic_0001.summary.completed"
GENERATED_INCOMPLETE="basic_0001.summary.incomplete"
GENERATED_PROTABLE_DIR="portable"
GENERATED_PORTABLE_ZIP="$GENERATED_PROTABLE_DIR".tar.gz

CALL_JSUB="julia ../../../jsub.jl -d -v "

#######################

# Unit tests for bash functions using the lehmannro/assert.sh framework
. ../assert.sh
echo ""
echo "Running integration test: basic_zip..."

### FUNCTIONS ###
source ../common_it_functions.sh
# function file_exists {
#   if [ -f "$1" ]; then echo "yes"; else echo "no"; fi
# }
## Overwrite the fnction in common_it_functions to deal with the directory produced by unzipping
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
  rm -fr ${GENERATED_PROTABLE_DIR}
}
# function isAbsolutePath {
#   local DIR="$1"
#   [[ ${DIR:0:1} == '/' ]] && echo "absolute" || echo "relative"
# }
# function isJobNameInQueue {
#   local jobName="$1"
#   local res=$(bjobs -J ${jobName})
#   if [ "$res" = "" ]; then
#     echo "no"
#   else
#     echo "yes"
#   fi
# }
# function awaitJobNameCompletion {
#   echo "Waiting for completion of job named ""$1"
#   while [ $(isJobNameInQueue "$1") == "yes" ]; do
#     sleep 1
#   done
#   echo "...job presumed to be completed."
# }
# # Function used to determine the require option (-c) and file path for the header file containing text included in all jobs
# function getCommonHeaderOptionString {
#   if [ "$1" == "" ]; then
#     echo ""
#   elif [ $(isAbsolutePath "$1") == "relative" ]; then
#     echo " -c ../""$1"
#   else
#     echo " -c ""$1"
#   fi
# }
function forcePathAbsolute {
  if [ "$1" == "" ]; then
    echo ""
  elif [ $(isAbsolutePath "$1") == "relative" ]; then
    echo "$PWD"/"$1"
  else
    echo "$1"
  fi
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
# assert "diff ${GENERATED_SUMMARY} ${EXPECTED_SUMMARY}" ""
# assert "file_exists ${GENERATED_SUMMARY_LIST}" "yes"
# assert "diff ${GENERATED_SUMMARY_LIST} ${EXPECTED_SUMMARY_LIST}" ""

# # Run jsub - create job file from previously generated summary
# # OPTION_HEADER=$(getCommonHeaderOptionString "$JOB_HEADER")
# echo "${CALL_JSUB} -j -u ${GENERATED_SUMMARY_LIST} $(getCommonHeaderOptionString "$JOB_HEADER")"
# ${CALL_JSUB} -j -u ${GENERATED_SUMMARY_LIST} $(getCommonHeaderOptionString "$JOB_HEADER")
# # Check that a job file is generated from the summary file
# assert "file_exists ${GENERATED_JOB_IN}" "yes"
# assert "diff -I '^# --- From file:*' -I "'^#BSUB ?P*'" ${GENERATED_JOB_IN} ${EXPECTED_JOB_IN}" "" # Ignore the line that contain absolute paths or the job header prefix
# assert "file_exists ${GENERATED_JOB_LIST}" "yes"
# assert "diff ${GENERATED_JOB_LIST} ${EXPECTED_JOB_LIST}" ""

# # Run jsub - stage 3 but instead of submitting copy jobs to a directory and zip it
# rm -fr ${GENERATED_PORTABLE_ZIP}
# ${CALL_JSUB} -b -z -a ${GENERATED_PROTABLE_DIR} -o ${GENERATED_JOB_LIST}
# awaitJobNameCompletion "$LSF_JOB_NAME"
# assert "file_exists ${GENERATED_PROTABLE_DIR}/${GENERATED_JOB_IN}" "yes"
# assert "file_exists ${GENERATED_PROTABLE_DIR}/${GENERATED_JOB_LIST}" "yes"
# assert "file_exists ${GENERATED_PROTABLE_DIR}/submit_lsf_jobs.sh" "yes"
# assert "file_exists ${GENERATED_PROTABLE_DIR}/job_submission_functions.sh" "yes"
# assert "file_exists ${GENERATED_PORTABLE_ZIP}" "yes"

clear_generated # Remove existing output from previous tests
# Extract zipped jobs and submit them
tar -zxvf ${GENERATED_PORTABLE_ZIP}
rm -rf ../${GENERATED_PROTABLE_DIR}
mv ${GENERATED_PROTABLE_DIR} .. # Too lazy to change the relative path in the protocol for this test alone
cd ../${GENERATED_PROTABLE_DIR}
# Manually combine the generated job and the rquired local system header information
if [[ ${ABSOLUTE_HEADER_PATH} != "" ]] && [[ ${GENERATED_JOB_IN} != "" ]]; then
  cat ${ABSOLUTE_HEADER_PATH} >> ${GENERATED_JOB_IN}
else
  echo "Warning, there are unset headers variables, job submission may fail..."
  echo "  ABSOLUTE_HEADER_PATH = "${ABSOLUTE_HEADER_PATH}
  echo "  GENERATED_JOB_IN = "${GENERATED_JOB_IN}
fi
bash submit_lsf_jobs.sh ${GENERATED_JOB_LIST}
awaitJobNameCompletion "$LSF_JOB_NAME"
sleep 2 # To let the system catch up with the job output being created
assert "file_exists ${GENERATED_JOB_DATA}" "yes"
assert "diff ${GENERATED_JOB_DATA} ${EXPECTED_JOB_DATA}" ""
assert "file_exists ${GENERATED_JOB_OUTPUT}" "yes"
assert "file_exists ${GENERATED_JOB_ERROR}" "yes"
assert "file_exists ${GENERATED_SUBMITTED_JOBS_LIST}" "yes"
assert "file_exists ${GENERATED_COMPLETED}" "yes"
assert "diff ${GENERATED_COMPLETED} ${EXPECTED_COMPLETED}" ""
pwd
ls -l

## end of test suite
echo ""
assert_end

pwd
ls -l

# EOF

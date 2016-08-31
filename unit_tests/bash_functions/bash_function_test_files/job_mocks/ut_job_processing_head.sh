#!/bin/bash
set -e

#BSUB header sutff

# General job options
JSUB_FLAG_TIMESTAMP=false
JSUB_FLAG_CHECK_VERSIONS=true

# Log and summary file paths
JSUB_PATH_TO_THIS_JOB="$0" # Note: using this will not work on the HPC, "$0" is for testing only, provide the actual file name when running LSF jobs.
JSUB_JOB_ID="unit_test_job"
JSUB_LOG_FILE="$1"
JSUB_SUMMARY_COMPLETED="$2"
JSUB_SUMMARY_INCOMPLETE="$3"


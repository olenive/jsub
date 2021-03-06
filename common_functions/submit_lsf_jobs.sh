#!/bin/bash
set -e

# Script for submitting a list of job files to an LSF queuing system

### INPUT ###
DATETIME=`date +%Y%m%d_%H%M%S`

# File listing job files
LISTJOBFILES="$1"
LISTSUBMITTED="$1".submitted

## Interpret arguments
[[ "$2" == "suppress-warnings" ]] && SUPPRESS_WARNINGS=true || SUPPRESS_WARNINGS=false
# [[ "$3" == "strict" ]] && STRICT=true || STRICT=false
# [[ "$4" == "verbose" ]] && VERBOSE=true || VERBOSE=false

CWD=$(pwd) # Get current working directory

#############

#### FUNCTIONS ####
# Get directory containing the script
function absoluteDirScript {
  local SRC=${BASH_SOURCE[0]}
  local DIR=""
  while [ -h "$SRC" ]; do
    DIR=$( cd -P $( dirname "$SRC") && pwd )
    SRC="\$(readlink "\$SRC")"
    [[ $SRC != /* ]] && SRC="$DIR/$SRC"
  done
  DIR=$( cd -P $(dirname "$SRC") && pwd )
  echo "$DIR"
}
# This function inserts the path to the script as a variable in the script.  This is require because a shell script running on the cluster cannot get its own location using the $0 variable.
function insertPathToSelf {
  local varName="JSUB_PATH_TO_THIS_JOB"
  local jobPath="$1"
  local export topPID=$$
  local tmpPath=${jobPath}.tmp.${topPID} # Create temporary file
  ## Try to make sure the temporary file does nota already exist
  if [ -f "$tmpPath" ]; then
    sleep 3
    if [ -f "$tmpPath" ]; then
      echo "ERROR (in $0 insertPathToSelf): Trying to create temporary file that already exists: ""$tmpPath"
      exit 1
    fi
  else
    sed -i.tmp.${topPID} "s|$varName=.*|$varName=\"$jobPath\"|" "$jobPath"  
  fi
  rm "$tmpPath"
}

## Include job submission functions
DIR_JSUB_FUNCTIONS=$(absoluteDirScript)
ls "$DIR_JSUB_FUNCTIONS"/"job_submission_functions.sh"
source "$DIR_JSUB_FUNCTIONS"/"job_submission_functions.sh"
###################

######## SCRIPT ########
if [ $# -eq 0 ]; then
  echo "$0"" requires an input file listing jobs to be submitted."
fi

## Log attempts to submit job
echo "$DATETIME"" - ""Submitting the following jobs from directory: ""$(pwd)" >> "$LISTSUBMITTED"

## Read lines from list of job file paths
while read -r line || [[ -n "$line" ]]; do

  ## Obtain absolute path to file
  filepath=""
  if [[ $(isAbsolutePath "$line") == "absolute" ]]; then
    filepath="$line"
  else
    filepath="$CWD"/"$line"
  fi

  ## Check if a record of this job being submitted already exists
  flagPresent=false
  if [[ $(isLineInFile ${LISTSUBMITTED} ${filepath}) == "yes" ]]; then
    [[ ${SUPPRESS_WARNINGS} == false ]] && echo "WARNING (""$0"") There already exists a record of the following job being submitted: ""$filepath";
    flagPresent=true
  fi

  ## bsub < file-path for each file and write to log file
  echo "Submitting job: ""$filepath" # [[ ${VERBOSE} == true ]] && "Submitting job file: ""$filepath"
  insertPathToSelf "$filepath"
  bsub < "$filepath"
  echo "$filepath" >> "$LISTSUBMITTED" # Generate a record of submitted files

done < "$LISTJOBFILES"
echo "" >> "$LISTSUBMITTED"

## Tell the user where the submitted jobs file is if it already contained records of these jobs
if [[ flagPresent == true ]]; then
  [[ ${SUPPRESS_WARNINGS} == false ]] && echo "See the following file for previous records of job submissions that matched these jobs: ""$LISTSUBMITTED";
fi
########################

# EOF


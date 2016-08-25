## job_processing parses the job file, writes to log and summary files, and calls version control functions.
# Function allowing job script termination
trap "exit 1" TERM
export TOP_PID=$$
function kill_this_job {
  echo "Terminating job $1"
  kill -s TERM $TOP_PID
}
# Tag variables
JSUB_BEGIN_JOB_TAG="#JSUB<begin_job>"
JSUB_CHECKPOINT_TAG="jcheck_"
JSUB_FINISH_JOB_TAG="#JSUB<finish_job>"
# Job processing variables
JSUB_PREVIOUS_END=0
JSUB_FLAG_FAIL=false
# Writes to log and summray (completed and incomplete) files
function process_job {
  local dateTime=""
  [[ ${JSUB_JOB_TIMESTAMP} = true ]] && dateTime=`date +%Y%m%d_%H%M%S`
  rm -f ${JSUB_SUMMARY_INCOMPLETE} # Clean out the summary.incomplete file so that it is ready to accept a new text from the start
  ## Loop over this job file and process lines
  local jline=0 # Line number within the job commands section
  local flagInJob=false
  local flagBlockEnded=false
  while read -r line || [[ -n "$line" ]]; do
    ## Check if we have entered or left the job commands section
    if [[ ${line} == ${JSUB_BEGIN_JOB_TAG}* ]]; then
      flagInJob=true
      continue
    elif [[ ${line} == ${JSUB_FINISH_JOB_TAG}* ]]; then
      jline=$((jline+1))
      flagInJob=false
    fi
    ## Only process the line if it originated form a summary file
    if [ ${flagInJob} = true ]; then
      jline=$((jline+1)) # Increment line numbers inside job
      ## Determin current line type
      if [ ${flagBlockEnded} = false ]; then
        if [ ${jline} -le ${JSUB_PREVIOUS_END} ]; then # A line before the block of code currently being executed
          : # do nothing
        elif [ ${jline} -gt ${JSUB_PREVIOUS_END} ]; then # A line within the block of code currently being executed
          ## Check if this line corresponds to the end of a block
          if [[ ${line} == ${JSUB_CHECKPOINT_TAG}* ]] || [[ ${line} == ${JSUB_FINISH_JOB_TAG}* ]]; then
            flagBlockEnded=true
            JSUB_PREVIOUS_END=${jline} # Update line number of last block end
          fi
          ## Write to log and summary files
          if [ ${JSUB_FLAG_FAIL} = false ]; then
            echo "$dateTime ""$JSUB_JOB_ID"" completed - "${line} >> ${JSUB_LOG_FILE}
            echo ${line} >> ${JSUB_SUMMARY_COMPLETED}
          else
            echo "$dateTime ""$JSUB_JOB_ID"" incomplete - "${line} >> ${JSUB_LOG_FILE}
            echo ${line} >> ${JSUB_SUMMARY_INCOMPLETE}
          fi
          [[ ${JSUB_VERSION_CONTROL} = true ]] && version_control # Do version control
        fi
      else # A line after the block of code that has just been executed
        echo ${line} >> ${JSUB_SUMMARY_INCOMPLETE}
      fi
    fi
  done < ${JSUB_THIS_JOB}
  [ ${JSUB_FLAG_FAIL} = true ] && kill_this_job ${JSUB_THIS_JOB} # Kill the job if a checkpoint fail occured (but let this function do logging etc first)
  return 0
}

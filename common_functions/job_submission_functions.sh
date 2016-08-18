# Functions used by the submit_lsf_jobs.sh script

# Determine if a path starts with a forward slash
function isAbsolutePath {
  local DIR="$1"
  [[ ${DIR:0:1} == '/' ]] && echo "absolute" || echo "relative"
}

# Check for duplicate lines in a text file
function checkForDuplicateLines {
  local file="$1"
  local _suppress_warnings="$2"
  local _strict="$3"
  [[ ${_suppress_warnings} == false ]] && echo "Checking for duplicates in " "$file"
  DUPLICATES=$(sort "$file" | uniq -c | awk '$1>1')
  if [ ${#DUPLICATES} -ne 0 ]; then
    if [[ ${_strict} == true ]]; then
      echo "TERMINATING (in checkForDuplicateLines) after finding duplicate entries in list of job files to be submitted:"
      sort "$file" | uniq -c | awk '$1>1'
      exit 1
    fi
    if [[ ${_suppress_warnings} == false ]] && [[ ${_suppress_warnings} == false ]]; then
      echo "WARNING (in checkForDuplicateLines): Found duplicate entries in list of job files to be submitted:"
      sort "$file" | uniq -c | awk '$1>1'
    fi
  fi
}

# Check if an exact match for the input string is a line in a text file
function isLineInFile {
  local file="$1"
  local query="$2"
  local flagMatch=false
  while read -r line || [[ -n "$line" ]]; do
    if [[ ${query} == ${line} ]]; then
      flagMatch=true
    fi
  done < "$file"
  [[ ${flagMatch} == true ]] && echo "yes" || echo "no"
}

# Get directory containing the script
function absolutePathScript {
  local SOURCE=${BASH_SOURCE[0]}
  local DIR=""
  while [ -h "$SOURCE" ]; do
    DIR=$( cd -P $( dirname "$SOURCE") && pwd )
    SOURCE="\$(readlink "\$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  done
  DIR=$( cd -P $( dirname "$SOURCE" ) && pwd )
  echo "$DIR"
}

# EOF

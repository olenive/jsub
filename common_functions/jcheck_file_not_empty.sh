function file_contains_nonwhitespace {
  while read -r line || [[ -n "$line" ]]; do
    if [[ "$line" = *[![:space:]]* ]]; then
      echo "yes"
      return 0
    fi
  done < "$1"
  echo "no"
}
function jcheck_file_not_empty {
  local dateTime=""
  [[ ${JSUB_JOB_TIMESTAMP} = true ]] && dateTime=`date +%Y%m%d_%H%M%S`
  for var in "$@"; do
    if [[ ! -s "$var" ]] || [[ $(file_contains_nonwhitespace "$var") = "no" ]]; then
      JSUB_FLAG_FAIL=true
      echo "$dateTime ""$JSUB_JOB_ID"" - Failed checkpoint jcheck_file_not_empty due to empty (or whitespace) file: ""$var"
      echo "$dateTime ""$JSUB_JOB_ID"" - Failed checkpoint jcheck_file_not_empty due to empty (or whitespace) file: ""$var" >> ${JSUB_LOG_FILE}
    else
      echo "$dateTime ""$JSUB_JOB_ID"" - Passed checkpoint jcheck_file_not_empty for file: ""$var" >> ${JSUB_LOG_FILE}
    fi
  done
}
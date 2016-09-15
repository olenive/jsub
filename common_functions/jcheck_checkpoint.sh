# Checks if a fail has been flagged up and provides a point from which jobs can be re-started.
# It is probably better to use more specific checkpoint functions such as jcheck_file_not_empty.
function jcheck_checkpoint {
  local dateTime=""
  [[ ${JSUB_JOB_TIMESTAMP} = true ]] && dateTime=`date +%Y%m%d_%H%M%S`
  if [[ "$JSUB_FLAG_FAIL" = true ]]; then
    echo "$dateTime ""$JSUB_JOB_ID"" - Fail flagged (JSUB_FLAG_FAIL) before call to jcheck_checkpoint."
    echo "$dateTime ""$JSUB_JOB_ID"" - Fail flagged (JSUB_FLAG_FAIL) before call to jcheck_checkpoint." >> ${JSUB_LOG_FILE}
  else
    echo "$dateTime ""$JSUB_JOB_ID"" - Passed jcheck_checkpoint." >> ${JSUB_LOG_FILE}
  fi
}
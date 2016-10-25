## Functions used to run integration test
function file_exists {
  if [ -f "$1" ]; then echo "yes"; else echo "no"; fi
}
function clear_generated {
  rm -rf "lsf_output"
  rm -rf "summaries"
  rm -rf "jobs"
  rm -rf "results"
  rm -f *".error"
  rm -f *".output"
}
function isAbsolutePath {
  local DIR="$1"
  [[ ${DIR:0:1} == '/' ]] && echo "absolute" || echo "relative"
}
function isJobNameInQueue {
  local jobName="$1"
  local res=$(bjobs -J ${jobName})
  if [ "$res" = "" ]; then
    echo "no"
  else
    echo "yes"
  fi
}
function awaitJobNameCompletion {
  echo "Awaiting completion of job named ""$1"
  while [ $(isJobNameInQueue "$1") == "yes" ]; do
    sleep 1
  done
  echo "...presumed to be completed."
}
# Function used to determine the require option (-c) and file path for the header file containing text included in all jobs
function getCommonHeaderOptionString {
  if [ "$1" == "" ]; then
    echo ""
  elif [ $(isAbsolutePath "$1") == "relative" ]; then
    echo " --header-from-file ../""$1"
  else
    echo " --header-from-file ""$1"
  fi
}
function forcePathAbsolute {
  if [ "$1" == "" ]; then
    echo ""
  elif [ $(isAbsolutePath "$1") == "relative" ]; then
    echo "$PWD"/"$1"
  else
    echo "$1"
  fi
}
function compare_contents { # Calls diff but if one of the input files does not exit returns an error string
  if ! [ -f "$1" ] || ! [ -f "$2" ] ; then
    ! [ -f "$1" ] && echo "Failed contents comparison due to missing file: $1"
    ! [ -f "$2" ] && echo "Failed contents comparison due to missing file: $2"
  else # pass remaining arguments as options to diff
    diff "$1" "$2" "${@:3}"
  fi
}

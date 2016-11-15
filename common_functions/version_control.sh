# Function used to try to keep track of the versions of arbitrary software on the system by checking the which command, --version and -version arguments and checking for the existance of git repositories.
function is_in_gitrepo { # Checks if file is being tracked by a git repository
  cd $(dirname "$1")
  [ -d .git ] || git rev-parse --is-inside-git-dir > /dev/null 2>&1 # Check if this directory is in a repo
  [ "$?" = 0 ] && git ls-files --error-unmatch $(basename "$1") > /dev/null 2>&1 # Check if the file is tracked
  [ "$?" = 0 ] && echo "yes" || echo "no"
}
function log_file_gitrepo { # Write status of git repository to a log file
  local pathSrc="$1"
  local logFile="$2"
  if [ -f "$pathSrc" ] && [ $(is_in_gitrepo "$pathSrc") = "yes" ]; then
    local pathRepo=$(cd $(dirname "$pathSrc"); git rev-parse --show-toplevel) # Get root of repository
    echo "$dateTime ""$JSUB_JOB_ID"" git - repository associated with: "${pathSrc} >> ${logFile}
    # Get the hash of the last commit.
    echo "Date and hash in repository: "${pathRepo} >> ${logFile}
    echo $(git --git-dir ${pathRepo}/.git  show -s --format=%ci HEAD)" "$(git --git-dir ${pathRepo}/.git rev-parse HEAD) >> ${logFile}
    # Write git status to log file
    echo "Status of repository at date_time: "`date +%Y%m%d_%H%M%S` >> ${logFile}
    git --git-dir=${pathRepo}/.git --work-tree=${pathRepo} status >> ${logFile}
  fi
}
function has_which {
  which "$1"  > /dev/null 2>&1
  [ "$?" = 0 ] && echo "yes" || echo "no"
}
function log_version { # $1 = word $2 = log file
  if [ $(has_which "$1") = "yes" ]; then
    echo "" >> "$2"
    echo "$dateTime ""$JSUB_JOB_ID"" version - ""which $1" >> "$2"
    echo $(which "$1") >> "$2"
  fi
}
function is_special_word { # Used to skip words for which version control should not be attempted
  declare -a exclude=('#' '=' '[' ']' '{' '}' '$?' 'if' 'then' 'else' 'elif' 'fi' 'for' 'while' 'do' 'done')
  local flagYes=false
  for word in "${exclude[@]}"; do
    if [ "$word" = "$1" ]; then
      flagYes=true
      break
    fi
  done
  [ "$flagYes" = true ] && echo "yes" || echo "no"
}
function version_control {
  local cmdString="$1"
  echo "Running version_control on cmdString: ""$cmdString" >> ${JSUB_LOG_FILE}
  for word in ${cmdString[@]}; do
    [[ ${cmdString[0]} = \#* ]] && break # Ignore commented lines
    echo "current word: ""$word" >> ${JSUB_LOG_FILE}
    if [ $(is_special_word "$word") = "yes" ]; then
      echo "...nothing to be done" >> ${JSUB_LOG_FILE}
    else
      log_version "$word" ${JSUB_LOG_FILE}
      log_file_gitrepo "$word" ${JSUB_LOG_FILE}
      echo "" >> ${JSUB_LOG_FILE}
    fi
  done
}
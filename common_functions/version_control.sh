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
    echo "Found git repository associated with: "${pathSrc} >> ${logFile}
    # Get the hash of the last commit.
    echo "Date and hash in repository: "${pathRepo} >> ${logFile}
    echo $(git --git-dir ${pathRepo}/.git  show -s --format=%ci HEAD)" "$(git --git-dir ${pathRepo}/.git rev-parse HEAD) >> ${logFile}
    # Write git status to log file
    echo "Status of repository at date_time: "`date +%Y%m%d_%H%M%S` >> ${logFile}
    git --git-dir=${pathRepo}/.git --work-tree=${pathRepo} status >> ${logFile}
  fi
}
function has_dashdash_version {
  "$1" --version  > /dev/null 2>&1
  [ "$?" = 0 ] && echo "yes" || echo "no"
}
function has_dash_version {
  "$1" -version  > /dev/null 2>&1
  [ "$?" = 0 ] && echo "yes" || echo "no"
}
function has_which {
  which "$1"  > /dev/null 2>&1
  [ "$?" = 0 ] && echo "yes" || echo "no"
}
function log_version { # $1 = word $2 = log file
  if [ $(has_dashdash_version "$1") = "yes" ]; then
    echo "### ""$1"" --version" >> "$2"
    echo $("$1" --version) >> "$2"
    echo "" >> "$2"
  elif [ $(has_dash_version "$1") = "yes" ]; then
    echo "### ""$1"" -version" >> "$2"
    echo $("$1" -version) >> "$2"
    echo "" >> "$2"
  fi
  if [ $(has_which "$1") = "yes" ]; then
    echo "### which $1" >> "$2"
    echo $(which "$1") >> "$2"
    echo "" >> "$2"
  fi
}
function is_special_word { # Used to skip words for which version control should not be attempted
  declare -a exclude=('[' ']' '{' '}' '$?' 'if' 'then' 'else' 'elif' 'fi' 'for' 'while' 'do' 'done')
  for word in "${exclude[@]}"; do
    if [ "$word" = "$1" ]; then
      echo "yes"
      break
    fi
  done
}
function version_control {
  if [ $(is_special_word "$1") = "yes" ]; then
    :
  else
    for word in "$1"; do
      # echo "Running version_control on word: ""$word" >> ${JSUB_LOG_FILE}
      log_version "$word" ${JSUB_LOG_FILE}
      log_file_gitrepo "$word" ${JSUB_LOG_FILE}
    done
  fi
}
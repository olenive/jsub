
# Attempts to obtain version information about tools and scripts used in a block of bash code.
function check_versions {
  echo "Running check_versions"
}

# Contents inserted from other files (this section is intended to be used only for functions):
# --- From file: jlang_function_test_files/dummy_bash_functions/dummy1.sh
function dummy1 {
echo Running_dummy_function_1 >> ${JSUB_LOG_FILE}
}
# --- From file: jlang_function_test_files/dummy_bash_functions/dummy2.sh
function dummy2 {
echo Running_dummy_function_2 >> ${JSUB_LOG_FILE}
}
function dummy2_1 {
echo Running_dummy_function_2_1 >> ${JSUB_LOG_FILE}
}
# --- From file: jlang_function_test_files/dummy_bash_functions/dummy3.sh
function dummy3 {
echo Running_dummy_function_3 >> ${JSUB_LOG_FILE}
}

function jcheck_resume {
  echo "Running jcheck_resume $@" >> ${JSUB_LOG_FILE}
  process_job "YYYYMMDD_HHMMSS"
}

#JSUB<begin_job>
#JGROUP second first third fourth fifth
echo "cmd 21" >> ${JSUB_LOG_FILE}
dummy1
jcheck_resume
#BSUB -J jobID
echo "cmd 22" >> ${JSUB_LOG_FILE}
dummy2
jcheck_resume
dummy2_1
#BSUB -o out.pj.output
echo "cmd 23" >> ${JSUB_LOG_FILE}
jcheck_resume
dummy3
#BSUB -e out.pj.error
jcheck_resume
echo "final executed command" >> ${JSUB_LOG_FILE}
#JSUB<finish_job>

# Finalise job
process_job

# EOF 

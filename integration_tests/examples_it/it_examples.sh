#!/bin/bash
set -e

# These integration tests run examples using the run_example_*.sh files and clear_example_*.sh files.
# Here the aim is to make sure the examples run rather than to test the correctness of the output.

### Integration test 1: fvars test

####### INPUTS ########
JOB_HEADER="$1"

#######################

### FUNCTIONS ###
source ../common_it_functions.sh
#################

. ../assert.sh
echo ""
echo "Running integration test: ""$0""..."

# Set current and target directories
DIR_ORIGIN=$(pwd)
DIR_EXAMPLES="../../examples/"

# Create a my_job_header.txt file
cp "$JOB_HEADER" "$DIR_EXAMPLES"/my_job_header.txt

# Set an alias for jsub (because this is what is used in the examples)
cd "$DIR_EXAMPLES"/..
alias jsub="julia $(pwd)/jsub.jl "
cd "$DIR_ORIGIN"

# Begin running tests
echo ""; echo " Testing example 1"
cd "$DIR_EXAMPLES"/"example_01"
# Clear out previously generated files and run the example
bash clear_example_01.sh
bash run_example_01.sh
bjobs
awaitJobNameCompletion echo_1_1
# Check that the expected files were generated
assert "file_exists echo_1_1.completed" "yes"
assert "file_exists echo_1_1.error" "yes"
assert "file_exists echo_1_1.lsf" "yes"
assert "file_exists echo_1_1.output" "yes"
assert "file_exists echo_1.log" "yes"
assert "file_exists echo_1.summary" "yes"
assert "file_exists echo.list-jobs" "yes"
assert "file_exists echo.list-jobs.submitted" "yes"
assert "file_exists echo.list-summaries" "yes"
assert "file_exists example_01_output.txt" "yes"
# 10
bash clear_example_01.sh
cd "$DIR_ORIGIN"

echo ""; echo " Testing example 2"
cd "$DIR_EXAMPLES"/"example_02"
# Clear out previously generated files and run the example
bash clear_example_02.sh
bash run_example_02_A.sh
bjobs
awaitJobNameCompletion echo02_vars02_A_1_1
# Check that the expected files were generated
assert "file_exists  echo02_vars02_A_1_1.completed" "yes"
assert "file_exists  echo02_vars02_A_1_1.error" "yes"
assert "file_exists  echo02_vars02_A_1_1.lsf" "yes"
assert "file_exists  echo02_vars02_A_1_1.output" "yes"
assert "file_exists  echo02_vars02_A_1.log" "yes"
assert "file_exists  echo02_vars02_A_1.summary" "yes"
assert "file_exists  echo02_vars02_A.list-jobs" "yes"
assert "file_exists  echo02_vars02_A.list-jobs.submitted" "yes"
assert "file_exists  echo02_vars02_A.list-summaries" "yes"
assert "file_exists  example_02_output.txt" "yes"
# 20
# Clear out previously generated files and run the example
bash clear_example_02.sh
bash run_example_02_B.sh
bjobs
awaitJobNameCompletion echo02_vars02_B_1_1
# Check that the expected files were generated
assert "file_exists  echo02_vars02_B_1_1.completed" "yes"
assert "file_exists  echo02_vars02_B_1_1.error" "yes"
assert "file_exists  echo02_vars02_B_1_1.lsf" "yes"
assert "file_exists  echo02_vars02_B_1_1.output" "yes"
assert "file_exists  echo02_vars02_B_1.log" "yes"
assert "file_exists  echo02_vars02_B_1.summary" "yes"
assert "file_exists  echo02_vars02_B.list-jobs" "yes"
assert "file_exists  echo02_vars02_B.list-jobs.submitted" "yes"
assert "file_exists  echo02_vars02_B.list-summaries" "yes"
assert "file_exists  example_02_output.txt" "yes"
# 20
bash clear_example_02.sh
cd "$DIR_ORIGIN"




## end of test suite
assert_end

# EOF


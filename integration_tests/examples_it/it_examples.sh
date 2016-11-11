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
# 30
bash clear_example_02.sh
cd "$DIR_ORIGIN"

echo ""; echo " Testing example 3"
cd "$DIR_EXAMPLES"/"example_03"
# Clear out previously generated files and run the example
bash clear_example_03.sh
bash run_example_03.sh
bjobs
awaitJobNameCompletion echo03_vars02_fvars03_1_1
awaitJobNameCompletion echo03_vars02_fvars03_2_2
awaitJobNameCompletion echo03_vars02_fvars03_3_3
# Check that the expected files were generated
assert "file_exists echo03_vars02_fvars03_1_1.completed" "yes"
assert "file_exists echo03_vars02_fvars03_1_1.error" "yes"
assert "file_exists echo03_vars02_fvars03_1_1.lsf" "yes"
assert "file_exists echo03_vars02_fvars03_1_1.output" "yes"
assert "file_exists echo03_vars02_fvars03_1.log" "yes"
assert "file_exists echo03_vars02_fvars03_1.summary" "yes"
assert "file_exists echo03_vars02_fvars03_2_2.completed" "yes"
assert "file_exists echo03_vars02_fvars03_2_2.error" "yes"
assert "file_exists echo03_vars02_fvars03_2_2.lsf" "yes"
assert "file_exists echo03_vars02_fvars03_2_2.output" "yes"
assert "file_exists echo03_vars02_fvars03_2.log" "yes"
assert "file_exists echo03_vars02_fvars03_2.summary" "yes"
assert "file_exists echo03_vars02_fvars03_3_3.completed" "yes"
assert "file_exists echo03_vars02_fvars03_3_3.error" "yes"
assert "file_exists echo03_vars02_fvars03_3_3.lsf" "yes"
assert "file_exists echo03_vars02_fvars03_3_3.output" "yes"
assert "file_exists echo03_vars02_fvars03_3.log" "yes"
assert "file_exists echo03_vars02_fvars03_3.summary" "yes"
assert "file_exists echo03_vars02_fvars03.list-jobs" "yes"
assert "file_exists echo03_vars02_fvars03.list-jobs.submitted" "yes"
assert "file_exists echo03_vars02_fvars03.list-summaries" "yes"
assert "file_exists outfile1.txt" "yes"
assert "file_exists outfile2.txt" "yes"
assert "file_exists outfile3.txt" "yes"
# 54
bash clear_example_03.sh
cd "$DIR_ORIGIN"

echo ""; echo " Testing example 4"
cd "$DIR_EXAMPLES"/"example_04"
# Clear out previously generated files and run the example
bash clear_example_04.sh
bash run_example_04.sh
bjobs
awaitJobNameCompletion sumpre_echo03_vars02_fvars03_1_1
awaitJobNameCompletion sumpre_echo03_vars02_fvars03_2_2
awaitJobNameCompletion sumpre_echo03_vars02_fvars03_3_3
# Check that the expected files were generated
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_1_1.lsf" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_1.log" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_2_2.lsf" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_2.log" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_3_3.lsf" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_3.log" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03.list-jobs" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03.list-jobs.submitted" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_1_1.error" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_1_1.output" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_2_2.error" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_2_2.output" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_3_3.error" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_3_3.output" "yes"
assert "file_exists outfile1.txt" "yes"
assert "file_exists outfile2.txt" "yes"
assert "file_exists outfile3.txt" "yes"
assert "file_exists progoress/completed/sumpre_echo03_vars02_fvars03_1_1.completed" "yes"
assert "file_exists progoress/completed/sumpre_echo03_vars02_fvars03_2_2.completed" "yes"
assert "file_exists progoress/completed/sumpre_echo03_vars02_fvars03_3_3.completed" "yes"
assert "file_exists summaries/sumpre_echo03_vars02_fvars03_1.summary" "yes"
assert "file_exists summaries/sumpre_echo03_vars02_fvars03_2.summary" "yes"
assert "file_exists summaries/sumpre_echo03_vars02_fvars03_3.summary" "yes"
assert "file_exists summaries/sumpre_echo03_vars02_fvars03.list-summaries" "yes"
# 78
bash clear_example_04.sh
cd "$DIR_ORIGIN"

echo ""; echo " Testing example 5"
cd "$DIR_EXAMPLES"/"example_05"
# Clear out previously generated files and run the example
bash clear_example_05.sh
bash run_example_05.sh
bjobs
awaitJobNameCompletion sumpre_echo03_vars02_fvars03_1_1
awaitJobNameCompletion sumpre_echo03_vars02_fvars03_2_2
awaitJobNameCompletion sumpre_echo03_vars02_fvars03_3_3
# Check that the expected files were generated
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_1_1.lsf" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_1.log" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_2_2.lsf" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_2.log" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_3_3.lsf" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_3.log" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03.list-jobs" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03.list-jobs.submitted" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_1_1.error" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_1_1.output" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_2_2.error" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_2_2.output" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_3_3.error" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_3_3.output" "yes"
assert "file_exists outfile1.txt" "yes"
assert "file_exists outfile2.txt" "yes"
assert "file_exists outfile3.txt" "yes"
assert "file_exists progoress/completed/sumpre_echo03_vars02_fvars03_1_1.completed" "yes"
assert "file_exists progoress/completed/sumpre_echo03_vars02_fvars03_2_2.completed" "yes"
assert "file_exists progoress/completed/sumpre_echo03_vars02_fvars03_3_3.completed" "yes"
assert "file_exists summaries/sumpre_echo03_vars02_fvars03_1.summary" "yes"
assert "file_exists summaries/sumpre_echo03_vars02_fvars03_2.summary" "yes"
assert "file_exists summaries/sumpre_echo03_vars02_fvars03_3.summary" "yes"
assert "file_exists summaries/sumpre_echo03_vars02_fvars03.list-summaries" "yes"
# 102
bash clear_example_05.sh
cd "$DIR_ORIGIN"

echo ""; echo " Testing example 5"
cd "$DIR_EXAMPLES"/"example_05"
# Clear out previously generated files and run the example
bash clear_example_05.sh
bash run_example_05.sh
bjobs
awaitJobNameCompletion sumpre_echo03_vars02_fvars03_1_1
awaitJobNameCompletion sumpre_echo03_vars02_fvars03_2_2
awaitJobNameCompletion sumpre_echo03_vars02_fvars03_3_3
# Check that the expected files were generated
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_1_1.lsf" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_1.log" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_2_2.lsf" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_2.log" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_3_3.lsf" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03_3.log" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03.list-jobs" "yes"
assert "file_exists jobs/jobpre_sumpre_echo03_vars02_fvars03.list-jobs.submitted" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_1_1.error" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_1_1.output" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_2_2.error" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_2_2.output" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_3_3.error" "yes"
assert "file_exists lsf_out/lsf_sumpre_echo03_vars02_fvars03_3_3.output" "yes"
assert "file_exists outfile1.txt" "yes"
assert "file_exists outfile2.txt" "yes"
assert "file_exists outfile3.txt" "yes"
assert "file_exists progoress/completed/sumpre_echo03_vars02_fvars03_1_1.completed" "yes"
assert "file_exists progoress/completed/sumpre_echo03_vars02_fvars03_2_2.completed" "yes"
assert "file_exists progoress/completed/sumpre_echo03_vars02_fvars03_3_3.completed" "yes"
assert "file_exists summaries/sumpre_echo03_vars02_fvars03_1.summary" "yes"
assert "file_exists summaries/sumpre_echo03_vars02_fvars03_2.summary" "yes"
assert "file_exists summaries/sumpre_echo03_vars02_fvars03_3.summary" "yes"
assert "file_exists summaries/sumpre_echo03_vars02_fvars03.list-summaries" "yes"
# 126
bash clear_example_05.sh
cd "$DIR_ORIGIN"

echo ""; echo " Testing example 6"
cd "$DIR_EXAMPLES"/"example_06"
# Clear out previously generated files and run the example
bash clear_example_06.sh
bash run_example_06.sh
bjobs
awaitJobNameCompletion echo06_vars06_fvars06_1_1
awaitJobNameCompletion echo06_vars06_fvars06_2_2
# Check that the expected files were generated
assert "file_exists jobs/echo06_vars06_fvars06_1_1.lsf" "yes"
assert "file_exists jobs/echo06_vars06_fvars06_1.log" "yes"
assert "file_exists jobs/echo06_vars06_fvars06_2_2.lsf" "yes"
assert "file_exists jobs/echo06_vars06_fvars06_2.log" "yes"
assert "file_exists jobs/echo06_vars06_fvars06.list-jobs" "yes"
assert "file_exists jobs/echo06_vars06_fvars06.list-jobs.submitted" "yes"
assert "file_exists lsf_out/echo06_vars06_fvars06_1_1.error" "yes"
assert "file_exists lsf_out/echo06_vars06_fvars06_1_1.output" "yes"
assert "file_exists lsf_out/echo06_vars06_fvars06_2_2.error" "yes"
assert "file_exists lsf_out/echo06_vars06_fvars06_2_2.output" "yes"
assert "file_exists progoress/completed/echo06_vars06_fvars06_1_1.completed" "yes"
assert "file_exists progoress/incomplete/echo06_vars06_fvars06_2_2.incomplete" "yes"
assert "file_exists results_Anum1.txt" "yes"
assert "file_exists results_Anum2.txt" "yes"
assert "file_exists results_Bnum1.txt" "yes"
assert "file_exists results_Bnum2.txt" "yes"
assert "file_exists summaries/echo06_vars06_fvars06_1.summary" "yes"
assert "file_exists summaries/echo06_vars06_fvars06_2.summary" "yes"
assert "file_exists summaries/echo06_vars06_fvars06.list-summaries" "yes"
# 145
bash clear_example_06.sh
cd "$DIR_ORIGIN"

echo ""; echo " Testing example 7"
cd "$DIR_EXAMPLES"/"example_07"
# Clear out previously generated files and run the example
bash clear_example_07.sh
bash run_example_07.sh
bjobs
awaitJobNameCompletion cat07_vars07_fvars07_1_1
awaitJobNameCompletion cat07_vars07_fvars07_2_2
# Check that the expected files were generated
assert "file_exists  summaries/cat07_vars07_fvars07_1.summary" "yes"
assert "file_exists  summaries/cat07_vars07_fvars07_2.summary" "yes"
assert "file_exists  summaries/cat07_vars07_fvars07.list-summaries" "yes"
assert "file_exists  dummy_output/pre_result_1A.txt" "yes"
assert "file_exists  dummy_output/pre_result_1B.txt" "yes"
assert "file_exists  dummy_output/pre_result_1C.txt" "yes"
assert "file_exists  dummy_output/pre_result_2A.txt" "yes"
assert "file_exists  dummy_output/pre_result_2B.txt" "yes"
assert "file_exists  dummy_output/pre_result_2C.txt" "yes"
assert "file_exists  dummy_output/result_1A.txt" "yes"
assert "file_exists  dummy_output/result_1B.txt" "yes"
assert "file_exists  dummy_output/result_1C.txt" "yes"
assert "file_exists  dummy_output/result_2A.txt" "yes"
assert "file_exists  dummy_output/result_2C.txt" "yes"
assert "file_exists  jobs/cat07_vars07_fvars07_1_1.lsf" "yes"
assert "file_exists  jobs/cat07_vars07_fvars07_1.log" "yes"
assert "file_exists  jobs/cat07_vars07_fvars07_2_2.lsf" "yes"
assert "file_exists  jobs/cat07_vars07_fvars07_2.log" "yes"
assert "file_exists  jobs/cat07_vars07_fvars07.list-jobs" "yes"
assert "file_exists  jobs/cat07_vars07_fvars07.list-jobs.submitted" "yes"
assert "file_exists  lsf_out/cat07_vars07_fvars07_1_1.error" "yes"
assert "file_exists  lsf_out/cat07_vars07_fvars07_1_1.output" "yes"
assert "file_exists  lsf_out/cat07_vars07_fvars07_2_2.error" "yes"
assert "file_exists  lsf_out/cat07_vars07_fvars07_2_2.output" "yes"
assert "file_exists  progoress/completed/cat07_vars07_fvars07_1_1.completed" "yes"
assert "file_exists  progoress/completed/cat07_vars07_fvars07_2_2.completed" "yes"
assert "file_exists  progoress/incomplete/cat07_vars07_fvars07_2_2.incomplete" "yes"
assert "file_exists  summaries/cat07_vars07_fvars07_1.summary" "yes"
assert "file_exists  summaries/cat07_vars07_fvars07_2.summary" "yes"
assert "file_exists  summaries/cat07_vars07_fvars07.list-summaries" "yes"

# re-run with the missing file now where it is expected
bash rerun_example_07.sh
bjobs
awaitJobNameCompletion cat07_vars07_fvars07_2_2.incomplete_1
assert "file_exists  re_jobs/re_cat07_vars07_fvars07_2_2.incomplete_1.lsf" "yes"
assert "file_exists  re_jobs/re_cat07_vars07_fvars07_2_2.incomplete.log" "yes"
assert "file_exists  re_jobs/re_resumed.list-jobs" "yes"
assert "file_exists  re_jobs/re_resumed.list-jobs.submitted" "yes"
assert "file_exists  re_lsf_out/lsf_cat07_vars07_fvars07_2_2.incomplete_1.error" "yes"
assert "file_exists  re_lsf_out/lsf_cat07_vars07_fvars07_2_2.incomplete_1.output" "yes"
assert "file_exists  re_progoress/completed/cat07_vars07_fvars07_2_2.incomplete_1.completed" "yes"

bash clear_example_07.sh
cd "$DIR_ORIGIN"



## end of test suite
assert_end

# EOF


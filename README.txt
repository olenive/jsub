This is a light weight tool for creating and submitting job file to the LSF queuing system.  Its purpose is to automate job file generation in cases where the same processing steps need to be applied to different sets of input data.

Dependencies
The code for generating job files is written in Julia (version 0.4.0) and uses the ArgParse package (v0.3.1).  Job files use bash shell command and have been tested with LSF version 9.1.2.0 in a Linux environment.


Aims
Traceability: Job files produced by jsub contain bash shell functions that write to log files as the job proceeds. This creates a record of the steps taken to obtain the resulting output data.

Modularity: Paths to the input data and the steps taken to process it can be specified in separate files.


Example 1 - minimal
The most basic use of jsub is to pass a file listing bash commands as an argument to --protocol.  The tool will create the required files and submit an LSF job.

NOTE: Depending on your LSF setup you may need to provide specific options to LSF, such as a grant code or a queue length.  The prefered way of doing this is to write the desired options into a text file (in the same format as you would in an LSF job file) and provide the path to this file as an argument to the "--header-from-file" option.
For a full list of options run jsub with the "--help" flag.

Example header file contents "my_job_header_file.txt":
#BSUB -P grant-code
#BSUB -q short

Assuming both Julia and LSF are running in the current environment and Julia is accessible with the julia command.
From the jsub directory:

alias jsub="julia $(pwd)/jsub.jl "

cd examples/example_01

jsub --protocol echo.protocol --header-from-file "my_job_header_file.txt"

Running this example should produce the following files:
./echo_1_1.completed
./echo_1_1.error
./echo_1_1.lsf
./echo_1_1.output
./echo_1.log
./echo_1.summary
./echo.list-jobs
./echo.list-jobs.submitted
./echo.list-summaries
./example_01_output.txt

Here is the order of events, jsub runs in three disticnt stages that may be run together or separately.

STAGE 1) 
The file "echo.protocol" is parsed and the file "echo_1.summary" is generated from it.
In this simple case the two files are identical but in more complex situations variables in *.protocol files are substituted for values in other files resulting in multiple *.summary files per *.protocol file (see below).
The file echo.list-summaries contains a list of the summary files generated (just one in this case).

STAGE 2) The echo_1.summary file is used to generate the job files echo_1_1.lsf and echo.list-jobs.

STAGE 3) The job files from stage 2 are submitted to LSF.  The list of submitted files is found in "echo.list-jobs.submitted" and the results of running the bash commands in the file can be seen in "example_01_output.txt".  LSF writes stdout and stderr to "echo_1_1.output" and "echo_1_1.error" respectively.  Functions in the job file create a list the steps that appear to have been completed successfully in the file "echo_1_1.completed" and write other information to "echo_1.log".


Example 2 - vars
Consider an extension of example 1 where want to echo specified strings to the output file.  Suppose that there are several combinations of inputs and we want to try them one at a time while keeping the overall procedure the same (see: examples/example_02/echo_vars.protocol).  

Variables are declared in the protocol file using the same syntax as in bash (e.g. $VARIABLE or ${VARIABLE}).

We can create a table of variable names and their associated values in a file and pass it as an argument to the --vars option (see examples/example_02/vars02.vars)

NOTE: While it is possible to declare variables in the protocol as you would in a bash script, this removes the ability to change their values without changing the protocol file.  Doing so may also cause problems for protocols that are used to generate multiple job files.

If we want to try a different set of values we don't need to change the echo_vars.protocol file, instead we can supply a different file to --vars.

NOTE: The expected format for a file passed to --vars is two, tab-delimited columns with the variable names in the left column.

cd examples/example_02

jsub --protocol echo02.protocol \
     --header-from-file "my_job_header_file.txt" \
     --vars vars02.vars


Example 3 - fvars
We often want to run the same procedure on a list of files, for example, different experimental samples.
To facilitate this the --fvars argument takes a path to a file that consists of a three, tab-delimited columns listing (1) variable names, (2) column numbers and (3) paths to list files.
One summary file is created for each row of the list files.  This summary file corresponds to the protocol file but with variable names substituted for values taken from the list files.

NOTE: the list files are required to have the same number of rows to avoid ambiguity.

The files listed in column 3 supply values to the matching variables in the protocol.

For example, if the file passed to --fvars contains the following lines:
LVAR1 1 list_file.txt 
LVAR2 2 list_file.txt 

and the file "list_file.txt" contains values:
row1col1  row1col2
row2col1  row2col2
row3col1  row3col2

Three summary files will be generated.  Instances of "$LVAR1" or "$LVAR2" will be replaces with values from the corresponding rows and columns found in "list_file.txt".

cd examples/example_03

jsub --protocol echo03.protocol \
     --header-from-file "my_job_header_file.txt" \
     --vars vars02.vars \
     --fvars fvars03.fvars

NOTE: Jobs are run in a non-deterministic order (determined by LSF) so it is usually best not to write the output from different jobs to the same file. 

NOTE: Variable values passed via --vars are used to expand matching variables in the file passed to --fvars.

NOTE: the two numbers in the default file names refer to the number of the summary file and the number of the job file respectively.


Example 4 - prefixes
The number of files generated by jsub and LSF starts to grow as longer lists are usesd.  We can use prefixes to specify output file locations (for a full list of prefix options run jsub with the --help flag).

cd examples/example_04

jsub --protocol echo03.protocol \
     --header-from-file "my_job_header_file.txt" \
     --vars vars02.vars \
     --fvars fvars03.fvars \
     --summary-prefix "summaries/sumpre_" \
     --job-prefix "jobs/jobpre_" \
     --prefix-lsf-out "lsf_out/lsf_" \
     --prefix-completed "progoress/completed/" \
     --prefix-incomplete "progoress/incomplete/" \
     --timestamp-files


Example 5 stages
In the above examples all the stages were run together.  Here we run them one at a time.

cd examples/example_05

To generate summary files from the protocol and variables supplied to --protocol, --vars, and --fvars we use the --generate-summaries flag.

jsub --generate-summaries \
     --protocol echo03.protocol \
     --vars vars02.vars \
     --fvars fvars03.fvars \
     --summary-prefix "summaries/sumpre_"

The --generate-jobs flag indicates that job files should be generated from summary files.  To do this we only need to pass the list of summary files using the --list-summaries option. 
However, to make sure that the job files have the correct header information used by LSF on your system, a header file may need to be provided.
The remaining options provide output prefixes to help keep things tidy. 

jsub --generate-jobs \
     --list-summaries summaries/sumpre_echo03_vars02_fvars03.list-summaries \
     --header-from-file "my_job_header_file.txt" \
     --job-prefix "jobs/jobpre_" \
     --prefix-lsf-out "lsf_out/lsf_" \
     --prefix-completed "progoress/completed/" \
     --prefix-incomplete "progoress/incomplete/" \
     
The job files can now be submitted to the queue.  The preferred way of doing this is to call jsub with the --submit-jobs flag and providing a path to the file listing the job file paths.

jsub --submit-jobs \
     --list-jobs jobs/jobpre_sumpre_echo03_vars02_fvars03.list-jobs

Submission is actually handled by a shell script (common_functions/submit_lsf_jobs.sh).  Functions in the job files rely on this script to set variables in the job file, that are required for logging and other functionality.  
It is possible to submit jobs without calling jsub but instead passing a list of job files to submit_lsf_jobs.sh.  This may be useful if Julia is not available on the system where the jobs are to be run.  To facilitate this the --portable flag can be used to create a single directory containing the relevant job files instead of submitting the jobs directly.


Example 6 checkpoints

To assert that a job is progressing successfully, checkpoint functions can be added to job files.  These are functions that set the environment variable JSUB_FLAG_FAIL to true if some condition is not satisfied.  This in turns causes the job to stop and relevant information to be written to log files.

Here we look at an example using the checkpoint function jcheck_file_not_empty.  This function takes a list of files and flags the job as failing if at least one of the files is empty (or only contains whitespace).

cd examples/example_06

jsub --generate-summaries --generate-jobs \
     --protocol echo06.protocol \
     --vars vars06.vars \
     --fvars fvars06.fvars \
     --header-from-file "my_job_header_file.txt" \
     --summary-prefix "summaries/" \
     --job-prefix "jobs/" \
     --prefix-lsf-out "lsf_out/" \
     --prefix-completed "progoress/completed/" \
     --prefix-incomplete "progoress/incomplete/" 

jsub --submit-jobs --list-jobs jobs/echo06_vars06_fvars06.list-jobs

Inspecting the results*.txt files shows that only job number 1 successfully executed all the supplied commands.
Looking in jobs/echo06_vars06_fvars06_2.log tells us that the checkpoing jcheck_file_not_empty was passed for the file results_Anum2.txt (ie that file was not empty) but failed for the file results_Bnum2.txt.
The remaining lines in the log file indicate the commands that were run but did not produce a satisfactory result (according to the checkpoint used).
The files in progress/complete and progress/incomplete list the commands that were 


Example 7 resuming a failed job

In some cases we may want to re-run the job that failed.  Depending on the circumstances it may be a better idea to fix the root of the problem and generate a new set of summary and job files.  However, the *.incomplete files can be used as summary files for a new job if it is considered apropriate.

In the following example, two jobs are generated and run.  One completes successfully but the second one fails due to a missing input file.

cd examples/example_07

mkdir -p dummy_output # create the directory for job results as indicated in the vars07.vars file

jsub --generate-summaries --generate-jobs \
     --protocol cat07.protocol \
     --vars vars07.vars \
     --fvars fvars07.fvars \
     --header-from-file "my_job_header_file.txt" \
     --summary-prefix "summaries/" \
     --job-prefix "jobs/" \
     --prefix-lsf-out "lsf_out/" \
     --prefix-completed "progoress/completed/" \
     --prefix-incomplete "progoress/incomplete/" 

jsub --submit-jobs --list-jobs jobs/cat07_vars07_fvars07.list-jobs

By inspecting the files in dummy_output/*, jobs/*.log and progress/incomplete/*, we can see that the second job failed to complete due to a missing file "dummy_data/data_2B.txt".
The missing file is hidden in dummy_data/missing.

mv dummy_data/missing/data_2B.txt dummy_data/data_2B.txt

We can now either re-run both jobs, only the failed job or we can create a new job containing only the steps that may not have completed successfully during our initial attempt.
This can be done using the file "progress/incomplete/cat07_vars07_fvars07_2_2.incomplete".
The most appropriate course of action will depend on your particular circumstances but in this example we will create a new job.  First we will need to create a list of summary files (just one in this case) to pass to Stage 2 of jsub.

echo progoress/incomplete/cat07_vars07_fvars07_2_2.incomplete > resumed.list-summaries

jsub --generate-jobs \
     --list-summaries resumed.list-summaries \
     --header-from-file "my_job_header_file.txt" \
     --job-prefix "re_jobs/re_" \
     --prefix-lsf-out "re_lsf_out/lsf_" \
     --prefix-completed "re_progoress/completed/" \
     --prefix-incomplete "re_progoress/incomplete/"

jsub --submit-jobs --list-jobs re_jobs/re_resumed.list-jobs

Now the contents of dummy_output/result_2C.txt is analgous to that of dummy_output/result_1C.txt

Note: Care should be taken when using this method of resuming incomplete jobs since the incomplete steps may have generated some data already.  If this data is not overwritten when the commands are called again, the results may not be as expected.

Example 8 job groups


...


Example 9 job and summary name tags in the protocol file

...



# A handy function for resetting example directories
function clean {
  mkdir -p TRASH
  mv * TRASH/
  mv TRASH/README.txt .
  mv TRASH/*.protocol .
  mv TRASH/my_job_header_file.txt .
  mv TRASH/*.vars .
  mv TRASH/*.fvars .
  mv TRASH/list_file.txt .
  mv TRASH/list_* .
  mv TRASH/dummy_* .
  mv dummy_data/data_2B.txt dummy_data/missing
}







This is a light weight tool for creating and submitting job file to the LSF queuing system.  Its purpose is to automate job file generation in cases where the same processing steps need to be applied to different sets of input data.

Dependencies
The code for generating job files is written in Julia (version 0.4.0) and uses the ArgParse package (v0.3.1).  Job files use bash shell command and have been tested with LSF version 9.1.2.0 in a Linux environment.


Aims
Traceability: Job files produced by jsub contain bash shell functions that write to log files as the job proceeds. This creating a record of the steps taken to obtain the resulting output data

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
LVAR1	1	list_file.txt 
LVAR2	2	list_file.txt 

and the file "list_file.txt" contains values:
row1col1	row1col2
row2col1	row2col2
row3col1	row3col2

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

... 


Example 6 checkpoints

...


Example 7 *.incomplete
When a job fails

...


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
}







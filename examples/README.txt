This is a light weight tool for creating and submitting job file to the LSF queuing system.  Its purpose is to automate job file generation in cases where the same processing steps need to be applied to different sets of input data.

Dependencies
The code for generating job files is written in Julia (version 0.4.0) and uses the ArgParse package (v0.3.1).  Job files use bash shell command and have been tested with LSF version 9.1.2.0 in a Linux environment.


Aims
Traceability: Job files produced by jsub contain bash shell functions that write to log files as the job proceeds. This creating a record of the steps taken to obtain the resulting output data

Modularity: Paths to the input data and the steps taken to process it may be specified in separate files.


Example 1
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

STAGE 1) The file "echo.protocol" is parsed and the file "echo_1.summary" is generated from it.  In this simple case the two files are identical but in more complex situations variables in *.protocol files are substituted for values in other files resulting in multiple *.summary files per *.protocol file (see below).  The file echo.list-summaries contains a list of the summary files generated (just one in this case).

STAGE 2) The echo_1.summary file is used to generate the job files echo_1_1.lsf and echo.list-jobs.

STAGE 3) The job files from stage 2 are submitted to LSF.  The list of submitted files is found in "echo.list-jobs.submitted" and the results of running the bash commands in the file can be seen in "example_01_output.txt".  LSF writes stdout and stderr to "echo_1_1.output" and "echo_1_1.error" respectively.  Functions in the job file create a list the steps that appear to have been completed successfully in the file "echo_1_1.completed" and write other information to "echo_1.log".





function trash {
  mkdir -p TRASH
  mv * TRASH/
  mv TRASH/README.txt .
  mv TRASH/*.protocol .
  mv TRASH/my_job_header_file.txt .
}

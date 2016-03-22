# Julia script for systematically generating HPC jobs which write to log files.

## Workflow outline:
# GenerateSummary ( protocol, sampleID ) -> summary
# GenerateJobFiles ( summary, jobID, jobHeader, jobFunctions, environmentVariables ) -> job_files, list_of_job_files
# SubmitJobs ( list_of_job_files, job_files ) -> outputHPC, errorHPC, completed.summary, incomplete.summary, logs/*.log, logs/*.summary, outputDataFiles, tmpFiles, listTmpFiles, listOutputIncomplete

##############

## Explanation ##

# This script facilitates the systematic creation and submission of jobs to the HPC while also writing to log files.

# Stage 1: Generate summary files for each sample.
#    inputs: i1.1) A list of sample IDs indicating which samples the job is to be run on.  This may contain more than one column when the the job involves multiple samples.
#            i1.2) A protocol file which indicates what programs are to be run and the paths to their inputs and outputs.  The protocol file may contain variables to be replaced by sample IDs.
# (todo: describe format of protocol file)
#
#   outputs: o1.1) Summary files for each sample.  These look similar to the protocol files but all the variables are expaneded.
# (todo: describe summary file format)
#            o1.2) List of summary files generated.

# Stage 2: Generate job files.
#    inputs: i2.1) List of summary file paths.
#            i2.2) Job batch ID to be used to generate a unique job file names.
#            i2.3) Job file header to be put at the top of every job file.
#            i2.4) File containing generic functions to be inserted into every job file.
#            i2.5) File containing the environment variables to be set at the start every job.
#
#   outputs: o2.1) LSF job files which can be submitted to the HPC.
#            o2.2) List of job files produced.

# Stage 3: Submit the job files as individual jobs to the HPC
#    inputs: i3.1) List of job files.

## Defaults


#################

### TODO: INPUT CHECKS ###


# Check that fileFvars contains 3 delmiterFvars separated columns

####### INPUTS #######

# Protocol file
baseDirectory="/Users/olenive/work/jsub_pipeliner/unit_tests/protocols/sample_variables"

#fileProtocol="/Users/olenive/work/jsub_pipeliner/unit_tests/protocols/basic/call_bash_scripts_01imac.protocol"
#fileProtocol="/Users/olenive/work/jsub_pipeliner/unit_tests/protocols/single_variable/call_bash_scripts_pathVar.protocol"
fileProtocol="/Users/olenive/work/jsub_pipeliner/unit_tests/protocols/sample_variables/call_bash_scripts_pathVar_sampleVars.protocol"

# Variables file
fileVars="/Users/olenive/work/jsub_pipeliner/unit_tests/protocols/sample_variables/call_bash_scripts_pathVar_sampleVars.vars"

# Variables from list
#fileFvars="/Users/olenive/work/jsub_pipeliner/unit_tests/protocols/sample_variables/call_bash_scripts_pathVar_sampleVars.fvars"
fileFvars="/Users/olenive/work/jsub_pipeliner/unit_tests/protocols/split/refs_samples.fvars"

## Default job header values
jobID="LSFjob";
numberOfCores=1;
numberOfHosts=1;
wallTime="8:00";
queue="normal"
grantCode="prepay-houlston"

jobHeader = string(
"#!/bin/bash\n
#BSUB -J \"$jobID\"\n
#BSUB -n $numberOfCores\n
#BSUB -R \"span[hosts=$numberOfHosts]\"\n
#BSUB -P $grantCode\n
#BSUB -W $wallTime\n
#BSUB -q $queue\n
#BSUB -o output.$jobID\n
#BSUB -e error.$jobID\n"
)

######################

## Hard coded variables
# First non-whitespace string indicating the start of a comment line
const comStr="#" # Note: this is expected to be a string ("#") rather than a character ('#').  Changing the string (char) used to indicate comments may cause problems further down the line.
# const dlmVars='\t' # Column delimiter for files containing variables
# const dlmProtocol=' ' # Column delimiter for the protocol file
const dlmWhitespace=[' ','\t','\n','\v','\f','\r'] # The default whitespace characters used by split
const flagWarn = true;
const delimiterFvars = '\t'
const verbose = false;


#### FUNCTIONS ####
include("./common_functions/jsub_common.jl")

###################


######### SCRIPT #########

## Read .vars file # Extract arrays of variable names and variable values
namesVarsRaw, valuesVarsRaw = parse_varsfile(fileVars)

## Expand variables in each row from .vars if they were assigned in a higher row (as though they are being assigned at the command line).
namesVars, valuesVars = expandinorder(namesVarsRaw, valuesVarsRaw)

## Read .fvar file (of 3 columns) and expand variables from .vars
namesFvars, infileColumnsFvars, filePathsFvars = parse_expandvars_in_varsfile(fileFvars, namesVars, valuesVars)

## Read .protocol file (of 1 column ) and expand variables from .vars
arrProtExpVars, cmdRowsProt = parse_expandvars_in_protocol(fileProtocol, namesVars, valuesVars)

## Read "list" files and return their contents in an dictionary (key: file path) (value: arrays of arrays) as well as corresponding command line indicies
dictListArr, dictCmdLineIdxs = parse_expandvars_in_listfiles(filePathsFvars, namesVars, valuesVars, delimiterFvars; verbose=false)

## Use variable values from "list" files to create multiple summary file arrays from the single .protocol file array
arrArrExpFvars = expandvars_in_protocol(arrProtExpVars, cmdRowsProt, namesFvars, infileColumnsFvars, filePathsFvars, dictListArr, dictCmdLineIdxs ; verbose = verbose)

## For each summary file array check where they first begin to diverge and or converge and merge/split as required





##########################
# EOF


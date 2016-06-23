# Julia script for systematically generating HPC jobs which write to log files.

## Workflow outline:
# GenerateSummary ( protocol, sampleID ) -> summary
# GenerateJobFiles ( summary, jobID, jobHeader, jobFunctions, environmentVariables ) -> job_files, list_of_job_files
# SubmitJobs ( list_of_job_files, job_files ) -> outputHPC, errorHPC, completed.summary, incomplete.summary, logs/*.log, logs/*.summary, outputDataFiles, tmpFiles, listTmpFiles, listOutputIncomplete

##############

## Explanation ##

# This script facilitates the systematic creation and submission of jobs to the LSF queuing system while also writing to log files.

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
#            i2.2) Job batch ID to be used to generate unique job file names.
#            i2.3) Job file header to be put at the top of every job file.
#            i2.4) File containing generic functions to be inserted into every job file.
#            i2.5) File containing the environment variables to be set at the start of every job.
#
#   outputs: o2.1) LSF job files which can be submitted to the LSF queuing system.
#            o2.2) List of job files produced.

# Stage 3: Submit the job files as individual jobs to the LSF queuing system
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
const delimiterFvars = '\t'
const verbose = false;
const adapt_quotation=true; # this should be the default to avoid nasty accidents

const SUPPRESS_WARNINGS=false;
num_suppressed = [0];

## Tags
tagsExpand = Dict(
  "tagSummaryName" => "#JSUB<protocol>",
  "tagSplit" => "#JGROUP"
)


#### FUNCTIONS ####
include("./common_functions/jsub_common.jl")
###################


######### MAIN #########



## Read .vars file # Extract arrays of variable names and variable values
namesVarsRaw, valuesVarsRaw = parse_varsfile_(fileVars, tagsExpand=tagsExpand)

## Expand variables in each row from .vars if they were assigned in a higher row (as though they are being assigned at the command line).
namesVars, valuesVars = expandinorder(namesVarsRaw, valuesVarsRaw, adapt_quotation=adapt_quotation)

## Read .fvar file (of 3 columns) and expand variables from .vars
namesFvars, infileColumnsFvars, filePathsFvars = parse_expandvars_fvarsfile_(fileFvars, namesVars, valuesVars; dlmFvars=delimiterFvars, adapt_quotation=adapt_quotation, tagsExpand=tagsExpand)

## Read .protocol file (of 1 column ) and expand variables from .vars
arrProtExpVars, cmdRowsProt = parse_expandvars_protocol_(fileProtocol, namesVars, valuesVars, adapt_quotation=adapt_quotation)

## Read "list" files and return their contents in a dictionary (key: file path) (value: arrays of arrays) as well as corresponding command line indicies
dictListArr, dictCmdLineIdxs = parse_expandvars_listfiles_(filePathsFvars, namesVars, valuesVars, delimiterFvars; verbose=false, adapt_quotation=adapt_quotation, tagsExpand=tagsExpand)

## Use variable values from "list" files to create multiple summary file arrays from the single .protocol file array
arrArrExpFvars = protocol_to_array(arrProtExpVars, cmdRowsProt, namesFvars, infileColumnsFvars, filePathsFvars, dictListArr, dictCmdLineIdxs; verbose=verbose, adapt_quotation=adapt_quotation)

## Generate list of job names
summaryPaths = get_summary_names(arrArrExpFvars; prefix="", suffix="", timestamp="")

## Take an expanded protocol in the form of an array of arrays and produce a summary file for each entry
create_summary_files_(arrArrExpFvars, summaryPaths; verbose=verbose)

## Read summary files into array of arrays of arrays
# Note: file2arrayofarrays_ returns a tuple of file contents and line number indices
summaryFilesData = map((x) -> file2arrayofarrays_(x, "#", cols=1, tagsExpand=tagsExpand), summaryPaths ) 

## Extract the summary array for each file
## Split into job arrays

## Write job files




# Report if there were any suppressed warnings
if num_suppressed[1] > 0
  println("Suppressed ", num_suppressed[1], " warnings.");
end
########################
# EOF


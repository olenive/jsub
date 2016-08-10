using ArgParse

# Julia program for systematically generating LSF jobs which write to log files.

## Workflow outline:
# GenerateSummary ( protocol, sampleID ) -> summary
# GenerateJobFiles ( summary, jobID, jobHeader, jobFunctions, environmentVariables ) -> job_files, list_of_job_files
# SubmitJobs ( list_of_job_files, job_files ) -> outputHPC, errorHPC, completed.summary, incomplete.summary, logs/*.log, logs/*.summary, outputDataFiles, tmpFiles, listTmpFiles, listOutputIncomplete

##############

## Explanation ##

# This tool facilitates the systematic creation and submission of jobs to the LSF queuing system while also writing to log files.

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

# Variables file
fileVars="/Users/olenive/work/jsub_pipeliner/unit_tests/protocols/sample_variables/call_bash_scripts_pathVar_sampleVars.vars";

# Variables from list
#fileFvars="/Users/olenive/work/jsub_pipeliner/unit_tests/protocols/sample_variables/call_bash_scripts_pathVar_sampleVars.fvars"
fileFvars="/Users/olenive/work/jsub_pipeliner/unit_tests/protocols/split/refs_samples.fvars";

# summaryFilePrefix="TEST/summaries/";
jobFilePrefix="TEST/jobfiles";

## Default job header values
# jobID="LSFjob";
# numberOfCores=1;
# numberOfHosts=1;
# wallTime="8:00";
# queue="normal"
# grantCode="prepay-houlston"

# String added to the header of every job file
commonHeaderSuffix = "\n#BSUB -P prepay-houlston";

# jobHeader = string(
# "#!/bin/bash\n
# #BSUB -J \"$jobID\"\n
# #BSUB -n $numberOfCores\n
# #BSUB -R \"span[hosts=$numberOfHosts]\"\n
# #BSUB -P $grantCode\n
# #BSUB -W $wallTime\n
# #BSUB -q $queue\n
# #BSUB -o output.$jobID\n
# #BSUB -e error.$jobID\n"
# )

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
  "header" => "#BSUB",
  "tagSummaryName" => "#JSUB<summary-name>",
  "tagSplit" => "#JGROUP"
)

## Paths to bash functions {"function name" => "path to file containing function"}
commonFunctions = Dict(
  "kill_this_job" => "common_functions/job_processing.sh",
  "process_job" => "common_functions/job_processing.sh",
)
checkpointsDict = Dict()

#### FUNCTIONS ####
include("./common_functions/jsub_common.jl")
###################


######### MAIN #########
# function main(args)
  ## Argparse settings
  argSettings = ArgParseSettings(description = "Julia program for systematically generating LSF jobs which write to log files.");

  @add_arg_table argSettings begin
      "-v", "--verbose"
      "-s", "--summary"
      "protocol"
      "-l", "--list"
      "-r", "--vars"
      "-f", "--fvars"
      "--summary-prefix"
  end

  parsed_args = parse_args(argSettings) # the result is a Dict{String,Any}
  println("Parsed args:")
  for (key,val) in parsed_args
      println("  $key  =>  $(repr(val))")
  end

  ## Determine string used in file names
  longName = "longName" #get_longname(fileProtocol, fileVars, fileFvars)

  ## Extract file paths from arguments
  fileProtocol = "";
  if parsed_args["protocol"] == nothing
    error("Please supply a path to a protocol file as the first argument.");
    return 1
  else
    fileProtocol = parsed_args["protocol"];
  end

  ## Read protocol, vars and fvars files and expand variables
  println("## Read protocol, vars and fvars files and expand variables")
  namesVars = []; valuesVars = [];
  if parsed_args["vars"] != nothing
    # Read .vars file # Extract arrays of variable names and variable values
    namesVarsRaw, valuesVarsRaw = parse_varsfile_(parsed_args["vars"], tagsExpand=tagsExpand);
    # Expand variables in each row from .vars if they were assigned in a higher row (as though they are being assigned at the command line).
    namesVars, valuesVars = expandinorder(namesVarsRaw, valuesVarsRaw, adapt_quotation=adapt_quotation);
  end
  namesFvars = []; infileColumnsFvars = []; filePathsFvars = [];
  if parsed_args["fvars"] != nothing
    # Read .fvar file (of 3 columns) and expand variables from .vars
    namesFvars, infileColumnsFvars, filePathsFvars = parse_expandvars_fvarsfile_(fileFvars, namesVars, valuesVars; dlmFvars=delimiterFvars, adapt_quotation=adapt_quotation, tagsExpand=tagsExpand);
  end

  # Read .protocol file (of 1 column ) and expand variables from .vars
  println("# Read .protocol file (of 1 column ) and expand variables from .vars")
  arrProtExpVars, cmdRowsProt = parse_expandvars_protocol_(fileProtocol, namesVars, valuesVars, adapt_quotation=adapt_quotation);

  dictListArr = Dict(); dictCmdLineIdxs = Dict();
  if parsed_args["list"] != nothing
    # Read "list" files and return their contents in a dictionary (key: file path) (value: arrays of arrays) as well as corresponding command line indicies
    dictListArr, dictCmdLineIdxs = parse_expandvars_listfiles_(filePathsFvars, namesVars, valuesVars, delimiterFvars; verbose=false, adapt_quotation=adapt_quotation, tagsExpand=tagsExpand);
    if length(keys(dictListArr)) != length(keys(dictCmdLineIdxs))
      error("Numbers of command rows (", length(keys(dictListArr)), ") and command row indices (", length(keys(dictCmdLineIdxs)), ") in list file (", filePathsFvars, ") do not match.")
    end
  end

  # Use variable values from "list" files to create multiple summary file arrays from the single .protocol file array
  println("# Use variable values from \"list\" files to create multiple summary file arrays from the single .protocol file array")
  arrArrExpFvars = [];
  if length(keys(dictListArr)) != 0 && length(keys(dictCmdLineIdxs)) != 0
    arrArrExpFvars = protocol_to_array(arrProtExpVars, cmdRowsProt, namesFvars, infileColumnsFvars, filePathsFvars, dictListArr, dictCmdLineIdxs; verbose=verbose, adapt_quotation=adapt_quotation);
  else
    push!(arrArrExpFvars, arrProtExpVars) # If there is no data from list files, simply proceed using the protocol with expanded varibles (if applicable)
  end

  ## Create summary files
  # Generate list of summary file paths.
  println("# Generate list of summary file paths.")
  summaryPaths = get_summary_names(arrArrExpFvars; tag="#JSUB<summary-name>", # if an entry with this tag is found in the protocol (arrArrExpFvars), the string following the tag will be used as the name
    longName=longName, # Otherwise the string passed to longName will be used as the basis of the summary file name
    prefix=parsed_args["summary-prefix"], suffix=".summary", timestamp="YYYYMMDD_HHMMSS"
  );
  # Take an expanded protocol in the form of an array of arrays and produce a summary file for each entry
  println("# Take an expanded protocol in the form of an array of arrays and produce a summary file for each entry")
  println(summaryPaths)
  create_summary_files_(arrArrExpFvars, summaryPaths; verbose=verbose);

  ## Read summary files and use them to create LSF job files
  println("## Read summary files and use them to create LSF job files")
  # Note: file2arrayofarrays_ returns a tuple of file contents (in an array) and line number indices (in an array)
  summaryFilesData = map((x) -> file2arrayofarrays_(x, "#", cols=1, tagsExpand=tagsExpand), summaryPaths );

  ## this can be done inside the create_job_file function
  # # Use summary file path and contents to generate job file names
  # arrJobFileNames = map((x, y) -> get_jobfile_name(x, y[1]), summaryPaths, summaryFilesData);

  # Get bash functions from files
  arrDictCheckpoints = map((x) -> identify_checkpoints(x[1], checkpointsDict; tagCheckpoint="jcheck_"), summaryFilesData );
  arrBashFunctions = map((x) -> get_bash_functions(commonFunctions, x), arrDictCheckpoints);

  # Split summary file contents into job arrays stored in dictionaries
  summaryArrDicts = map((x) -> split_summary(x[1]; tagSplit=tagsExpand["tagSplit"]), summaryFilesData);

  ## Get job IDs from summary basenames
  arrJobIDs = map((x) -> basename(remove_suffix(x, ".summary")) , summaryPaths)

  # ## Check and warn if there are conflicting options in the job arrays
  # map((x) -> detect_option_conflicts(jobArray, tag="#BSUB", option="-J"), 

  ## Write job files
  jobFilePaths = map((summaryFilePath, dictSummaries, jobID) -> create_jobs_from_summary_(summaryFilePath, dictSummaries, commonFunctions, checkpointsDict; 
    directoryForJobFiles=jobFilePrefix, jobID=jobID, jobDate=get_timestamp_(nothing), headerSuffix=commonHeaderSuffix),
    summaryPaths, summaryArrDicts, arrJobIDs
  )

# end

# main(ARGS)

# Report if there were any suppressed warnings
if num_suppressed[1] > 0
  println("Suppressed ", num_suppressed[1], " warnings.");
end
########################
# EOF


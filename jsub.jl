using ArgParse

argSettings = ArgParseSettings(description = string(
"This is a tool for systematically generating LSF jobs which write to log files. Below is an outline of the process.\n",
"\n",
"\n",
"\n",
"\n",
"\n  STAGE 1: Generate summary files for each set of input data.\n",
"\n",
"\n",
"\n    STAGE 1 INPUTS:\n",
"\nPath to protocol file (-p).\n",
"\n(Optional) Variables file supplied with the --vars (-r) option.\n",
"\n(Optional) Variables from lists file supplied with the --fvars (-f) option.\n",
"\n",
"\n",
"\n    STAGE 1 OUTPUTS:\n",
"\nSummary files generated by expanding the variables in the protocol file.\n",
"\nText file listing paths to the generated summary files.\n",
"\n",
"\n",
"\n",
"\n",
"\n   STAGE 2: Generate job files.\n",
"\n",
"\n",
"\n     STAGE 2 INPUTS:\n",
"\nText file listing the of paths to the generated summary files.  If stages 1 and 2 are run together the summary files from stage 1 will be used.\n",
"\n",
"\n",
"\n     STAGE 2 OUTPUTS:\n",
"\nJob files generated from summary files.\n",
"\nText file listing paths to the generated job files.\n",
"\n",
"\n",
"\n",
"\n",
"\n   STAGE 3: Submit jobs to the queuing system.\n",
"\n",
"\n",
"\n     STAGE 3 INPUTS:\n",
"\nText file listing paths to the generated job files.  If stages 2 and 3 are run together the job files from stage 2 will be used for stage 3.\n",
"\n",
"\n",
"\n     STAGE 3 OUTPUTS:\n",
"\nLog files written by the job files.\n",
"\nStarndard output and error output from the queuing system as well as any output produced by running the commands contained in the job files.",
"\n",
"\n",
"\n",
));
sourcePath = dirname(Base.source_path()) * "/"; # Get the path to the jsub.jl file

####### INPUTS #######

# Variables file
fileVars="/Users/olenive/work/jsub_pipeliner/unit_tests/protocols/sample_variables/call_bash_scripts_pathVar_sampleVars.vars";

# Variables from list
#fileFvars="/Users/olenive/work/jsub_pipeliner/unit_tests/protocols/sample_variables/call_bash_scripts_pathVar_sampleVars.fvars"
fileFvars="/Users/olenive/work/jsub_pipeliner/unit_tests/protocols/split/refs_samples.fvars";

# summaryFilePrefix="TEST/summaries/";
jobFilePrefix = sourcePath * "TEST/jobfiles";

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

num_suppressed = [0];

## Tags
tagsExpand = Dict(
  "header" => "#BSUB",
  "tagSummaryName" => "#JSUB<summary-name>",
  "tagSplit" => "#JGROUP"
)

## Paths to bash functions {"function name" => "path to file containing function"}
commonFunctions = Dict(
  "kill_this_job" => sourcePath * "common_functions/job_processing.sh",
  "process_job" => sourcePath * "common_functions/job_processing.sh",
)
checkpointsDict = Dict()

#### FUNCTIONS ####
include("./common_functions/jsub_common.jl")

## Extract file path from arguments
function get_path_from_args(parsed_args, arg; verbose=false)
  if parsed_args[arg] == false
    error("Please supply an argument to the \"--", arg, "\" option.");
  else
    verbose && println("Parsed argument to --" * arg * ": " * parsed_args["protocol"])
    return parsed_args["protocol"]
  end
end
###################

######### MAIN #########
# function main(args)
## Argparse settings
@add_arg_table argSettings begin
  "-p", "--protocol"
    help = "Path to \"protocol\" file.  This file contains commands to be run with variables to be substituted using values from files supplied with \"--vars (-r)\" and/or \"--fvars (-f)\" options."

  "-v", "--verbose"
    action = :store_true
    help = "Verbose mode prints warnings and additional information to std out." 

  "-s", "--generate-summaries"
    action = :store_true
    help = "Generate summary files from protocol files using variables from files where supplied (see --help for --vars & --fvars options)." 

  "-j", "--generate-jobs"
    action = :store_true
    help = "Generate LSF job files from summary files." 

  "-u", "--list-summaries"
    help = "Path to a text file listing summary file paths." 

  "-o", "--list-jobs"
    help = "Path to a text file listing job file paths." 

  "-b", "--submit-jobs"
    action = :store_true
    help = "Submit LSF job files to the queue." 

  "-r", "--vars"
    help = "Path to \"variables\" file.  This file contains two columns - variable names and variable values.  Matching variable names found in the \"protocol\" will be substituted with the corresponding values.  Variable names may themselves contain variables which will be expanded if the variable name-value pair is found above (in this vars file)."

  "-f", "--fvars"
    help = "Path to \"file variables\" file.  The purpose of this file is to declare variables that are to be substituted with values taken from a list in another file.  This file consists of three columns - variable names, list file column and list file path."

  "-w", "--suppress-warnings"
    action = :store_true
    help = "Do not print warnings to std out." 

  "-m", "--summary-prefix"
    help = "Prefix to summary files."

end

parsed_args = parse_args(argSettings) # the result is a Dict{String,Any}
println("Parsed args:")
for (key,val) in parsed_args
    println("  $key  =>  $(repr(val))")
end

## Process flag states
SUPPRESS_WARNINGS = parsed_args["suppress-warnings"];
flagVerbose = parsed_args["verbose"];
requiredStages = map_flags_sjb(parsed_args["generate-summaries"], parsed_args["generate-jobs"], parsed_args["submit-jobs"])
println(requiredStages);

# Extract file path from arguments
fileProtocol = "";
if parsed_args["protocol"] == nothing
  error("Please supply a path to a protocol file as the first argument.");
  return 1
else
  fileProtocol = parsed_args["protocol"];
end

### TODO: INPUT CHECKS ###
# Check that fileFvars contains 3 delmiterFvars separated columns

## STAGE 1
if requiredStages[1] == '1'
  ###############
  flagVerbose && println("\nSTAGE 1:");
  ###############

  ## Determine string used in file names
  fileProtocol = get_path_from_args(parsed_args, "protocol"; verbose=flagVerbose);
  longName = "longName" #get_longname(fileProtocol, fileVars, fileFvars)

  ## Read protocol, vars and fvars files and expand variables
  flagVerbose && println("## Read protocol, vars and fvars files and expand variables");
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
  (flagVerbose && length(namesVars) > 0) && println("Expanding variables in :" * fileProtocol);
  arrProtExpVars, cmdRowsProt = parse_expandvars_protocol_(fileProtocol, namesVars, valuesVars, adapt_quotation=adapt_quotation);

  dictListArr = Dict(); dictCmdLineIdxs = Dict();
  if parsed_args["fvars"] != nothing
    # Read "list" files and return their contents in a dictionary (key: file path) (value: arrays of arrays) as well as corresponding command line indicies
    dictListArr, dictCmdLineIdxs = parse_expandvars_listfiles_(filePathsFvars, namesVars, valuesVars, delimiterFvars; verbose=false, adapt_quotation=adapt_quotation, tagsExpand=tagsExpand);
    if length(keys(dictListArr)) != length(keys(dictCmdLineIdxs))
      error("Numbers of command rows (", length(keys(dictListArr)), ") and command row indices (", length(keys(dictCmdLineIdxs)), ") in list file (", filePathsFvars, ") do not match.")
    end
  end

  # Use variable values from "list" files to create multiple summary file arrays from the single .protocol file array
  flagVerbose && println("# Use variable values from \"list\" files to create multiple summary file arrays from the single .protocol file array");
  arrArrExpFvars = [];
  if length(keys(dictListArr)) != 0 && length(keys(dictCmdLineIdxs)) != 0
    arrArrExpFvars = protocol_to_array(arrProtExpVars, cmdRowsProt, namesFvars, infileColumnsFvars, filePathsFvars, dictListArr, dictCmdLineIdxs; verbose=verbose, adapt_quotation=adapt_quotation);
  else
    push!(arrArrExpFvars, arrProtExpVars); # If there is no data from list files, simply proceed using the protocol with expanded varibles (if applicable)
  end

  ## Create summary files
  # Generate list of summary file paths.
  println("# Generate list of summary file paths.")
  summaryPaths = get_summary_names(arrArrExpFvars; tag="#JSUB<summary-name>", # if an entry with this tag is found in the protocol (arrArrExpFvars), the string following the tag will be used as the name
    longName=longName, # Otherwise the string passed to longName will be used as the basis of the summary file name
    prefix=parsed_args["summary-prefix"], suffix=".summary", timestamp="YYYYMMDD_HHMMSS"
  );
  # Take an expanded protocol in the form of an array of arrays and produce a summary file for each entry
  flagVerbose && println("Generating summary files...");
  create_summary_files_(arrArrExpFvars, summaryPaths; verbose=flagVerbose);

  flagVerbose && println("");
end

## STAGE 2
if requiredStages[2] == '1'
  ###############
  flagVerbose && println("STAGE 2");
  ###############
  flagVerbose && println("Reading summary files to be used for job files");
  # Note: file2arrayofarrays_ returns a tuple of file contents (in an array) and line number indices (in an array)
  summaryFilesData = map((x) -> file2arrayofarrays_(x, "#", cols=1, tagsExpand=tagsExpand), summaryPaths );

  flagVerbose && println("Importing bash functions from files");
  arrDictCheckpoints = map((x) -> identify_checkpoints(x[1], checkpointsDict; tagCheckpoint="jcheck_"), summaryFilesData );
  arrBashFunctions = map((x) -> get_bash_functions(commonFunctions, x), arrDictCheckpoints);

  flagVerbose && println("Splitting summary file contents into separate jobs.");
  summaryArrDicts = map((x) -> split_summary(x[1]; tagSplit=tagsExpand["tagSplit"]), summaryFilesData);

  flagVerbose && println("Getting job file names from summary file basenames.");
  arrJobIDs = map((x) -> basename(remove_suffix(x, ".summary")) , summaryPaths);

  ## Write job files
  jobFilePaths = map((summaryFilePath, dictSummaries, jobID) -> create_jobs_from_summary_(summaryFilePath, dictSummaries, commonFunctions, checkpointsDict; 
    directoryForJobFiles=jobFilePrefix, jobID=jobID, jobDate=get_timestamp_(nothing), headerSuffix=commonHeaderSuffix, verbose=flagVerbose),
    summaryPaths, summaryArrDicts, arrJobIDs
  );

  flagVerbose && println("");
end

## STAGE 3
if requiredStages[3] == '1'
  ###############
  flagVerbose && println("STAGE 3");
  ###############

  flagVerbose && println("");
end

# end
# main(ARGS)

# Report if there were any suppressed warnings
if num_suppressed[1] > 0
  println("Suppressed ", num_suppressed[1], " warnings.");
end
########################
# EOF


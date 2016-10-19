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

## Default job header values
# jobID="LSFjob";
# numberOfCores=1;
# numberOfHosts=1;
# wallTime="8:00";
# queue="normal"
# grantCode="prepay-houlston"

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
# const verbose = false;
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
  "version_control" => sourcePath * "common_functions/version_control.sh",
)
checkpointsDict = Dict(
  "jcheck_file_not_empty" => sourcePath * "common_functions/jcheck_file_not_empty.sh",
  "jcheck_checkpoint" => sourcePath * "common_functions/jcheck_checkpoint.sh",
)

bsubOptions = [
"-ar",
"-B",
"-H",
"-I", "-Ip", "-Is", # [-tty]
"-IS", "-ISp", "-ISs", "-IX", #[-tty]
"-K",
"-N",
"-r", "-rn",
"-ul",
"-a", "esub_application", # [([argument[,argument...]])]..."
"-app", # application_profile_name
"-b", # [[year:][month:]day:]hour:minute
"-C", # core_limit
"-c", # [hour:]minute[/host_name | /host_model]
"-clusters", # "all [~cluster_name] ... | cluster_name[+[pref_level]] ... [others[+[pref_level]]]"
"-cwd", # "current_working_directory"
"-D", # data_limit
"-E", # "pre_exec_command [arguments ...]"
"-Ep", # "post_exec_command [arguments ...]"
"-e", # error_file
"-eo", #error_file
"-ext", #[sched] "external_scheduler_options"
"-F", # file_limit
"-f", # local_file operator [remote_file]" ...
"-freq", # numberUnit
"-G", # user_group
"-g", # job_group_name
"-i", # input_file | -is input_file
"-J", # job_name | -J "job_name[index_list]%job_slot_limit"
"-Jd", # "job_description"
"-jsdl", # file_name | -jsdl_strict file_name
"-k", # "checkpoint_dir [init=initial_checkpoint_period][checkpoint_period] [method=method_name]"
"-L", # login_shell
"-Lp", # ls_project_name
"-M", # mem_limit
"-m", # "host_name[@cluster_name][[!] | +[pref_level]] | host_group[[!] | +[pref_level | compute_unit[[!] | +[pref_level]] ..."
"-mig", # migration_threshold
"-n", # min_proc[,max_proc]
"-network", # " network_res_req"
"-o", # output_file
"-oo", # output_file
"-outdir", # output_directory
"-P", # project_name
"-p", # process_limit
"-pack", # job_submission_file
"-Q", # "[exit_code ...] [EXCLUDE(exit_code ...)]"
"-q", # "queue_name ..."
"-R", # "res_req" [-R "res_req" ...]
"-rnc", # resize_notification_cmd
"-S", # stack_limit
"-s", # signal
"-sla", # service_class_name
"-sp", # priority
"-T", # thread_limit
"-t", # [[[year:]month:]day:]hour:minute
"-U", # reservation_ID
"-u", # mail_user
"-v", # swap_limit
"-W", # [hour:]minute[/host_name | /host_model]
"-We", # [hour:]minute[/host_name | /host_model]
"-w", # 'dependency_expression'
"-wa", # 'signal'
"-wt", # '[hour:]minute'
"-XF",
"-Zs",
"-h",
"-V",
];

#### FUNCTIONS FROM OTHER FIELS ####
include("./common_functions/jsub_common.jl")
####################################

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

  "-n", "--name"
    help = "Name string to be used in all files."

  "-q", "--job-prefix"
    help = "Prefix to job file paths."

  "-t", "--timestamp"
    action = :store_true
    help = "Add timestamps to summary and job files."

  "-a", "--portable"
    help = "A directory to which copies of the job files as well as the submission script and relevant functions will be written.  This is do so that the jobs can be easily copied over to and run on a system where jsub.jl can not be run directly."

  "-z", "--zip-jobs"
    action = :store_true
    help = "Create a zip file containing the jobs directory supplied to the \"--portable\" (-a) option for ease of copying."

  "-l", "--common-header"
    help = "String to be included at the start of every job file."

  "-c", "--common-lsf-options"
    help = "Path to a file containing text to be included in every job file header.  This is intended to be used for common lsf options"

  "-y", "--no-version-control"
    action = :store_false
    help = "Do not call the bash function which does version control inside these jobs."

  "-d", "--no-process-timestamp"
    action = :store_false
    help = "When this flag is not present, timestamps of the format \"YYYYMMDD_HHMMSS\" are added to the log file by job files running the process_job function."

  "-k", "--keep-superfluous-quotes"
    action = :store_true
    help = "Do not remove superfluous quotes.  For example, the string \"abc\"\"def\" will not be converted to \"abcdef\"."

  "-g", "--fvars-delimiter"
    help = "Delimiter used in the .fvars file.  The default delmiter character is a tab ('\t').  The .fvars file is expected to contain three columns (1) variable name, (2) one-indexed column number, (3) path to a text file."

  "-e", "--prefix-lsf-out"
    help = "Prefix given to the output (*.output) and error (*.error) files produced when running an LSF job."
end

parsed_args = parse_args(argSettings) # the result is a Dict{String,Any}
# for (key,val) in parsed_args
#     println("  $key  =>  $(repr(val))")
# end

## Process flag states
SUPPRESS_WARNINGS = parsed_args["suppress-warnings"];
flagVerbose = parsed_args["verbose"];
const delimiterFvars = get_argument(parsed_args, "fvars-delimiter", verbose=flagVerbose, optional=true, default='\t');
flagKeepQuotes = get_argument(parsed_args, "keep-superfluous-quotes", verbose=flagVerbose, optional=true, default=false);
requiredStages = map_flags_sjb(parsed_args["generate-summaries"], parsed_args["generate-jobs"], parsed_args["submit-jobs"])
flagVerbose && print("\nInterpreted jsub arguments as requesting the following stages: ")
(flagVerbose && requiredStages[1]=='1') && print("1 ")
(flagVerbose && requiredStages[2]=='1') && print("2 ")
(flagVerbose && requiredStages[3]=='1') && print("3 ")
flagVerbose && print("\n\n")

## Initialise shared variables
summaryPaths = [];
jobFilePaths = [];
pathSubmissionScript = string(sourcePath, "/common_functions/submit_lsf_jobs.sh");
pathSubmissionFunctions = string(sourcePath, "/common_functions/job_submission_functions.sh");

## Get file paths and prefixes from arguments
pathProtocol = get_argument(parsed_args, "protocol"; verbose=flagVerbose, optional=(requiredStages[1]=='0'),
  default=""
);
pathVars = get_argument(parsed_args, "vars"; verbose=flagVerbose, optional=true, default="");
pathFvars = get_argument(parsed_args, "fvars"; verbose=flagVerbose, optional=true, default="");
summaryFilePrefix = get_argument(parsed_args, "summary-prefix", verbose=flagVerbose, optional=true, default="");
jobFilePrefix = get_argument(parsed_args, "job-prefix", verbose=flagVerbose, optional=true, default="");

## Create directory for job files if it does not already exist
mkpath(dirname(jobFilePrefix));

## Determine strings used in file names
longName = get_argument(parsed_args, "name"; verbose=flagVerbose, optional=true, 
  default=get_longname(pathProtocol, pathVars, pathFvars,
    get_argument(parsed_args, "list-summaries"; optional=true, default=""),
    get_argument(parsed_args, "list-jobs"; optional=true, default=""),
    keepSuffix=false
  )
);

## Get path to summaries list file
pathSummariesList = get_argument(parsed_args, "list-summaries"; verbose=flagVerbose, optional=true,
 default=string(summaryFilePrefix, longName, ".list-summaries")
);

doJsubVersionControl=(get_argument(parsed_args, "no-version-control"; verbose=flagVerbose, optional=true, default=true));
processTimestamp=(get_argument(parsed_args, "no-process-timestamp"; verbose=flagVerbose, optional=true, default=true));

## Get path to jobs list file
#outFilePath = string(jobFilePrefix, basename(remove_suffix(summaryFilePath, ".summary")), group, jobFileSuffix); # get longName from file path
pathJobsList = get_argument(parsed_args, "list-jobs"; verbose=flagVerbose, 
  optional=(requiredStages[2]=='1' || requiredStages[3]=='0'), # Only optional if stage 2 is being run or stage 3 is not being run (the jobs have to come from)
  default=string(jobFilePrefix, basename(summaryFilePrefix), longName, ".list-jobs")
);

# String used at the start of every job file
jobFileHeader = get_argument(parsed_args, "common-header"; verbose=flagVerbose, optional=true, default="#!/bin/bash\nset -eu\n");

# String added to the header of every job file
pathCommonHeader = get_argument(parsed_args, "common-lsf-options"; verbose=flagVerbose, optional=true, default=nothing);
pathCommonHeader != nothing ? commonHeaderSuffix = readall(pathCommonHeader) : commonHeaderSuffix="";


flagVerbose && println(string("Prefix for output file names: ", longName));

## TODO: Check input file format
# Check that pathFvars contains 3 delmiterFvars separated columns

## STAGE 1
function run_stage1_(pathProtocol, pathVars, pathFvars; flagVerbose=false, adapt_quotation=true, delimiterFvars='\t', tagsExpand=Dict(), keep_superfluous_quotes=false)

  flagVerbose && println("\n - STAGE 1: Generating summary files using data from files supplied to the --protocol, --vars and --fvars options.");

  ## Read protocol, vars and fvars files and expand variables
  namesVars = []; valuesVars = [];
  if pathVars != ""
    flagVerbose && println(string("Expanding variables line by line in data from \"--vars\" file: ", pathVars));
    # Read .vars file # Extract arrays of variable names and variable values
    namesVarsRaw, valuesVarsRaw = parse_varsfile_(pathVars, tagsExpand=tagsExpand);
    # Expand variables in each row from .vars if they were assigned in a higher row (as though they are being assigned at the command line).
    namesVars, valuesVars = expandinorder(namesVarsRaw, valuesVarsRaw, adapt_quotation=adapt_quotation);
  end
  namesFvars = []; infileColumnsFvars = []; filePathsFvars = [];
  if pathFvars != ""
    flagVerbose && println(string("Expanding variables in data from \"--fvars\" file using names and values from the \"--vars\" file: ", pathFvars));
    namesFvars, infileColumnsFvars, filePathsFvars = parse_expandvars_fvarsfile_(pathFvars, namesVars, valuesVars; dlmFvars=delimiterFvars, adapt_quotation=adapt_quotation, tagsExpand=tagsExpand, keep_superfluous_quotes=keep_superfluous_quotes);
  end

  # Read .protocol file (of 1 column ) and expand variables from .vars
  (flagVerbose && length(namesVars) > 0) && println("Expanding variables in protocol file using values from the --vars file.");
  arrProtExpVars, cmdRowsProt = parse_expandvars_protocol_(pathProtocol, namesVars, valuesVars, adapt_quotation=adapt_quotation, tagsExpand=tagsExpand, keep_superfluous_quotes=keep_superfluous_quotes);

  dictListArr = Dict(); dictCmdLineIdxs = Dict();
  if pathFvars != ""
    println(string("Expanding variables from the --fvars file using values from the files listed in each row..."));
    dictListArr, dictCmdLineIdxs = parse_expandvars_listfiles_(filePathsFvars, namesVars, valuesVars, delimiterFvars; verbose=false, adapt_quotation=adapt_quotation, tagsExpand=tagsExpand, keep_superfluous_quotes=keep_superfluous_quotes);
    if length(keys(dictListArr)) != length(keys(dictCmdLineIdxs))
      error("Numbers of command rows (", length(keys(dictListArr)), ") and command row indices (", length(keys(dictCmdLineIdxs)), ") in list file (", filePathsFvars, ") do not match.")
    end
  end

  ## Create summary files
  # Use variable values from "list" files to create multiple summary file arrays from the single .protocol file array
  flagVerbose && println("Creating summary files...");
  arrArrExpFvars = [];
  if length(keys(dictListArr)) != 0 && length(keys(dictCmdLineIdxs)) != 0
    arrArrExpFvars = protocol_to_array(arrProtExpVars, cmdRowsProt, namesFvars, infileColumnsFvars, filePathsFvars, dictListArr, dictCmdLineIdxs; verbose=false, adapt_quotation=adapt_quotation, keep_superfluous_quotes=keep_superfluous_quotes);
  else
    push!(arrArrExpFvars, arrProtExpVars); # If there is no data from list files, simply proceed using the protocol with expanded varibles (if applicable)
  end
  # Generate list of summary file paths.
  summaryPaths = get_summary_names(arrArrExpFvars; tag="#JSUB<summary-name>", # if an entry with this tag is found in the protocol (arrArrExpFvars), the string following the tag will be used as the name
    longName=longName, # Otherwise the string passed to longName will be used as the basis of the summary file name
    prefix=summaryFilePrefix,
    suffix=".summary",
    timestamp=(
      parsed_args["timestamp"] ? get_timestamp_(nothing) : "";
    )
  );
  # Take an expanded protocol in the form of an array of arrays and produce a summary file for each entry
  outputSummaryPaths = create_summary_files_(arrArrExpFvars, summaryPaths; verbose=flagVerbose);
  println(string("Writing list of summary files to: ", pathSummariesList));
  writedlm(pathSummariesList, outputSummaryPaths);

  return pathSummariesList
end

## STAGE 2
function run_stage2_(pathSummariesList, pathJobsList; flagVerbose=false, tagsExpand=Dict(), checkpointsDict=Dict(), commonFunctions=Dict(), tagCheckpoint="jcheck_", doJsubVersionControl=true, processTimestamp=true)
  flagVerbose && println("\n - STAGE 2: Using summary files to generate LSF job files.");
  summaryPaths2 = readdlm(pathSummariesList); # Read paths to summary files from list file
  summaryFilesData = map((x) -> file2arrayofarrays_(x, "#", cols=1, tagsExpand=tagsExpand), summaryPaths2 ); # Note: file2arrayofarrays_ returns a tuple of file contents (in an array) and line number indices (in an array)

  flagVerbose && println("Importing bash functions from files...");
  arrDictCheckpoints = map((x) -> identify_checkpoints(x[1], checkpointsDict; tagCheckpoint="jcheck_"), summaryFilesData );
  arrBashFunctions = map((x) -> get_bash_functions(commonFunctions, x), arrDictCheckpoints);

  flagVerbose && println("Splitting summary file contents into separate jobs...");
  summaryArrDicts = map((x) -> split_summary(x[1]; tagSplit=tagsExpand["tagSplit"]), summaryFilesData);

  # flagVerbose && println("Getting job file names from summary file basenames...");
  # arrJobIDs = map((x) -> basename(remove_suffix(x, ".summary")) , summaryPaths2);

  ## Get job date
  jobDate = parsed_args["timestamp"] ? get_timestamp_(nothing) : "";

  ## Get prefix for *.error and *.output files (written by the LSF job)
  prefixOutputError = get_argument(parsed_args, "prefix-lsf-out", verbose=flagVerbose, optional=true, default="");

  ## Get job ID and check that the list is unique
  jobIDTag = "#JSUB<job-id>";
  flagVerbose && println("Getting job ID prefixes from summary file lines starting with: ", jobIDTag);
  preArrJobIDs = map((x) -> get_taggedunique(x[1], jobIDTag), summaryFilesData );
  arrJobIDs = replace_empty_strings(preArrJobIDs, prefix=string(longName, "_") );
  (length(arrJobIDs) != length(unique(arrJobIDs))) && error(" in run_stage2_ the array of job IDs contains non-qunique entries:\n", arrJobIDs);
  println("arrJobIDs");
  println(arrJobIDs);

  ## Write job files
  arrDictFilePaths = map((summaryFilePath, dictSummaries, jobID) -> create_jobs_from_summary_(summaryFilePath, dictSummaries, commonFunctions, checkpointsDict; 
      jobFilePrefix=jobFilePrefix, jobID=jobID, jobDate=jobDate,
      doJsubVersionControl=doJsubVersionControl, processTimestamp=processTimestamp, headerSuffix=commonHeaderSuffix, verbose=flagVerbose, bsubOptions=bsubOptions, headerPrefix=jobFileHeader, prefixOutputError=prefixOutputError
    ),
    summaryPaths2, summaryArrDicts, arrJobIDs,
  );

  ## Get an array of job priorities
  arrDictPriorities = map((dictSummaries, dictFilePaths, jobID) -> get_priorities(dictSummaries, dictFilePaths), summaryArrDicts, arrDictFilePaths, arrJobIDs)

  ## Re-order job paths list according to job priority
  arrArrOrderedJobPaths = map((ranksDict, pathsDict) -> order_by_dictionary(ranksDict, pathsDict), arrDictPriorities, arrDictFilePaths)

  ## Write ordered list of job paths to file
  string2file_(pathJobsList, join(map(x -> join(x, '\n'), arrArrOrderedJobPaths), '\n'));

  return pathJobsList
end

## STAGE 3
function run_stage3_(pathJobsList, pathPortable, pathSubmissionScript, pathSubmissionFunctions; flagVerbose=false, flagZip=false)
  flagVerbose && println("\n - STAGE 3: Submitting LSF jobs.");

  ## Call the job submission script or copy it to the jobs directory
  if (pathPortable == "")
    SUPPRESS_WARNINGS ? arg2 = "suppress-warnings" : arg2 = "";
    flagVerbose && println("Submitting jobs to LSF queuing system using...");
    flagVerbose && println("bash $pathSubmissionScript $pathJobsList $arg2");
    subRun = "";
    if checkforlsf_()
      try
        run(`bash $pathSubmissionScript $pathJobsList $arg2`);
      catch
        println(subRun);
      end
    else
      println("The LSF queuing system does not appear to be available on this system.")
      # println("If this is incorrect consider amending line 423 of jsub.jl or submitting manually using:")
      println("Finished running jsub stage 3 without submitting any jobs.")
    end
    ## Point out that the zip option currently only works in combination with the portable option
    if flagZip == true
      (!SUPPRESS_WARNINGS) && println("WARNING (in jsub.jl): The --zip-jobs (-z) flag was supplied but an argument to the --portable (-a) option was not supplied.  Currently the -z option only works together with -a so it will have no effect here.");
    end
  else
    # Get the target directory from the the portable option or use default
    pathPortableZip = get_zip_dir_path(pathPortable);
    mkpath(pathPortable); # Create the portable directory if needed

    # Parse list of job paths and copy them to the portable directory (if it's not the same directory)
    flagVerbose && println(string("Copying file listing jobs (", basename(pathJobsList), ") to the directory: ", pathPortable));
    cp(pathJobsList, string(pathPortable, "/", basename(pathJobsList)), remove_destination=true); # Copy list of jobs
    arrJobPaths = split(readall(pathJobsList), '\n')
    for jobFile in arrJobPaths
      if !ispath(jobFile)
        (!SUPPRESS_WARNINGS) && println("WARNING (in jsub.jl): The list file $pathJobsList contains a non-valid path: $jobFile");
      elseif (dirname(jobFile) != pathPortable)
        flagVerbose && println(string("Copying job file \"$jobFile\" to directory specificed by the --portable (-a) option: ", pathPortable));
        cp(jobFile, string(pathPortable, "/", basename(jobFile)), remove_destination=true);
      end
    end

    flagVerbose && println(string("Writing a copy of the submission script and functions file to the job file directory: ", pathPortable));
    # println("pathSubmissionScript = ", pathSubmissionScript);
    cp(pathSubmissionScript, string(pathPortable, "/", basename(pathSubmissionScript)), remove_destination=true);
    # println("pathSubmissionFunctions = ", pathSubmissionFunctions);
    cp(pathSubmissionFunctions, string(pathPortable, "/", basename(pathSubmissionFunctions)), remove_destination=true);
    flagVerbose && println(string("The jobs can be submitted to the queuing system by running the shell script: ", basename(pathSubmissionScript)));
    
    ## Zip jobs directory if requested
    if flagZip == true
      flagVerbose && println("Zipping jobs directory: ", pathPortable);
      flagVerbose && println("             into file: ", pathPortableZip);
      flagVerbose ? zipVerbose = "v" : zipVerbose = ""
      subZip = "";
      try
        subZip = run(`tar -zc$[zipVerbose]f $pathPortableZip $pathPortable`);
      catch
        println(subZip);
      end
    end
  end
  flagVerbose && println("");
end

## RUN ##
if requiredStages[1] == '1'
  pathSummariesList = run_stage1_(pathProtocol, pathVars, pathFvars; flagVerbose=flagVerbose, adapt_quotation=adapt_quotation, delimiterFvars=delimiterFvars, tagsExpand=tagsExpand, keep_superfluous_quotes=flagKeepQuotes)
end
if requiredStages[2] == '1'
  pathJobsList = run_stage2_(pathSummariesList, pathJobsList; flagVerbose=flagVerbose, tagsExpand=tagsExpand, checkpointsDict=checkpointsDict, commonFunctions=commonFunctions, doJsubVersionControl=doJsubVersionControl, processTimestamp=processTimestamp)
end
if requiredStages[3] == '1'
  run_stage3_(pathJobsList, 
    get_argument(parsed_args, "portable", verbose=flagVerbose, optional=true, default=""),
    pathSubmissionScript, pathSubmissionFunctions; flagVerbose=flagVerbose, flagZip=parsed_args["zip-jobs"]
  )
end
#########

# Report if there were any suppressed warnings
if num_suppressed[1] > 0
  println("Suppressed ", num_suppressed[1], " warnings.");
end
########################
# EOF


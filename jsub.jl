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
const comStr="#" # Note: this is expected to be "#".  Changing the string (char) used to indicate comments may cause problems further down the line.
# const dlmVars='\t' # Column delimiter for files containing variables
# const dlmProtocol=' ' # Column delimiter for the protocol file
const dlmWhitespace=[' ','\t','\n','\v','\f','\r'] # The default whitespace characters used by split
const flagWarn = true;
const delimiterFvars = '\t'

#### FUNCTIONS ####
function IsComment(wline, comStr) # Check if input string starts with the comment sub-string after any leading whitespace
  lstrip(wline)[1:length(comStr)] == comStr ? true : false
end

function IsBlank(wline) # Check if line is blank
  lstrip(wline) == "" ? true : false
end

function ReadFileIntoArrayOfArrays(fpath; cols=0::Integer, delimiter = nothing)
  println("Reading file: ", fpath)
  cols==0 ? println("into '", delimiter, "' delimited columns") : println("into ", cols, " '", delimiter, "' delimited columns");
  #println("delimiter: ", delimiter)
  arrRaw = split(readall(fpath), '\n'); # Read the input file
  commandRows = []; # row numbers of non-comment non-blank rows
  listOut = Array(Array, 0); #arrOut = Array(AbstractString, size(arrRaw)[1], numCols); # output array
  iNonBlank=0; 
  for wline in arrRaw
    if IsBlank(wline) == false
      iNonBlank+=1;
      if IsComment(wline, comStr)
        push!(listOut, [wline])
      else
        push!(commandRows, iNonBlank); # Index non-blank non-comment lines
        # Parse non-blank non-comment line data
        line = lstrip(wline); #print(line, "\n\n");
        # Check delimiter and split line
        arrLine = Array(ASCIIString, 0);
        if delimiter == nothing
          arrLine = split(line, dlmWhitespace; limit=cols, keep=false);
          # if cols != 0;
          #   warn("In function ReadFileIntoArrayOfArrays cols=", cols, " but delimiter=", delimiter, ". Using default split(::ASCIIString) method which splits by whitespace so the number of output columns may not correspond to the cols option.")
          # end
        else
          arrLine = split(line, delimiter; limit=cols, keep=false);
        end
        push!(listOut, arrLine);
      end
    end
  end
  return listOut, commandRows
end

function SanitizeVariableNameOrValue(str)
  # remove leading or trailing spaces
  sanitized = lstrip(rstrip(str))
  return sanitized
end

function ExtractColumnFromArrayOfArrays(arrArr, rows, col::Integer; dlm=' ')
  colVals=[];
  if col > 0
    for row in arrArr[rows]
      #println(row)
      push!(colVals, SanitizeVariableNameOrValue(row[col]) );
    end
  elseif col == 0
    for row in arrArr[rows]
      #println(row)
      push!(colVals, join((map( x->SanitizeVariableNameOrValue(x), row[1:end] )), dlm) );
    end
  else
    warn("(in ExtractColumnFromArrayOfArrays) unexpected column value parameter, expecting a non-negative integer but found: ", col);
  end
  return colVals
end

# function CheckStringSanity()
#   # warn about $ signs
#   # warn about #
#   # warn if line is < 5 chars long
# end

function  WarnOfNonReplacedSubstrings(inp, pat)
  if contains(inp, pat)
    warn("Not expanding variable matching pattern(s) \"$pat\" in string: ", inp);
  end
end

function ExpandOneVariableAtDollars(inputString, name, value)
  ## Replace # testString = "\"\${VAR}\"/unit_tests/ foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"\"\$VAR\"\".txt\""
  inputReCurly                 = replace(inputString,          string( "\${", name, "}"), value); # \${VAR}
  inputReCurlyReQuoted         = replace(inputReCurly,         string("\"\$", name, "\""), value); # \"\$VAR\"
  inputReCurlyReQuotedReSpaced = replace(inputReCurlyReQuoted, string( " \$", name, " "), value); # " \$VAR "
  ## Do not replace and warn about cases like \${VAR*  e.g. \${VAR%  # \${VAR:  # \${VAR#  # \${VAR?
  if flagWarn
    WarnOfNonReplacedSubstrings(inputReCurlyReQuotedReSpaced, string("\${", name) );
  end
  return inputReCurlyReQuotedReSpaced
end

function ExpandManyVariablesAtDollars(inputString, varNames, varVals)
  # Check that varNames is the same size as varVals
  if size(varNames) != size(varVals)
    ArgumentError(" in ExpandVariablesAtDollars size($varNames) != size($varVals).  Each input variable name should have exactly one corresponding value.  Is the .vars file correctly formated?")
  end
  outputString = inputString; # initialize, to be overwritten at each iteration of the loop
  for idx = 1:size(varNames)[1]
    name = SanitizeVariableNameOrValue(string(varNames[idx]));
    value = SanitizeVariableNameOrValue(string(varVals[idx]));
    outputString = ExpandOneVariableAtDollars(outputString, name, value)
  end
  return outputString
end

function ExpandVariablesInArrayOfArrays(arrArr, rows, varNames, varVals; verbose=true)
  # Check that varNames is the same size as varVals
  if size(varNames) != size(varVals)
    ArgumentError(" in ExpandVariablesInArrayOfArrays size($varNames) != size($varVals).  Each input variable name should have exactly one corresponding value.  Is the .vars or .fvars file correctly formated?")
  end
  arrOut = arrArr # Initialize output array
  irows = 0; # Note this is an index of the variable "rows" (which is itself an index)
  for arrRow in arrArr[rows]
    irows += 1;
    if verbose
      print("Expanding values in: ")
      for col in arrRow
        print(col, "\t")
      end
      print("\n")
    end
    if verbose
      print("       resulting in: ")
    end
    icol = 0;
    for col in arrRow
      icol += 1;
      expanded = ExpandManyVariablesAtDollars(col, varNames, varVals)
      if verbose
        print(expanded, "\t")
      end
      arrOut[rows[irows]][icol] = expanded
    end
    if verbose
      print("\n")
    end
  end
  return arrOut
end

# This function is needed to deal with escaped quotes that are created when julia reads a path containing quotes from a file.
function SanitizePath(raw)
  # Substrings inside and outside single quoutes are treated differently
  arrSplitSingle = split(raw, "'");
  arrOut = Array(AbstractString, size(arrSplitSingle) );
  # Replace escaped double-quotes in substrings outside of single quotes
  for idx in 1:2:length(arrSplitSingle) 
    arrOut[idx] = replace(arrSplitSingle[idx], "\"", "");
  end
  # Substrings inside single quotes are left unaltered (using print(string) later removes the '\' in front of the double quotes) 
  for jdx in 2:2:length(arrSplitSingle)
    arrOut[jdx] = arrSplitSingle[jdx]
  end
  return join(arrOut)
end

## Function for reading every list file given in .fvars and extracting arrays of variable values
# function ValuesFromLists (fpath, column) # Read a 'list' file and extract values from a selected column
#   arrArr, cmdRows = ReadFileIntoArrayOfArrays(fileList; cols=0, delimiter = nothing)
# end

function ParseVarsFile(fileVars)
  arrVars, cmdRowsVars = ReadFileIntoArrayOfArrays(fileVars; cols=2, delimiter="\t");
  namesVars = ExtractColumnFromArrayOfArrays(arrVars, cmdRowsVars, 1);
  valuesVars = ExtractColumnFromArrayOfArrays(arrVars, cmdRowsVars, 2);
  return namesVars, valuesVars
end

function ParseExpandVarsInFvarsFile(fileFvars, namesVars, valuesVars; dlmFvars=delimiterFvars)
  arrFvars, cmdRowsFvars = ReadFileIntoArrayOfArrays(fileFvars; cols=3, delimiter=dlmFvars);
  ## Use variables from .vars to expand values in .fvars
  arrExpFvars = ExpandVariablesInArrayOfArrays(arrFvars, cmdRowsFvars, namesVars, valuesVars );
  # Extract arrays of variable names and variable values
  namesFvars = ExtractColumnFromArrayOfArrays(arrFvars, cmdRowsFvars, 1);
  infileColumnsFvars = ExtractColumnFromArrayOfArrays(arrFvars, cmdRowsFvars, 2);

  # Get sanitized paths from strings in the third column of the .fvars file
  # Note that this is done after expanding any variables (from .vars) contained in the file paths.
  filePathsFvars = map(SanitizePath, ExtractColumnFromArrayOfArrays(arrFvars, cmdRowsFvars, 3));

  return namesFvars, infileColumnsFvars, filePathsFvars
end

function ParseExpandVarsInProtocolFile(fileProtocol, namesVars, valuesVars)
  arrProt, cmdRowsProt = ReadFileIntoArrayOfArrays(fileProtocol; cols=1, delimiter=nothing);
  ## Use variables from .vars to expand values in .protocol
  arrProtExpVars = ExpandVariablesInArrayOfArrays(arrProt, cmdRowsProt, namesVars, valuesVars )
  return arrProtExpVars, cmdRowsProt
end

# Expand variables in .fvars file using values from .vars file
function ParseExpandVarsInListFiles(filePathsFvars, namesVars, valuesVars, dlmFvars; verbose=false)
  ## Read each list file
  dictListArr = Dict(); # Dictionary with file paths as keys and file contents (arrays of arrays) as values.
  dictCmdLineIdxs = Dict(); #previously: # arrCmdLineIdxs = Array(Array, length(filePathsFvars) ); # Array for storing line counts from input files
  idx=0;
  for file in filePathsFvars
    idx+=1;
    arrList, cmdRowsList = ReadFileIntoArrayOfArrays(file; cols=0, delimiter=dlmFvars);
    arrListExpVars = ExpandVariablesInArrayOfArrays(arrList, cmdRowsList, namesVars, valuesVars ; verbose = verbose);
    dictListArr[file] = arrListExpVars;
    dictCmdLineIdxs[file] = cmdRowsList; #previously: # arrCmdLineIdxs[idx] = cmdRowsList
  end
  ## Warn if number of command row numbers differ between files
  if length( unique( map( x->length(x),  values(dictCmdLineIdxs) ) ) ) != 1  #previously: # if length(unique(map( x -> length(x) , arrCmdLineIdxs ))) != 1
    warn("(in ExpandVarsInListFiles) detected different numbers of command lines (non-comment non-blank) in input files:")
    for file in filePathsFvars
      println("number of command lines: ", length(dictCmdLineIdxs[file]), ", in file: ", filePathsFvars[file])
    end
  end
  ## Warn if indicies of command rows differ between files
  if length(unique(values(dictCmdLineIdxs))) != 1 #previously: # if length(unique(arrCmdLineIdxs)) != 1
    warn("(in ExpandVarsInListFiles) detected different indices of command lines (non-comment non-blank) in input files:")
    for idx = 1:length(filePathsFvars)
      println("Index of command lines: ", dictCmdLineIdxs[idx], ", in file: ", filePathsFvars[idx])
    end
  end
  return dictListArr, dictCmdLineIdxs
end

# Expand varaibles in .protocol using values from .fvars.  This necessarily results in one output summary file per list entry (list files indicated in .fvars)
function ExpandFvarsInProtocol(arrProt, cmdRowsProt, namesFvars, infileColumnsFvars, filePathsFvars, dictListArr, dictCmdLineIdxs)
  
  ## Loop over length of list files (currently assuming that all lists are of the same length but this may need to change in the future)
  for iln in 1:maximum( map(x->length(x), values(dictCmdLineIdxs)) )
    
    # Initialise array for holding values of each Fvar for the current list row (across all list files)
    valuesFvars = Array(AbstractString, size(namesFvars));
    
    ## Loop over Fvar names
    for ivar in 1:length(namesFvars)
      ## Get Fvar value from corresponding row of its list file
      # .fvar variable name, column and list file.
      fvarName = namesFvars[ivar];
      fvarColumnInListFile = parse(Int, infileColumnsFvars[ivar]); 
      fvarFile = filePathsFvars[ivar]; # Get the list file name associated with this Fvar
      listArr =  dictListArr[fvarFile]; # array of arrays of the contents of the list file
      cmdLineIdxs = dictCmdLineIdxs[fvarFile]; # Rows in the list file which contain data as opposed to comments or being empty
      fvarValue = ExtractColumnFromArrayOfArrays(listArr, cmdLineIdxs, fvarColumnInListFile)[iln]; # This particular value of the Fvar
      valuesFvars[ivar] = fvarValue;
    end

    ## Create a new summary file array for the current list row (across all list files)
    arrExpFvars = ExpandVariablesInArrayOfArrays(arrProt, cmdRowsProt, namesFvars, valuesFvars )

  end



end

###################


######### SCRIPT #########

## Read .vars file # Extract arrays of variable names and variable values
namesVars, valuesVars = ParseVarsFile(fileVars)

## Read .fvar file (of 3 columns) and expand variables from .vars
namesFvars, infileColumnsFvars, filePathsFvars = ParseExpandVarsInFvarsFile(fileFvars, namesVars, valuesVars)

## Read .protocol file (of 1 column ) and expand variables from .vars
arrProtExpVars, cmdRowsProt = ParseExpandVarsInProtocolFile(fileProtocol, namesVars, valuesVars)

## Read "list" files and return their contents in an dictionary (key: file path) (value: arrays of arrays) as well as corresponding command line indicies
dictListArr, dictCmdLineIdxs = ParseExpandVarsInListFiles(filePathsFvars, namesVars, valuesVars, delimiterFvars; verbose=false)

## Use variable values from "list" files to create summary files from the .protocol
ExpandFvarsInProtocol(arrProtExpVars, cmdRowsProt, namesFvars, infileColumnsFvars, filePathsFvars, dictListArr, dictCmdLineIdxs)







##########################
# EOF


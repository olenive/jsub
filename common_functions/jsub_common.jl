## This file contains the julia functions used throughout the jsub utility.

function IsComment(wline, comStr) # Check if input string starts with the comment sub-string after any leading whitespace
  lstrip(wline)[1:length(comStr)] == comStr ? true : false
end

function IsBlank(wline) # Check if line is blank
  lstrip(wline) == "" ? true : false
end

function ReadFileIntoArrayOfArrays(fpath, comStr; cols=0::Integer, delimiter = nothing)
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


# Check if the subsequent character in the input string terminates any potential variable name
function IsNextCharacterVariableNameCompliant(inString, ichr) # Note ichr is the current character and not the character being checked because we may be at the end of the string.
  # Check if character is alphanumeric or an underscore
  if ichr+1 > length(inString)
    return false
  else
    if isalnum(inString[ichr+1]) || inString[ichr+1] == '_'
      return true
    else
      return false
    end
  end
end

# Determine the role of the character in the input string.
function DeterminCharacterLabel(inString, ichr, previousLabels)
  char = inString[ichr]
  outLabels = Set([])
  
  #### Labels are not mutually exclusive ####
  # outside: not part of a potential variable name
  # dollar: character indicating start of variable name
  # curly_open: opening curly brace in variable name
  # curly_close: closing curly brace in variable name
  # curly_inside: part of a variable name inside curly braces
  # plain: part of a variable name without curly braces
  # terminating: indicates the end of a variable name
  # discard: indicates the end of a variable in an unexpected manner
  ###########################################

  ## Outside of candidate varaible name or at start of string
  if ("outside" in previousLabels) || isempty(previousLabels) ||  ("curly_close" in previousLabels)
    # Check for opening dollar sign
    if char != '\$'
      push!(outLabels, "outside")
    else
      push!(outLabels, "dollar")
    end
  end

  ## After a terminating character
  if ("terminating" in previousLabels)
    # Check for opening dollar sign
    if char != '\$'
      # Check for closing curly brace
      if ( ("curly_inside" in previousLabels) || ("curly_open" in previousLabels) ) && char=='}'
        # Note: Checks for this closing curly brace and warnings should happen when looking at the previous character
        push!(outLabels, "curly_close")
      else
        push!(outLabels, "outside")
      end
    else
      push!(outLabels, "dollar")
    end
  end

  ## Inside candidate variable name
  if !("terminating" in previousLabels) && (("plain" in previousLabels) || ("curly_inside" in previousLabels) || ("dollar" in previousLabels) || ("curly_open" in previousLabels))
    # Check for opening dollar sign
    if char == '\$'
      push!(outLabels, "dollar")
    end

    # Check if this is a terminating character
    if !IsNextCharacterVariableNameCompliant(inString, ichr)
      push!(outLabels, "terminating")

      # Label as discard if this is the first character after the opening dollar sign or curly brace
      if ("curly_open" in previousLabels) || ("dollar" in previousLabels)
        push!(outLabels, "discard")
      end

      ## Check for missing closing curly brace
      if ("curly_inside" in previousLabels) && ( ichr==length(inString) || inString[ichr+1]!='}' ) 
        warn(" (in DeterminCharacterLabel) Expecting closing curly brace after position ", ichr, " in string: ", inString)
        push!(outLabels, "discard")
      end
    end

    ## Propogate label state from previous character
    if ("plain" in previousLabels) 
      push!(outLabels, "plain")
    
    elseif ("curly_inside" in previousLabels)
      push!(outLabels, "curly_inside")
    
    elseif ("dollar" in previousLabels)
      # Check if this character is name compliant or an opening curly brace
      if IsNextCharacterVariableNameCompliant(inString, ichr-1 ) # -1 because the function looks at the next character
        push!(outLabels, "plain")
      elseif char=='{'
        push!(outLabels, "curly_open")
      end
    
    elseif ("curly_open" in previousLabels)
      if char=='}' # Check for premature closing brace
        warn(" (in DeterminCharacterLabel) Found closing curly brace immediately after an opening curly brace \"\${}\" in string: ", inString)
      elseif IsNextCharacterVariableNameCompliant(inString, ichr-1 ) # -1 because the function looks at the next character
        push!(outLabels, "curly_inside")
      end
    
    end
  end
  return outLabels
end

# Assign labels to each character in a string
function AssignLabels(inString)
  charLabels = [];
  ## For each character in the string
  for ichr in 1:length(inString)
    char = inString[ichr];
    ## Assign a label
    label = Set([])
    if ichr==1
      label = DeterminCharacterLabel(inString, ichr, Set([]))
    else
      label = DeterminCharacterLabel(inString, ichr, charLabels[ichr-1])
    end
    push!(charLabels, label )
    println(inString[ichr], " ", label)
  end
  return charLabels
end

# Take a potential variable name, the charLabels of the characters, compare against known variable names and return the string to be appended to the output.
function ProcessCandidateNames(candidate, terminatingLabelSet, name, value)
  ## Check for discard label
  if ("discard" in terminatingLabelSet)
    return candidate
  end
  ## Determin if using curlly or just dollar
  if ("curly_inside" in terminatingLabelSet)
    prefix="\${";
    suffix="}";
  elseif ("plain" in terminatingLabelSet)
    prefix="\$";
    suffix="";
  else
    prefix="";
    suffix="";
    warn(" (in ProcessCandidateNames) expecting either a \"curly_inside\" or a \"plain\" label in the terminatingLabelSet of candidate (", candidate, ") but found: ", terminatingLabelSet );
  end
  testName = prefix*name*suffix;
  println(testName, " vs ", candidate)
  if testName == candidate
    return value
  else
    return candidate
  end
end

function ExpandOneVariableAtDollars(inString, name, value)  # this will not remove double quoutes aroud a variable (this function could do with refactoring/rewriting (see ut_jsub_common.jl for the necessary unit test))
  # Initialise
  #flagWarn = false;
  outString = "";
  candidate = ""; # potential variable name
  istart = 0;

  ## Get vector of character label sets
  charLabels = AssignLabels(inString);

  ## Process string based on character labels
  for ichr in 1:length(inString)
    char = inString[ichr];
    # println("ExpandOneVariableAtDollars: (", ichr, ") ", char)
    ## Process on the basis of the label
    if ("outside" in charLabels[ichr]) # Not in a variable name
      outString = outString * string(char); # Add to output string (this could be made more efficient but should not take much CPU time in practice anyway)
    elseif ("terminating" in charLabels[ichr]) # Reached end of potential variable name
      candidate = candidate * string(char); # Add to candidate name string
      # println("1 added to candidate: ", string(candidate[end]));
      ## Check for closing curly brace and append it to candidate name
      if ("curly_inside" in charLabels[ichr]) && !("discard" in charLabels[ichr])
        #println("dealing with closing curly brace in discarded candidate name: ", candidate)
        candidate = candidate * string(inString[ichr+1]); # Note: this should never be called for the final character in the input string
        # println("2 added to candidate: ", string(candidate[end]));
      end
      ## Process, append and re-intialise candidate variable name
      # println("B ProcessCandidateNames: ", candidate, ",  ", charLabels[ichr], ",  ", name, ",  ", value)
      processedCandidate = ProcessCandidateNames(candidate, charLabels[ichr], name, value);
      # println("B Appending: ", processedCandidate )
      outString = outString * processedCandidate; ## Add candidate string or variable value to output
      candidate = ""; 
      istart = 1;
    elseif !("curly_close" in charLabels[ichr]) # closing curly braces are added to the candidate in the lines above
      candidate = candidate * string(char); # Add to candidate name string
      # println("3 added to candidate: ", string(candidate[end]));
    end
  end

  return outString
end

function ExpandManyVariablesAtDollars(inString, varNames, varVals)
  # Check that varNames is the same size as varVals
  if size(varNames) != size(varVals)
    ArgumentError(" in ExpandVariablesAtDollars size($varNames) != size($varVals).  Each input variable name should have exactly one corresponding value.  Is the .vars file correctly formated?")
  end
  outString = inString; # initialize, to be overwritten at each iteration of the loop
  for idx = 1:size(varNames)[1]
    name = SanitizeVariableNameOrValue(string(varNames[idx]));
    value = SanitizeVariableNameOrValue(string(varVals[idx]));
    outString = ExpandOneVariableAtDollars(outString, name, value)
  end
  return outString
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
  arrVars, cmdRowsVars = ReadFileIntoArrayOfArrays(fileVars, comStr; cols=2, delimiter="\t");
  namesVars = ExtractColumnFromArrayOfArrays(arrVars, cmdRowsVars, 1);
  valuesVars = ExtractColumnFromArrayOfArrays(arrVars, cmdRowsVars, 2);
  return namesVars, valuesVars
end

function ExpandInOrder(namesVarsRaw, valuesVarsRaw) # Expand variable values one row at a time as though they are being assigned at a shell command line
  if (length(namesVarsRaw) != length(valuesVarsRaw)) # Check that in put vector lengths match
    warn(" (in ExpandInOrder) variable name and values arguments should be vectors of equal lengths but appear to be of different lengths.")
  end
  ## For each input row expand the variables in the values vector using using name-value paris from preceeding rows
  valuesVars = Array(Any, length(namesVarsRaw))
  for irow in 1:length(namesVarsRaw)
    if irow == 1
      valuesVars[irow] = valuesVarsRaw[irow];
    else 
      valuesVars[irow] = ExpandManyVariablesAtDollars(valuesVarsRaw[irow], namesVarsRaw[1:irow-1], valuesVarsRaw[1:irow-1]); ## length comparison done inside ExpandManyVariablesAtDollars  
    end
  end
  namesVars = namesVarsRaw; # in this version variable names containing the names of other variables are treated as literal strings (variables not expanded)
  return namesVars, valuesVars  
end

function ParseExpandVarsInFvarsFile(fileFvars, namesVars, valuesVars; dlmFvars=delimiterFvars)
  arrFvars, cmdRowsFvars = ReadFileIntoArrayOfArrays(fileFvars, comStr; cols=3, delimiter=dlmFvars);
  ## Use variables from .vars to expand values in .fvars
  arrExpFvars = ExpandVariablesInArrayOfArrays(arrFvars, cmdRowsFvars, namesVars, valuesVars ; verbose = verbose);
  # Extract arrays of variable names and variable values
  namesFvars = ExtractColumnFromArrayOfArrays(arrFvars, cmdRowsFvars, 1);
  infileColumnsFvars = ExtractColumnFromArrayOfArrays(arrFvars, cmdRowsFvars, 2);

  # Get sanitized paths from strings in the third column of the .fvars file
  # Note that this is done after expanding any variables (from .vars) contained in the file paths.
  filePathsFvars = map(SanitizePath, ExtractColumnFromArrayOfArrays(arrFvars, cmdRowsFvars, 3));

  return namesFvars, infileColumnsFvars, filePathsFvars
end

function ParseExpandVarsInProtocolFile(fileProtocol, namesVars, valuesVars)
  arrProt, cmdRowsProt = ReadFileIntoArrayOfArrays(fileProtocol, comStr; cols=1, delimiter=nothing);
  ## Use variables from .vars to expand values in .protocol
  arrProtExpVars = ExpandVariablesInArrayOfArrays(arrProt, cmdRowsProt, namesVars, valuesVars ; verbose = verbose)
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
    arrList, cmdRowsList = ReadFileIntoArrayOfArrays(file, comStr; cols=0, delimiter=dlmFvars);
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
function ExpandFvarsInProtocol(arrProt, cmdRowsProt, namesFvars, infileColumnsFvars, filePathsFvars, dictListArr, dictCmdLineIdxs ; verbose = false )
  arrArrExpFvars = []; ## Initialise array for holding summary file arrays-of-arrays
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
    arrExpFvars = ExpandVariablesInArrayOfArrays(arrProt, cmdRowsProt, namesFvars, valuesFvars ; verbose = verbose )
    push!(arrArrExpFvars, arrExpFvars)
  end
  return arrArrExpFvars
end


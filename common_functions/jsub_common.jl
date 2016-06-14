## This file contains the julia functions used throughout the jsub utility.

function iscomment(wline, comStr) # Check if input string starts with the comment sub-string after any leading whitespace
  lstrip(wline)[1:length(comStr)] == comStr ? true : false
end

function isblank(wline) # Check if line is blank
  lstrip(wline) == "" ? true : false
end

function file2arrayofarrays(fpath, comStr; cols=0::Integer, delimiter = nothing, verbose=false)
  println("Reading file: ", fpath)
  cols==0 ? println("into '", delimiter, "' delimited columns") : println("into ", cols, " '", delimiter, "' delimited columns");
  #println("delimiter: ", delimiter)
  arrRaw = split(readall(fpath), '\n'); # Read the input file
  commandRows = []; # row numbers of non-comment non-blank rows
  ## Initialise output array
  listOut = Array(Array{UTF8String}, 0); # Insisting of UTF8String here to avoid conversion problems later (MethodError: `convert` has no method matching convert(::Type{SubString{ASCIIString}}, ::UTF8String))  #arrOut = Array(AbstractString, size(arrRaw)[1], numCols); 
  iNonBlank=0; 
  for wline in arrRaw
    if isblank(wline) == false
      iNonBlank+=1;
      if iscomment(wline, comStr)
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
          #   warn("In function file2arrayofarrays cols=", cols, " but delimiter=", delimiter, ". Using default split(::ASCIIString) method which splits by whitespace so the number of output columns may not correspond to the cols option.")
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

function sanitizestring(str)
  # remove leading or trailing spaces
  sanitized = lstrip(rstrip(str))
  return sanitized
end

function columnfrom_arrayofarrays(arrArr, rows, col::Integer; dlm=' ')
  colVals=[];
  if col > 0
    for row in arrArr[rows]
      #println(row)
      push!(colVals, sanitizestring(row[col]) );
    end
  elseif col == 0
    for row in arrArr[rows]
      #println(row)
      push!(colVals, join((map( x->sanitizestring(x), row[1:end] )), dlm) );
    end
  else
    SUPPRESS_WARNINGS ? num_suppressed[1] += 1 : warn("(in columnfrom_arrayofarrays) unexpected column value parameter, expecting a non-negative integer but found: ", col);
  end
  return colVals
end

# function CheckStringSanity()
#   # warn about $ signs
#   # warn about #
#   # warn if line is < 5 chars long
# end

function  warn_notreplaced(inp, pat)
  if contains(inp, pat)
    SUPPRESS_WARNINGS ? num_suppressed[1] += 1 : warn("Not expanding variable matching pattern(s) \"$pat\" in string: ", inp); 
  end
end


# Check if the subsequent character in the input string terminates any potential variable name
function nextcharacter_isnamecompliant(inString, ichr) # Note ichr is the current character and not the character being checked because we may be at the end of the string.
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
function determinelabel(inString, ichr, previousLabels)
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
    if !nextcharacter_isnamecompliant(inString, ichr)
      push!(outLabels, "terminating")

      # Label as discard if this is the first character after the opening dollar sign or curly brace
      if ("curly_open" in previousLabels) || ("dollar" in previousLabels)
        push!(outLabels, "discard")
      end

      ## Check for missing closing curly brace
      if ("curly_inside" in previousLabels) && ( ichr==length(inString) || inString[ichr+1]!='}' ) 
        SUPPRESS_WARNINGS ? num_suppressed[1] += 1 : warn(" (in determinelabel) Expecting closing curly brace after position ", ichr, " in string: ", inString);
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
      if nextcharacter_isnamecompliant(inString, ichr-1 ) # -1 because the function looks at the next character
        push!(outLabels, "plain")
      elseif char=='{'
        push!(outLabels, "curly_open")
      end
    
    elseif ("curly_open" in previousLabels)
      if char=='}' # Check for premature closing brace
        SUPPRESS_WARNINGS ? num_suppressed[1] += 1 : warn(" (in determinelabel) Found closing curly brace immediately after an opening curly brace \"\${}\" in string: ", inString);
      elseif nextcharacter_isnamecompliant(inString, ichr-1 ) # -1 because the function looks at the next character
        push!(outLabels, "curly_inside")
      end
    
    end
  end
  return outLabels
end

# Assign labels to each character in a string
function assignlabels(inString)
  charLabels = [];
  ## For each character in the string
  for ichr in 1:length(inString)
    char = inString[ichr];
    ## Assign a label
    label = Set([])
    if ichr==1
      label = determinelabel(inString, ichr, Set([]))
    else
      label = determinelabel(inString, ichr, charLabels[ichr-1])
    end
    push!(charLabels, label )
    # println(inString[ichr], " ", label)
  end
  return charLabels
end

# Take a potential variable name, the charLabels of the characters, compare against known variable names and return the string to be appended to the output.
function processcandidatename(candidate, terminatingLabelSet, name, value; returnTrueOrFalse=false) # returnTrueOrFalse=true means that instead of returning the value to replace the variable name, true will be returned if a valid name exists (false otherwise)
  ## Check for discard label
  if ("discard" in terminatingLabelSet)
    returnTrueOrFalse ? false : return candidate
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
    SUPPRESS_WARNINGS ? num_suppressed[1] += 1 : warn(" (in processcandidatename) expecting either a \"curly_inside\" or a \"plain\" label in the terminatingLabelSet of candidate (", candidate, ") but found: ", terminatingLabelSet );
  end
  testName = prefix*name*suffix;
  # println(testName, " vs ", candidate)
  if testName == candidate
    returnTrueOrFalse ? true : return value
  else
    returnTrueOrFalse ? false : return candidate
  end
end

## Takes a string and replaces name with value where a match is found
# adapt_quotation=true: Attemts to keep the pattern of quotation consistent before and after substitution by inserting quotes
# returTF=true: Returns true if inString contains a name that would be substituted for value (but does not return the resulting string)
function expandnameafterdollar(inString, name, value; adapt_quotation=false, returnTF=false)
  # Initialise
  outString = "";
  candidate = ""; # potential variable name
  istart = 0;

  charLabels = assignlabels(inString); # Get vector of character label sets
  inclusive_start = 0; inclusive_finish = 0;
  ## Process string based on character labels
  for ichr in 1:length(inString)
    char = inString[ichr];
    ## Process on the basis of the label
    if ("outside" in charLabels[ichr]) # Not in a variable name
      outString = outString * string(char); # Add to output string (this could be made more efficient but should not take much CPU time in practice anyway)
    elseif ("terminating" in charLabels[ichr]) # Reached end of potential variable name
      candidate = candidate * string(char); # Add to candidate name string # println("1 added to candidate: ", string(candidate[end]));
      ## Check for closing curly brace and append it to candidate name
      if ("curly_inside" in charLabels[ichr]) && !("discard" in charLabels[ichr]) #println("dealing with closing curly brace in discarded candidate name: ", candidate)
        candidate = candidate * string(inString[ichr+1]); # Note: this should never be called for the final character in the input string # println("2 added to candidate: ", string(candidate[end]));
      end
      ## Process, append and re-intialise candidate variable name # println("B processcandidatename: ", candidate, ",  ", charLabels[ichr], ",  ", name, ",  ", value)
      processedCandidate = "";
      if returnTF
        return processcandidatename(candidate, charLabels[ichr], name, value; returnTrueOrFalse=true);
      else  
        processedCandidate = processcandidatename(candidate, charLabels[ichr], name, value);
        ## Insert quotes in the resulting string (optional) to maintain the patter of quotation before and after substitution of name for value.
        if processedCandidate != candidate && adapt_quotation
          inclusive_start = length(outString)+1;
          inclusive_finish = length(outString)+length(candidate); 
          processedCandidate = enforce_quote_consistency(inString, processedCandidate, inclusive_start, inclusive_finish; charQuote='\"')
        end
      end
      # println("B Appending: ", processedCandidate )
      outString = outString * processedCandidate; ## Add candidate string or variable value to output
      candidate = ""; 
      istart = 1;
    elseif !("curly_close" in charLabels[ichr]) # closing curly braces are added to the candidate in the lines above
      candidate = candidate * string(char); # Add to candidate name string # println("3 added to candidate: ", string(candidate[end]));
    end
  end
  return outString
end

function assign_quote_state(inString, charQuote::Char) # For each character in the input and output string assign a 0 if it is outside quotes or a 1 if it is inside quotes or a 2 if it is a quote character
  out = [];
  inside_quotes = false;
  for idx in 1:length(inString)
    if inString[idx] == charQuote
      push!(out, 2);
      inside_quotes = !inside_quotes;
    else
      push!(out, inside_quotes*1);
    end
  end
  return out
end

function substitute_string(inString, subString, inclusive_start, inclusive_finish; charQuote='\"', quotes_before=0, quotes_after=0)
  return inString[1:inclusive_start-1] * repeat(string(charQuote), quotes_before) * subString * repeat(string(charQuote), quotes_after) * inString[inclusive_finish+1:end];
end

## Get the index of the first and last non-quote character in a section of the input string indicated by inclusive_start and inclusive_finish
function get_index_of_first_and_last_nonquote_characters(inString, charQuote::Char; iStart=1, iFinish=0)
  # Determine end of sub-string
  if iFinish == 0
    iFinish=length(inString)
  end
  idx_first = 0; idx_last = 0; # Zero indicates that no non-quote characters were found in the input string
  # Loop forwards over the string to find the first non-quote character
  for fwd in iStart:iFinish
    if inString[fwd] != charQuote
      idx_first = fwd;
      break
    end
  end
  # Loop backwards over the string to find the last non-quote character
  for fwd in 1:iFinish+1-iStart
    rev = iFinish+1-fwd
    if inString[rev] != charQuote
      idx_last = rev;
      break
    end
  end
  return idx_first, idx_last
end

## Check that substitution of part of a string does not change the inside/outside quote status of other parts of the string
function check_quote_consistency(inString, subString, inclusive_start, inclusive_finish; charQuote='\"', verbose=false, quotes_before=0, quotes_after=0)
  ## Get indices of prefix, suffix (before and after) and substituted string
  idx_prefix = collect(1:inclusive_start-1);
  # idx_suffix_in = collect(inclusive_finish+1:end);
  # idx_suffix_out = collect(inclusive_start+quotes_before+length(subString)+quotes_after:end);
  idx_subbed = collect(inclusive_start+quotes_before:inclusive_start+quotes_before+length(subString)-1);
  ## Get quote patterns for inString, the string into which subString will be substituted at the positions indicated by inclusive_start and inclusive_finish
  pattern_inString = assign_quote_state(inString, charQuote);
  pattern_prefix_in = pattern_inString[idx_prefix];
  pattern_suffix_in = pattern_inString[inclusive_finish+1:end];
  ## Get quote pattern for the string resulting from the substitution (including additional quotes added using the quotes_before and quotes_after options)
  outString = substitute_string(inString, subString, inclusive_start, inclusive_finish, quotes_before=quotes_before, quotes_after=quotes_after);
  pattern_outString = assign_quote_state(outString, charQuote);
  pattern_prefix_out = pattern_outString[idx_prefix];
  pattern_suffix_out = pattern_outString[inclusive_start+quotes_before+length(subString)+quotes_after:end];
  ## Get quote patterns for subString on it's own and after insertion into inString
  pattern_subString_before = assign_quote_state(subString, charQuote);
  pattern_subString_after = pattern_outString[idx_subbed];
  # ## Count the number of quotes in both strings and determine if they are even or odd
  # iseven_inString = iseven(length(split(inString, charQuote))-1;)
  # iseven_outString = iseven(length(split(outString, charQuote))-1;)
  ## Get the last character type remaining from inString before and after substitution
  last_in = ""; last_out = "";
  if length(pattern_inString[inclusive_finish+1:end]) > 0
    last_in = pattern_inString[inclusive_finish+1:end][end]
  end
  if length(pattern_outString[inclusive_start+quotes_before+length(subString)+quotes_after:end]) > 0
    last_out = pattern_outString[inclusive_start+quotes_before+length(subString)+quotes_after:end][end];
  end
  ## Print variables used to determine the result (for debugging)
  if verbose
    println("    Verbose output of check_quote_consistency:")
    println(inString)
    println(outString)
    println(pattern_inString')
    println(pattern_outString')
    println("before: ", pattern_prefix_in, " vs ", pattern_prefix_out, " -> ", pattern_prefix_in == pattern_prefix_out)
    println("inserted: ", pattern_subString_before, " vs ", pattern_subString_after, " -> ", pattern_subString_before == pattern_subString_after)
    println("after: ", pattern_suffix_in, " vs ", pattern_suffix_out, " -> ", pattern_suffix_in == pattern_suffix_out)
    println("last character: ", last_in, " vs ", last_out, " -> ", last_in == last_out)
    # println("Number of ", string(charQuote), ": ", length(split(inString, charQuote))-1, " vs ", length(split(outString, charQuote))-1)
    # println(iseven_inString == iseven_outString)
    println("")
  end
  ## Check and return result
  if ( pattern_subString_before == pattern_subString_after # Check that the quote pattern of subString remains the same after it is substituted into inString  
    && pattern_prefix_in == pattern_prefix_out # Check that the quote pattern of the parts of inString before and after subString remains unchanged after the substitution
    && pattern_suffix_in == pattern_suffix_out
    && last_in == last_out # Check for cases where the last character is a quote and is replaced (e.g. A"B" -> A"C)
    #&& iseven_inString == iseven_outString # Check that the resulting numbers of quotes are either both even or both odd
    )
    return true;
  else
    return false;
  end
end

## Alter a string so that substituting it into another string (e.g. variable name for its value) does not change the inside/outside quote status of other parts of the string
# Return value consists of the subString argument with quotes (charQuote) added before and after to try to prevent changes in the quoting pattern before and after substitution.
# ignore_fails=true: If quote pattern is still inconsistent return the original subString
function enforce_quote_consistency(inString, subString, inclusive_start, inclusive_finish; charQuote='\"', ignore_fails=false, verbose=false)
  pattern_before = assign_quote_state(inString, charQuote);
  ## Try adding different quote permutations until one gives a consistent result
  for num_before in [0,1,2]
    for num_after in [0,1,2]
      consistent = check_quote_consistency(inString, subString, inclusive_start, inclusive_finish, quotes_before=num_before, quotes_after=num_after, charQuote=charQuote, verbose=verbose);
      if verbose # For debugging
        println("    Verbose output of enforce_quote_consistency:")
        println("num_before = ", num_before, ", num_after = ", num_after)
        println("check_quote_consistency -> ", consistent)
        println("pattern_before[1:inclusive_start-1] == pattern_after[1:inclusive_start-1] -> ", pattern_before[1:inclusive_start-1] == pattern_after[1:inclusive_start-1] )
        println("pattern_before[inclusive_finish+1:end] == pattern_after[inclusive_finish+1+num_before:end] -> ", pattern_before[inclusive_finish+1:end] == pattern_after[inclusive_finish+1+num_before:end])
        println("")
      end
      if consistent # Check that the new string is consistent after substitution  
        return repeat(string(charQuote), num_before) * subString * repeat(string(charQuote), num_after) 
      end
    end
  end
  ## Adding quotes on either side did not fix the problem
  if !ignore_fails
    error("Unable to enforce quote consistency for: ", "inString=[", inString, "], subString=[", subString, "], inclusive_start=[", inclusive_start, "] (inString[inclusive_start]=",inString[inclusive_start],"), inclusive_finish=[", inclusive_finish, "], (inString[inclusive_finish]=",inString[inclusive_finish],"), charQuote=[", charQuote, "]")
  else
    return subString  
  end
end

## Expand many variables in a string
function expandmanyafterdollars(inString, varNames, varVals; adapt_quotation=false, returnTF=false)
  # Check that varNames is the same size as varVals
  if size(varNames) != size(varVals)
    ArgumentError(" in ExpandVariablesAtDollars size($varNames) != size($varVals).  Each input variable name should have exactly one corresponding value.  Is the .vars file correctly formated?")
  end
  outString = inString; # initialize, to be overwritten at each iteration of the loop
  for idx = 1:size(varNames)[1]
    name = sanitizestring(string(varNames[idx]));
    value = sanitizestring(string(varVals[idx]));
    outString = expandnameafterdollar(outString, name, value, adapt_quotation=adapt_quotation, returnTF=returnTF)
  end
  return outString
end

# Add a closing quote to a string if one is needed
function enforce_closingquote(inString, charQuote::Char)
  pattern = assign_quote_state(inString, charQuote);
  # Determine if extending the string by one non-quote character would result in the string ending in an un-quoted state
  non_quote = 'a';
  if charQuote == non_quote # find a chacter that does not match the quote-character
    non_quote = 'b';
  end
  longerString = inString * string(non_quote);
  longerPattern = assign_quote_state(longerString, charQuote);
  if longerPattern[end] == 1
    return inString * string(charQuote)
  else
    return inString
  end
end

# Expand variables in array of arrays containing commands (ignoring comment lines)
function expand_inarrayofarrays(arrArr, rows, varNames, varVals; verbose=false, adapt_quotation=false, returnTF=false) 
  # Check that varNames is the same size as varVals
  if size(varNames) != size(varVals)
    ArgumentError(" in expand_inarrayofarrays size($varNames) != size($varVals).  Each input variable name should have exactly one corresponding value.  Is the .vars or .fvars file correctly formated?")
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
      print("       resulting in: ")
    end
    icol = 0;
    for col in arrRow
      icol += 1;
      expanded = expandmanyafterdollars(col, varNames, varVals, adapt_quotation=adapt_quotation, returnTF=returnTF)
      if adapt_quotation # Add closing quote to string
        expanded = enforce_closingquote(expanded, '\"');
      end
      if verbose
        print(expanded, "\t")
      end
      arrOut[rows[irows]][icol] = expanded;
    end
    if verbose
      print("\n")
    end
  end
  return arrOut
end

# This function is needed to deal with escaped quotes that are created when julia reads a path containing quotes from a file.
function sanitizepath(raw)
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
#   arrArr, cmdRows = file2arrayofarrays(fileList; cols=0, delimiter = nothing)
# end

# Expand variable values one row at a time as though they are being assigned at a shell command line
function expandinorder(namesVarsRaw, valuesVarsRaw; adapt_quotation=false, returnTF=false)
  ## Check that in put vector lengths match
  if (length(namesVarsRaw) != length(valuesVarsRaw)) 
    SUPPRESS_WARNINGS ? num_suppressed[1] += 1 : warn(" (in expandinorder) variable name and values arguments should be vectors of equal lengths but appear to be of different lengths.");
  end
  ## For each input row expand the variables in the values vector using using name-value paris from preceeding rows
  valuesVars = Array(Any, length(namesVarsRaw))
  for irow in 1:length(namesVarsRaw)
    if irow == 1
      valuesVars[irow] = valuesVarsRaw[irow];
    else 
      valuesVars[irow] = expandmanyafterdollars(valuesVarsRaw[irow], namesVarsRaw[1:irow-1], valuesVarsRaw[1:irow-1], adapt_quotation=adapt_quotation, returnTF=returnTF); ## length comparison done inside expandmanyafterdollars
      valuesVarsRaw[irow] = valuesVars[irow]; # Update the values to be used for subsequent expansions
    end
  end
  namesVars = namesVarsRaw; # in this version variable names containing the names of other variables are treated as literal strings (variables not expanded)
  return namesVars, valuesVars  
end

# Read the .vars file and expand variables row by row.
function parse_varsfile(fileVars; dlmVars=nothing)
  arrVars, cmdRowsVars = file2arrayofarrays(fileVars, comStr; cols=2, delimiter=dlmVars);
  namesVars = columnfrom_arrayofarrays(arrVars, cmdRowsVars, 1);
  valuesVars = columnfrom_arrayofarrays(arrVars, cmdRowsVars, 2);
  return namesVars, valuesVars # This can subsequently be expanded row by row using the expandinorder function.
end

# Read the .fvars file and expand variables row by row.
function parse_expandvars_fvarsfile(fileFvars, namesVars, valuesVars; dlmFvars=nothing, adapt_quotation=false, verbose=false) # Read the .fvars file 
  arrFvars, cmdRowsFvars = file2arrayofarrays(fileFvars, comStr; cols=3, delimiter=dlmFvars);
  ## Use variables from .vars to expand values in .fvars
  arrExpFvars = expand_inarrayofarrays(arrFvars, cmdRowsFvars, namesVars, valuesVars; verbose = verbose, adapt_quotation=adapt_quotation);
  # Extract arrays of variable names and variable values
  namesFvars = columnfrom_arrayofarrays(arrFvars, cmdRowsFvars, 1);
  infileColumnsFvars = columnfrom_arrayofarrays(arrFvars, cmdRowsFvars, 2);

  # Get sanitized paths from strings in the third column of the .fvars file
  # Note that this is done after expanding any variables (from .vars) contained in the file paths.
  filePathsFvars = map(sanitizepath, columnfrom_arrayofarrays(arrFvars, cmdRowsFvars, 3));

  return namesFvars, infileColumnsFvars, filePathsFvars
end

function parse_expandvars_protocol(fileProtocol, namesVars, valuesVars; adapt_quotation=false, verbose=false)
  arrProt, cmdRowsProt = file2arrayofarrays(fileProtocol, comStr; cols=1, delimiter=nothing);
  ## Use variables from .vars to expand values in .protocol
  arrProtExpVars = expand_inarrayofarrays(arrProt, cmdRowsProt, namesVars, valuesVars ; verbose = verbose, adapt_quotation=adapt_quotation)
  return arrProtExpVars, cmdRowsProt
end

# Expand variables in .fvars file using values from list files
function parse_expandvars_listfiles(filePathsFvars, namesVars, valuesVars, dlmFvars; verbose=false, adapt_quotation=false)
  ## Read each list file
  dictListArr = Dict(); # Dictionary with file paths as keys and file contents (arrays of arrays) as values.
  dictCmdLineIdxs = Dict(); #previously: # arrCmdLineIdxs = Array(Array, length(filePathsFvars) ); # Array for storing line counts from input files
  idx=0;
  for file in filePathsFvars
    idx+=1;
    arrList, cmdRowsList = file2arrayofarrays(file, comStr; cols=0, delimiter=dlmFvars);
    arrListExpVars = expand_inarrayofarrays(arrList, cmdRowsList, namesVars, valuesVars ; verbose = verbose, adapt_quotation=adapt_quotation);
    dictListArr[file] = arrListExpVars;
    dictCmdLineIdxs[file] = cmdRowsList; #previously: # arrCmdLineIdxs[idx] = cmdRowsList
  end
  ## Warn if number of command row numbers differ between files
  if length( unique( map( x->length(x),  values(dictCmdLineIdxs) ) ) ) != 1  #previously: # if length(unique(map( x -> length(x) , arrCmdLineIdxs ))) != 1
    SUPPRESS_WARNINGS ? num_suppressed[1] += 1 : warn("(in ExpandVarsInListFiles) detected different numbers of command lines (non-comment non-blank) in input files:");
    for file in filePathsFvars
      println("number of command lines: ", length(dictCmdLineIdxs[file]), ", in file: ", filePathsFvars[file])
    end
  end
  ## Warn if indicies of command rows differ between files
  if length(unique(values(dictCmdLineIdxs))) != 1 #previously: # if length(unique(arrCmdLineIdxs)) != 1
    SUPPRESS_WARNINGS ? num_suppressed[1] += 1 : warn("(in ExpandVarsInListFiles) detected different indices of command lines (non-comment non-blank) in input files:");
    for idx = 1:length(filePathsFvars)
      println("Index of command lines: ", dictCmdLineIdxs[idx], ", in file: ", filePathsFvars[idx])
    end
  end
  return dictListArr, dictCmdLineIdxs
end

# Expand varaibles in .protocol using values from .fvars.  This necessarily results in one output summary file per list entry (list files indicated in .fvars)
function protocol_to_array(arrProt, cmdRowsProt, namesFvars, infileColumnsFvars, filePathsFvars, dictListArr, dictCmdLineIdxs ; verbose = false, adapt_quotation=false)
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
      fvarValue = columnfrom_arrayofarrays(listArr, cmdLineIdxs, fvarColumnInListFile)[iln]; # This particular value of the Fvar
      valuesFvars[ivar] = fvarValue;
    end
    ## Create a new summary file array for the current list row (across all list files)
    arrExpFvars = expand_inarrayofarrays(arrProt, cmdRowsProt, namesFvars, valuesFvars ; verbose = verbose, adapt_quotation=adapt_quotation )
    push!(arrArrExpFvars, arrExpFvars)
  end
  return arrArrExpFvars
end


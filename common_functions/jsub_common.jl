## This file contains the julia functions used throughout the jsub utility.

function get_timestamp_(theTime)
  if theTime == nothing
    theTime = now();
    return string( 
      Dates.year(theTime), 
      dec(Dates.month(theTime), 2), 
      dec(Dates.day(theTime), 2), 
      "_",
      dec(Dates.hour(theTime), 2),
      dec(Dates.minute(theTime), 2),
      dec(Dates.second(theTime), 2)
    )
  else
    return theTime
  end
end

function iscomment(wline, comStr) # Check if input string starts with the comment sub-string after any leading whitespace
  line = lstrip(wline);
  if length(line) >= length(comStr)
    line[1:length(comStr)] == comStr ? (return true) : (return false)
  else
    return false
  end
end

function isblank(wline) # Check if line is blank
  lstrip(wline) == "" ? true : false
end

# Remove the begining of a string if it matches another string
function remove_prefix(long, prefix)
  startswith(long, prefix) ? (return long[length(prefix)+1:end]) : (return long);
end

# Remove the end from a string if it matches another string
function remove_suffix(long, suffix)
  endswith(long, suffix) ? (return long[1:end - length(suffix)]) : (return long);
end

# # Identify rows that begin with a tag indicating instructions for jsub.  The values in these rows should be expanded even if they begin with a comment.
# function get_tag_rowindices(tagsExpand)
#   return []
# end

function file2arrayofarrays_(fpath, comStr; cols=0::Integer, delimiter=nothing, verbose=false, tagsExpand=nothing)
  if verbose
    println("Reading file: ", fpath)
    cols==0 ? println("into '", delimiter, "' delimited columns") : println("into ", cols, " '", delimiter, "' delimited columns");
  end
  #println("delimiter: ", delimiter)
  arrRaw = split(readall(fpath), '\n'); # Read the input file
  commandRows = []; # row numbers of non-comment non-blank rows
  ## Initialise output array
  listOut = Array(Array{UTF8String}, 0); # Insisting of UTF8String here to avoid conversion problems later (MethodError: `convert` has no method matching convert(::Type{SubString{ASCIIString}}, ::UTF8String))  #arrOut = Array(AbstractString, size(arrRaw)[1], numCols); 
  iNonBlank = 0; 
  for wline in arrRaw
    if isblank(wline) == false
      iNonBlank += 1;
      if iscomment(wline, comStr)
        push!(listOut, [wline])
        # Supplement command rows vector with rows that begin with a comment-tag instruction to jsub (e.g. #JSUB etc...)
        if tagsExpand != nothing
          if any(x -> iscomment(wline, x), values(tagsExpand) ) # Check if the line begins with any of the tags that would indicate that its contents should be expanded
            push!(commandRows, iNonBlank); # Index non-blank non-comment lines
          end
        end
      else
        push!(commandRows, iNonBlank); # Index non-blank non-comment lines
        # Parse non-blank non-comment line data
        line = lstrip(wline); #print(line, "\n\n");
        # Check delimiter and split line
        arrLine = Array(ASCIIString, 0);
        if delimiter == nothing
          arrLine = split(line, dlmWhitespace; limit=cols, keep=false);
          # if cols != 0;
          #   warn("In function file2arrayofarrays_ cols=", cols, " but delimiter=", delimiter, ". Using default split(::ASCIIString) method which splits by whitespace so the number of output columns may not correspond to the cols option.")
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
  arrOut = deepcopy(arrArr) # Initialize output array
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
    arrOut[jdx] = deepcopy(arrSplitSingle[jdx])
  end
  return join(arrOut)
end

## Function for reading every list file given in .fvars and extracting arrays of variable values
# function ValuesFromLists (fpath, column) # Read a 'list' file and extract values from a selected column
#   arrArr, cmdRows = file2arrayofarrays_(fileList; cols=0, delimiter = nothing)
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
function parse_varsfile_(fileVars; dlmVars=nothing, tagsExpand=nothing)
  arrVars, cmdRowsVars = file2arrayofarrays_(fileVars, comStr; cols=2, delimiter=dlmVars, tagsExpand=tagsExpand);
  namesVars = columnfrom_arrayofarrays(arrVars, cmdRowsVars, 1);
  valuesVars = columnfrom_arrayofarrays(arrVars, cmdRowsVars, 2);
  return namesVars, valuesVars # This can subsequently be expanded row by row using the expandinorder function.
end

# Read the .fvars file and expand variables row by row.
function parse_expandvars_fvarsfile_(fileFvars, namesVars, valuesVars; dlmFvars=nothing, adapt_quotation=false, verbose=false, tagsExpand=nothing) # Read the .fvars file 
  arrFvars, cmdRowsFvars = file2arrayofarrays_(fileFvars, comStr; cols=3, delimiter=dlmFvars, tagsExpand=tagsExpand);
  ## Use variables from .vars to expand values in .fvars
  arrExpFvars = expand_inarrayofarrays(arrFvars, cmdRowsFvars, namesVars, valuesVars; verbose = verbose, adapt_quotation=adapt_quotation);
  # Extract arrays of variable names and variable values
  namesFvars = columnfrom_arrayofarrays(arrExpFvars, cmdRowsFvars, 1);
  infileColumnsFvars = columnfrom_arrayofarrays(arrExpFvars, cmdRowsFvars, 2);

  # Get sanitized paths from strings in the third column of the .fvars file
  # Note that this is done after expanding any variables (from .vars) contained in the file paths.
  filePathsFvars = map(sanitizepath, columnfrom_arrayofarrays(arrExpFvars, cmdRowsFvars, 3));

  return namesFvars, infileColumnsFvars, filePathsFvars
end

function parse_expandvars_protocol_(fileProtocol, namesVars, valuesVars; adapt_quotation=false, verbose=false, tagsExpand=nothing)
  arrProt, cmdRowsProt = file2arrayofarrays_(fileProtocol, comStr; cols=1, delimiter=nothing, tagsExpand=tagsExpand);
  ## Use variables from .vars to expand values in .protocol
  arrProtExpVars = expand_inarrayofarrays(arrProt, cmdRowsProt, namesVars, valuesVars ; verbose = verbose, adapt_quotation=adapt_quotation)
  return arrProtExpVars, cmdRowsProt
end

# Expand variables in .fvars file using values from list files
function parse_expandvars_listfiles_(filePathsFvars, namesVars, valuesVars, dlmFvars; verbose=false, adapt_quotation=false, tagsExpand=nothing)
  ## Read each list file
  dictListArr = Dict(); # Dictionary with file paths as keys and file contents (arrays of arrays) as values.
  dictCmdLineIdxs = Dict(); #previously: # arrCmdLineIdxs = Array(Array, length(filePathsFvars) ); # Array for storing line counts from input files
  idx=0;
  for file in filePathsFvars
    idx+=1;
    arrList, cmdRowsList = file2arrayofarrays_(file, comStr; cols=0, delimiter=dlmFvars, tagsExpand=tagsExpand);
    arrListExpVars = expand_inarrayofarrays(arrList, cmdRowsList, namesVars, valuesVars ; verbose = verbose, adapt_quotation=adapt_quotation);
    dictListArr[file] = deepcopy(arrListExpVars);
    dictCmdLineIdxs[file] = cmdRowsList; #previously: # arrCmdLineIdxs[idx] = cmdRowsList
  end
  ## Warn if number of command row numbers differ between files
  if length( unique( map( x->length(x),  values(dictCmdLineIdxs) ) ) ) != 1  #previously: # if length(unique(map( x -> length(x) , arrCmdLineIdxs ))) != 1
    if !SUPPRESS_WARNINGS 
      warn("(in parse_expandvars_listfiles_) detected different numbers of command lines (non-comment non-blank) in input files:");
      for file in filePathsFvars
        println("number of command lines: ", length(dictCmdLineIdxs[file]), ", in file: ", filePathsFvars[file])
      end
    else
      num_suppressed[1] += 1;
    end
  end
  ## Warn if numbers of uniqe indicies of command rows differ between files
  if length(unique(values(dictCmdLineIdxs))) != 1 #previously: # if length(unique(arrCmdLineIdxs)) != 1
    if !SUPPRESS_WARNINGS  
      warn("(in parse_expandvars_listfiles_) detected different indices of command lines (non-comment non-blank) in input files:");
      for idx = 1:length(filePathsFvars)
        println("Index of command lines: ", dictCmdLineIdxs[idx], ", in file: ", filePathsFvars[idx])
      end
    else
      num_suppressed[1] += 1;
    end
  end
  return dictListArr, dictCmdLineIdxs
end

# Expand varaibles in .protocol using values from .fvars.  This necessarily results in one output summary file per list entry (list files indicated in .fvars)
function protocol_to_array(arrProt, cmdRowsProt, namesFvars, infileColumnsFvars, filePathsFvars, dictListArr, dictCmdLineIdxs ; verbose=false, adapt_quotation=false)
  arrArrExpFvars = []; ## Initialise array for holding summary file data in the form of an arrays-of-arrays
  ## Loop over length of list files (currently assuming that all lists are of the same length but this may need to change in the future)
  for iln in 1:maximum( map(x->length(x), values(dictCmdLineIdxs)) )
    # Initialise array for holding values of each Fvar for the current list row (across all list files)
    valuesFvars = Array(AbstractString, size(namesFvars));
    ## Get the values of Fvars for the current list row
    for ivar in 1:length(namesFvars)
      ## Get Fvar value from corresponding row of its list file
      # .fvar variable name, column and list file.
      fvarName = namesFvars[ivar]; # Get variable name
      fvarColumnInListFile = parse(Int, infileColumnsFvars[ivar]); # Get column number
      fvarFile = filePathsFvars[ivar]; # Get the list file name associated with this Fvar
      listArr = dictListArr[fvarFile]; # array of arrays of the contents of the list file
      cmdLineIdxs = dictCmdLineIdxs[fvarFile]; # Rows in the list file which contain data as opposed to comments or being empty
      valuesFvars[ivar] = columnfrom_arrayofarrays(listArr, cmdLineIdxs, fvarColumnInListFile)[iln]; # This particular value of the Fvar
    end
    ## Create a new summary file array for the current list row (across all list files)
    if verbose
      println("Expanding variables using values from row ", iln, " of list files.")
      println("arrProt = ", arrProt)
      println("namesFvars = ", namesFvars);
      println("valuesFvars = ", valuesFvars);
    end
    push!(arrArrExpFvars, expand_inarrayofarrays(arrProt, cmdRowsProt, namesFvars, valuesFvars; verbose=verbose, adapt_quotation=adapt_quotation ))
  end
  return arrArrExpFvars
end

# Use input protocol, vars and fvars file names to generate a long name string to be used as part of the output summary and job file names.
function get_longname(pathProtocol, pathVars, pathFvars; keepSuffix=false)
  keepSuffix ? baseProtocol = basename(pathProtocol) : baseProtocol = remove_suffix(basename(pathProtocol), ".protocol");
  keepSuffix ? baseVars = basename(pathVars) : baseVars = remove_suffix(basename(pathVars), ".vars");
  keepSuffix ? baseFvars = basename(pathFvars) : baseFvars = remove_suffix(basename(pathFvars), ".fvars");
  (length(baseProtocol) > 0 && length(baseVars * baseFvars) > 0) ? dlm1 = "_" : dlm1 = "";
  (length(baseProtocol * baseVars) > 0 && length(baseFvars) > 0) ? dlm2 = "_" : dlm2 = "";
  out = string(
    baseProtocol,
    dlm1,
    baseVars,
    dlm2,
    baseFvars
  )
  if out == ""
    out = string(hash(pathProtocol*pathVars*pathFvars));
    if out == ""
      error(string("Unable to generate name string from the following variables:\n", pathProtocol, "\n", pathVars, "\n", pathFvars))
    end
  end
  return out
end

# Get summary file names by reading protocol file arrays and looking for the first instance of a tag or simply numbering them
function get_summary_names(arrProt; prefix=nothing, suffix=".summary", timestamp="", tag="#JSUB<summary-name>", allowNonUnique=false, longName=nothing)
  if prefix == nothing
    prefix = "";
  end
  summaryNames = [];
  lenTag = length(tag);
  idx = 0;
  for arr in arrProt
    idx += 1; # println("\n\nidx = ", idx, "  arr = ", arr, "\n")
    foundName = false;
    for subarr in arr
      line = lstrip(join(subarr));
      if iscomment(line, tag)
        push!(summaryNames, string(prefix, lstrip(line[lenTag+1:end]), suffix)); # Use name from file
        foundName = true;
        break        
      end
    end
    if !foundName
      length(timestamp) > 0 ? delim = "_" : delim = "";
      if longName == nothing
        push!(summaryNames, string(prefix, "summary", dec(idx, 4), delim, timestamp, suffix)); # Use default name
      else
        push!(summaryNames, string(prefix, longName, "_", dec(idx, 4), delim, timestamp, suffix)); # Use longName
      end
    end
  end
  # Check to make sure unique job names are returned (unless the allowNonUnique option is set to true)
  if !allowNonUnique && length(summaryNames) != length(unique(summaryNames))
    error(" (in get_summary_names) output list of summary file names contains non-unique entries.")
  else
    return summaryNames
  end
end

# # Get job file names
# function get_jobfile_name(summaryName, group; summaryFileExtension=".summary")
#   baseName = remove_suffix(basename(summaryName), summaryFileExtension); # Remove the .summary file extension
#   length(group) > 0 ? dlm = "_" : dlm = "";
#   return string(baseName, dlm, group)
# end

# Write summary files
function create_summary_files_(arrArrExpFvars, summaryPaths; verbose=false, createDirectory=true)
  outputPaths = []; # list of paths of the summary files created
  ## Check that number of elements in array matches number of file paths
  if length(arrArrExpFvars) != length(summaryPaths)
    SUPPRESS_WARNINGS ? num_suppressed[1] += 1 : warn("(in create_summary_files_) number of elements in data array (", length(arrArrExpFvars), ") does not match number of file paths provided (", length(summaryPaths), "). Excess data will not be written to files." );
  end
  ## Check that summary file names are unique
  if length(unique(summaryPaths)) != length(summaryPaths)
    SUPPRESS_WARNINGS ? num_suppressed[1] += 1 : warn("(in create_summary_files_) number of unique summary file paths (", length(unique(summaryPaths)), ") does not match total number of file paths provided (", length(summaryPaths), ")." );
  end
  ## Write lines to files
  ipath = 0;
  for file in summaryPaths
    ipath += 1;
    if verbose
      println("Writing to summary file: ", file);
    end
    createDirectory && mkpath(dirname(file));
    stream = open(file, "w");
    arrExpFvars = arrArrExpFvars[ipath];
    for subarr in arrExpFvars
      write(stream, string(join(subarr), "\n"));
    end
    push!(outputPaths, file);
    close(stream);
  end
  return outputPaths
end

# Split summary file array into arrays (stored in a dictionary) from which job files will be created.
function split_summary(summary; tagSplit="#JGROUP", root="root")
  jobs = Dict();
  current = [];
  group = root;
  tagLength = length(tagSplit);
  ## Split array of lines into dictionary of groups
  for arrLine in summary
    line = lstrip(join(arrLine));
    if iscomment(line, tagSplit)  # Determine if line begins with tagSplit string
      jobs[group] = current; # Add existing group to dict
      current = []; # Clear current group array
      group = split(line[tagLength+1:end])[1] # Determine group name
    end
    push!(current, arrLine)
  end
  jobs[group] = current; # Add existing group to dict
  return jobs
end

## Creates strings of the form 'done("jobID1")&&done("jobID2")'' (this should probably be refactored to be part of cmd_await_jobs)
function construct_conditions(arrNames; condition="done", operator="&&")
  lenArray = length(arrNames);
  if lenArray == 0
    return ""
  else
    out = string("\'", condition, "(\"", arrNames[1], "\")" );
    if lenArray > 1
      for idx = 2:lenArray
        out = string(out, operator, condition, "(\"", arrNames[idx], "\")");
      end
    end
    return string(out, "\'")
  end
end

# Return a job ID with a date or generate a hash from the jobArray
function jobID_or_hash(jobArray; jobID=nothing, jobDate="")
  if jobDate == nothing
    jobDate = "";
  end
  if jobID == nothing
    length(jobDate) > 0 ? delim = "_" : delim = "";
    jobID = string(jobDate, delim, hash(jobArray));
  else
    (length(jobDate) > 0) && (length(jobID) > 0) ? delim = "_" : delim = "";
    jobID = string(jobDate, delim, jobID);
  end
  return jobID
end

# Determine parent jobs which must be completed first
function cmd_await_jobs(jobArray; root="root", tagHeader="\n#BSUB", option="-w", condition="done", tagSplit="#JGROUP", jobID=nothing, jobDate=nothing)
  jobDate = get_timestamp_(jobDate);
  jobID = jobID_or_hash(jobArray; jobID=jobID); # Generate unique-ish job ID if one is not provided
  # Check if the first entry in the job array begins with a group tag (tagSplit) and use this tag to identify parent jobs
  if iscomment(join(jobArray[1]), tagSplit)
    groupString = lstrip(join(jobArray[1]));
    groupName = "";
    groupParents = [];
    if length(groupString) > length(tagSplit)
      afterTag = split(groupString);
      if length(afterTag) > 1
        length(afterTag) > 2 ? groupNames = [root; afterTag[3:end]] : groupNames = [root]
        length(jobID) > 0 ? delim = "_" : delim = "";
        groupParents = map( (x) -> string(jobID, delim, x), groupNames); # Note that a root job is always added
      end
    end
    return string(tagHeader, " ", option, " ", construct_conditions(groupParents; condition=condition))
  else
    return ""
  end
end

# Retrives the group name associated with this job (this not the job ID), assuming that the jobArray is a list of commands with the first entry being of the form "#JGROUP groupName ..."
function get_groupname(jobArray; tagSplit="#JGROUP")
  # Get group name
  groupName = "";
  if iscomment(join(jobArray[1]), tagSplit)
    afterTag = split(lstrip(join(jobArray[1])));
    if length(afterTag) > 1
      groupName = string(afterTag[2]);
    else
      throw("Found a group/split tag without an associated group name", " on line: ", join(jobArray[1]));
    end
  end
  return groupName
end

## Use summary file name and array of job instructions to get a file name for each job.
function generate_jobfilepath(summaryName, jobArray; tagSplit="#JGROUP", prefix="", suffix=".lsf")
  groupName = get_groupname(jobArray, tagSplit=tagSplit);
  if summaryName != nothing
    return string(prefix, summaryName, "_", groupName, suffix)
  else
    return string(prefix, hash(jobArray), "_", groupName, suffix)
  end
end

# Read job dictionary and return job header
function create_job_header_string(jobArray; root="root", tagHeader="\n#BSUB", prefix="#!/bin/bash\n", suffix="", tagSplit="#JGROUP", jobID=nothing, jobDate=nothing, appendOptions=true, rootSleepSeconds=nothing)
  # arrHeaderRows = jobArray[find((x)->iscomment(join(x), tagHeader), jobArray)] # Extract header rows from among command rows
  jobID = jobID_or_hash(jobArray; jobID=jobID, jobDate=jobDate);
  groupName = get_groupname(jobArray, tagSplit=tagSplit);
  length(groupName) > 0 ? idDelim = "_" : idDelim = "";
  # Generate options strings
  options = "";
  if appendOptions
    ## Determine group ID (first entry after group tag (e.g #JGROUP groupID otherGroupID ...))
    options = string(tagHeader, " -J $jobID", idDelim, groupName, tagHeader, " -e $jobID", idDelim, groupName, ".error", tagHeader, " -o $jobID", idDelim, groupName, ".output", "\n");
  end
  # If this is a root job, add a wait (sleep) command to give enough time for jobs which depend on this one to be submitted.  This may not be strictly necessary or may need to be made more robust depending on how LSF actually handles these things and the response times of the system in question.
  waitInstructions = "";
  if rootSleepSeconds != nothing && groupName == ""
    waitInstructions = string("\nsleep ", rootSleepSeconds, "\n");
  end
  return string(
    prefix,
    # join( map( x -> join(x), arrHeaderRows), '\n'), 
    # '\n',
    cmd_await_jobs(jobArray, root=root, tagHeader=tagHeader, tagSplit=tagSplit, jobID=jobID, jobDate=jobDate),
    options,
    waitInstructions,
    suffix 
  );
end

# Identify checkpoints so that only the functions that are actually used may be appended
function identify_checkpoints(jobArray, checkpointsDict; tagCheckpoint="jcheck_")
  out = Dict();
  arrCheckpointRows = jobArray[find((x)->iscomment(join(x), tagCheckpoint), jobArray)]; # Get rows starting with tagCheckpoint
  arrCheckpointFunctions = unique(map((x)->(split(join(x))[1]), arrCheckpointRows)); # Get the checkpoint function from each of those rows
  allNames = keys(checkpointsDict);
  for name in arrCheckpointFunctions
    if name in allNames
      out[name] = checkpointsDict[name];
    else
      SUPPRESS_WARNINGS ? num_suppressed[1] += 1 : warn("(in identify_checkpoints) function named \"", name, "\" not found in the dictionary that maps bash function names to file paths where they are stored.");
    end
  end
  return out
end

# Read bash functions from files into Dict
function get_bash_functions(common_functions::Dict, selected_functions::Dict)
  all = merge(common_functions, selected_functions); # merge into one dict
  out = Dict();
  for (key, val) in all # read functions from files
    out[val] = readall(val);
  end
  return out # return dict of {function names => function strings}
end

## Create job file from array of instructions and a dictionary of functions
# Use file2arrayofarrays_(x, "#", cols=1) to read summary file
function create_job_file_(outFilePath, jobArray, functionsDictionary::Dict; summaryFileOfOrigin="", root="root", tagBegin="#JSUB<begin-job>", tagFinish="#JSUB<finish-job>", tagHeader="\n#BSUB", tagCheckpoint="jcheck_", headerPrefix="#!/bin/bash\n" , headerSuffix="", summaryFile="", jobID=nothing, jobDate=nothing, appendOptions=true, rootSleepSeconds=nothing, verbose=false)
  # Check if jobArray is empty
  if jobArray == []
    SUPPRESS_WARNINGS ? num_suppressed[1] += 1 : warn("(in create_job_file_) Array of job contents is empty, no job file created.");
  else
    # Overwrite with header
    if (verbose) 
      println("Writing to job file: ", outFilePath);
    end
    stream = open(outFilePath, "w");
    write(stream, create_job_header_string(jobArray; root=root, tagHeader=tagHeader, prefix=headerPrefix, suffix=headerSuffix, jobID=jobID, jobDate=jobDate, appendOptions=appendOptions, rootSleepSeconds=rootSleepSeconds));
    # Append tag variables
    write(stream, "\n# Tag variables\n");
    # Append common functions
    write(stream, "\n\n# Contents inserted from other files (this section is intended to be used only for functions):\n");
    for key in sort(collect(keys(functionsDictionary)))
      write(stream, string("\n# --- From file: ", key, "\n") );
      write(stream, string(functionsDictionary[key]));
    end
    # Append commands
    write(stream, "\n\n# Commands taken from summary file: $summaryFileOfOrigin\n");
    write(stream, string("\n", tagBegin, "\n"));
    map((x) -> write(stream, join(x), '\n'), jobArray);
    write(stream, string("\n", tagFinish, "\n"));
    close(stream)
  end
end

## Create all the job files associated with a particular summary file (Note that using the option filePathOverride means input to the jobFilePrefix and jobFileSuffix options will be ignored)
function create_jobs_from_summary_(summaryFilePath, dictSummaries::Dict, commonFunctions::Dict, checkpointsDict::Dict; jobFilePrefix="", filePathOverride=nothing, root="root", jobFileSuffix=".lsf",
    tagBegin="#JSUB<begin-job>", tagFinish="#JSUB<finish-job>", tagHeader="\n#BSUB", tagCheckpoint="jcheck_", headerPrefix="#!/bin/bash\n", headerSuffix="", summaryFile="", jobID=nothing, jobDate=nothing, appendOptions=true, rootSleepSeconds=nothing, verbose=false
  )
  arrJobFilePaths = [];
  ## For each group in the summary file create a job file
  for (idx, pair) in enumerate(dictSummaries)
    group = pair[1];
    if length(dictSummaries) == 1 
      group = ""; # If there is only one job file produced from this summary, there is no need to append the root group name to the file name
      rootSleepSeconds=nothing; # No need to add a sleep command since there will be no submitted jobs that are dependent on this one existing.
    end
    jobArray = pair[2];
    dictCheckpoints = get_bash_functions(
      commonFunctions,
      identify_checkpoints(jobArray, checkpointsDict; tagCheckpoint=tagCheckpoint) ## Extract the checkpoints/bash functions needed for each job file
    );
    ## Get job file name from path and group
    outFilePath = "";
    if filePathOverride != nothing
      outFilePath = filePathOverride;
    else
      (length(group) > 0) ? (group = "_" * group) : (group = ""); # # (length(group) > 0 && group != root) ? (group = "_" * group) : (group = ""); # job file specific suffix
      outFilePath = string(jobFilePrefix, basename(remove_suffix(summaryFilePath, ".summary")), group, jobFileSuffix); # get longName from file path
    end
    ## Check for conflicting -J options
    if detect_option_conflicts(jobArray; tag=remove_prefix(tagHeader, "\n"), option="-J")
      SUPPRESS_WARNINGS ? num_suppressed[1] += 1 : warn("(in create_jobs_from_summary_) found conflicting instances of #BSUB -J in the following array of commands:\n", jobArray);
    end
    ## Create job file
    push!(arrJobFilePaths, outFilePath)
    create_job_file_(outFilePath, jobArray, dictCheckpoints; summaryFileOfOrigin=summaryFilePath, root=root,
      tagBegin=tagBegin, tagFinish=tagFinish, tagHeader=tagHeader, tagCheckpoint=tagCheckpoint, headerPrefix=headerPrefix, headerSuffix=headerSuffix, summaryFile=summaryFile, jobID=jobID, jobDate=jobDate, appendOptions=appendOptions, rootSleepSeconds=rootSleepSeconds, verbose=verbose
    );
  end
  ## Check that summary file names are unique
  if length(unique(arrJobFilePaths)) != length(arrJobFilePaths)
    SUPPRESS_WARNINGS ? num_suppressed[1] += 1 : warn("(in create_jobs_from_summary_) number of unique job file paths (", length(unique(arrJobFilePaths)), ") does not match total number of file paths generated (", length(arrJobFilePaths), ")." );
  end
  return arrJobFilePaths
end

## Check if a #BSUB option appears more than once in the job array.
function detect_option_conflicts(jobArray; tag="#BSUB", option="-J")
  matchIndices = [];
  matchValues = [];
  idx = 0;
  for line in jobArray
    idx += 1;
    words = split(join(line))
    # Split string of the form "tag option value" and check if values differ
    if length(words) >= 3 && words[1] == tag && words[2] == option
      push!(matchIndices, idx)
      push!(matchValues, words[3])
    end
  end
  length(unique(matchValues)) > 1 ? (return true) : (return false);
end

## Map the states of the -s -j -b (summaries, jobs and submit) flags to the required steps
function map_flags_sjb(flagSummaries, flagJobs, flagSubmit)
  flags = string(1*flagSummaries, 1*flagJobs, 1*flagSubmit);
  mapping = Dict(
    "000" => "111",
    "100" => "100",
    "010" => "010",
    "001" => "001",
    "101" => "111",
    "111" => "111",
    "011" => "011",
    "110" => "110",
  );
  return mapping[flags]
end

## Extract file path from arguments
function get_argument(dictArguments::Dict, option; verbose=false, optional=false, path=false)
  if !optional && (dictArguments[option] == false || dictArguments[option] == nothing)
    error("Please supply an argument to the \"--", option, "\" option.");
  else
    verbose && println(string("Parsed argument to --", option, ": ", dictArguments[option]));
    if path && (dictArguments[option] == false || dictArguments[option] == nothing)
      return ""
    else
      return dictArguments[option]
    end
  end
end




# EOF






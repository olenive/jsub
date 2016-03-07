# Run a basic test on functions from jsub_common.jl

## FUNCTIONS ##

function IsMatchOrWarn( first, second )
  if first == second
    println("pass")
    return true
  else
    println("Detected mismatch between the two tuples:")
    println(first)
    println(second)
    return false
  end
end

function DetectedFail()
  #println("Detected a fail");
  global FLAG_TEST_FAIL = true;
end

###############

### MACROS ###
macro call_and_compare( funCall, expected )
  println("Test function call: ", funCall)
  output = :($funCall)
  msgPass = string("PASS: output matches expected for function call: $funCall");
  msgFail = string("FAIL: output does not match expected for function call: $funCall");
  return quote
    #:($output == $expected ? println($msgPass) : println($msgFail))
    #$output == $expected ? println("output is:\n", $output, "\n", $msgPass) : println("output is:\n", $output, "\nbut the expected output is: \n", $expected,  $msgFail)
    if $output == $expected
      println("expected output is:\n", $expected, "\nactual output is: \n", $output, "\n", $msgPass) 
    else
      println("expected output is:\n", $expected, "\nbut the actual output is: \n", $output, "\n", $msgFail)
      DetectedFail();
    end
  end
end


##############

## Hard coded variables
# First non-whitespace string indicating the start of a comment line
const comStr="#" # Note: this is expected to be a string ("#") rather than a character ('#').  Changing the string (char) used to indicate comments may cause problems further down the line.
# const dlmVars='\t' # Column delimiter for files containing variables
# const dlmProtocol=' ' # Column delimiter for the protocol file
const dlmWhitespace=[' ','\t','\n','\v','\f','\r'] # The default whitespace characters used by split
const flagWarn = true;
const delimiterFvars = '\t'
const verbose = false;

# Initialise flags
global FLAG_TEST_FAIL = false

# Load functions from file
include("../../common_functions/jsub_common.jl")

# Load test files
pathToTestProtocol = "jlang_function_test_files/refs_samples.protocol"
pathToTestVars = "jlang_function_test_files/refs_samples.vars"
pathToTestFvars = "jlang_function_test_files/refs_samples.fvars"


########################################
######## Run tests on functions ########
########################################
### For each function, declare input argument and expected output, then run the function and check that the outcome matches what is expected.

## IsComment
@call_and_compare IsComment("  \t  \# # This line is a comment", comStr) true
@call_and_compare IsComment("  \t  \# This line is still a comment", comStr) true
@call_and_compare IsComment("  \t  not a comment", comStr) false
@call_and_compare IsComment("really not a comment", comStr) false

## IsBlank
@call_and_compare IsBlank("") true
@call_and_compare IsBlank(" ") true
@call_and_compare IsBlank("	") true
@call_and_compare IsBlank("			 ") true
@call_and_compare IsBlank("asdf b c #") false
@call_and_compare IsBlank(" b c d") false
@call_and_compare IsBlank(" \"") false
@call_and_compare IsBlank("			'#") false

## ReadFileIntoArrayOfArrays
# Create expected array to compare against
# File looks like:
# ************************************************************************
# This file contains the common variables in using refs_samples.protocol

# DIR_BASE        "/Users/olenive/work/jsub_pipeliner"
# DIR_OUTPUT      "/Users/olenive/work/output_testing_jsub"

# PRE_REF_FILE1   "$DIR_BASE"/"unit_tests/data/header_coordinate"
# PRE_REF_FILE2   "$DIR_BASE"/"unit_tests/data/hg19.chrom.sizes"

# REF_FILE        "$DIR_OUTPUT"/"utSplit_refFile.txt"
# SAMPLE_OUTPUT_1 "$DIR_OUTPUT"/"utSplit_out1_"

# VAR1    "_valueVar1_"
# # VAR2  "_valueVar2_"

# # In the next line "$VAR1" is replaced by "_valueVar1_" but only in the second column.
# VAR$VAR1        "_valueVar$VAR1_"

# # In the next line "$VAR2" is replaced by nothing because VAR2 is commented out above
# VAR$VAR2        "_valueVar$VAR2_"

# ************************************************************************
expCmdRowsVars = [2,3,4,5,6,7,8,11,13] # Rows in expArrVars that contain commands and not comments
expArrVars = []#Array(Array{AbstractString} (7,))
push!(expArrVars, ["# This file contains the common variables in using refs_samples.protocol"])
push!(expArrVars, ["DIR_BASE", "\"/Users/olenive/work/jsub_pipeliner\""])
push!(expArrVars, ["DIR_OUTPUT", "\"/Users/olenive/work/output_testing_jsub\""])
push!(expArrVars, ["PRE_REF_FILE1", "\"\$DIR_BASE\"/\"unit_tests/data/header_coordinate\""])
push!(expArrVars, ["PRE_REF_FILE2", "\"\$DIR_BASE\"/\"unit_tests/data/hg19.chrom.sizes\""])
push!(expArrVars, ["REF_FILE", "\"\$DIR_OUTPUT\"/\"utSplit_refFile.txt\""])
push!(expArrVars, ["SAMPLE_OUTPUT_1", "\"\$DIR_OUTPUT\"/\"utSplit_out1_\""])
push!(expArrVars, ["VAR1", "\"_valueVar1_\""])
push!(expArrVars, ["# VAR2\t\"_valueVar2_\""])
# Note that the replacement mentioned in the text in the array below occurs at a later step (here we are just reading the file)
push!(expArrVars, ["# In the next line \"\$VAR1\" is replaced by \"_valueVar1_\" but only in the second column."])
push!(expArrVars, ["VAR\$VAR1", "\"_valueVar\$VAR1_\""])
push!(expArrVars, ["# In the next line \"\$VAR2\" is replaced by nothing because VAR2 is commented out above"])
push!(expArrVars, ["VAR\$VAR2", "\"_valueVar\$VAR2_\""])

@call_and_compare ReadFileIntoArrayOfArrays(pathToTestVars, "#") (expArrVars, expCmdRowsVars)

# ************************************************************************
# # This file contains the names of varibales, column numbers and source file paths from which the value of the variable should be taken.
# # <variable name> <column in file>  <file path>
# LANE_NUM  0 "$DIR_BASE"/"unit_tests/lists/multiLane_"'"1"'"col.txt"
# # The zero in the <column in file> field indicates that all columns shold be used (or treated as one column)
# SAMPLEID  1 "$DIR_BASE"/"unit_tests/lists/sampleIDs_1col.txt"

# # The value of DIR_BASE is declared in refs_samples.vars


# ************************************************************************
expCmdRowsFvars = [3,5]
expArrFvars = []
push!(expArrFvars, ["# This file contains the names of varibales, column numbers and source file paths from which the value of the variable should be taken."])
push!(expArrFvars, ["# <variable name>	<column in file>	<file path>"])
push!(expArrFvars, ["LANE_NUM", "0", "\"\$DIR_BASE\"/\"unit_tests/lists/multiLane_\"\'\"1\"\'\"col.txt\""])
push!(expArrFvars, ["# The zero in the <column in file> field indicates that all columns shold be used (or treated as one column)"])
push!(expArrFvars, ["SAMPLEID", "1", "\"\$DIR_BASE\"/\"unit_tests/lists/sampleIDs_1col.txt\""])
push!(expArrFvars, ["# The value of DIR_BASE is declared in refs_samples.vars"])

@call_and_compare ReadFileIntoArrayOfArrays(pathToTestFvars, "#") (expArrFvars, expCmdRowsFvars)


## SanitizeVariableNameOrValue
@call_and_compare SanitizeVariableNameOrValue("	  test string with a tab	here	 ") "test string with a tab\there"

## ExtractColumnFromArrayOfArrays
@call_and_compare ExtractColumnFromArrayOfArrays(expArrFvars, expCmdRowsFvars, 2; dlm=' ') ["0", "1"]
@call_and_compare ExtractColumnFromArrayOfArrays(expArrFvars, expCmdRowsFvars, 0; dlm=' ') [string("LANE_NUM",' ',"0",' ',"\"\$DIR_BASE\"/\"unit_tests/lists/multiLane_\"\'\"1\"\'\"col.txt\""), string("SAMPLEID",' ',"1",' ',"\"\$DIR_BASE\"/\"unit_tests/lists/sampleIDs_1col.txt\"")]

## WarnOfNonReplacedSubstrings
# WarnOfNonReplacedSubstrings("this include sub-string.", "sub-string")

## ExpandOneVariableAtDollars
testString = "start in\$VAR string \"\${VAR}\"/unit_tests/ foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"\"\$VAR\"\".txt\""
expString  = "start in!!! string \"!!!\"/unit_tests/ foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"!!!\".txt\""
@call_and_compare ExpandOneVariableAtDollars(testString, "VAR", "!!!") expString

## ExpandManyVariablesAtDollars
testString = "start in\$VAR0 string \"\${VAR1}\"/unit_tests/ foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"\"\$VAR2\"\".txt\""
expString  = "start in000 string \"!!!1\"/unit_tests/ foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"!!!2\".txt\""
@call_and_compare ExpandManyVariablesAtDollars(testString, ["VAR0", "VAR1", "VAR2"], ["000", "!!!1", "!!!2"]) expString

## ExpandVariablesInArrayOfArrays
testArr = []
push!(testArr, ["# first comment string \${VAR}, \$VAR1 \"\"\$VAR2\""])
push!(testArr, [testString])
push!(testArr, ["# second comment string  \${VAR}, \$VAR1 \"\"\$VAR2\""])
push!(testArr, [testString])
push!(testArr, ["# third comment string  \${VAR}, \$VAR1 \"\"\$VAR2\""])
expArr = []
push!(expArr, ["# first comment string \${VAR}, \$VAR1 \"\"\$VAR2\""])
push!(expArr, [expString])
push!(expArr, ["# second comment string  \${VAR}, \$VAR1 \"\"\$VAR2\""])
push!(expArr, [expString])
push!(expArr, ["# third comment string  \${VAR}, \$VAR1 \"\"\$VAR2\""])
@call_and_compare ExpandVariablesInArrayOfArrays(testArr, [2,4], ["VAR0", "VAR1", "VAR2"], ["000", "!!!1", "!!!2"]; verbose=true) expArr

## SanitizePath
testPath = "\"\$DIR_BASE\"/\"unit_tests/lists/multiLane_\"\'\"1\"\'\"col.txt\""
expPath = "\$DIR_BASE/unit_tests/lists/multiLane_\"1\"col.txt"
@call_and_compare SanitizePath(testPath)  expPath




# FAIL: output does not match expected for function call: ExpandOneVariableAtDollars(testString,"VAR","!!!")
# FAIL: output does not match expected for function call: ExpandManyVariablesAtDollars(testString,["VAR0","VAR1","VAR2"],["000","!!!1","!!!2"])
# FAIL: output does not match expected for function call: ExpandVariablesInArrayOfArrays(testArr,[2,4],["VAR0","VAR1","VAR2"],["000","!!!1","!!!2"]; verbose=true)



########################################

if FLAG_TEST_FAIL
  warn(" *** One or more unit tests failed in ut_jsub_common.jl ***")
end


# EOF










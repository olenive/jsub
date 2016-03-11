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
macro call_and_compare( funCall, expected ) # Note this macro actually makes to calls to the function, this should probably be fixed
  println("Test function call: ", funCall)
  #println("1")
  output = :($funCall)
  #println("2")
  msgPass = string("PASS: output matches expected for function call: $funCall");
  msgFail = string("FAIL: output does not match expected for function call: $funCall");
  return quote
    #:($output == $expected ? println($msgPass) : println($msgFail))
    #$output == $expected ? println("output is:\n", $output, "\n", $msgPass) : println("output is:\n", $output, "\nbut the expected output is: \n", $expected,  $msgFail)
    if $output == $expected
      #println("3.1")
      println("expected output is:\n", $expected, "\nactual output is: \n", $output, "\n", $msgPass) 
    else
      #println("3.2")
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

# ## IsCharacterVariableNameCompliant
# @call_and_compare IsCharacterVariableNameCompliant('a', "outside") false
# @call_and_compare IsCharacterVariableNameCompliant('a', "plain") true
# @call_and_compare IsCharacterVariableNameCompliant('1', "plain") true
# @call_and_compare IsCharacterVariableNameCompliant('_', "plain") true
# @call_and_compare IsCharacterVariableNameCompliant('$', "plain") false
# @call_and_compare IsCharacterVariableNameCompliant('{', "plain") false
# @call_and_compare IsCharacterVariableNameCompliant('}', "plain") false
# @call_and_compare IsCharacterVariableNameCompliant('a', "curly") true
# @call_and_compare IsCharacterVariableNameCompliant('1', "curly") true
# @call_and_compare IsCharacterVariableNameCompliant('_', "curly") true
# @call_and_compare IsCharacterVariableNameCompliant('$', "curly") false
# @call_and_compare IsCharacterVariableNameCompliant('{', "curly") false
# @call_and_compare IsCharacterVariableNameCompliant('}', "curly") true

## IsNextCharacterVariableNameCompliant
@call_and_compare IsNextCharacterVariableNameCompliant("123aA\$bB_x@~!\"{}?{#", 0) true
@call_and_compare IsNextCharacterVariableNameCompliant("123aA\$bB_x@~!\"{}?{#", 1) true
@call_and_compare IsNextCharacterVariableNameCompliant("123aA\$bB_x@~!\"{}?{#", 5) false
@call_and_compare IsNextCharacterVariableNameCompliant("123aA\$bB_x@~!\"{}?{#", 6) true
@call_and_compare IsNextCharacterVariableNameCompliant("123aA\$bB_x@~!\"{}?{#", 8) true
@call_and_compare IsNextCharacterVariableNameCompliant("123aA\$bB_x@~!\"{}?{#", 9) true
@call_and_compare IsNextCharacterVariableNameCompliant("123aA\$bB_x@~!\"{}?{#", 11) false
@call_and_compare IsNextCharacterVariableNameCompliant("123aA\$bB_x@~!\"{}?{#", 14) false
@call_and_compare IsNextCharacterVariableNameCompliant("123aA\$bB_x@~!\"{}?{#", 15) false
@call_and_compare IsNextCharacterVariableNameCompliant("123aA\$bB_x@~!\"{}?{#", 16) false
@call_and_compare IsNextCharacterVariableNameCompliant("123aA\$bB_x@~!\"{}?{#", 17) false
@call_and_compare IsNextCharacterVariableNameCompliant("123aA\$bB_x@~!\"{}?{#", 19) false

## DeterminCharacterLabel
#### Labels are not mutually exclusive ####
# outside: not part of a potential variable name
# dollar: character indicating start of variable name
# curly_open: opening curly brace in variable name
# curly_close: closing curly brace in variable name
# curly_inside: part of a variable name inside curly braces
# plain: part of a variable name without curly braces
# terminating: indicates the end of a variable name outside curly braces
# discard: indicates the end of a variable in an unexpected manner
###########################################

@call_and_compare DeterminCharacterLabel("\$VAR", 1, []) ["dollar"]
@call_and_compare DeterminCharacterLabel("\$VAR", 2, ["dollar"]) ["plain"]
@call_and_compare DeterminCharacterLabel("\$VAR", 3, ["plain"]) ["plain"]
@call_and_compare DeterminCharacterLabel("\$VAR", 4, ["plain"]) ["terminating", "plain"]

@call_and_compare DeterminCharacterLabel("\"\$VAR\"", 1, []) ["outside"]
@call_and_compare DeterminCharacterLabel("\"\$VAR\"", 2, ["outside"]) ["dollar"]
@call_and_compare DeterminCharacterLabel("\"\$VAR\"", 3, ["dollar"]) ["plain"]
@call_and_compare DeterminCharacterLabel("\"\$VAR\"", 4, ["plain"]) ["plain"]
@call_and_compare DeterminCharacterLabel("\"\$VAR\"", 5, ["plain"]) ["terminating", "plain"]
@call_and_compare DeterminCharacterLabel("\"\$VAR\"", 6, ["terminating"]) ["outside"]

@call_and_compare DeterminCharacterLabel("\$VAR", ichr, previousLabels) []
@call_and_compare DeterminCharacterLabel("\$VAR", ichr, previousLabels) []
@call_and_compare DeterminCharacterLabel("\$VAR", ichr, previousLabels) []

@call_and_compare DeterminCharacterLabel("\"\$VAR\"", ichr, previousLabels) []
@call_and_compare DeterminCharacterLabel("\"\$VAR\"", ichr, previousLabels) []
@call_and_compare DeterminCharacterLabel("\"\$VAR\"", ichr, previousLabels) []

@call_and_compare DeterminCharacterLabel("pre $VAR as$VARVAR$VAR_\"\$VAR\"", ichr, previousLabels) []

@call_and_compare DeterminCharacterLabel("pre ${VAR} as${VARVAR}${VAR_\"\${VAR:?}\"", ichr, previousLabels) []


## ExpandOneVariableAtDollars
@call_and_compare ExpandOneVariableAtDollars("\$DIR_BASE", "DIR_BASE", "/path/some/where/") "/path/some/where/"
@call_and_compare ExpandOneVariableAtDollars("\$DIR_BASE", "VAR", "/path/some/where/") "\$DIR_BASE"
@call_and_compare ExpandOneVariableAtDollars("\${DIR_BASE}", "DIR_BASE", "/path/some/where/") "/path/some/where/"
@call_and_compare ExpandOneVariableAtDollars("\${DIR_BASE}", "VAR", "/path/some/where/") "\${DIR_BASE}"
@call_and_compare ExpandOneVariableAtDollars("\"\$DIR_BASE\"", "DIR_BASE", "/path/some/where/") "\"/path/some/where/\""
@call_and_compare ExpandOneVariableAtDollars("\"\${DIR_BASE}\"", "DIR_BASE", "/path/some/where/") "\"/path/some/where/\""
@call_and_compare ExpandOneVariableAtDollars("\"\${DIR_BASE}\"", "DIR_BASE", "/path/some/where/") "\"/path/some/where/\""

# Any character other than a letter number or underscore should indicate the end of a vairable name
@call_and_compare ExpandOneVariableAtDollars( "aa\"bb/\$DIR_BASE-" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/-"
@call_and_compare ExpandOneVariableAtDollars( "aa\"bb/\$DIR_BASE---\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/---\""
@call_and_compare ExpandOneVariableAtDollars( "aa\"bb/\$DIR_BASE/so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where//so/on/\""
@call_and_compare ExpandOneVariableAtDollars( "aa\"bb/\$DIR_BASE?so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/?so/on/\""
@call_and_compare ExpandOneVariableAtDollars( "aa\"bb/\$DIR_BASE}so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb/\$DIR_BASE}so/on/\""
@call_and_compare ExpandOneVariableAtDollars( "aa\"bb/\$DIR_BASE)so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/)so/on/\""
@call_and_compare ExpandOneVariableAtDollars( "aa\"bb/\$DIR_BASE,so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/,so/on/\""
@call_and_compare ExpandOneVariableAtDollars( "aa\"bb/\$DIR_BASE.so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/.so/on/\""
@call_and_compare ExpandOneVariableAtDollars( "aa\"bb/\$DIR_BASE\$so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/\$so/on/\""
@call_and_compare ExpandOneVariableAtDollars( "aa\"bb/\$DIR_BASE so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/ so/on/\""
@call_and_compare ExpandOneVariableAtDollars( "aa\"bb/\$DIR_BASE+so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/+so/on/\""
@call_and_compare ExpandOneVariableAtDollars( "aa\"bb/\$DIR_BASE-so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/-so/on/\""

testString = "start in\$VAR string \"\${VAR}\"/unit_tests/ foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"\"\$VAR\"\".txt\"\$VAR"
expString  = "start in888 string \"888\"/unit_tests/ foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"\"888\"\".txt\"888" # expString  = "start in!!! string \"!!!\"/unit_tests/ foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"!!!\".txt\""
@call_and_compare ExpandOneVariableAtDollars(testString, "VAR", "888") expString


## ExpandManyVariablesAtDollars
testString = "start in\$VAR1 string \"\${VAR2}\"/unit_tests/ foo\${VAR0#*} bar\${VAR0%afd} baz\${VAR0:?asdf} boo\${VAR0?!*} moo\${VAR0\$!*} \"sample\"\"\$VAR3\"\".txt\""
expString  = "start in111 string \"222\"/unit_tests/ foo\${VAR0#*} bar\${VAR0%afd} baz\${VAR0:?asdf} boo\${VAR0?!*} moo\${VAR0\$!*} \"sample\"\"\$VAR3\"\".txt\""
@call_and_compare ExpandManyVariablesAtDollars(testString, ["VAR0", "VAR1", "VAR2"], ["000", "111", "222"]) expString
@call_and_compare ExpandManyVariablesAtDollars("aa\"bb/\$DIR_BASE\"", ["DIR_BASE", "VAR1", "VAR2"], ["/path/some/where/", "AAA", "BBB"]) "aa\"bb//path/some/where/\""

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

## ParseVarsFile
expNamesRaw = [
"DIR_BASE"
"DIR_OUTPUT"
"PRE_REF_FILE1"
"PRE_REF_FILE2"
"REF_FILE"
"SAMPLE_OUTPUT_1"
"VAR1"
"VAR\$VAR1"
"VAR\$VAR2"
]
expValuesRaw = [
"\"/Users/olenive/work/jsub_pipeliner\""
"\"/Users/olenive/work/output_testing_jsub\""
"\"\$DIR_BASE\"/\"unit_tests/data/header_coordinate\""
"\"\$DIR_BASE\"/\"unit_tests/data/hg19.chrom.sizes\""
"\"\$DIR_OUTPUT\"/\"utSplit_refFile.txt\""
"\"\$DIR_OUTPUT\"/\"utSplit_out1_\""
"\"_valueVar1_\""
"\"_valueVar\$VAR1_\""
"\"_valueVar\$VAR2_\""
]
@call_and_compare ParseVarsFile(pathToTestVars) (expNamesRaw, expValuesRaw)

## ExpandInOrder
namesVarsRaw, valuesVarsRaw = ParseVarsFile(pathToTestVars)
expNames = [
"DIR_BASE"
"DIR_OUTPUT"
"PRE_REF_FILE1"
"PRE_REF_FILE2"
"REF_FILE"
"SAMPLE_OUTPUT_1"
"VAR1"
"VAR\$VAR1"
"VAR\$VAR2"
]
expValues = [
"\"/Users/olenive/work/jsub_pipeliner\""
"\"/Users/olenive/work/output_testing_jsub\""
"\"\/Users/olenive/work/jsub_pipeliner\"/\"unit_tests/data/header_coordinate\""
"\"\/Users/olenive/work/jsub_pipeliner\"/\"unit_tests/data/hg19.chrom.sizes\""
"\"\/Users/olenive/work/output_testing_jsub\"/\"utSplit_refFile.txt\""
"\"\/Users/olenive/work/output_testing_jsub\"/\"utSplit_out1_\""
"\"_valueVar1_\""
"\"_valueVar_valueVar1_\""
"\"_valueVar\$VAR2_\""
]
@call_and_compare ExpandInOrder(namesVarsRaw, valuesVarsRaw) (expNames, expValues)

########################################

if FLAG_TEST_FAIL
  warn(" *** One or more unit tests failed in ut_jsub_common.jl ***")
end


# EOF




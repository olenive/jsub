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
  msgPass = string("PASS: output matches expected.");
  msgFail = string("FAIL: output does not match expected.");
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
expArrVars = []#Array(Array{AbstractString} (7,))
expCmdRowsVars = []# Array(Int, 7)
# File looks like:
# ************************************************************************
# # This file contains the common variables in using refs_samples.protocol

# DIR_BASE  "/Users/olenive/work/jsub_pipeliner"
# DIR_OUTPUT  "/Users/olenive/work/output_testing_jsub"

# PRE_REF_FILE1 "$DIR_BASE"/"unit_tests/data/header_coordinate"
# PRE_REF_FILE2 "$DIR_BASE"/"unit_tests/data/hg19.chrom.sizes"

# REF_FILE  "$DIR_OUTPUT"/"utSplit_refFile.txt"
# SAMPLE_OUTPUT_1 "$DIR_OUTPUT"/"utSplit_out1_"


# ************************************************************************
push!(expArrVars, ["# This file contains the common variables in using refs_samples.protocol"])
push!(expArrVars, ["DIR_BASE", "\"/Users/olenive/work/jsub_pipeliner\""])
push!(expArrVars, ["DIR_OUTPUT", "\"/Users/olenive/work/output_testing_jsub\""])
push!(expArrVars, ["PRE_REF_FILE1", "\"$DIR_BASE\"/\"unit_tests/data/header_coordinate\""])
push!(expArrVars, ["PRE_REF_FILE2", "\"$DIR_BASE\"/\"unit_tests/data/hg19.chrom.sizes\""])
push!(expArrVars, ["REF_FILE", "\"$DIR_OUTPUT\"/\"utSplit_refFile.txt\""])
push!(expArrVars, ["SAMPLE_OUTPUT_1", "\"$DIR_OUTPUT\"/\"utSplit_out1_\""])
expCmdRowsVars = [2,3,4,5,6,7] # Rows in expArrVars that contain commands and not comments

@call_and_compare ReadFileIntoArrayOfArrays(pathToTestVars) (expArrVars, expCmdRowsVars)



















########################################
# EOF










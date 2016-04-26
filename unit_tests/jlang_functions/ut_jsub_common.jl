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
  global flag_test_fail = true;
end

###############

### MACROS ###
macro call_and_compare( funCall, expected ) # Note this macro actually makes to calls to the function, this should probably be fixed
  #println("Test function call: ", funCall)
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
      #println("expected output is:\n", $expected, "\nactual output is: \n", $output, "\n", $msgPass) 
      println(".")
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
global flag_test_fail = false

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

## iscomment
@call_and_compare iscomment("  \t  \# # This line is a comment", comStr) true
@call_and_compare iscomment("  \t  \# This line is still a comment", comStr) true
@call_and_compare iscomment("  \t  not a comment", comStr) false
@call_and_compare iscomment("really not a comment", comStr) false

## isblank
@call_and_compare isblank("") true
@call_and_compare isblank(" ") true
@call_and_compare isblank("	") true
@call_and_compare isblank("			 ") true
@call_and_compare isblank("asdf b c #") false
@call_and_compare isblank(" b c d") false
@call_and_compare isblank(" \"") false
@call_and_compare isblank("			'#") false

## file2arrayofarrays
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

@call_and_compare file2arrayofarrays(pathToTestVars, "#") (expArrVars, expCmdRowsVars)

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

@call_and_compare file2arrayofarrays(pathToTestFvars, "#") (expArrFvars, expCmdRowsFvars)


## sanitizestring
@call_and_compare sanitizestring("	  test string with a tab	here	 ") "test string with a tab\there"

## columnfrom_arrayofarrays
@call_and_compare columnfrom_arrayofarrays(expArrFvars, expCmdRowsFvars, 2; dlm=' ') ["0", "1"]
@call_and_compare columnfrom_arrayofarrays(expArrFvars, expCmdRowsFvars, 0; dlm=' ') [string("LANE_NUM",' ',"0",' ',"\"\$DIR_BASE\"/\"unit_tests/lists/multiLane_\"\'\"1\"\'\"col.txt\""), string("SAMPLEID",' ',"1",' ',"\"\$DIR_BASE\"/\"unit_tests/lists/sampleIDs_1col.txt\"")]

## warn_notreplaced
# warn_notreplaced("this include sub-string.", "sub-string")

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

## nextcharacter_isnamecompliant
                                                       #          1111 111111
                                                       #12345 67890123 456789
@call_and_compare nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 0) true
@call_and_compare nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 1) true
@call_and_compare nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 5) false
@call_and_compare nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 6) true
@call_and_compare nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 8) true
@call_and_compare nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 9) true
@call_and_compare nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 11) false
@call_and_compare nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 14) false
@call_and_compare nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 15) false
@call_and_compare nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 16) false
@call_and_compare nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 17) false
@call_and_compare nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 19) false

## determinelabel
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

@call_and_compare determinelabel("\$VAR", 1, Set([]) ) Set(["dollar"])
@call_and_compare determinelabel("\$VAR", 2, Set(["dollar"])) Set(["plain"])
@call_and_compare determinelabel("\$VAR", 3, Set(["plain"])) Set(["plain"])
@call_and_compare determinelabel("\$VAR", 4, Set(["plain"])) Set(["terminating", "plain"])

                                         # 1234567
@call_and_compare determinelabel("\$VAR aa", 1, Set([]) ) Set(["dollar"])
@call_and_compare determinelabel("\$VAR aa", 2, Set(["dollar"])) Set(["plain"])
@call_and_compare determinelabel("\$VAR aa", 3, Set(["plain"])) Set(["plain"])
@call_and_compare determinelabel("\$VAR aa", 4, Set(["plain"])) Set(["terminating", "plain"])
@call_and_compare determinelabel("\$VAR aa", 5, Set(["terminating", "plain"])) Set(["outside"])
@call_and_compare determinelabel("\$VAR aa", 6, Set(["outside"])) Set(["outside"])
@call_and_compare determinelabel("\$VAR aa", 7, Set(["outside"])) Set(["outside"])

                                         # 123456
@call_and_compare determinelabel("\${VAR}", 1, Set([]) ) Set(["dollar"])
@call_and_compare determinelabel("\${VAR}", 2, Set(["dollar"])) Set(["curly_open"])
@call_and_compare determinelabel("\${VAR}", 3, Set(["curly_open"])) Set(["curly_inside"])
@call_and_compare determinelabel("\${VAR}", 4, Set(["curly_inside"])) Set(["curly_inside"])
@call_and_compare determinelabel("\${VAR}", 5, Set(["curly_inside"])) Set(["terminating", "curly_inside"])
@call_and_compare determinelabel("\${VAR}", 6, Set(["terminating", "curly_inside"])) Set(["curly_close",])
@call_and_compare determinelabel("\${VAR}_a", 7, Set(["curly_close"])) Set(["outside"])
@call_and_compare determinelabel("\${VAR}_a", 6, Set(["outside"])) Set(["outside"])

@call_and_compare determinelabel("\"\$VAR\"", 1, Set([])) Set(["outside"])
@call_and_compare determinelabel("\"\$VAR\"", 2, Set(["outside"])) Set(["dollar"])
@call_and_compare determinelabel("\"\$VAR\"", 3, Set(["dollar"])) Set(["plain"])
@call_and_compare determinelabel("\"\$VAR\"", 4, Set(["plain"])) Set(["plain"])
@call_and_compare determinelabel("\"\$VAR\"", 5, Set(["plain"])) Set(["terminating", "plain"])
@call_and_compare determinelabel("\"\$VAR\"", 6, Set(["terminating"])) Set(["outside"])
                                        
                                         #          11 1111111 12222 2 2222 2
                                         #1234 5678901 2345678 90123 4 5678 9
@call_and_compare determinelabel("pre \$VAR as\$VARVAR\$VAR_\"\$VAR\"", 13, Set(["dollar"])) Set(["plain"])
@call_and_compare determinelabel("pre \$VAR as\$VARVAR\$VAR_\"\$VAR\"", 18, Set(["plain"])) Set(["plain", "terminating"])
@call_and_compare determinelabel("pre \$VAR as\$VARVAR\$VAR_\"\$VAR\"", 19, Set(["dollar"])) Set(["dollar"])

                                         #          1111 111111222 222222 2 33333333 33
                                         #1234 567890123 456789012 345678 9 01234567 89
@call_and_compare determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 14, Set(["outside"])) Set(["dollar"])
@call_and_compare determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 15, Set(["dollar"])) Set(["curly_open"])
@call_and_compare determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 16, Set(["curly_open"])) Set(["curly_inside"])
@call_and_compare determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 21, Set(["curly_inside"])) Set(["curly_inside", "terminating"])
@call_and_compare determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 22, Set(["terminating", "curly_inside"])) Set(["curly_close"])
@call_and_compare determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 23, Set(["curly_close"])) Set(["dollar"])

@call_and_compare determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 33, Set(["curly_inside"])) Set(["curly_inside"])
@call_and_compare determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 34, Set(["curly_inside"])) Set(["curly_inside", "terminating", "discard"])
@call_and_compare determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 35, Set(["curly_inside", "terminating"])) Set(["outside"])

## assignlabels
#              #          1         2            3         4          5          6         7          8          9          0           1            2             3
#              #12345678 901234567890 1 234567 89012345678901234 567890123456 78901234567890 1234567890123456 7890123456789 01234 56789 0123456 7 8 9012 3 45678 9 0123
# testString = "start in\$VAR string \"\${VAR}\"/unit_tests/ foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"\"\$VAR\"\".txt\"\$VAR"

             #            1           2          3
             # 1 23456 789012 3456789 0123456789 0
testString = "\"\$VAR*\$VAR x\${VAR} \${VAR:?@}_\""
expLabels = [
Set(["outside"]) # 1

Set(["dollar"]) # 2
Set(["plain"]) # 3
Set(["plain"]) # 4
Set(["plain", "terminating"]) # 5
Set(["outside"]) # 6

Set(["dollar"]) # 7
Set(["plain"]) # 8
Set(["plain"]) # 9
Set(["plain", "terminating"]) # 10
Set(["outside"]) # 11
Set(["outside"]) # 12

Set(["dollar"]) # 13
Set(["curly_open"]) # 14
Set(["curly_inside"]) # 15
Set(["curly_inside"]) # 16
Set(["curly_inside", "terminating"]) # 17
Set(["curly_close"]) # 18
Set(["outside"]) # 19

Set(["dollar"]) # 20
Set(["curly_open"]) # 21
Set(["curly_inside"]) # 22
Set(["curly_inside"]) # 23
Set(["curly_inside", "terminating", "discard"]) # 24
Set(["outside"]) # 25
Set(["outside"]) # 26
Set(["outside"]) # 27
Set(["outside"]) # 28
Set(["outside"]) # 29

Set(["outside"]) # 30
]
@call_and_compare assignlabels(testString) expLabels
             #            1           2          3
             # 1 23456 789012 3456789 0123456789 0
testString = "\$VAR"
expLabels = [
Set(["dollar"]) # 2
Set(["plain"]) # 3
Set(["plain"]) # 4
Set(["plain", "terminating"]) # 5
]
@call_and_compare assignlabels(testString) expLabels
             #           1           2          3
             # 12345 6789012 3456789 0123456789 0
testString = "\${VAR\$!*}"
expLabels = [
Set(["dollar"]) # 1
Set(["curly_open"]) # 2
Set(["curly_inside"]) # 3
Set(["curly_inside"]) # 4
Set(["curly_inside", "terminating", "discard"]) # 5
Set(["dollar"]) # 6
Set(["terminating", "discard"]) # 7
Set(["outside"]) # 8
Set(["outside"]) # 9
]
@call_and_compare assignlabels(testString) expLabels

## processcandidatename(candidate, terminatingLabelSet, name, value)
@call_and_compare processcandidatename("\$F", Set(["terminating", "plain"]), "FOO", "888") "\$F"
@call_and_compare processcandidatename("\$!", Set(["terminating", "plain"]), "FOO", "888") "\$!"
@call_and_compare processcandidatename("moo\${VAR\$!*}", Set(["terminating", "plain"]), "FOO", "888") "moo\${VAR\$!*}"
@call_and_compare processcandidatename("\${VAR\$!*}", Set(["terminating", "plain"]), "FOO", "888") "\${VAR\$!*}"

@call_and_compare processcandidatename("\$FOOO", Set(["terminating", "plain"]), "FOO", "888") "\$FOOO"
@call_and_compare processcandidatename("FOO", Set(["terminating", "plain"]), "FOO", "888")  "FOO"
@call_and_compare processcandidatename("\$FOO", Set(["terminating", "plain"]), "FOO", "888")  "888"
@call_and_compare processcandidatename("\${FOO}", Set(["terminating", "plain"]), "FOO", "888")  "\${FOO}"
@call_and_compare processcandidatename("\${FOO", Set(["terminating", "plain"]), "FOO", "888")  "\${FOO"
@call_and_compare processcandidatename("\${FOO", Set(["terminating" ]), "FOO", "888")  "\${FOO"

@call_and_compare processcandidatename("\$FOOO", Set(["terminating", "curly_inside"]), "FOO", "888")  "\$FOOO"
@call_and_compare processcandidatename("FOO", Set(["terminating", "curly_inside"]), "FOO", "888")  "FOO"
@call_and_compare processcandidatename("\$FOO", Set(["terminating", "curly_inside"]), "FOO", "888")  "\$FOO"
@call_and_compare processcandidatename("\${FOO}", Set(["terminating", "curly_inside"]), "FOO", "888")  "888"
@call_and_compare processcandidatename("\${FOO", Set(["terminating", "curly_inside"]), "FOO", "888")  "\${FOO"

@call_and_compare processcandidatename("\$FOOO", Set(["terminating", "curly_inside", "discard"]), "FOO", "888") "\$FOOO"
@call_and_compare processcandidatename("FOO", Set(["terminating", "curly_inside", "discard"]), "FOO", "888")  "FOO"
@call_and_compare processcandidatename("\$FOO", Set(["terminating", "curly_inside", "discard"]), "FOO", "888")  "\$FOO"
@call_and_compare processcandidatename("\${FOO}", Set(["terminating", "curly_inside", "discard"]), "FOO", "888")  "\${FOO}"
@call_and_compare processcandidatename("\${FOO", Set(["terminating", "curly_inside", "discard"]), "FOO", "888")  "\${FOO"

# testString = "s\${VAR}\"o\${VAR#*}"
# expString  = "s888\"o\${VAR#*}"
# @call_and_compare processcandidatename(testString, Set(["terminating", "curly_inside", "discard"]), "VAR", "888") expString

## expandnameafterdollar
@call_and_compare expandnameafterdollar("\$DIR_BASE", "DIR_BASE", "/path/some/where/") "/path/some/where/"
@call_and_compare expandnameafterdollar("\$DIR_BASE", "VAR", "/path/some/where/") "\$DIR_BASE"
@call_and_compare expandnameafterdollar("\${DIR_BASE}", "DIR_BASE", "/path/some/where/") "/path/some/where/"
@call_and_compare expandnameafterdollar("\${DIR_BASE}", "VAR", "/path/some/where/") "\${DIR_BASE}"
@call_and_compare expandnameafterdollar("\"\$DIR_BASE\"", "DIR_BASE", "/path/some/where/") "\"/path/some/where/\""
@call_and_compare expandnameafterdollar("\"\${DIR_BASE}\"", "DIR_BASE", "/path/some/where/") "\"/path/some/where/\""
@call_and_compare expandnameafterdollar("\"\${DIR_BASE}\"", "DIR_BASE", "/path/some/where/") "\"/path/some/where/\""

# Any character other than a letter number or underscore should indicate the end of a vairable name
@call_and_compare expandnameafterdollar( "aa\"bb/\$DIR_BASE-" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/-"
@call_and_compare expandnameafterdollar( "aa\"bb/\$DIR_BASE---\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/---\""
@call_and_compare expandnameafterdollar( "aa\"bb/\$DIR_BASE/so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where//so/on/\""
@call_and_compare expandnameafterdollar( "aa\"bb/\$DIR_BASE?so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/?so/on/\""
@call_and_compare expandnameafterdollar( "aa\"bb/\$DIR_BASE}so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/}so/on/\""
@call_and_compare expandnameafterdollar( "aa\"bb/\$DIR_BASE)so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/)so/on/\""
@call_and_compare expandnameafterdollar( "aa\"bb/\$DIR_BASE,so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/,so/on/\""
@call_and_compare expandnameafterdollar( "aa\"bb/\$DIR_BASE.so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/.so/on/\""
@call_and_compare expandnameafterdollar( "aa\"bb/\$DIR_BASE\$so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/\$so/on/\""
@call_and_compare expandnameafterdollar( "aa\"bb/\$DIR_BASE so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/ so/on/\""
@call_and_compare expandnameafterdollar( "aa\"bb/\$DIR_BASE+so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/+so/on/\""
@call_and_compare expandnameafterdollar( "aa\"bb/\$DIR_BASE-so/on/\"" , "DIR_BASE", "/path/some/where/") "aa\"bb//path/some/where/-so/on/\""

testString = "foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"\"\$VAR\"\".txt\"\$VAR"
expString  = "foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"\"888\"\".txt\"888"
@call_and_compare expandnameafterdollar(testString, "VAR", "888") expString

testString = "start in\$VAR string \"\${VAR}\"/unit_tests/ foo"
expString  = "start in888 string \"888\"/unit_tests/ foo"
@call_and_compare expandnameafterdollar(testString, "VAR", "888") expString

testString = "\"\${VAR}\"/unit_tests/ foo\${VAR#*}"
expString  = "\"888\"/unit_tests/ foo\${VAR#*}"
@call_and_compare expandnameafterdollar(testString, "VAR", "888") expString

testString = "s\${VARd}\"/s/o\${VAR#*}"
expString  = "s\${VARd}\"/s/o\${VAR#*}"
@call_and_compare expandnameafterdollar(testString, "VAR", "888") expString

testString = "s\$VARX}\"/s/o\${VAR#*}"
expString  = "s\$VARX}\"/s/o\${VAR#*}"
@call_and_compare expandnameafterdollar(testString, "VAR", "888") expString

testString = "s\${VAR\"/s/o\${VAR#*}"
expString  = "s\${VAR\"/s/o\${VAR#*}"
@call_and_compare expandnameafterdollar(testString, "VAR", "888") expString

testString = "s\${VAR\"o\${VAR#*}"
expString  = "s\${VAR\"o\${VAR#*}"
@call_and_compare expandnameafterdollar(testString, "VAR", "888") expString

testString = "s\${VAR}\"o\${VAR#*}"
expString  = "s888\"o\${VAR#*}"
@call_and_compare expandnameafterdollar(testString, "VAR", "888") expString

testString = "s\${VAR}\"o"
expString  = "s888\"o"
@call_and_compare expandnameafterdollar(testString, "VAR", "888") expString

testString = "start in\$VAR string \"\${VAR}\"/unit_tests/ foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"\"\$VAR\"\".txt\"\$VAR"
expString  = "start in888 string \"888\"/unit_tests/ foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"\"888\"\".txt\"888" # expString  = "start in!!! string \"!!!\"/unit_tests/ foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"!!!\".txt\""
@call_and_compare expandnameafterdollar(testString, "VAR", "888") expString

## expandmanyafterdollars
testString = "start in\$VAR1 string \"\${VAR2}\"/unit_tests/ foo\${VAR0#*} bar\${VAR0%afd} baz\${VAR0:?asdf} boo\${VAR0?!*} moo\${VAR0\$!*} \"sample\"\"\$VAR3\"\".txt\""
expString  = "start in111 string \"222\"/unit_tests/ foo\${VAR0#*} bar\${VAR0%afd} baz\${VAR0:?asdf} boo\${VAR0?!*} moo\${VAR0\$!*} \"sample\"\"\$VAR3\"\".txt\""
@call_and_compare expandmanyafterdollars(testString, ["VAR0", "VAR1", "VAR2"], ["000", "111", "222"]) expString
@call_and_compare expandmanyafterdollars("aa\"bb/\$DIR_BASE\"", ["DIR_BASE", "VAR1", "VAR2"], ["/path/some/where/", "AAA", "BBB"]) "aa\"bb//path/some/where/\""

## expand_inarrayofarrays
testArr = []
push!(testArr, ["# first comment string \${VAR}, \$VAR1 \"\"\$VAR2\""])
push!(testArr, ["string \${VAR}, \$VAR1 \"\"\$VAR2\""])
push!(testArr, ["# second comment string  \${VAR}, \$VAR1 \"\"\$VAR2\""])
push!(testArr, ["string  \${VAR}, \$VAR1 \"\"\$VAR2\""])
push!(testArr, ["# third comment string  \${VAR}, \$VAR1 \"\"\$VAR2\""])
expArr = []
push!(expArr, ["# first comment string \${VAR}, \$VAR1 \"\"\$VAR2\""])
push!(expArr, ["string \${VAR}, 111 \"\"222\""])
push!(expArr, ["# second comment string  \${VAR}, \$VAR1 \"\"\$VAR2\""])
push!(expArr, ["string  \${VAR}, 111 \"\"222\""])
push!(expArr, ["# third comment string  \${VAR}, \$VAR1 \"\"\$VAR2\""])
@call_and_compare expand_inarrayofarrays(testArr, [2,4], ["VAR0", "VAR1", "VAR2"], ["000", "111", "222"]; verbose=true) expArr

# expand_inarrayofarrays(arrFvars, cmdRowsFvars, namesVars, valuesVars; verbose = verbose)
arrArr = []
push!(arrArr, ["# This file contains the names of varibales, column numbers and source file paths from which the value of the variable should be taken."])
push!(arrArr, ["# <variable name>\t<column in file>\t<file path>"])
push!(arrArr, ["LANE_NUM","0","\"\$DIR_BASE\"/\"unit_tests/lists/multiLane_\"'\"1\"'\"col.txt\""])
push!(arrArr, ["# The zero in the <column in file> field indicates that all columns shold be used (or treated as one column)"])
push!(arrArr, ["SAMPLEID","1","\"\$DIR_BASE\"/\"unit_tests/lists/sampleIDs_1col.txt\""])
push!(arrArr, ["# The value of DIR_BASE is declared in refs_samples.vars"])
rows = [3,5]
varNames=[
 "DIR_BASE" 
 "SCRIPT"   
 "DOLLARVAR"
 "HELLO"
]
varVals=[
 "\"/Users/olenive/work/jsub_pipeliner/\""
 "\"utbash space.sh\""                    
 "\"\$dolla\""                            
 "\"Hello spaces and tabs\tand...\"" 
]
expArr = []
push!(expArr, ["# This file contains the names of varibales, column numbers and source file paths from which the value of the variable should be taken."])
push!(expArr, ["# <variable name>\t<column in file>\t<file path>"])
push!(expArr, ["LANE_NUM","0","\"\"/Users/olenive/work/jsub_pipeliner/\"\"/\"unit_tests/lists/multiLane_\"'\"1\"'\"col.txt\""])
push!(expArr, ["# The zero in the <column in file> field indicates that all columns shold be used (or treated as one column)"])
push!(expArr, ["SAMPLEID","1","\"\"/Users/olenive/work/jsub_pipeliner/\"\"/\"unit_tests/lists/sampleIDs_1col.txt\""])
push!(expArr, ["# The value of DIR_BASE is declared in refs_samples.vars"])
@call_and_compare expand_inarrayofarrays(arrArr, rows, varNames, varVals; verbose=true) expArr
# arrArr=arrFvars; rows=cmdRowsFvars; varNames=namesVars; varVals=valuesVars; verbose=true;
# expand_inarrayofarrays(arrFvars, cmdRowsFvars, namesVars, valuesVars; verbose = verbose)

## sanitizepath
testPath = "\"\$DIR_BASE\"/\"unit_tests/lists/multiLane_\"\'\"1\"\'\"col.txt\""
expPath = "\$DIR_BASE/unit_tests/lists/multiLane_\"1\"col.txt"
@call_and_compare sanitizepath(testPath)  expPath

## parse_varsfile
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
@call_and_compare parse_varsfile(pathToTestVars) (expNamesRaw, expValuesRaw)

## expandinorder
namesVarsRaw, valuesVarsRaw = parse_varsfile(pathToTestVars)
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
"\"\"/Users/olenive/work/jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\""
"\"\"/Users/olenive/work/jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\"" 
"\"\"/Users/olenive/work/output_testing_jsub\"\"/\"utSplit_refFile.txt\""            
"\"\"/Users/olenive/work/output_testing_jsub\"\"/\"utSplit_out1_\""                  
"\"_valueVar1_\""                                     
"\"_valueVar\$VAR1_\""                                
"\"_valueVar\$VAR2_\"" 
]
@call_and_compare expandinorder(namesVarsRaw, valuesVarsRaw) (expNames, expValues)

## parse_varsfile
fileVars="../protocols/split/refs_samples.vars"
expNames1=[
"DIR_BASE",
"DIR_OUTPUT",
"SCR_CREATE_REFS",
"SCR_PROCESS_SAMPLE",
"DIR_DATA",
"PRE_REF_FILE1",
"PRE_REF_FILE2",
"REF_FILE",
"PREFIX_0",
"SUFFIX_0",
"PREFIX_1"
]
expValues1=[
"\"/Users/olenive/work/jsub_pipeliner/\"",
"\"\$DIR_BASE\"/\"unit_tests/outputs/split/\"",
"\"\$DIR_BASE\"/\"unit_tests/shell_scripts/write_files/ut_create_reference.sh\"",
"\"\$DIR_BASE\"/\"unit_tests/shell_scripts/write_files/ut_process.sh\"",
"\"\$DIR_BASE\"/\"unit_tests/data/dummy_sample_files/\"",
"\"\$DIR_BASE\"/\"unit_tests/data/header_coordinate\"",
"\"\$DIR_BASE\"/\"unit_tests/data/hg19.chrom.sizes\"",
"\"\$DIR_OUTPUT\"/\"ut_split_refFile.txt\"",
"\"dummy_\"",
"\".txt\"",
"\"\$DIR_OUTPUT\"/\"ut_split_output_\""
]
@call_and_compare parse_varsfile(fileVars, dlmVars="\t") (expNames1, expValues1)

expNames2=[
"DIR_BASE",
"DIR_OUTPUT",
"SCR_CREATE_REFS",
"SCR_PROCESS_SAMPLE",
"DIR_DATA",
"PRE_REF_FILE1",
"PRE_REF_FILE2",
"REF_FILE",
"PREFIX_0",
"SUFFIX_0",
"PREFIX_1"
];
expValues2=[
"\"/Users/olenive/work/jsub_pipeliner/\"",
"\"\$DIR_BASE\"/\"unit_tests/outputs/split/\"",
"\"\$DIR_BASE\"/\"unit_tests/shell_scripts/write_files/ut_create_reference.sh\"",
"\"\$DIR_BASE\"/\"unit_tests/shell_scripts/write_files/ut_process.sh\"",
"\"\$DIR_BASE\"/\"unit_tests/data/dummy_sample_files/\"",
"\"\$DIR_BASE\"/\"unit_tests/data/header_coordinate\"",
"\"\$DIR_BASE\"/\"unit_tests/data/hg19.chrom.sizes\"",
"\"\$DIR_OUTPUT\"/\"ut_split_refFile.txt\"",
"\"dummy_\"",
"\".txt\"",
"\"\$DIR_OUTPUT\"/\"ut_split_output_\""
];
# @call_and_compare expandinorder(namesVarsRaw, valuesVarsRaw) (expNames2, expValues2)

## parse_expandvars_in_protocol

## parse_expandvars_in_listfiles

## expandvars_in_protocol

########################################

if flag_test_fail
  warn(" *** One or more unit tests failed in ut_jsub_common.jl ***")
else
  println("Unit tests completed successfully.")
end

# EOF




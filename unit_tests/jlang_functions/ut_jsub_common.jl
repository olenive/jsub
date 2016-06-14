# Run a basic test on functions from jsub_common.jl

using Base.Test

### Counters ###
ut_counter = [0, 0, 0];
################

## FUNCTIONS ##
function increment(counter, index)
  counter[index] += 1;
end
function ut_handler(r::Test.Success)
  increment(ut_counter,1);
end
function ut_handler(r::Test.Failure)
  increment(ut_counter,2);
  println(" *** FAILED TEST *** for expression: $(r.expr)")
end
function ut_handler(r::Test.Error)
  increment(ut_counter,3);
  rethrow(r)
end
function ut_report(counter)
  print("Completed unit tests:") #print("Completed \"", name, "\" ")
  print(" ", counter[1], " passes,")
  print(" ", counter[2], " failures,")
  print(" ", counter[3], " exceptions,")
  print("\n")
  return nothing
end
###############

### MACROS ###

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

const SUPPRESS_WARNINGS=true;
num_suppressed = [0];

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
Test.with_handler(ut_handler) do

  ## iscomment
  @test iscomment("  \t  \# # This line is a comment", comStr) == true
  @test iscomment("  \t  \# This line is still a comment", comStr) == true
  @test iscomment("  \t  not a comment", comStr) == false
  @test iscomment("really not a comment", comStr) == false

  ## isblank
  @test isblank("") == true
  @test isblank(" ") == true
  @test isblank("	") == true
  @test isblank("			 ") == true
  @test isblank("asdf b c #") == false
  @test isblank(" b c d") == false
  @test isblank(" \"") == false
  @test isblank("			'#") == false


  ## file2arrayofarrays
  # Create expected array to compare against
  # File looks like:
  # ************************************************************************
  # This file contains the common variables in using refs_samples.protocol

  # DIR_BASE        "../../../jsub_pipeliner"
  # DIR_OUTPUT      "../../../output_testing_jsub"

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
  push!(expArrVars, ["DIR_BASE", "\"../../../jsub_pipeliner\""])
  push!(expArrVars, ["DIR_OUTPUT", "\"../../../output_testing_jsub\""])
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

  @test file2arrayofarrays(pathToTestVars, "#") == (expArrVars, expCmdRowsVars)

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

  @test file2arrayofarrays(pathToTestFvars, "#") == (expArrFvars, expCmdRowsFvars)


  ## sanitizestring
  @test sanitizestring("	  test string with a tab	here	 ") == "test string with a tab\there"

  ## columnfrom_arrayofarrays
  @test columnfrom_arrayofarrays(expArrFvars, expCmdRowsFvars, 2; dlm=' ') == ["0", "1"]
  @test columnfrom_arrayofarrays(expArrFvars, expCmdRowsFvars, 0; dlm=' ') == [string("LANE_NUM",' ',"0",' ',"\"\$DIR_BASE\"/\"unit_tests/lists/multiLane_\"\'\"1\"\'\"col.txt\""), string("SAMPLEID",' ',"1",' ',"\"\$DIR_BASE\"/\"unit_tests/lists/sampleIDs_1col.txt\"")]

  ## warn_notreplaced
  # warn_notreplaced("this include sub-string.", "sub-string")

  # ## IsCharacterVariableNameCompliant
  # @test IsCharacterVariableNameCompliant('a', "outside") false
  # @test IsCharacterVariableNameCompliant('a', "plain") true
  # @test IsCharacterVariableNameCompliant('1', "plain") true
  # @test IsCharacterVariableNameCompliant('_', "plain") true
  # @test IsCharacterVariableNameCompliant('$', "plain") false
  # @test IsCharacterVariableNameCompliant('{', "plain") false
  # @test IsCharacterVariableNameCompliant('}', "plain") false
  # @test IsCharacterVariableNameCompliant('a', "curly") true
  # @test IsCharacterVariableNameCompliant('1', "curly") true
  # @test IsCharacterVariableNameCompliant('_', "curly") true
  # @test IsCharacterVariableNameCompliant('$', "curly") false
  # @test IsCharacterVariableNameCompliant('{', "curly") false
  # @test IsCharacterVariableNameCompliant('}', "curly") true

  ## nextcharacter_isnamecompliant
                                                         #          1111 111111
                                                         #12345 67890123 456789
  @test nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 0) == true
  @test nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 1) == true
  @test nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 5) == false
  @test nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 6) == true
  @test nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 8) == true
  @test nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 9) == true
  @test nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 11) == false
  @test nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 14) == false
  @test nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 15) == false
  @test nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 16) == false
  @test nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 17) == false
  @test nextcharacter_isnamecompliant("123aA\$bB_x@~!\"{}?{#", 19) == false

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

  @test determinelabel("\$VAR", 1, Set([]) ) == Set(["dollar"])
  @test determinelabel("\$VAR", 2, Set(["dollar"])) == Set(["plain"])
  @test determinelabel("\$VAR", 3, Set(["plain"])) == Set(["plain"])
  @test determinelabel("\$VAR", 4, Set(["plain"])) == Set(["terminating", "plain"])

                                           # 1234567
  @test determinelabel("\$VAR aa", 1, Set([]) ) == Set(["dollar"])
  @test determinelabel("\$VAR aa", 2, Set(["dollar"])) == Set(["plain"])
  @test determinelabel("\$VAR aa", 3, Set(["plain"])) == Set(["plain"])
  @test determinelabel("\$VAR aa", 4, Set(["plain"])) == Set(["terminating", "plain"])
  @test determinelabel("\$VAR aa", 5, Set(["terminating", "plain"])) == Set(["outside"])
  @test determinelabel("\$VAR aa", 6, Set(["outside"])) == Set(["outside"])
  @test determinelabel("\$VAR aa", 7, Set(["outside"])) == Set(["outside"])

                                           # 123456
  @test determinelabel("\${VAR}", 1, Set([]) ) == Set(["dollar"])
  @test determinelabel("\${VAR}", 2, Set(["dollar"])) == Set(["curly_open"])
  @test determinelabel("\${VAR}", 3, Set(["curly_open"])) == Set(["curly_inside"])
  @test determinelabel("\${VAR}", 4, Set(["curly_inside"])) == Set(["curly_inside"])
  @test determinelabel("\${VAR}", 5, Set(["curly_inside"])) == Set(["terminating", "curly_inside"])
  @test determinelabel("\${VAR}", 6, Set(["terminating", "curly_inside"])) == Set(["curly_close",])
  @test determinelabel("\${VAR}_a", 7, Set(["curly_close"])) == Set(["outside"])
  @test determinelabel("\${VAR}_a", 6, Set(["outside"])) == Set(["outside"])

  @test determinelabel("\"\$VAR\"", 1, Set([])) == Set(["outside"])
  @test determinelabel("\"\$VAR\"", 2, Set(["outside"])) == Set(["dollar"])
  @test determinelabel("\"\$VAR\"", 3, Set(["dollar"])) == Set(["plain"])
  @test determinelabel("\"\$VAR\"", 4, Set(["plain"])) == Set(["plain"])
  @test determinelabel("\"\$VAR\"", 5, Set(["plain"])) == Set(["terminating", "plain"])
  @test determinelabel("\"\$VAR\"", 6, Set(["terminating"])) == Set(["outside"])
                                          
                                           #          11 1111111 12222 2 2222 2
                                           #1234 5678901 2345678 90123 4 5678 9
  @test determinelabel("pre \$VAR as\$VARVAR\$VAR_\"\$VAR\"", 13, Set(["dollar"])) == Set(["plain"])
  @test determinelabel("pre \$VAR as\$VARVAR\$VAR_\"\$VAR\"", 18, Set(["plain"])) == Set(["plain", "terminating"])
  @test determinelabel("pre \$VAR as\$VARVAR\$VAR_\"\$VAR\"", 19, Set(["dollar"])) == Set(["dollar"])

                                           #          1111 111111222 222222 2 33333333 33
                                           #1234 567890123 456789012 345678 9 01234567 89
  @test determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 14, Set(["outside"])) == Set(["dollar"])
  @test determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 15, Set(["dollar"])) == Set(["curly_open"])
  @test determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 16, Set(["curly_open"])) == Set(["curly_inside"])
  @test determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 21, Set(["curly_inside"])) == Set(["curly_inside", "terminating"])
  @test determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 22, Set(["terminating", "curly_inside"])) == Set(["curly_close"])
  @test determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 23, Set(["curly_close"])) == Set(["dollar"])

  @test determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 33, Set(["curly_inside"])) == Set(["curly_inside"])
  @test determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 34, Set(["curly_inside"])) == Set(["curly_inside", "terminating", "discard"])
  @test determinelabel("pre \${VAR} as\${VARVAR}\${VAR_\"\${VAR:?}\"", 35, Set(["curly_inside", "terminating"])) == Set(["outside"])

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
  @test assignlabels(testString) == expLabels
               #            1           2          3
               # 1 23456 789012 3456789 0123456789 0
  testString = "\$VAR"
  expLabels = [
  Set(["dollar"]) # 2
  Set(["plain"]) # 3
  Set(["plain"]) # 4
  Set(["plain", "terminating"]) # 5
  ]
  @test assignlabels(testString) == expLabels
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
  @test assignlabels(testString) == expLabels

  ## processcandidatename(candidate, terminatingLabelSet, name, value)
  @test processcandidatename("\$F", Set(["terminating", "plain"]), "FOO", "888") == "\$F"
  @test processcandidatename("\$!", Set(["terminating", "plain"]), "FOO", "888") == "\$!"
  @test processcandidatename("moo\${VAR\$!*}", Set(["terminating", "plain"]), "FOO", "888") == "moo\${VAR\$!*}"
  @test processcandidatename("\${VAR\$!*}", Set(["terminating", "plain"]), "FOO", "888") == "\${VAR\$!*}"

  @test processcandidatename("\$FOOO", Set(["terminating", "plain"]), "FOO", "888") == "\$FOOO"
  @test processcandidatename("FOO", Set(["terminating", "plain"]), "FOO", "888")  == "FOO"
  @test processcandidatename("\$FOO", Set(["terminating", "plain"]), "FOO", "888")  == "888"
  @test processcandidatename("\${FOO}", Set(["terminating", "plain"]), "FOO", "888")  == "\${FOO}"
  @test processcandidatename("\${FOO", Set(["terminating", "plain"]), "FOO", "888")  == "\${FOO"
  @test processcandidatename("\${FOO", Set(["terminating" ]), "FOO", "888")  == "\${FOO"

  @test processcandidatename("\$FOOO", Set(["terminating", "curly_inside"]), "FOO", "888")  == "\$FOOO"
  @test processcandidatename("FOO", Set(["terminating", "curly_inside"]), "FOO", "888")  == "FOO"
  @test processcandidatename("\$FOO", Set(["terminating", "curly_inside"]), "FOO", "888")  == "\$FOO"
  @test processcandidatename("\${FOO}", Set(["terminating", "curly_inside"]), "FOO", "888")  == "888"
  @test processcandidatename("\${FOO", Set(["terminating", "curly_inside"]), "FOO", "888")  == "\${FOO"

  @test processcandidatename("\$FOOO", Set(["terminating", "curly_inside", "discard"]), "FOO", "888") == "\$FOOO"
  @test processcandidatename("FOO", Set(["terminating", "curly_inside", "discard"]), "FOO", "888")  == "FOO"
  @test processcandidatename("\$FOO", Set(["terminating", "curly_inside", "discard"]), "FOO", "888")  == "\$FOO"
  @test processcandidatename("\${FOO}", Set(["terminating", "curly_inside", "discard"]), "FOO", "888")  == "\${FOO}"
  @test processcandidatename("\${FOO", Set(["terminating", "curly_inside", "discard"]), "FOO", "888")  == "\${FOO"

  ## processcandidatename(candidate, terminatingLabelSet, name, value)
  @test processcandidatename("\$F", Set(["terminating", "plain"]), "FOO", "888"; returnTrueOrFalse=true) == false
  @test processcandidatename("\$!", Set(["terminating", "plain"]), "FOO", "888"; returnTrueOrFalse=true) == false
  @test processcandidatename("moo\${VAR\$!*}", Set(["terminating", "plain"]), "FOO", "888"; returnTrueOrFalse=true) == false
  @test processcandidatename("\${VAR\$!*}", Set(["terminating", "plain"]), "FOO", "888"; returnTrueOrFalse=true) == false

  @test processcandidatename("\$FOOO", Set(["terminating", "plain"]), "FOO", "888"; returnTrueOrFalse=true) == false
  @test processcandidatename("FOO", Set(["terminating", "plain"]), "FOO", "888"; returnTrueOrFalse=true)  == false
  @test processcandidatename("\$FOO", Set(["terminating", "plain"]), "FOO", "888"; returnTrueOrFalse=true)  == true
  @test processcandidatename("\${FOO}", Set(["terminating", "plain"]), "FOO", "888"; returnTrueOrFalse=true)  == false
  @test processcandidatename("\${FOO", Set(["terminating", "plain"]), "FOO", "888"; returnTrueOrFalse=true)  == false
  @test processcandidatename("\${FOO", Set(["terminating" ]), "FOO", "888"; returnTrueOrFalse=true)  == false

  @test processcandidatename("\$FOOO", Set(["terminating", "curly_inside"]), "FOO", "888"; returnTrueOrFalse=true)  == false
  @test processcandidatename("FOO", Set(["terminating", "curly_inside"]), "FOO", "888"; returnTrueOrFalse=true)  == false
  @test processcandidatename("\$FOO", Set(["terminating", "curly_inside"]), "FOO", "888"; returnTrueOrFalse=true)  == false
  @test processcandidatename("\${FOO}", Set(["terminating", "curly_inside"]), "FOO", "888"; returnTrueOrFalse=true)  == true
  @test processcandidatename("\${FOO", Set(["terminating", "curly_inside"]), "FOO", "888"; returnTrueOrFalse=true)  == false

  @test processcandidatename("\$FOOO", Set(["terminating", "curly_inside", "discard"]), "FOO", "888"; returnTrueOrFalse=true) == false
  @test processcandidatename("FOO", Set(["terminating", "curly_inside", "discard"]), "FOO", "888"; returnTrueOrFalse=true)  == false
  @test processcandidatename("\$FOO", Set(["terminating", "curly_inside", "discard"]), "FOO", "888"; returnTrueOrFalse=true)  == false
  @test processcandidatename("\${FOO}", Set(["terminating", "curly_inside", "discard"]), "FOO", "888"; returnTrueOrFalse=true)  == true
  @test processcandidatename("\${FOO", Set(["terminating", "curly_inside", "discard"]), "FOO", "888"; returnTrueOrFalse=true)  == false

  # testString = "s\${VAR}\"o\${VAR#*}"
  # expString  = "s888\"o\${VAR#*}"
  # @test processcandidatename(testString, Set(["terminating", "curly_inside", "discard"]), "VAR", "888") expString

  ## expandnameafterdollar
  @test expandnameafterdollar("\$DIR_BASE", "DIR_BASE", "/path/some/where/") == "/path/some/where/"
  @test expandnameafterdollar("\$DIR_BASE", "VAR", "/path/some/where/") == "\$DIR_BASE"
  @test expandnameafterdollar("\${DIR_BASE}", "DIR_BASE", "/path/some/where/") == "/path/some/where/"
  @test expandnameafterdollar("\${DIR_BASE}", "VAR", "/path/some/where/") == "\${DIR_BASE}"
  @test expandnameafterdollar("\"\$DIR_BASE\"", "DIR_BASE", "/path/some/where/") == "\"/path/some/where/\""
  @test expandnameafterdollar("\"\${DIR_BASE}\"", "DIR_BASE", "/path/some/where/") == "\"/path/some/where/\""
  @test expandnameafterdollar("\"\${DIR_BASE}\"", "DIR_BASE", "/path/some/where/") == "\"/path/some/where/\""

  # Any character other than a letter number or underscore should indicate the end of a vairable name
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE-" , "DIR_BASE", "/path/some/where/") == "aa\"bb//path/some/where/-"
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE---\"" , "DIR_BASE", "/path/some/where/") == "aa\"bb//path/some/where/---\""
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE/so/on/\"" , "DIR_BASE", "/path/some/where/") == "aa\"bb//path/some/where//so/on/\""
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE?so/on/\"" , "DIR_BASE", "/path/some/where/") == "aa\"bb//path/some/where/?so/on/\""
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE}so/on/\"" , "DIR_BASE", "/path/some/where/") == "aa\"bb//path/some/where/}so/on/\""
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE)so/on/\"" , "DIR_BASE", "/path/some/where/") == "aa\"bb//path/some/where/)so/on/\""
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE,so/on/\"" , "DIR_BASE", "/path/some/where/") == "aa\"bb//path/some/where/,so/on/\""
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE.so/on/\"" , "DIR_BASE", "/path/some/where/") == "aa\"bb//path/some/where/.so/on/\""
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE\$so/on/\"" , "DIR_BASE", "/path/some/where/") == "aa\"bb//path/some/where/\$so/on/\""
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE so/on/\"" , "DIR_BASE", "/path/some/where/") == "aa\"bb//path/some/where/ so/on/\""
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE+so/on/\"" , "DIR_BASE", "/path/some/where/") == "aa\"bb//path/some/where/+so/on/\""
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE-so/on/\"" , "DIR_BASE", "/path/some/where/") == "aa\"bb//path/some/where/-so/on/\""

  ## expandnameafterdollar
  @test expandnameafterdollar("\$DIR_BASE", "DIR_BASE", "/path/some/where/"; returnTF=true) == true
  @test expandnameafterdollar("\$DIR_BASE", "VAR", "/path/some/where/"; returnTF=true) == false
  @test expandnameafterdollar("\${DIR_BASE}", "DIR_BASE", "/path/some/where/"; returnTF=true) == true
  @test expandnameafterdollar("\${DIR_BASE}", "VAR", "/path/some/where/"; returnTF=true) == false
  @test expandnameafterdollar("\"\$DIR_BASE\"", "DIR_BASE", "/path/some/where/"; returnTF=true) == true
  @test expandnameafterdollar("\"\${DIR_BASE}\"", "DIR_BASE", "/path/some/where/"; returnTF=true) == true
  @test expandnameafterdollar("\"\${DIR_BASE}\"", "DIR_BASE", "/path/some/where/"; returnTF=true) == true

  # Any character other than a letter number or underscore should indicate the end of a vairable name
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE-" , "DIR_BASE", "/path/some/where/"; returnTF=true) == true
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE---\"" , "DIR_BASE", "/path/some/where/"; returnTF=true) == true
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE/so/on/\"" , "DIR_BASE", "/path/some/where/"; returnTF=true) == true
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE?so/on/\"" , "DIR_BASE", "/path/some/where/"; returnTF=true) == true
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE}so/on/\"" , "DIR_BASE", "/path/some/where/"; returnTF=true) == true
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE)so/on/\"" , "DIR_BASE", "/path/some/where/"; returnTF=true) == true
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE,so/on/\"" , "DIR_BASE", "/path/some/where/"; returnTF=true) == true
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE.so/on/\"" , "DIR_BASE", "/path/some/where/"; returnTF=true) == true
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE\$so/on/\"" , "DIR_BASE", "/path/some/where/"; returnTF=true) == true
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE so/on/\"" , "DIR_BASE", "/path/some/where/"; returnTF=true) == true
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE+so/on/\"" , "DIR_BASE", "/path/some/where/"; returnTF=true) == true
  @test expandnameafterdollar( "aa\"bb/\$DIR_BASE-so/on/\"" , "DIR_BASE", "/path/some/where/"; returnTF=true) == true

  testString = "foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"\"\$VAR\"\".txt\"\$VAR"
  expString  = "foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"\"888\"\".txt\"888"
  @test expandnameafterdollar(testString, "VAR", "888") == expString

  testString = "start in\$VAR string \"\${VAR}\"/unit_tests/ foo"
  expString  = "start in888 string \"888\"/unit_tests/ foo"
  @test expandnameafterdollar(testString, "VAR", "888") == expString

  testString = "\"\${VAR}\"/unit_tests/ foo\${VAR#*}"
  expString  = "\"888\"/unit_tests/ foo\${VAR#*}"
  @test expandnameafterdollar(testString, "VAR", "888") == expString

  testString = "s\${VARd}\"/s/o\${VAR#*}"
  expString  = "s\${VARd}\"/s/o\${VAR#*}"
  @test expandnameafterdollar(testString, "VAR", "888") == expString

  testString = "s\$VARX}\"/s/o\${VAR#*}"
  expString  = "s\$VARX}\"/s/o\${VAR#*}"
  @test expandnameafterdollar(testString, "VAR", "888") == expString

  testString = "s\${VAR\"/s/o\${VAR#*}"
  expString  = "s\${VAR\"/s/o\${VAR#*}"
  @test expandnameafterdollar(testString, "VAR", "888") == expString

  testString = "s\${VAR\"o\${VAR#*}"
  expString  = "s\${VAR\"o\${VAR#*}"
  @test expandnameafterdollar(testString, "VAR", "888") == expString

  testString = "s\${VAR}\"o\${VAR#*}"
  expString  = "s888\"o\${VAR#*}"
  @test expandnameafterdollar(testString, "VAR", "888") == expString

  testString = "s\${VAR}\"o"
  expString  = "s888\"o"
  @test expandnameafterdollar(testString, "VAR", "888") == expString

  testString = "start in\$VAR string \"\${VAR}\"/unit_tests/ foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"\"\$VAR\"\".txt\"\$VAR"
  expString  = "start in888 string \"888\"/unit_tests/ foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"\"888\"\".txt\"888" # expString  = "start in!!! string \"!!!\"/unit_tests/ foo\${VAR#*} bar\${VAR%afd} baz\${VAR:?asdf} boo\${VAR?!*} moo\${VAR\$!*} \"sample\"!!!\".txt\""
  @test expandnameafterdollar(testString, "VAR", "888") == expString

  ## assign_quote_state(inString, charQuote) # For each character in the input and output string assign a 0 if it is outside quotes or a 1 if it is inside quotes or a 2 if it is a quote character
  @test assign_quote_state("A\"B\"", '\"') == [0, 2, 1, 2]
                           #1234 5678 90123 4 5678 90123 4567 89012            #1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6  7  8  9  0  1  2
  @test assign_quote_state("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", '\"') == [0, 0, 0, 0, 2, 1, 1, 1, 2, 0, 0, 0, 0, 2, 1, 1, 1, 1, 2, 0, 0, 0, 0, 2, 1, 1, 1, 2, 0, 0, 0, 0]
  @test assign_quote_state("out0\"in1\"out1\"\"val\"\"out2\"in2\"out3", '\"') == [0, 0, 0, 0, 2, 1, 1, 1, 2, 0, 0, 0, 0, 2, 2, 0, 0, 0, 2, 2, 0, 0, 0, 0, 2, 1, 1, 1, 2, 0, 0, 0, 0]
  @test assign_quote_state("out0\"in1\"out1\"\"\"val\"\"\"out2\"in2\"out3", '\"') == [0, 0, 0, 0, 2, 1, 1, 1, 2, 0, 0, 0, 0, 2, 2, 2, 1, 1, 1, 2, 2, 2, 0, 0, 0, 0, 2, 1, 1, 1, 2, 0, 0, 0, 0]
                           # 123456 78 901234 56
  @test assign_quote_state("\"Hello\" \"World\"", '\"') == [2,1,1,1,1,1,2,0,2,1,1,1,1,1,2]
  @test assign_quote_state("\"Hello\" \"Sky", '\"') == [2,1,1,1,1,1,2,0,2,1,1,1]

  ## substitute_string(inString, subString, inclusive_start, inclusive_finish)
  @test substitute_string("A\"B\"C", "\"D", 2, 5) == "A\"D"
                          #12345678901                                    #12345678901
  @test substitute_string("Hello World", "Sky", 7, 11) == "Hello Sky"
                          # 123456 78 901234 56                       # 123456 78 901234 56
  @test substitute_string("\"Hello\" \"World\"", "Sky", 9, 15)     == "\"Hello\" Sky"
  @test substitute_string("\"Hello\" \"World\"", "Sky", 10, 14)    == "\"Hello\" \"Sky\""
  @test substitute_string("\"Hello\" \"World\"", "\"Sky", 9, 15)   == "\"Hello\" \"Sky"
  @test substitute_string("\"Hello\" \"World\"", "Sky\"", 9, 15)   == "\"Hello\" Sky\""
  @test substitute_string("\"Hello\" \"World\"", "\"Sky\"", 9, 15) == "\"Hello\" \"Sky\""
  @test substitute_string("\"Hello\" World\"", "Sky\"", 9, 14)     == "\"Hello\" Sky\""
                          #1234 5678 90123 4 5678 90123 4567 89012
  @test substitute_string("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "val", 15, 18)     == "out0\"in1\"out1\"val\"out2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "v\"a\"l", 15, 18) == "out0\"in1\"out1\"v\"a\"l\"out2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "\"val\"", 15, 18) == "out0\"in1\"out1\"\"val\"\"out2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "\"val", 15, 18)   == "out0\"in1\"out1\"\"val\"out2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "val\"", 15, 18)   == "out0\"in1\"out1\"val\"\"out2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "\"\"val\"\"", 15, 18)   == "out0\"in1\"out1\"\"\"val\"\"\"out2\"in2\"out3"
                          #1234 5678 90123 4567890123 4567 89012
  @test substitute_string("out0\"in1\"out1\${VAR}out2\"in2\"out3", "val", 14, 19) == "out0\"in1\"out1valout2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\${VAR}out2\"in2\"out3", "\"val\"", 14, 19) == "out0\"in1\"out1\"val\"out2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\${VAR}out2\"in2\"out3", "x\"val\"y", 14, 19) == "out0\"in1\"out1x\"val\"yout2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\${VAR}out2\"in2\"out3", "x\"valy", 14, 19) == "out0\"in1\"out1x\"valyout2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\${VAR}out2\"in2\"out3", "xval\"y", 14, 19) == "out0\"in1\"out1xval\"yout2\"in2\"out3"

  ## get_index_of_first_and_last_nonquote_characters(string, charQuote; inclusive_start=1, inclusive_finish=0)
  @test get_index_of_first_and_last_nonquote_characters("12\"45\"7", '\"') == (1, 7)
  @test get_index_of_first_and_last_nonquote_characters("12\"45\"7", '\"'; iStart=3, iFinish=6) == (4, 5)
  @test get_index_of_first_and_last_nonquote_characters("12\"4567\"9", '\"'; iStart=3) == (4, 9)
  @test get_index_of_first_and_last_nonquote_characters("12\"4567\"9", '\"'; iFinish=3) == (1, 2)
  @test get_index_of_first_and_last_nonquote_characters("12\"4567\"9", '\"'; iStart=3, iFinish=3) == (0, 0)
                                                        #12345678901
  @test get_index_of_first_and_last_nonquote_characters("Hello World", '\"'; iStart=7, iFinish=11) == (7,11)

  ## check_quote_consistency(inString, subString, inclusive_start, inclusive_finish; charQuote='\"')
  # Check inside/outside quote consistency.  The idea is that a substitution of a variable name for its value should not change the quote status of the rest of the string
  @test check_quote_consistency("A\"B\"C", "\"D", 2, 5; charQuote='\"', verbose=false) == true
  @test check_quote_consistency("A\"B\"C\"", "\"D", 2, 5; charQuote='\"', verbose=false) == true
  @test check_quote_consistency("A\"B\"CE", "\"D", 2, 5; charQuote='\"', verbose=false) == false
  @test check_quote_consistency("A\"B\"", "\"C", 2, 5; charQuote='\"', verbose=false) == true
                                #12345678901
  @test check_quote_consistency("Hello World", "Sky", 7, 11; charQuote='\"', verbose=false) == true
                                # 123456 78 901234 56
  @test check_quote_consistency("\"Hello\" \"World\"", "Sky", 9, 15; charQuote='\"', verbose=false) == true
  @test check_quote_consistency("\"Hello\" \"World\"", "Sky", 10, 14; charQuote='\"', verbose=false) == false
  @test check_quote_consistency("\"Hello\" \"World\"", "\"Sky", 9, 15; charQuote='\"', verbose=false) == true # "Hello" "World" -> "Hello" "Sky (note the lack of closing quote, this should be addressed later using enforce_closingquote)
  @test check_quote_consistency("\"Hello\" \"World\"", "Sky\"", 9, 15; charQuote='\"', verbose=false) == true
  @test check_quote_consistency("\"Hello\" \"World\"", "\"Sky\"", 9, 15; charQuote='\"', verbose=false) == true
  @test check_quote_consistency("\"Hello\" World\"", "Sky\"", 9, 14; charQuote='\"', verbose=false) == true
                                #1234 5678 90123 4 5678 90123 4567 89012
  @test check_quote_consistency("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "val", 15, 18; charQuote='\"', verbose=false) == false
  @test check_quote_consistency("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "v\"a\"l", 15, 18; charQuote='\"') == false
  @test check_quote_consistency("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "\"val\"", 15, 18; charQuote='\"') == false
  @test check_quote_consistency("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "val\"", 15, 18; charQuote='\"') == false
  @test check_quote_consistency("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "\"val", 15, 18; charQuote='\"') == false
  @test check_quote_consistency("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "\"\"val\"\"", 15, 18; charQuote='\"', verbose=false) == false
                                #1234 5678 90123 4567890123 4567 89012
  @test check_quote_consistency("out0\"in1\"out1\${VAR}out2\"in2\"out3", "val", 14, 19; charQuote='\"') == true
  @test check_quote_consistency("out0\"in1\"out1\${VAR}out2\"in2\"out3", "\"val\"", 14, 19; charQuote='\"') == true
  @test check_quote_consistency("out0\"in1\"out1\${VAR}out2\"in2\"out3", "x\"val\"y", 14, 19; charQuote='\"') == true
  @test check_quote_consistency("out0\"in1\"out1\${VAR}out2\"in2\"out3", "x\"valy", 14, 19; charQuote='\"') == false
  @test check_quote_consistency("out0\"in1\"out1\${VAR}out2\"in2\"out3", "xval\"y", 14, 19; charQuote='\"') == false
                                #1234 5678 90123 4 5 6789 0 123 4567 8 90123
  @test check_quote_consistency("out0\"in1\"out1\"\"\$VAR\"\"out2\"in2\"out3", "val", 16, 19; charQuote='\"', verbose=false) == true
                                #1234 5678 90123 4 5 6789 0 123 4567 8 90123
  # @test check_quote_consistency("out0\"in1\"out1\"\"\$in2\"out2\"in3\"out3", "ooo\"", 16, 19)

  ## enforce_quote_consistency(inString, subString, inclusive_start, inclusive_finish; charQuote='\"')
  # Change a string so that substitution does not change the inside/outside quote stat of the rest of the string.
  # enforce_quote_consistency(inString, subString, inclusive_start, inclusive_finish; charQuote='\"', ignore_fails=false)
                          #1234 5678 90123 4 5678 90123 4567 89012
  @test substitute_string("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "val", 15, 18)     == "out0\"in1\"out1\"val\"out2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "v\"a\"l", 15, 18) == "out0\"in1\"out1\"v\"a\"l\"out2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "\"val\"", 15, 18) == "out0\"in1\"out1\"\"val\"\"out2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "\"val", 15, 18)   == "out0\"in1\"out1\"\"val\"out2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "val\"", 15, 18)   == "out0\"in1\"out1\"val\"\"out2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "\"\"val\"\"", 15, 18)   == "out0\"in1\"out1\"\"\"val\"\"\"out2\"in2\"out3"
                          #1234 5678 90123 4567890123 4567 89012
  @test substitute_string("out0\"in1\"out1\${VAR}out2\"in2\"out3", "val", 14, 19) == "out0\"in1\"out1valout2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\${VAR}out2\"in2\"out3", "\"val\"", 14, 19) == "out0\"in1\"out1\"val\"out2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\${VAR}out2\"in2\"out3", "x\"val\"y", 14, 19) == "out0\"in1\"out1x\"val\"yout2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\${VAR}out2\"in2\"out3", "x\"valy", 14, 19) == "out0\"in1\"out1x\"valyout2\"in2\"out3"
  @test substitute_string("out0\"in1\"out1\${VAR}out2\"in2\"out3", "xval\"y", 14, 19) == "out0\"in1\"out1xval\"yout2\"in2\"out3"

                                  # 1234
  @test enforce_quote_consistency("\$in0", "ooo", 1, 4; charQuote='\"', verbose=false) == "ooo" 
  @test enforce_quote_consistency("\$in0", "\"iii", 1, 4; charQuote='\"', verbose=false) == "\"iii" # Note the lack of a closing quote in the resulting string, this should be added after all substitutions using enforce_closingquote 
  @test enforce_quote_consistency("\$in0", "ooo\"", 1, 4; charQuote='\"', verbose=false) == "ooo\"" 
  @test enforce_quote_consistency("\$in0", "\"iii\"", 1, 4; charQuote='\"', verbose=false) == "\"iii\"" 
                                  # 1 2345
  @test enforce_quote_consistency("\"\$in0", "ooo", 2, 5; charQuote='\"', verbose=false) == "\"ooo" 
  @test enforce_quote_consistency("\"\$in0", "\"iii", 2, 5; charQuote='\"', verbose=false) == "\"\"iii"
  @test enforce_quote_consistency("\"\$in0", "ooo\"", 2, 5; charQuote='\"', verbose=false) == "\"ooo\""   # Note the lack of a closing quote in the resulting string, this should be added after all substitutions using enforce_closingquote 
  @test enforce_quote_consistency("\"\$in0", "\"iii\"", 2, 5; charQuote='\"', verbose=false) == "\"\"iii\"" 
                                  # 1 2345
  @test enforce_quote_consistency("\$in0\"", "ooo", 1, 4; charQuote='\"', verbose=false) == "ooo"   # Note the lack of a closing quote in the resulting string, this should be added after all substitutions using enforce_closingquote 
  @test enforce_quote_consistency("\$in0\"", "\"iii", 1, 4; charQuote='\"', verbose=false) == "\"iii"
  @test enforce_quote_consistency("\$in0\"", "ooo\"", 1, 4; charQuote='\"', verbose=false) == "ooo\"" 
  @test enforce_quote_consistency("\$in0\"", "\"iii\"", 1, 4; charQuote='\"', verbose=false) == "\"iii\"" 
                                  # 1 2345 6
  @test enforce_quote_consistency("\"\$in0\"", "ooo", 2, 5; charQuote='\"', verbose=false) == "\"ooo" 
  @test enforce_quote_consistency("\"\$in0\"", "\"iii", 2, 5; charQuote='\"', verbose=false) == "\"\"iii"
  @test enforce_quote_consistency("\"\$in0\"", "ooo\"", 2, 5; charQuote='\"', verbose=false) == "\"ooo\"" 
  @test enforce_quote_consistency("\"\$in0\"", "\"iii\"", 2, 5; charQuote='\"', verbose=false) == "\"\"iii\"" 

                                  #1234 5678 90123 4 5678 90123 4567 89012
  @test enforce_quote_consistency("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "out", 15, 18; charQuote='\"', verbose=false) == "\"out\""
  @test enforce_quote_consistency("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "o\"i\"o", 15, 18; charQuote='\"') == "\"o\"i\"o\""
  @test enforce_quote_consistency("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "\"iii\"", 15, 18; charQuote='\"') == "\"\"iii\"\""
  @test enforce_quote_consistency("out0\"in1\"out1\"\$in2\"out2\"in3\"out3", "ooo\"", 15, 18; charQuote='\"', verbose=false) == "\"ooo\"" 
  @test enforce_quote_consistency("out0\"in1\"out1\"\$in2\"out2\"in3\"out3", "\"iii", 15, 18; charQuote='\"', verbose=false) == "\"\"iii" 
                                  #1234 5678 90123 4567 89012 3456 789012
  @test enforce_quote_consistency("out0\"in1\"out1\$VAR\"int1\"ot2\"int3", "out",     14, 17; charQuote='\"', verbose=false) == "out"
  @test enforce_quote_consistency("out0\"in1\"out1\$VAR\"int2\"ot2\"int3", "o\"i\"o", 14, 17; charQuote='\"') == "o\"i\"o"
  @test enforce_quote_consistency("out0\"in1\"out1\$VAR\"int2\"ot2\"int3", "\"iii\"", 14, 17; charQuote='\"') == "\"iii\""
  @test enforce_quote_consistency("out0\"in1\"out1\$in2\"int2\"ot3\"int3", "ooo\"",   14, 17; charQuote='\"', verbose=false) == "ooo\"\"" 
  @test enforce_quote_consistency("out0\"in1\"out1\$in2\"int2\"ot3\"int3", "\"iii",   14, 17; charQuote='\"', verbose=false) == "\"iii\"" 
                                  #1234 5678 90123 4 567890123 4567 89012
  @test enforce_quote_consistency("out0\"in1\"out1\"\$iii jjj2\"ot2\"int3", "out",     15, 18; charQuote='\"', verbose=false) == "\"out\""
  @test enforce_quote_consistency("out0\"in1\"out1\"\$iii jjj2\"ot2\"int3", "o\"i\"o", 15, 18; charQuote='\"')                == "\"o\"i\"o\""
  @test enforce_quote_consistency("out0\"in1\"out1\"\$iii jjj2\"ot2\"int3", "\"iii\"", 15, 18; charQuote='\"')                == "\"\"iii\"\""
  @test enforce_quote_consistency("out0\"in1\"out1\"\$in2 jjj2\"ot3\"int3", "ooo\"",   15, 18; charQuote='\"', verbose=false) == "\"ooo\"" 
  @test enforce_quote_consistency("out0\"in1\"out1\"\$in2 jjj2\"ot3\"int3", "\"iii",   15, 18; charQuote='\"', verbose=false) == "\"\"iii" 

  @test enforce_quote_consistency("out0\"in1\"out1\"\$in2 jjj2\"ot3\"int3", "ooo\"iii",   15, 18; charQuote='\"', verbose=false) == "\"ooo\"iii"
  @test enforce_quote_consistency("out0\"in1\"out1\"\$in2 jjj2\"ot3\"int3", "\"iii\"ooo",   15, 18; charQuote='\"', verbose=false) == "\"\"iii\"ooo\""

                                  #1234 5678 90123 4567890123 4567 89012
  @test enforce_quote_consistency("out0\"in1\"out1\${VAR}out2\"in2\"out3", "ooo", 14, 19; charQuote='\"') == "ooo"
  @test enforce_quote_consistency("out0\"in1\"out1\${VAR}out2\"in2\"out3", "\"iii\"", 14, 19; charQuote='\"') == "\"iii\""
  @test enforce_quote_consistency("out0\"in1\"out1\${VAR}out2\"in2\"out3", "xo\"iii\"yo", 14, 19; charQuote='\"') == "xo\"iii\"yo"
  @test enforce_quote_consistency("out0\"in1\"out1\${VAR}out2\"in2\"out3", "xo\"iii", 14, 19; charQuote='\"') == "xo\"iii\""
  @test enforce_quote_consistency("out0\"in1\"out1\${VAR}out2\"in2\"out3", "xooo\"yo", 14, 19; charQuote='\"') == "xooo\"yo\""
                                  #12 345 67890123 456 789 0
  @test enforce_quote_consistency("o1\"i1\${VAR}i2\"o2\"i3\"", "x1\"y1\${val}x2\"y2\"x3\"", 6, 11; charQuote='\"') == "\"x1\"y1\${val}x2\"y2\"x3\"\""
  # assign_quote_state("o1\"i1\${VAR}i2\"o2\"i3\"", '\"')'
  # assign_quote_state("x1\"y1\${val}x2\"y2\"x3\"", '\"')'
  # assign_quote_state(substitute_string("o1\"i1\${VAR}i2\"o2\"i3\"", enforce_quote_consistency("o1\"i1\${VAR}i2\"o2\"i3\"", "x1\"y1\${val}x2\"y2\"x3\"", 6, 11; charQuote='\"'), 6, 11), '\"')'

  # adapt_quotation=true -> Attemt to keep the pattern of quotation consistent before and after substitution by inserting quotes
  @test expandnameafterdollar("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "VAR", "\"value\""; adapt_quotation=false) == "out0\"in1\"out1\"\"value\"\"out2\"in2\"out3"
  @test expandnameafterdollar("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "VAR", "\"value\""; adapt_quotation=true) == "out0\"in1\"out1\"\"\"value\"\"\"out2\"in2\"out3"
  @test expandnameafterdollar("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "VAR", "value"; adapt_quotation=true) == "out0\"in1\"out1\"\"value\"\"out2\"in2\"out3"
  @test expandnameafterdollar("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "VAR", "v\"al\"ue"; adapt_quotation=true) == "out0\"in1\"out1\"\"v\"al\"ue\"\"out2\"in2\"out3"
  @test expandnameafterdollar("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "VAR", "\"va\"l\"ue\""; adapt_quotation=true) == "out0\"in1\"out1\"\"\"va\"l\"ue\"\"\"out2\"in2\"out3"
  @test expandnameafterdollar("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "VAR", "\"value"; adapt_quotation=true) == "out0\"in1\"out1\"\"\"value\"out2\"in2\"out3"
  @test expandnameafterdollar("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "VAR", "va\"lue"; adapt_quotation=true) == "out0\"in1\"out1\"\"va\"lue\"out2\"in2\"out3"
  @test expandnameafterdollar("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "VAR", "value\""; adapt_quotation=true) == "out0\"in1\"out1\"\"value\"\"out2\"in2\"out3"
  @test expandnameafterdollar("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", "VAR", "\"v\"\"a\"\"l\"\"u\"\"e\""; adapt_quotation=true) == "out0\"in1\"out1\"\"\"v\"\"a\"\"l\"\"u\"\"e\"\"\"out2\"in2\"out3"

  ## expandmanyafterdollars
  testString = "start in\$VAR1 string \"\${VAR2}\"/unit_tests/ foo\${VAR0#*} bar\${VAR0%afd} baz\${VAR0:?asdf} boo\${VAR0?!*} moo\${VAR0\$!*} \"sample\"\"\$VAR3\"\".txt\""
  expString  = "start in111 string \"222\"/unit_tests/ foo\${VAR0#*} bar\${VAR0%afd} baz\${VAR0:?asdf} boo\${VAR0?!*} moo\${VAR0\$!*} \"sample\"\"\$VAR3\"\".txt\""
  @test expandmanyafterdollars(testString, ["VAR0", "VAR1", "VAR2"], ["000", "111", "222"]) == expString
  @test expandmanyafterdollars("aa\"bb/\$DIR_BASE\"", ["DIR_BASE", "VAR1", "VAR2"], ["/path/some/where/", "AAA", "BBB"]) == "aa\"bb//path/some/where/\""

  @test expandmanyafterdollars("oo\"ii\"oo\"\$VAR1\"_\${VAR3}_ \$VAR2 \"ii\"oo", ["VAR1", "VAR2", "VAR3"], ["|inv|", "|ouv|", "|curly|"], adapt_quotation=false) == "oo\"ii\"oo\"|inv|\"_|curly|_ |ouv| \"ii\"oo"
  @test expandmanyafterdollars("oo\"ii\"oo\"\$VAR1\"_\${VAR3}_ \$VAR2 \"ii\"oo", ["VAR1", "VAR2", "VAR3"], ["|inv|", "|ouv|", "|curly|"], adapt_quotation=true)  == "oo\"ii\"oo\"\"|inv|\"\"_|curly|_ |ouv| \"ii\"oo"
  @test expandmanyafterdollars("oo\"ii\"oo\"\$VAR1\"_\${VAR3}_ \$VAR2 \"ii\"oo", ["VAR1", "VAR2", "VAR3"], ["\"|inv|\"", "|ouv|", "\"|curly|\""], adapt_quotation=true)  == "oo\"ii\"oo\"\"\"|inv|\"\"\"_\"|curly|\"_ |ouv| \"ii\"oo"

  ## enforce_closingquote
  @test enforce_closingquote("a", '\"') == "a"
  @test enforce_closingquote("\"a", '\"') == "\"a\""
  @test enforce_closingquote("a\"", '\"') == "a\"\""
  @test enforce_closingquote("\"a\"", '\"') == "\"a\""
  @test enforce_closingquote("abc", '\"') == "abc"
  @test enforce_closingquote("\"abc", '\"') == "\"abc\""
  @test enforce_closingquote("abc\"", '\"') == "abc\"\""
  @test enforce_closingquote("\"abc\"", '\"') == "\"abc\""
  @test enforce_closingquote("string  \${VAR}, \$VAR1 \"\"\$VAR2\"", '\"') == "string  \${VAR}, \$VAR1 \"\"\$VAR2\"\""

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
  @test expand_inarrayofarrays(testArr, [2,4], ["VAR0", "VAR1", "VAR2"], ["000", "111", "222"]; verbose=false) == expArr

  testArr = []
  push!(testArr, ["# first comment string \${VAR}, \$VAR1 \"\"\$VAR2\""])
  push!(testArr, ["string \${VAR}, \$VAR1 \"\$VAR2\""])
  push!(testArr, ["# second comment string  \${VAR}, \$VAR1 \"\"\$VAR2\""])
  push!(testArr, ["string  \${VAR}, \$VAR1 \"\$VAR2\""])
  push!(testArr, ["# third comment string  \${VAR}, \$VAR1 \"\"\$VAR2\""])
  expArr = []
  push!(expArr, ["# first comment string \${VAR}, \$VAR1 \"\"\$VAR2\""])
  push!(expArr, ["string \${VAR}, 111 \"\"222\"\""])
  push!(expArr, ["# second comment string  \${VAR}, \$VAR1 \"\"\$VAR2\""])
  push!(expArr, ["string  \${VAR}, 111 \"\"222\"\""])
  push!(expArr, ["# third comment string  \${VAR}, \$VAR1 \"\"\$VAR2\""])
  @test expand_inarrayofarrays(testArr, [2,4], ["VAR0", "VAR1", "VAR2"], ["000", "111", "222"], verbose=false, adapt_quotation=true) == expArr

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
   "\"../../../jsub_pipeliner/\""
   "\"utbash space.sh\""                    
   "\"\$dolla\""                            
   "\"Hello spaces and tabs\tand...\"" 
  ]
  expArr = []
  push!(expArr, ["# This file contains the names of varibales, column numbers and source file paths from which the value of the variable should be taken."])
  push!(expArr, ["# <variable name>\t<column in file>\t<file path>"])
  push!(expArr, ["LANE_NUM","0","\"\"../../../jsub_pipeliner/\"\"/\"unit_tests/lists/multiLane_\"'\"1\"'\"col.txt\""])
  push!(expArr, ["# The zero in the <column in file> field indicates that all columns shold be used (or treated as one column)"])
  push!(expArr, ["SAMPLEID","1","\"\"../../../jsub_pipeliner/\"\"/\"unit_tests/lists/sampleIDs_1col.txt\""])
  push!(expArr, ["# The value of DIR_BASE is declared in refs_samples.vars"])
  @test expand_inarrayofarrays(arrArr, rows, varNames, varVals; verbose=true) == expArr
  # arrArr=arrFvars; rows=cmdRowsFvars; varNames=namesVars; varVals=valuesVars; verbose=true;
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
   "\"../../../jsub_pipeliner/\""
   "\"utbash space.sh\""                    
   "\"\$dolla\""                            
   "\"Hello spaces and tabs\tand...\"" 
  ]
  expArr = []
  push!(expArr, ["# This file contains the names of varibales, column numbers and source file paths from which the value of the variable should be taken."])
  push!(expArr, ["# <variable name>\t<column in file>\t<file path>"])
  push!(expArr, ["LANE_NUM","0","\"\"\"../../../jsub_pipeliner/\"\"\"/\"unit_tests/lists/multiLane_\"'\"1\"'\"col.txt\""])
  push!(expArr, ["# The zero in the <column in file> field indicates that all columns shold be used (or treated as one column)"])
  push!(expArr, ["SAMPLEID","1","\"\"\"../../../jsub_pipeliner/\"\"\"/\"unit_tests/lists/sampleIDs_1col.txt\""])
  push!(expArr, ["# The value of DIR_BASE is declared in refs_samples.vars"])
  @test expand_inarrayofarrays(arrArr, rows, varNames, varVals; verbose=true, adapt_quotation=true) == expArr

  ## sanitizepath
  testPath = "\"\$DIR_BASE\"/\"unit_tests/lists/multiLane_\"\'\"1\"\'\"col.txt\""
  expPath = "\$DIR_BASE/unit_tests/lists/multiLane_\"1\"col.txt"
  @test sanitizepath(testPath) == expPath

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
  "\"../../../jsub_pipeliner\""
  "\"../../../output_testing_jsub\""
  "\"\$DIR_BASE\"/\"unit_tests/data/header_coordinate\""
  "\"\$DIR_BASE\"/\"unit_tests/data/hg19.chrom.sizes\""
  "\"\$DIR_OUTPUT\"/\"utSplit_refFile.txt\""
  "\"\$DIR_OUTPUT\"/\"utSplit_out1_\""
  "\"_valueVar1_\""
  "\"_valueVar\$VAR1_\""
  "\"_valueVar\$VAR2_\""
  ]
  @test parse_varsfile(pathToTestVars) == (expNamesRaw, expValuesRaw)

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
  "\"../../../jsub_pipeliner\""              
  "\"../../../output_testing_jsub\""
  "\"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\""
  "\"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\"" 
  "\"\"../../../output_testing_jsub\"\"/\"utSplit_refFile.txt\""            
  "\"\"../../../output_testing_jsub\"\"/\"utSplit_out1_\""                  
  "\"_valueVar1_\""                                     
  "\"_valueVar\$VAR1_\""                                
  "\"_valueVar\$VAR2_\"" 
  ]
  @test expandinorder(namesVarsRaw, valuesVarsRaw) == (expNames, expValues)

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
  "\"../../../jsub_pipeliner\""
  "\"../../../output_testing_jsub\""
  "\"\"\"../../../jsub_pipeliner\"\"\"/\"unit_tests/data/header_coordinate\""
  "\"\"\"../../../jsub_pipeliner\"\"\"/\"unit_tests/data/hg19.chrom.sizes\""
  "\"\"\"../../../output_testing_jsub\"\"\"/\"utSplit_refFile.txt\""
  "\"\"\"../../../output_testing_jsub\"\"\"/\"utSplit_out1_\""
  "\"_valueVar1_\""
  "\"_valueVar\$VAR1_\""
  "\"_valueVar\$VAR2_\""
  ]
  @test expandinorder(namesVarsRaw, valuesVarsRaw, adapt_quotation=true) == (expNames, expValues)

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
  "\"../../../jsub_pipeliner/\"",
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
  @test parse_varsfile(fileVars, dlmVars="\t") == (expNames1, expValues1)

  fileFvars="jlang_function_test_files/refs_samples.fvars"
  expNamesFvars=["LANE_NUM", "SAMPLEID"];
  expInfileColumnsFvars=["0","1"];
  expFilePathsFvars=[
  "../../../jsub_pipeliner//unit_tests/lists/multiLane_\"1\"col.txt",
  "../../../jsub_pipeliner//unit_tests/lists/sampleIDs_1col.txt"
  ];
  @test parse_expandvars_fvarsfile(fileFvars, expNames1, expValues1, dlmFvars="\t", verbose=false, adapt_quotation=false) == (expNamesFvars, expInfileColumnsFvars, expFilePathsFvars)

  fileFvars="jlang_function_test_files/refs_samples.fvars"
  expNamesFvars=["LANE_NUM", "SAMPLEID"];
  expInfileColumnsFvars=["0","1"];
  expFilePathsFvars=[
  "../../../jsub_pipeliner//unit_tests/lists/multiLane_\"1\"col.txt",
  "../../../jsub_pipeliner//unit_tests/lists/sampleIDs_1col.txt"
  ];
  @test parse_expandvars_fvarsfile(fileFvars, expNames1, expValues1, dlmFvars="\t", verbose=false, adapt_quotation=true) == (expNamesFvars, expInfileColumnsFvars, expFilePathsFvars)  

  ## parse_expandvars_in_protocol
  fileProtocol="jlang_function_test_files/refs_samples.protocol"
  expCmdRowsProt=[

  ];
  expArrProt=[

  ];
  parse_expandvars_protocol(fileProtocol, expNames1, expValues1; adapt_quotation=false, verbose=true) == (expArrProt, expCmdRowsProt)

  ## parse_expandvars_in_listfiles

  ## expandvars_in_protocol

#PRODIG

  ########################################

  # Report if there were any suppressed warnings
  if num_suppressed[1] > 0
    println("Suppressed ", num_suppressed[1], " warnings.  These unit tests intentionally include cases that produce warnings.");
  end

  # Report number of test passes, fails and exceptions
  ut_report(ut_counter)

end # Test.with_handler(ut_handler) do
########################################
########################################
########################################
# EOF




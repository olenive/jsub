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
function compare_arrays(arrA, arrB)
  arrFalses = []
  if length(arrA) != length(arrB)
    println("Different lengths!")
  end
  for idx = 1:length(arrA)
    # println(arrA[idx] == arrB[idx])
    try
      if (arrA[idx] != arrB[idx])
        push!(arrFalses, idx)
        println(" -- Mismatch on line: ", idx)
        println(arrA[idx], "\n", arrB[idx])
        println("\n")
      end
    catch
      print(" -- Remaining unmatched lines:")
      if idx <= length(arrA)
        print(" from array A\n");
        println(arrA[idx]);
      end
      if idx <= length(arrB)
        print(" from array B\n");
        println(arrB[idx]);
      end
    end
  end
  return arrFalses
end 
###############

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
function inc()
  include("../../common_functions/jsub_common.jl")
end

# Load test files
pathToTestProtocol = "jlang_function_test_files/refs_samples.protocol"
pathToTestVars = "jlang_function_test_files/refs_samples.vars"
pathToTestFvars = "jlang_function_test_files/refs_samples.fvars"

########################################
######## Run tests on functions ########
########################################
### For each function, declare input argument and expected output, then run the function and check that the outcome matches what is expected.
println("\nRunning unit tests of julia functions...")
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

  ## remove_prefix(long, prefix)
  @test remove_prefix("summary.summary.summar.summary.summary", "summary.") == "summary.summar.summary.summary"
  @test remove_prefix("summary.summary.summar.summary.summaryX", "summary.") == "summary.summar.summary.summaryX"
  @test remove_prefix("\n#BSUB", "\n") == "#BSUB"

  ## remove_suffix(long, suffix)
  @test remove_suffix("summary.summary.summar.summary.summary", ".summary") == "summary.summary.summar.summary"
  @test remove_suffix("summary.summary.summar.summary.summaryX", ".summary") == "summary.summary.summar.summary.summaryX"

  ## file2arrayofarrays_
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
  push!(expArrVars, ["DIR_OUTPUT", "\"\$DIR_BASE/output_testing_jsub\""])
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

  @test file2arrayofarrays_("jlang_function_test_files/refs_samples.vars", "#") == (expArrVars, expCmdRowsVars)

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

  @test file2arrayofarrays_(pathToTestFvars, "#") == (expArrFvars, expCmdRowsFvars)

  pathToTestSummary = "jlang_function_test_files/summary_files/ut_summary_tags.txt"
  suppliedTagsExpand = Dict(
    "tagSummaryName" => "#JSUB<summary-name>",
    "tagSplit" => "#JGROUP"
  )
  expectedSummary = [];
  push!(expectedSummary, ["# This data would come from reading summary files."]);
  push!(expectedSummary, ["#JSUB<summary-name>ProtocolName"]);
  push!(expectedSummary, ["bash echo \"cmd 1\""]);
  push!(expectedSummary, ["#JGROUP first"]);
  push!(expectedSummary, ["bash echo \"cmd 12\""]);
  push!(expectedSummary, ["bash echo \"cmd 13\""]);
  push!(expectedSummary, ["#JGROUP second first"]);
  push!(expectedSummary, ["bash echo \"cmd 21\""]);
  push!(expectedSummary, ["bash echo \"cmd 22\""]);
  expectedIndices = [2,3,4,5,6,7,8,9]
  @test file2arrayofarrays_(pathToTestSummary, "#", cols=1, tagsExpand=suppliedTagsExpand) == (expectedSummary, expectedIndices)
  expectedIndices = [3,5,6,8,9]
  @test file2arrayofarrays_(pathToTestSummary, "#", cols=1) == (expectedSummary, expectedIndices)

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

  ## is_escaped(inString, position, charEscape)
  @test_throws BoundsError is_escaped("", 0, '\\')
  @test is_escaped("", 1, '\\') == false
  @test is_escaped("A", 1, '\\') == false
  @test is_escaped("AB", 2, '\\') == false
  @test is_escaped("\\B", 2, '\\') == true
  @test is_escaped("\\B", 1, '\\') == false
  @test is_escaped("\\\\B", 1, '\\') == false
  @test is_escaped("\\\\B", 2, '\\') == true
  @test is_escaped("\\\\B", 3, '\\') == false
                  #  \ \ \B
  @test is_escaped("\\\\\\B", 4, '\\') == true
  @test is_escaped("\\\\\\\\B", 5, '\\') == false
                  # 12 345 67 8
  @test is_escaped("he\"ll\\o\"", 6, '\\') == false

  ## remove_nonescaped_quotes(line, charQuote::Char, charEscape::Char)
  @test remove_nonescaped("hello", '\"', '\\') == "hello"
  @test remove_nonescaped("he\"llo", '\"', '\\') == "hello"
  @test remove_nonescaped("he\\\"llo", '\"', '\\') == "he\\\"llo"
  @test remove_nonescaped("he\\\"ll\\\"o\\\"", '\"', '\\') == "he\\\"ll\\\"o\\\""
  @test remove_nonescaped("he\\\"ll\"o\\\"", '\"', '\\') == "he\\\"llo\\\""
                         # 12 345 67 8
  @test remove_nonescaped("he\\\"llo\\\"", '\\', '\\') == "he\"llo\""
  @test remove_nonescaped(remove_nonescaped("he\\\"ll\"o\\\"", '\"', '\\'), '\\', '\\') == "he\"llo\""

  ## assign_quote_state(inString, charQuote) # For each character in the input and output string assign a 0 if it is outside quotes or a 1 if it is inside quotes or a 2 if it is a quote character
  @test assign_quote_state("A\"B\"", '\"') == [0, 2, 1, 2]
                           #1234 5678 90123 4 5678 90123 4567 89012            #1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6  7  8  9  0  1  2
  @test assign_quote_state("out0\"in1\"out1\"\$VAR\"out2\"in2\"out3", '\"') == [0, 0, 0, 0, 2, 1, 1, 1, 2, 0, 0, 0, 0, 2, 1, 1, 1, 1, 2, 0, 0, 0, 0, 2, 1, 1, 1, 2, 0, 0, 0, 0]
  @test assign_quote_state("out0\"in1\"out1\"\"val\"\"out2\"in2\"out3", '\"') == [0, 0, 0, 0, 2, 1, 1, 1, 2, 0, 0, 0, 0, 2, 2, 0, 0, 0, 2, 2, 0, 0, 0, 0, 2, 1, 1, 1, 2, 0, 0, 0, 0]
  @test assign_quote_state("out0\"in1\"out1\"\"\"val\"\"\"out2\"in2\"out3", '\"') == [0, 0, 0, 0, 2, 1, 1, 1, 2, 0, 0, 0, 0, 2, 2, 2, 1, 1, 1, 2, 2, 2, 0, 0, 0, 0, 2, 1, 1, 1, 2, 0, 0, 0, 0]
                           # 123456 78 901234 56
  @test assign_quote_state("\"Hello\" \"World\"", '\"') == [2,1,1,1,1,1,2,0,2,1,1,1,1,1,2]
  @test assign_quote_state("\"Hello\" \"Sky", '\"') == [2,1,1,1,1,1,2,0,2,1,1,1]
  # Test default escape character cases
                          # A "B \ "
  @test assign_quote_state("A\"B\\\"", '\"') == [0,2,1,1,1]
                          #  \ "A \ " 
  @test assign_quote_state("\\\"A\\\"", '\"') == [0,0,0,0,0]
                          #  \ \ "A \ \ " 
  @test assign_quote_state("\\\\\"A\\\\\"", '\"') == [0,0,2,1,1,1,2]
                          #  \ \ \ "A \ \ \ " 
  @test assign_quote_state("\\\\\\\"A\\\\\\\"", '\"') == [0,0,0,0,0,0,0,0,0]
                          #  \ \ \ "A \ \ \ "X 
  @test assign_quote_state("\\\\\\\"A\\\\\\\"X", '\"') == [0,0,0,0,0,0,0,0,0,0]
                          #  \ \ \ \ "A \ \ \ \ " 
  @test assign_quote_state("\\\\\\\\\"A\\\\\\\\\"", '\"') == [0,0,0,0,2,1,1,1,1,1,2]
                          #  \ \ \ \ "A \ \ \ \ "X 
  @test assign_quote_state("\\\\\\\\\"A\\\\\\\\\"X", '\"') == [0,0,0,0,2,1,1,1,1,1,2,0]
  @test assign_quote_state("", '\"') == []
  @test assign_quote_state("A\"B\\\"CD\"EF", '\"') == [0, 2, 1, 1, 1, 1, 1, 2, 0, 0]
  @test assign_quote_state("A\"B\\\\\"CD\"EF", '\"') == [0, 2, 1, 1, 1, 2, 0, 0, 2, 1, 1] # backslash is escaped by a backslash
                          # 0 21 1 1 200 211
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
  # Escaped quote test cases
                                                        #1 2 34 567 89 0 1
  @test get_index_of_first_and_last_nonquote_characters("1\\\"2\"45\"7\\\"", '\"') == (1, 11)
  @test get_index_of_first_and_last_nonquote_characters("\"\\\"2\"45\"7\\\"", '\"') == (2, 11)

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
  # Test with the keep_superfluous_quotes=false option
  @test expandmanyafterdollars("\$FOO", ["FOO"], ["BAR"]; keep_superfluous_quotes=false) == "BAR"
  @test expandmanyafterdollars("\$FOO\"", ["FOO"], ["BAR"]; keep_superfluous_quotes=false) == "BAR"
  @test expandmanyafterdollars("\$FOO\"\"", ["FOO"], ["BAR"]; keep_superfluous_quotes=false) == "BAR"
  @test expandmanyafterdollars("\$FOO\"\"xx", ["FOO"], ["BAR"]; keep_superfluous_quotes=false) == "BARxx"
  @test expandmanyafterdollars("\$FOO\"\"\"xx", ["FOO"], ["BAR"]; keep_superfluous_quotes=false) == "BAR\"xx"

  remove_superfluous_quotes("BAR\"\"xx", '\"', 2, 1)

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

  testArr = []
  push!(testArr, ["# first comment string \${VAR}, \$VAR1 \"\"\$VAR2\""])
  push!(testArr, ["string \${VAR}, \$VAR1 \"\$VAR2\""])
  push!(testArr, ["# second comment string  \${VAR}, \$VAR1 \"\"\$VAR2\""])
  push!(testArr, ["string  \${VAR}, \$VAR1 \"\$VAR2\""])
  push!(testArr, ["# third comment string  \${VAR}, \$VAR1 \"\"\$VAR2\""])
  expArr = []
  push!(expArr, ["# first comment string \${VAR}, 111 \"\"222\"\""])
  push!(expArr, ["string \${VAR}, 111 \"\"222\"\""])
  push!(expArr, ["# second comment string  \${VAR}, \$VAR1 \"\"\$VAR2\""])
  push!(expArr, ["string  \${VAR}, 111 \"\"222\"\""])
  push!(expArr, ["# third comment string  \${VAR}, \$VAR1 \"\"\$VAR2\""])
  @test expand_inarrayofarrays(testArr, [1,2,4], ["VAR0", "VAR1", "VAR2"], ["000", "111", "222"], verbose=false, adapt_quotation=true) == expArr


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
  @test expand_inarrayofarrays(arrArr, rows, varNames, varVals; verbose=false) == expArr
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
  @test expand_inarrayofarrays(arrArr, rows, varNames, varVals; verbose=false, adapt_quotation=true) == expArr

  ## sanitizepath
  testPath = "\"\$DIR_BASE\"/\"unit_tests/lists/multiLane_\"\'\"1\"\'\"col.txt\""
  expPath = "\$DIR_BASE/unit_tests/lists/multiLane_\"1\"col.txt"
  @test sanitizepath(testPath) == expPath

  ## parse_varsfile_
  # pathToTestVars = "jlang_function_test_files/refs_samples.vars"
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
  "\"\$DIR_BASE/output_testing_jsub\""
  "\"\$DIR_BASE\"/\"unit_tests/data/header_coordinate\""
  "\"\$DIR_BASE\"/\"unit_tests/data/hg19.chrom.sizes\""
  "\"\$DIR_OUTPUT\"/\"utSplit_refFile.txt\""
  "\"\$DIR_OUTPUT\"/\"utSplit_out1_\""
  "\"_valueVar1_\""
  "\"_valueVar\$VAR1_\""
  "\"_valueVar\$VAR2_\""
  ]
  @test parse_varsfile_("jlang_function_test_files/refs_samples.vars") == (expNamesRaw, expValuesRaw)

  ## expandinorder
  # namesVarsRaw, valuesVarsRaw = parse_varsfile_(pathToTestVars)
  namesVarsRaw = [
  "DIR_BASE"
  "DIR_OUTPUT"
  "PRE_REF_FILE1"
  "PRE_REF_FILE2"
  "REF_FILE"
  "SAMPLE_OUTPUT_1"
  "VAR1"
  "VAR\$VAR1"
  "VAR\$VAR2"
  ];
  valuesVarsRaw = [
  "\"../../../jsub_pipeliner\""
  "\"\$DIR_BASE/output_testing_jsub\""
  "\"\$DIR_BASE\"/\"unit_tests/data/header_coordinate\""
  "\"\$DIR_BASE\"/\"unit_tests/data/hg19.chrom.sizes\""
  "\"\$DIR_OUTPUT\"/\"utSplit_refFile.txt\""
  "\"\$DIR_OUTPUT\"/\"utSplit_out1_\""
  "\"_valueVar1_\""
  "\"_valueVar\$VAR1_\""
  "\"_valueVar\$VAR2_\""
  ];
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
  ];
  expValues = [
  "\"../../../jsub_pipeliner\""
  "\"\"../../../jsub_pipeliner\"/output_testing_jsub\""
  "\"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\""
  "\"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\""
  "\"\"\"../../../jsub_pipeliner\"/output_testing_jsub\"\"/\"utSplit_refFile.txt\""
  "\"\"\"../../../jsub_pipeliner\"/output_testing_jsub\"\"/\"utSplit_out1_\""
  "\"_valueVar1_\""
  "\"_valueVar\$VAR1_\""
  "\"_valueVar\$VAR2_\"" 
  ];
  @test expandinorder(namesVarsRaw, valuesVarsRaw, adapt_quotation=false) == (expNames, expValues)

  namesVarsRaw = [
  "DIR_BASE"
  "DIR_OUTPUT"
  "PRE_REF_FILE1"
  "PRE_REF_FILE2"
  "REF_FILE"
  "SAMPLE_OUTPUT_1"
  "VAR1"
  "VAR\$VAR1"
  "VAR\$VAR2"
  ];
  valuesVarsRaw = [
  "\"../../../jsub_pipeliner\""
  "\"\$DIR_BASE/output_testing_jsub\""
  "\"\$DIR_BASE\"/\"unit_tests/data/header_coordinate\""
  "\"\$DIR_BASE\"/\"unit_tests/data/hg19.chrom.sizes\""
  "\"\$DIR_OUTPUT\"/\"utSplit_refFile.txt\""
  "\"\$DIR_OUTPUT\"/\"utSplit_out1_\""
  "\"_valueVar1_\""
  "\"_valueVar\$VAR1_\""
  "\"_valueVar\$VAR2_\""
  ];
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
  ];
  expValues = [
  "\"../../../jsub_pipeliner\""
  "\"\"\"../../../jsub_pipeliner\"\"/output_testing_jsub\""
  "\"\"\"../../../jsub_pipeliner\"\"\"/\"unit_tests/data/header_coordinate\""
  "\"\"\"../../../jsub_pipeliner\"\"\"/\"unit_tests/data/hg19.chrom.sizes\""
  "\"\"\"\"\"../../../jsub_pipeliner\"\"/output_testing_jsub\"\"\"/\"utSplit_refFile.txt\""
  "\"\"\"\"\"../../../jsub_pipeliner\"\"/output_testing_jsub\"\"\"/\"utSplit_out1_\""
  "\"_valueVar1_\""
  "\"_valueVar\$VAR1_\""
  "\"_valueVar\$VAR2_\"" 
  ];
  @test expandinorder(namesVarsRaw, valuesVarsRaw, adapt_quotation=true) == (expNames, expValues)

  ## parse_varsfile_
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
  @test parse_varsfile_(fileVars, dlmVars="\t") == (expNames1, expValues1)

  fileFvars="jlang_function_test_files/refs_samples.fvars"
  expNamesFvars=["LANE_NUM", "SAMPLEID"];
  expInfileColumnsFvars=["0","1"];
  expFilePathsFvars=[
  "../../../jsub_pipeliner//unit_tests/lists/multiLane_\"1\"col.txt",
  "../../../jsub_pipeliner//unit_tests/lists/sampleIDs_1col.txt"
  ];
  @test parse_expandvars_fvarsfile_(fileFvars, expNames1, expValues1, dlmFvars="\t", verbose=false, adapt_quotation=false) == (expNamesFvars, expInfileColumnsFvars, expFilePathsFvars)

  fileFvars="jlang_function_test_files/refs_samples.fvars"
  expNamesFvars=["LANE_NUM", "SAMPLEID"];
  expInfileColumnsFvars=["0","1"];
  expFilePathsFvars=[
  "../../../jsub_pipeliner//unit_tests/lists/multiLane_\"1\"col.txt",
  "../../../jsub_pipeliner//unit_tests/lists/sampleIDs_1col.txt"
  ];
  @test parse_expandvars_fvarsfile_(fileFvars, expNames1, expValues1, dlmFvars="\t", verbose=false, adapt_quotation=true) == (expNamesFvars, expInfileColumnsFvars, expFilePathsFvars)  

  ## parse_expandvars_in_protocol
  expNamesIn0 = [
  "DIR_BASE"
  "DIR_OUTPUT"
  "PRE_REF_FILE1"
  "PRE_REF_FILE2"
  "REF_FILE"
  "SAMPLE_OUTPUT_1"
  "VAR1"
  "VAR\$VAR1"
  "VAR\$VAR2"
  ];
  expValuesIn0 = [
  "\"../../../jsub_pipeliner\""
  "\"\"../../../jsub_pipeliner\"/output_testing_jsub\""
  "\"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\""
  "\"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\""
  "\"\"\"../../../jsub_pipeliner\"/output_testing_jsub\"\"/\"utSplit_refFile.txt\""
  "\"\"\"../../../jsub_pipeliner\"/output_testing_jsub\"\"/\"utSplit_out1_\""
  "\"_valueVar1_\""
  "\"_valueVar\$VAR1_\""
  "\"_valueVar\$VAR2_\"" 
  ];
  fileProtocol="jlang_function_test_files/refs_samples.protocol"
  expCmdRowsProt=[2,3];
  expArrProt=[]
  push!(expArrProt, ["# A very minimalistic hypothetical protocol file"])
  push!(expArrProt, ["bash \"../../../jsub_pipeliner\"/somescript.sh  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" \"\"\"../../../jsub_pipeliner\"/output_testing_jsub\"\"/\"utSplit_out1_\""])
  push!(expArrProt, ["python \"\"../../../jsub_pipeliner\"\"/\"therscript.py\" \"\"\"\"../../../jsub_pipeliner\"/output_testing_jsub\"\"/\"utSplit_out1_\"\" \"\"../../../jsub_pipeliner\"/output_testing_jsub\"/\"processed1.txt\""])
  push!(expArrProt, ["# The end"])
  @test parse_expandvars_protocol_(fileProtocol, expNamesIn0, expValuesIn0; adapt_quotation=false, verbose=false) == (expArrProt, expCmdRowsProt)

  expNamesIn1 = [
  "DIR_BASE"
  "DIR_OUTPUT"
  "PRE_REF_FILE1"
  "PRE_REF_FILE2"
  "REF_FILE"
  "SAMPLE_OUTPUT_1"
  "VAR1"
  "VAR\$VAR1"
  "VAR\$VAR2"
  ];
  expValuesIn1 = [
  "\"../../../jsub_pipeliner\""
  "\"\"../../../jsub_pipeliner\"/output_testing_jsub\""
  "\"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\""
  "\"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\""
  "\"\"\"../../../jsub_pipeliner\"/output_testing_jsub\"\"/\"utSplit_refFile.txt\""
  "\"\"\"../../../jsub_pipeliner\"/output_testing_jsub\"\"/\"utSplit_out1_\""
  "\"_valueVar1_\""
  "\"_valueVar\$VAR1_\""
  "\"_valueVar\$VAR2_\"" 
  ];
  fileProtocol="jlang_function_test_files/refs_samples.protocol"
  expCmdRowsProt=[2,3]; # Blank lines are not counted
  expArrProt=[]
  push!(expArrProt, ["# A very minimalistic hypothetical protocol file"])
  push!(expArrProt, ["bash \"../../../jsub_pipeliner\"/somescript.sh  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" \"\"\"../../../jsub_pipeliner\"/output_testing_jsub\"\"/\"utSplit_out1_\""])
  push!(expArrProt, ["python \"\"\"../../../jsub_pipeliner\"\"\"/\"therscript.py\" \"\"\"\"\"../../../jsub_pipeliner\"/output_testing_jsub\"\"/\"utSplit_out1_\"\"\" \"\"../../../jsub_pipeliner\"/output_testing_jsub\"/\"processed1.txt\""])
  push!(expArrProt, ["# The end"])
  @test parse_expandvars_protocol_(fileProtocol, expNamesIn1, expValuesIn1; adapt_quotation=true, verbose=false) == (expArrProt, expCmdRowsProt)

  ## parse_expandvars_listfiles_(filePathsFvars, namesVars, valuesVars, dlmFvars; verbose=false, adapt_quotation=false)
  fileFvars="jlang_function_test_files/refs_samples.fvars"
  supNamesFvars=["LANE_NUM", "SAMPLEID"];
  supInfileColumnsFvars=["0","1"];
  supFilePathsFvars=[
  "../../../jsub_pipeliner//unit_tests/lists/multiLane_\"1\"col.txt",
  "../../../jsub_pipeliner//unit_tests/lists/sampleIDs_1col.txt"
  ];
  supNamesIn0 = [
  "DIR_BASE"
  "DIR_OUTPUT"
  "PRE_REF_FILE1"
  "PRE_REF_FILE2"
  "REF_FILE"
  "SAMPLE_OUTPUT_1"
  "VAR1"
  "VAR\$VAR1"
  "VAR\$VAR2"
  ];
  supValuesIn0 = [
  "\"../../../jsub_pipeliner\""
  "\"\"../../../jsub_pipeliner\"/output_testing_jsub\""
  "\"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\""
  "\"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\""
  "\"\"\"../../../jsub_pipeliner\"/output_testing_jsub\"\"/\"utSplit_refFile.txt\""
  "\"\"\"../../../jsub_pipeliner\"/output_testing_jsub\"\"/\"utSplit_out1_\""
  "\"_valueVar1_\""
  "\"_valueVar\$VAR1_\""
  "\"_valueVar\$VAR2_\"" 
  ];
  arrFileContents1 = [];
  push!(arrFileContents1, ["\"path\/to\/\"Lane'\"1\"1'", "path\/to\"Lane\"\"1\"2"]);
  push!(arrFileContents1, ["Lane\"2\"1"]);
  push!(arrFileContents1, ["Lane31", "Lane32", "Lane33"]);
  push!(arrFileContents1, ["Lane41", "Lane42", "Lane43", "Lane44"]);
  push!(arrFileContents1, ["Lane51"]);
  push!(arrFileContents1, ["Lane61"]);
  push!(arrFileContents1, ["Lane71", "Lane72"]);
  arrFileNonCommentLines1 = [1,2,3,4,5,6,7]
  arrFileContents2 = [];
  push!(arrFileContents2, ["Sample001"]);
  push!(arrFileContents2, ["Sample002"]);
  push!(arrFileContents2, ["Sample003"]);
  push!(arrFileContents2, ["Sample004"]);
  push!(arrFileContents2, ["Sample005"]);
  push!(arrFileContents2, ["Sample006"]);
  push!(arrFileContents2, ["Sample007"]);
  arrFileNonCommentLines2 = [1,2,3,4,5,6,7]
  dictListArr = Dict(
  "../../../jsub_pipeliner//unit_tests/lists/multiLane_\"1\"col.txt" => arrFileContents1,
  "../../../jsub_pipeliner//unit_tests/lists/sampleIDs_1col.txt" => arrFileContents2
  )
  dictCmdLineIdxs = Dict(
  "../../../jsub_pipeliner//unit_tests/lists/multiLane_\"1\"col.txt" => arrFileNonCommentLines1,
  "../../../jsub_pipeliner//unit_tests/lists/sampleIDs_1col.txt" => arrFileNonCommentLines2
  )
  @test parse_expandvars_listfiles_(supFilePathsFvars, supNamesIn0, supValuesIn0, "\t"; adapt_quotation=false, verbose=false) == (dictListArr, dictCmdLineIdxs)
  @test parse_expandvars_listfiles_(supFilePathsFvars, supNamesIn0, supValuesIn0, "\t"; adapt_quotation=true, verbose=false) == (dictListArr, dictCmdLineIdxs)

  ## protocol_to_array(arrProt, cmdRowsProt, namesFvars, infileColumnsFvars, filePathsFvars, dictListArr, dictCmdLineIdxs ; verbose = false, adapt_quotation=false)
  # Supplied input
  supArrProt=[]
  push!(supArrProt, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"])
  push!(supArrProt, ["bash \${a_bash_script_dot_sh} \${LANE_NUM} \${SAMPLEID} fileA_\${SAMPLEID}"])
  push!(supArrProt, ["python \${a_python_script_dot_py}                       fileA_\${SAMPLEID}  fileB_\${SAMPLEID}"])
  push!(supArrProt, ["./path/to/binary.exe  fileB_\${SAMPLEID}  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supArrProt, ["# The end"])
  supCmdRowsProt=[2,3,4];
  supNamesFvars=["LANE_NUM", "SAMPLEID"];
  supInfileColumnsFvars=["0","1"];
  supFilePathsFvars=[
  "dummy/path/to/lane_numbers.list", # "../../../jsub_pipeliner//unit_tests/lists/multiLane_\"1\"col.txt",
  "dummy/path/to/sampleIDs.list"  # "../../../jsub_pipeliner//unit_tests/lists/sampleIDs_1col.txt"
  ];
  supNamesIn = [
  "DIR_BASE"
  "DIR_OUTPUT"
  "PRE_REF_FILE1"
  "PRE_REF_FILE2"
  ];
  supValuesIn = [
  "\"../../../jsub_pipeliner\""
  "\"\"../../../jsub_pipeliner\"/output_testing_jsub\""
  "\"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\""
  "\"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\""
  ];
  # These arrays contain data that would be read from list files into dictionaries
  arrFileContents1 = [];
  push!(arrFileContents1, ["\"path\/to\/\"Lane'\"1\"1'", "path\/to\"Lane\"\"1\"2"]);
  push!(arrFileContents1, ["Lane\"2\"1"]);
  push!(arrFileContents1, ["Lane31", "Lane32", "Lane33"]);
  push!(arrFileContents1, ["Lane41", "Lane42", "Lane43", "Lane44"]);
  push!(arrFileContents1, ["Lane51"]);
  push!(arrFileContents1, ["Lane61"]);
  push!(arrFileContents1, ["Lane71", "Lane72"]);
  arrFileNonCommentLines1 = [1,2,3,4,5,6,7]
  arrFileContents2 = [];
  push!(arrFileContents2, ["Sample001"]);
  push!(arrFileContents2, ["Sample002"]);
  push!(arrFileContents2, ["Sample003"]);
  push!(arrFileContents2, ["Sample004"]);
  push!(arrFileContents2, ["Sample005"]);
  push!(arrFileContents2, ["Sample006"]);
  push!(arrFileContents2, ["Sample007"]);
  arrFileNonCommentLines2 = [1,2,3,4,5,6,7];
  supDictListArr = Dict(
  supFilePathsFvars[1] => arrFileContents1,
  supFilePathsFvars[2] => arrFileContents2
  );
  supDictCmdLineIdxs = Dict(
  supFilePathsFvars[1] => arrFileNonCommentLines1,
  supFilePathsFvars[2] => arrFileNonCommentLines2
  );
  # Expected output
  expectedSummaryArrayOfArrays = [];
  expectedSubArray = [];
  push!(expectedSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(expectedSubArray, ["bash \${a_bash_script_dot_sh} \"path\/to\/\"Lane'\"1\"1' path\/to\"Lane\"\"1\"2 Sample001 fileA_Sample001"])
  push!(expectedSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample001  fileB_Sample001"])
  push!(expectedSubArray, ["./path/to/binary.exe  fileB_Sample001  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(expectedSubArray, ["# The end"]);
  push!(expectedSummaryArrayOfArrays, expectedSubArray); expectedSubArray = [];
  push!(expectedSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(expectedSubArray, ["bash \${a_bash_script_dot_sh} Lane\"2\"1 Sample002 fileA_Sample002"])
  push!(expectedSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample002  fileB_Sample002"])
  push!(expectedSubArray, ["./path/to/binary.exe  fileB_Sample002  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(expectedSubArray, ["# The end"]);
  push!(expectedSummaryArrayOfArrays, expectedSubArray); expectedSubArray = [];
  push!(expectedSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(expectedSubArray, ["bash \${a_bash_script_dot_sh} Lane31 Lane32 Lane33 Sample003 fileA_Sample003"])
  push!(expectedSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample003  fileB_Sample003"])
  push!(expectedSubArray, ["./path/to/binary.exe  fileB_Sample003  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(expectedSubArray, ["# The end"]);
  push!(expectedSummaryArrayOfArrays, expectedSubArray); expectedSubArray = [];
  push!(expectedSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(expectedSubArray, ["bash \${a_bash_script_dot_sh} Lane41 Lane42 Lane43 Lane44 Sample004 fileA_Sample004"])
  push!(expectedSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample004  fileB_Sample004"])
  push!(expectedSubArray, ["./path/to/binary.exe  fileB_Sample004  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(expectedSubArray, ["# The end"]);
  push!(expectedSummaryArrayOfArrays, expectedSubArray); expectedSubArray = [];
  push!(expectedSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(expectedSubArray, ["bash \${a_bash_script_dot_sh} Lane51 Sample005 fileA_Sample005"])
  push!(expectedSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample005  fileB_Sample005"])
  push!(expectedSubArray, ["./path/to/binary.exe  fileB_Sample005  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(expectedSubArray, ["# The end"]);
  push!(expectedSummaryArrayOfArrays, expectedSubArray); expectedSubArray = [];
  push!(expectedSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(expectedSubArray, ["bash \${a_bash_script_dot_sh} Lane61 Sample006 fileA_Sample006"])
  push!(expectedSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample006  fileB_Sample006"])
  push!(expectedSubArray, ["./path/to/binary.exe  fileB_Sample006  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(expectedSubArray, ["# The end"]);
  push!(expectedSummaryArrayOfArrays, expectedSubArray); expectedSubArray = [];
  push!(expectedSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(expectedSubArray, ["bash \${a_bash_script_dot_sh} Lane71 Lane72 Sample007 fileA_Sample007"])
  push!(expectedSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample007  fileB_Sample007"])
  push!(expectedSubArray, ["./path/to/binary.exe  fileB_Sample007  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(expectedSubArray, ["# The end"]);
  push!(expectedSummaryArrayOfArrays, expectedSubArray); 
  @test protocol_to_array(supArrProt, supCmdRowsProt, supNamesFvars, supInfileColumnsFvars, supFilePathsFvars, supDictListArr, supDictCmdLineIdxs; verbose=false, adapt_quotation=false) == expectedSummaryArrayOfArrays;
  @test protocol_to_array(supArrProt, supCmdRowsProt, supNamesFvars, supInfileColumnsFvars, supFilePathsFvars, supDictListArr, supDictCmdLineIdxs; verbose=false, adapt_quotation=true) == expectedSummaryArrayOfArrays;
  
  # Again but with #JSUB<summary-name>
  supArrProt=[]
  push!(supArrProt, ["#JSUB<summary-name> sample id is \${SAMPLEID}"])
  push!(supArrProt, ["bash \${a_bash_script_dot_sh} \${LANE_NUM} \${SAMPLEID} fileA_\${SAMPLEID}"])
  push!(supArrProt, ["python \${a_python_script_dot_py}                       fileA_\${SAMPLEID}  fileB_\${SAMPLEID}"])
  push!(supArrProt, ["./path/to/binary.exe  fileB_\${SAMPLEID}  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supArrProt, ["# The end"])
  supCmdRowsProt=[1,2,3,4];
  # These array contain data that would be read from list files into dictionaries
  arrFileContents1 = [];
  push!(arrFileContents1, ["\"path\/to\/\"Lane'\"1\"1'", "path\/to\"Lane\"\"1\"2"]);
  push!(arrFileContents1, ["Lane\"2\"1"]);
  push!(arrFileContents1, ["Lane31", "Lane32", "Lane33"]);
  push!(arrFileContents1, ["Lane41", "Lane42", "Lane43", "Lane44"]);
  push!(arrFileContents1, ["Lane51"]);
  push!(arrFileContents1, ["Lane61"]);
  push!(arrFileContents1, ["Lane71", "Lane72"]);
  arrFileNonCommentLines1 = [1,2,3,4,5,6,7]
  arrFileContents2 = [];
  push!(arrFileContents2, ["Sample001"]);
  push!(arrFileContents2, ["Sample002"]);
  push!(arrFileContents2, ["Sample003"]);
  push!(arrFileContents2, ["Sample004"]);
  push!(arrFileContents2, ["Sample005"]);
  push!(arrFileContents2, ["Sample006"]);
  push!(arrFileContents2, ["Sample007"]);
  arrFileNonCommentLines2 = [1,2,3,4,5,6,7];
  supDictListArr = Dict(
  supFilePathsFvars[1] => arrFileContents1,
  supFilePathsFvars[2] => arrFileContents2
  );
  supDictCmdLineIdxs = Dict(
  supFilePathsFvars[1] => arrFileNonCommentLines1,
  supFilePathsFvars[2] => arrFileNonCommentLines2
  );
  # Expected output
  expectedSummaryArrayOfArrays = [];
  expectedSubArray = [];
  push!(expectedSubArray, ["#JSUB<summary-name> sample id is Sample001"]);
  push!(expectedSubArray, ["bash \${a_bash_script_dot_sh} \"path\/to\/\"Lane'\"1\"1' path\/to\"Lane\"\"1\"2 Sample001 fileA_Sample001"])
  push!(expectedSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample001  fileB_Sample001"])
  push!(expectedSubArray, ["./path/to/binary.exe  fileB_Sample001  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(expectedSubArray, ["# The end"]);
  push!(expectedSummaryArrayOfArrays, expectedSubArray); expectedSubArray = [];
  push!(expectedSubArray, ["#JSUB<summary-name> sample id is Sample002"]);
  push!(expectedSubArray, ["bash \${a_bash_script_dot_sh} Lane\"2\"1 Sample002 fileA_Sample002"])
  push!(expectedSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample002  fileB_Sample002"])
  push!(expectedSubArray, ["./path/to/binary.exe  fileB_Sample002  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(expectedSubArray, ["# The end"]);
  push!(expectedSummaryArrayOfArrays, expectedSubArray); expectedSubArray = [];
  push!(expectedSubArray, ["#JSUB<summary-name> sample id is Sample003"]);
  push!(expectedSubArray, ["bash \${a_bash_script_dot_sh} Lane31 Lane32 Lane33 Sample003 fileA_Sample003"])
  push!(expectedSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample003  fileB_Sample003"])
  push!(expectedSubArray, ["./path/to/binary.exe  fileB_Sample003  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(expectedSubArray, ["# The end"]);
  push!(expectedSummaryArrayOfArrays, expectedSubArray); expectedSubArray = [];
  push!(expectedSubArray, ["#JSUB<summary-name> sample id is Sample004"]);
  push!(expectedSubArray, ["bash \${a_bash_script_dot_sh} Lane41 Lane42 Lane43 Lane44 Sample004 fileA_Sample004"])
  push!(expectedSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample004  fileB_Sample004"])
  push!(expectedSubArray, ["./path/to/binary.exe  fileB_Sample004  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(expectedSubArray, ["# The end"]);
  push!(expectedSummaryArrayOfArrays, expectedSubArray); expectedSubArray = [];
  push!(expectedSubArray, ["#JSUB<summary-name> sample id is Sample005"]);
  push!(expectedSubArray, ["bash \${a_bash_script_dot_sh} Lane51 Sample005 fileA_Sample005"])
  push!(expectedSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample005  fileB_Sample005"])
  push!(expectedSubArray, ["./path/to/binary.exe  fileB_Sample005  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(expectedSubArray, ["# The end"]);
  push!(expectedSummaryArrayOfArrays, expectedSubArray); expectedSubArray = [];
  push!(expectedSubArray, ["#JSUB<summary-name> sample id is Sample006"]);
  push!(expectedSubArray, ["bash \${a_bash_script_dot_sh} Lane61 Sample006 fileA_Sample006"])
  push!(expectedSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample006  fileB_Sample006"])
  push!(expectedSubArray, ["./path/to/binary.exe  fileB_Sample006  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(expectedSubArray, ["# The end"]);
  push!(expectedSummaryArrayOfArrays, expectedSubArray); expectedSubArray = [];
  push!(expectedSubArray, ["#JSUB<summary-name> sample id is Sample007"]);
  push!(expectedSubArray, ["bash \${a_bash_script_dot_sh} Lane71 Lane72 Sample007 fileA_Sample007"])
  push!(expectedSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample007  fileB_Sample007"])
  push!(expectedSubArray, ["./path/to/binary.exe  fileB_Sample007  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(expectedSubArray, ["# The end"]);
  push!(expectedSummaryArrayOfArrays, expectedSubArray); 
  @test protocol_to_array(supArrProt, supCmdRowsProt, supNamesFvars, supInfileColumnsFvars, supFilePathsFvars, supDictListArr, supDictCmdLineIdxs; verbose=false, adapt_quotation=false) == expectedSummaryArrayOfArrays;
  @test protocol_to_array(supArrProt, supCmdRowsProt, supNamesFvars, supInfileColumnsFvars, supFilePathsFvars, supDictListArr, supDictCmdLineIdxs; verbose=false, adapt_quotation=true) == expectedSummaryArrayOfArrays;

  ## get_summary_names(arrProt; prefix="", suffix="", timestamp=false, tag="#JSUB<summary-name>")
  # Supplied input
  supSummaryArrayOfArrays = [];
  supSubArray = [];
  push!(supSubArray, ["#JSUB<summary-name>the first job"]);
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} \"path\/to\/\"Lane'\"1\"1' path\/to\"Lane\"\"1\"2 Sample001 fileA_Sample001"])
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample001  fileB_Sample001"])
  push!(supSubArray, ["./path/to/binary.exe  fileB_Sample001  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["#JSUB<summary-name> the second job"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} Lane\"2\"1 Sample002 fileA_Sample002"])
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample002  fileB_Sample002"])
  push!(supSubArray, ["./path/to/binary.exe  fileB_Sample002  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} Lane31 Lane32 Lane33 Sample003 fileA_Sample003"])
  push!(supSubArray, [" #JSUB<summary-name>\tthe third job"]);
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample003  fileB_Sample003"])
  push!(supSubArray, ["./path/to/binary.exe  fileB_Sample003  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} Lane41 Lane42 Lane43 Lane44 Sample004 fileA_Sample004"])
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample004  fileB_Sample004"])
  push!(supSubArray, ["  #JSUB<summary-name> \tthe fourth job"]);
  push!(supSubArray, ["./path/to/binary.exe  fileB_Sample004  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} Lane51 Sample005 fileA_Sample005"])
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample005  fileB_Sample005"])
  push!(supSubArray, ["./path/to/binary.exe  fileB_Sample005  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} Lane61 Sample006 fileA_Sample006"])
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample006  fileB_Sample006"])
  push!(supSubArray, ["./path/to/binary.exe  fileB_Sample006  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supSubArray, ["# The end"]);
  push!(supSubArray, ["#JSUB<summary-name>the sixth job"]);
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  push!(supSubArray, ["\t#JSUB<summary-name>the seventh job"]);
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} Lane71 Lane72 Sample007 fileA_Sample007"])
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample007  fileB_Sample007"])
  push!(supSubArray, ["./path/to/binary.exe  fileB_Sample007  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray);
  # Expected output
  expNames = [
  "the first job.summary",
  "the second job.summary",
  "the third job.summary",
  "the fourth job.summary",
  "summary0005_YYYYMMDD_HHMMSS.summary",
  "the sixth job.summary",
  "the seventh job.summary"
  ];
  @test get_summary_names(supSummaryArrayOfArrays, timestamp="YYYYMMDD_HHMMSS", tag="#JSUB<summary-name>") == expNames
  expNames = [
  "PRE_the first job_SUF",
  "PRE_the second job_SUF",
  "PRE_the third job_SUF",
  "PRE_the fourth job_SUF",
  "PRE_summary0005_YYYYMMDD_HHMMSS_SUF",
  "PRE_the sixth job_SUF",
  "PRE_the seventh job_SUF"
  ];  
  @test get_summary_names(supSummaryArrayOfArrays; prefix="PRE_", suffix="_SUF", timestamp="YYYYMMDD_HHMMSS", tag="#JSUB<summary-name>") == expNames
  # Test what happens if multiple name tags are present in the array
  supSummaryArrayOfArrays = [];
  supSubArray = [];
  push!(supSubArray, ["#JSUB<summary-name>the first job"]);
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} \"path\/to\/\"Lane'\"1\"1' path\/to\"Lane\"\"1\"2 Sample001 fileA_Sample001"])
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample001  fileB_Sample001"])
  push!(supSubArray, ["./path/to/binary.exe  fileB_Sample001  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  push!(supSubArray, ["\t#JSUB<summary-name>the seventh job twin"]);
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} Lane71 Lane72 Sample007 fileA_Sample007"])
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample007  fileB_Sample007"])
  push!(supSubArray, ["\t#JSUB<summary-name> the seventh job twin"]);
  push!(supSubArray, ["./path/to/binary.exe  fileB_Sample007  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supSubArray, ["\t#JSUB<summary-name> the other seventh job"]);
  push!(supSubArray, ["# The end"]);  
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  expNames = [
    "the first job.summary",
    "the seventh job twin.summary"
  ]
  @test get_summary_names(supSummaryArrayOfArrays, timestamp="YYYYMMDD_HHMMSS", tag="#JSUB<summary-name>") == expNames
  # Test for cases when non-uique names are present
  # Test what happens if multiple name tags are present in the array
  supSummaryArrayOfArrays = [];
  supSubArray = [];
  push!(supSubArray, ["#JSUB<summary-name>the first job"]);
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} \"path\/to\/\"Lane'\"1\"1' path\/to\"Lane\"\"1\"2 Sample001 fileA_Sample001"])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  supSubArray = [];
  push!(supSubArray, ["#JSUB<summary-name>the first job"]);
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} \"path\/to\/\"Lane'\"1\"1' path\/to\"Lane\"\"1\"2 Sample001 fileA_Sample001"])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  push!(supSubArray, ["\t#JSUB<summary-name>the seventh job twin"]);
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} Lane71 Lane72 Sample007 fileA_Sample007"])
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample007  fileB_Sample007"])
  push!(supSubArray, ["\t#JSUB<summary-name> the seventh job twin"]);
  push!(supSubArray, ["\t#JSUB<summary-name> the other seventh job"]);
  push!(supSubArray, ["# The end"]);  
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  @test_throws ErrorException get_summary_names(supSummaryArrayOfArrays, timestamp="YYYYMMDD_HHMMSS", tag="#JSUB<summary-name>")
  
  supSummaryArrayOfArrays = [];
  supSubArray = [];
  push!(supSubArray, ["#JSUB<summary-name>the first job"]);
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} \"path\/to\/\"Lane'\"1\"1' path\/to\"Lane\"\"1\"2 Sample001 fileA_Sample001"])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  supSubArray = [];
  push!(supSubArray, ["#JSUB<summary-name>the first job"]);
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} \"path\/to\/\"Lane'\"1\"1' path\/to\"Lane\"\"1\"2 Sample001 fileA_Sample001"])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  push!(supSubArray, ["\t#JSUB<summary-name>the seventh job twin"]);
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} Lane71 Lane72 Sample007 fileA_Sample007"])
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample007  fileB_Sample007"])
  push!(supSubArray, ["\t#JSUB<summary-name> the seventh job twin"]);
  push!(supSubArray, ["\t#JSUB<summary-name> the other seventh job"]);
  push!(supSubArray, ["# The end"]);  
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  expNames = [
    "the first job.summary",
    "the first job.summary",
    "the seventh job twin.summary"
  ]
  @test get_summary_names(supSummaryArrayOfArrays, allowNonUnique=true, timestamp="YYYYMMDD_HHMMSS", tag="#JSUB<summary-name>") == expNames

  ## previous_character(inString, index)
  @test previous_entry("abcd", 1) == nothing
  @test previous_entry("abcd", 2) == 'a'
  @test previous_entry("abcd", 4) == 'c'

  ## previous_character(inString, index)
  @test next_entry("abcd", 1) == 'b'
  @test next_entry("abcd", 2) == 'c'
  @test next_entry("abcd", 4) == nothing

  ## function at_entry(arr, index)
  @test_throws BoundsError at_entry("abcd", -1)
  @test at_entry("abcd", 0) == nothing
  @test at_entry("abcd", 1) == 'a'
  @test at_entry("abcd", 2) == 'b'
  @test at_entry("abcd", 3) == 'c'
  @test at_entry("abcd", 4) == 'd'
  @test at_entry("abcd", 5) == nothing
  @test_throws BoundsError at_entry("abcd", 6)

  ## is_quotestate_conserved(strA, strB, quoteChar::Char)
  @test is_quotestate_conserved("000\"\"000", "000000", '\"') == true
  @test is_quotestate_conserved("00\"111\"\"111\"", "00\"111111\"", '\"') == true
  @test is_quotestate_conserved("00\"111\"\"\"\"111\"", "00\"111111\"", '\"') == true
  @test is_quotestate_conserved("00\"111\"\"\"000\"", "00\"111111\"", '\"') == false
  @test is_quotestate_conserved("00\"111\"\"\"000\"", "00\"111\"000", '\"') == true
  @test is_quotestate_conserved("00\"111\"\"\"\"\"000\"", "00\"111\"000", '\"') == true

  ## index_statechanges(states, intQuoteChar)
  @test_throws ErrorException index_statechanges([1,1,2,0,0,0], 2) # Quote state should start with either a quote (2) or on-quote character (0)
  @test_throws ErrorException index_statechanges([2,1,1,0,0,0,2], 2) # At least one quote is required to change the quote state
  expectedPairIndeces = [];
  push!(expectedPairIndeces, [0,1]);
  @test index_statechanges([0,0,0], 2) == (expectedPairIndeces, [0])
  expectedPairIndeces = [];
  push!(expectedPairIndeces, [0,2]);
  push!(expectedPairIndeces, [3,5]);
  @test index_statechanges([2,1,1,2,0,0,0], 2) == (expectedPairIndeces, [1, 1])
  expectedPairIndeces = [];
  push!(expectedPairIndeces, [0,3]);
  push!(expectedPairIndeces, [4,8]);
  @test index_statechanges([2,2,1,1,2,2,2,0,0,0], 2) == (expectedPairIndeces, [2, 3])
  expectedPairIndeces = [];
  push!(expectedPairIndeces, [0,2]);
  push!(expectedPairIndeces, [3,6]);
  push!(expectedPairIndeces, [7,9]);
                          # 1 2 3 4 5 6 7 8 9 0 1
  @test index_statechanges([2,1,1,2,2,1,1,2,0,0,0], 2) == (expectedPairIndeces, [1, 2, 1])
  expectedPairIndeces = [];
  push!(expectedPairIndeces, [0,2]);
  push!(expectedPairIndeces, [3,6]);
  push!(expectedPairIndeces, [7,9]);
  push!(expectedPairIndeces, [11,13]);
                          # 1 2 3 4 5 6 7 8 9 0 1 2 3 4
  @test index_statechanges([2,1,1,2,2,1,1,2,0,0,0,2,1,1], 2) == (expectedPairIndeces, [1, 2, 1, 1])
  expectedPairIndeces = [];
  push!(expectedPairIndeces, [0,2]);
  push!(expectedPairIndeces, [3,6]);
  push!(expectedPairIndeces, [7,9]);
  push!(expectedPairIndeces, [11,13]);
  push!(expectedPairIndeces, [14,16]);
                          # 1 2 3 4 5 6 7 8 9 0 1 2 3 4
  @test index_statechanges([2,1,1,2,2,1,1,2,0,0,0,2,1,1,2], 2) == (expectedPairIndeces, [1, 2, 1, 1, 1])
  expectedPairIndeces = [];
  push!(expectedPairIndeces, [0,2]);
  push!(expectedPairIndeces, [3,6]);
  push!(expectedPairIndeces, [7,9]);
  push!(expectedPairIndeces, [11,13]);
  push!(expectedPairIndeces, [14,17]);
                          # 1 2 3 4 5 6 7 8 9 0 1 2 3 4
  @test index_statechanges([2,1,1,2,2,1,1,2,0,0,0,2,1,1,2,2], 2) == (expectedPairIndeces, [1, 2, 1, 1, 2])
  # Test castes where there is some text before a quote is encountered
  expectedPairIndeces = [];
  push!(expectedPairIndeces, [0,1]);
  push!(expectedPairIndeces, [5,8]);
  push!(expectedPairIndeces, [10,13]);
                          # 1 2 3 4 5 6 7 8 9 0 1 2 3 4 
  @test index_statechanges([0,0,0,0,0,2,2,0,0,0,2,2,0,0], 2) == (expectedPairIndeces, [0, 2, 2])
  expectedPairIndeces = [];
  push!(expectedPairIndeces, [0,1]);
  push!(expectedPairIndeces, [5,8]);
  push!(expectedPairIndeces, [10,13]);
  push!(expectedPairIndeces, [14,16]);
                          # 1 2 3 4 5 6 7 8 9 0 1 2 3 4 
  @test index_statechanges([0,0,0,0,0,2,2,0,0,0,2,2,0,0,2], 2) == (expectedPairIndeces, [0, 2, 2, 1])
  expectedPairIndeces = [];
  push!(expectedPairIndeces, [0,1]);
  push!(expectedPairIndeces, [3,5]);
  push!(expectedPairIndeces, [7,11]);
  push!(expectedPairIndeces, [14,16]);
                          # 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
  @test index_statechanges([0,0,0,2,1,1,1,2,2,2,0,0,0,0,2], 2) == (expectedPairIndeces, [0, 1, 3, 1])

  ## remove_superfluous_quotes(line, quoteChar::Char)
  @test remove_superfluous_quotes("summaryPrefix_\"\"sample0001A\"\".output", '\"', 2, 1) == "summaryPrefix_sample0001A.output"
  @test remove_superfluous_quotes("abc\"efg\"\"asdf\"", '\"', 2, 1) ==  "abc\"efgasdf\""
                                  #123 4567 8 9 01234 5
  @test remove_superfluous_quotes("abc\"efg\"\"\"asdf\"", '\"', 2, 1) ==  "abc\"efg\"asdf" #"abc\"efg\"asdf\""
                                  #ooo  iii      oooo                      ooo  iii  oooo  # ooo  iii  oooo
  @test remove_superfluous_quotes("abc\"efg\"\"\"\"asdf\"", '\"', 2, 1) ==  "abc\"efgasdf\""
                                #  ooo  iii        iiii                      ooo  iiiiiii
  @test remove_superfluous_quotes("abc\"efg\"\"\"asdf\"", '\"', 2, 1) ==  "abc\"efg\"asdf"
  @test remove_superfluous_quotes("abc\"efg\"\"\"\"\"asdf\"", '\"', 2, 1) ==  "abc\"efg\"asdf"
  @test remove_superfluous_quotes("000\"\"000", '\"', 2, 1) ==  "000000"
  @test remove_superfluous_quotes("00\"111\"\"111\"", '\"', 2, 1) ==  "00\"111111\""
  @test remove_superfluous_quotes("00\"111\"\"\"\"111\"", '\"', 2, 1) ==  "00\"111111\""
  @test remove_superfluous_quotes("00\"111\"\"\"000\"", '\"', 2, 1) ==  "00\"111\"000"
  @test remove_superfluous_quotes("00\"111\"\"\"\"\"000\"", '\"', 2, 1) ==  "00\"111\"000"
  # Tests for cases with escaped quotes
  @test remove_superfluous_quotes("000\"\"000\\\"", '\"', 2, 1) ==  "000000\\\""

  ## create_summary_files_(arrArrExpFvars, summaryPaths; verbose=verbose)
  # Supplied input
  summaryPaths = [
    "jlang_function_test_files/summary_files/summary1.txt",
    "jlang_function_test_files/summary_files/summary2.txt",
    "jlang_function_test_files/summary_files/summary3.txt",
    "jlang_function_test_files/summary_files/summary4.txt",
    "jlang_function_test_files/summary_files/summary5.txt",
    "jlang_function_test_files/summary_files/summary6.txt",
    "jlang_function_test_files/summary_files/summary7.txt"
  ];
  map((x) -> try; run(`rm $x`); end, summaryPaths); # remove files before running test
  supSummaryArrayOfArrays = [];
  supSubArray = [];
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} \"path\/to\/\"Lane'\"1\"1' path\/to\"Lane\"\"1\"2 Sample001 fileA_Sample001"])
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample001  fileB_Sample001"])
  push!(supSubArray, ["./path/to/binary.exe  fileB_Sample001  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} Lane\"2\"1 Sample002 fileA_Sample002"])
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample002  fileB_Sample002"])
  push!(supSubArray, ["./path/to/binary.exe  fileB_Sample002  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} Lane31 Lane32 Lane33 Sample003 fileA_Sample003"])
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample003  fileB_Sample003"])
  push!(supSubArray, ["./path/to/binary.exe  fileB_Sample003  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} Lane41 Lane42 Lane43 Lane44 Sample004 fileA_Sample004"])
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample004  fileB_Sample004"])
  push!(supSubArray, ["./path/to/binary.exe  fileB_Sample004  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} Lane51 Sample005 fileA_Sample005"])
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample005  fileB_Sample005"])
  push!(supSubArray, ["./path/to/binary.exe  fileB_Sample005  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} Lane61 Sample006 fileA_Sample006"])
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample006  fileB_Sample006"])
  push!(supSubArray, ["./path/to/binary.exe  fileB_Sample006  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray); supSubArray = [];
  push!(supSubArray, ["# In practice this array would be produced by reading a .protocol file and expanding variables using the table in a .vars file"]);
  push!(supSubArray, ["bash \${a_bash_script_dot_sh} Lane71 Lane72 Sample007 fileA_Sample007"])
  push!(supSubArray, ["python \${a_python_script_dot_py}                       fileA_Sample007  fileB_Sample007"])
  push!(supSubArray, ["./path/to/binary.exe  fileB_Sample007  \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/header_coordinate\" \"\"../../../jsub_pipeliner\"\"/\"unit_tests/data/hg19.chrom.sizes\" "])
  push!(supSubArray, ["# The end"]);
  push!(supSummaryArrayOfArrays, supSubArray);
  # Expected output consists of files written to disk
  create_summary_files_(supSummaryArrayOfArrays, summaryPaths; verbose=false)
  # Read output back into array of arrays of arrays and check if it matches what was supplied
  @test map((x) -> file2arrayofarrays_(x, "#", cols=1)[1], summaryPaths ) == supSummaryArrayOfArrays

  ## split_summary(summary; tagSplit="#JGROUP")
  # suppliedSummaryIndices = [3,4,5];
  suppliedSummaryArray = [];
  push!(suppliedSummaryArray, ["# This data would come from reading summary files."]);
  push!(suppliedSummaryArray, ["#JSUB<summary-name>ProtocolName"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 1\""]);
  push!(suppliedSummaryArray, ["# #JGROUP comment in betwen"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 2\""]);
  push!(suppliedSummaryArray, ["# #JGROUP other comment"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 3\""]);
  expectedSummaryArray = []
  push!(expectedSummaryArray, ["# This data would come from reading summary files."]);
  push!(expectedSummaryArray, ["#JSUB<summary-name>ProtocolName"]);
  push!(expectedSummaryArray, ["bash echo \"cmd 1\""]);
  push!(expectedSummaryArray, ["# #JGROUP comment in betwen"]);
  push!(expectedSummaryArray, ["bash echo \"cmd 2\""]);
  push!(expectedSummaryArray, ["# #JGROUP other comment"]);
  push!(expectedSummaryArray, ["bash echo \"cmd 3\""]);
  expectedSummaryDict = Dict("root" => expectedSummaryArray)
  @test split_summary(suppliedSummaryArray; tagSplit="#JGROUP") == expectedSummaryDict

  # suppliedSummaryIndices = [3,4,5];
  suppliedSummaryArray = [];
  push!(suppliedSummaryArray, ["# This data would come from reading summary files."]);
  push!(suppliedSummaryArray, ["#JSUB<summary-name>ProtocolName"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 1\""]);
  push!(suppliedSummaryArray, ["#JGROUP first"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 12\""]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 13\""]);
  push!(suppliedSummaryArray, ["#JGROUP second first"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 21\""]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 22\""]);
  root = [];
  push!(root, ["# This data would come from reading summary files."]);
  push!(root, ["#JSUB<summary-name>ProtocolName"]);
  push!(root, ["bash echo \"cmd 1\""]);
  group1 = [];
  push!(group1, ["#JGROUP first"]);
  push!(group1, ["bash echo \"cmd 12\""]);
  push!(group1, ["bash echo \"cmd 13\""]);
  group2 = [];
  push!(group2, ["#JGROUP second first"]);
  push!(group2, ["bash echo \"cmd 21\""]);
  push!(group2, ["bash echo \"cmd 22\""]);
  expectedSummaryDict = Dict(
    "root" => root,
    "first" => group1,
    "second" => group2
  )
  @test split_summary(suppliedSummaryArray; tagSplit="#JGROUP") == expectedSummaryDict

  # suppliedSummaryIndices = [3,4,5];
  suppliedSummaryArray = [];
  push!(suppliedSummaryArray, ["#JGROUP zeroth"]);
  push!(suppliedSummaryArray, ["# This data would come from reading summary files."]);
  push!(suppliedSummaryArray, ["#JSUB<summary-name>ProtocolName"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 1\""]);
  push!(suppliedSummaryArray, ["#JGROUP first"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 12\""]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 13\""]);
  push!(suppliedSummaryArray, ["#JGROUP second first"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 21\""]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 22\""]);
  root = [];
  group0 = [];
  push!(group0, ["#JGROUP zeroth"]);
  push!(group0, ["# This data would come from reading summary files."]);
  push!(group0, ["#JSUB<summary-name>ProtocolName"]);
  push!(group0, ["bash echo \"cmd 1\""]);
  group1 = [];
  push!(group1, ["#JGROUP first"]);
  push!(group1, ["bash echo \"cmd 12\""]);
  push!(group1, ["bash echo \"cmd 13\""]);
  group2 = [];
  push!(group2, ["#JGROUP second first"]);
  push!(group2, ["bash echo \"cmd 21\""]);
  push!(group2, ["bash echo \"cmd 22\""]);
  expectedSummaryDict = Dict(
    "root" => root,
    "zeroth" => group0,
    "first" => group1,
    "second" => group2
  )
  @test split_summary(suppliedSummaryArray; tagSplit="#JGROUP") == expectedSummaryDict
  # Test for error if group names repeat
  suppliedSummaryArray = [];
  push!(suppliedSummaryArray, ["#JGROUP zeroth"]);
  push!(suppliedSummaryArray, ["# This data would come from reading summary files."]);
  push!(suppliedSummaryArray, ["#JSUB<summary-name>ProtocolName"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 1\""]);
  push!(suppliedSummaryArray, ["#JGROUP first"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 12\""]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 13\""]);
  push!(suppliedSummaryArray, ["#JGROUP second first"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 21\""]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 22\""]);
  push!(suppliedSummaryArray, ["#JGROUP first"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 31\""]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 32\""]);
  push!(suppliedSummaryArray, ["#JGROUP third second"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 41\""]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 42\""]);
  @test_throws ErrorException split_summary(suppliedSummaryArray; tagSplit="#JGROUP")

  ## construct_conditions(arrParents; condition="done", operator="&&")
  suppliedNames = ["first", "second", "third", "fourth"];
  expectedString = "\'done(\"first\")&&done(\"second\")&&done(\"third\")&&done(\"fourth\")\'";
  @test construct_conditions(suppliedNames; condition="done", operator="&&") == expectedString

  ## get_groupparents(jobArray, jobID; root="root", tagHeader="\n#BSUB", tagSplit="#JGROUP", jobDate="")
  ## cmd_await_jobs(jobArray; condition="done", tagSplit="#JGROUP")
  suppliedJobArray00 = [];
  push!(suppliedJobArray00, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray00, ["bash echo \"cmd 22\""]);
  @test get_groupparents(suppliedJobArray00, ""; root="root", jobDate="") == []
  expectedCommand = "\n#BSUB -w \'done(\"root\")&&done(\"first\")&&done(\"third\")&&done(\"fourth\")&&done(\"fifth\")\'";
  @test cmd_await_jobs(suppliedJobArray00, ""; option="-w", condition="done", tagSplit="#JGROUP", jobDate="") == ""

  suppliedJobArray00b = [];
  push!(suppliedJobArray00b, ["#JGROUP root"]);
  push!(suppliedJobArray00b, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray00b, ["bash echo \"cmd 22\""]);
  @test_throws ErrorException get_groupparents(suppliedJobArray00b, ""; root="root", jobDate="");
  @test_throws ErrorException cmd_await_jobs(suppliedJobArray00b, ""; option="-w", condition="done", tagSplit="#JGROUP", jobDate="")

  suppliedJobArray00c = [];
  push!(suppliedJobArray00c, ["#JGROUP"]);
  push!(suppliedJobArray00c, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray00c, ["bash echo \"cmd 22\""]);
  @test_throws ErrorException get_groupparents(suppliedJobArray00c, ""; root="root", jobDate="")
  @test_throws ErrorException cmd_await_jobs(suppliedJobArray00c, ""; option="-w", condition="done", tagSplit="#JGROUP", jobDate="")
  
  suppliedJobArray01 = [];
  push!(suppliedJobArray01, ["#JGROUP second first third fourth fifth"]);
  push!(suppliedJobArray01, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray01, ["bash echo \"cmd 22\""]);
  @test get_groupparents(suppliedJobArray01, ""; root="root", jobDate="") == ["root", "first", "third", "fourth", "fifth"]
  expectedCommand = "\n#BSUB -w \'done(\"root\")&&done(\"first\")&&done(\"third\")&&done(\"fourth\")&&done(\"fifth\")\'";
  @test cmd_await_jobs(suppliedJobArray01, ""; option="-w", condition="done", tagSplit="#JGROUP", jobDate="") == expectedCommand

  suppliedJobArray02 = [];
  push!(suppliedJobArray02, ["#JGROUP second first third fourth fifth"]);
  push!(suppliedJobArray02, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray02, ["bash echo \"cmd 22\""]);
  @test get_groupparents(suppliedJobArray02, "11331234539506827047"; root="root", jobDate="") == ["11331234539506827047_root", "11331234539506827047_first", "11331234539506827047_third", "11331234539506827047_fourth", "11331234539506827047_fifth"]
  expectedCommand = "\n#BSUB -w \'done(\"11331234539506827047_root\")&&done(\"11331234539506827047_first\")&&done(\"11331234539506827047_third\")&&done(\"11331234539506827047_fourth\")&&done(\"11331234539506827047_fifth\")\'";
  @test cmd_await_jobs(suppliedJobArray02, jobID_or_hash(suppliedJobArray02; jobID=nothing); option="-w", condition="done", tagSplit="#JGROUP") == expectedCommand

  suppliedJobArray03 = [];
  push!(suppliedJobArray03, ["#JGROUP second first third fourth fifth"]);
  push!(suppliedJobArray03, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray03, ["bash echo \"cmd 22\""]);
  @test get_groupparents(suppliedJobArray02, "ID01"; root="root", jobDate="") == ["ID01_root", "ID01_first", "ID01_third", "ID01_fourth", "ID01_fifth"]
  expectedCommand = "\n#BSUB -w \'done(\"ID01_root\")&&done(\"ID01_first\")&&done(\"ID01_third\")&&done(\"ID01_fourth\")&&done(\"ID01_fifth\")\'";
  @test cmd_await_jobs(suppliedJobArray03, "ID01"; option="-w", condition="done", tagSplit="#JGROUP", jobDate="") == expectedCommand
  # Test with date
  suppliedJobArray04 = [];
  push!(suppliedJobArray04, ["#JGROUP second first third fourth fifth"]);
  push!(suppliedJobArray04, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray04, ["bash echo \"cmd 22\""]);
  @test get_groupparents(suppliedJobArray02, "ID01"; root="root", jobDate="YYYYMMDD_HHMMSS") == ["YYYYMMDD_HHMMSS_ID01_root", "YYYYMMDD_HHMMSS_ID01_first", "YYYYMMDD_HHMMSS_ID01_third", "YYYYMMDD_HHMMSS_ID01_fourth", "YYYYMMDD_HHMMSS_ID01_fifth"]
  expectedCommand = "\n#BSUB -w \'done(\"YYYYMMDD_HHMMSS_ID01_root\")&&done(\"YYYYMMDD_HHMMSS_ID01_first\")&&done(\"YYYYMMDD_HHMMSS_ID01_third\")&&done(\"YYYYMMDD_HHMMSS_ID01_fourth\")&&done(\"YYYYMMDD_HHMMSS_ID01_fifth\")\'";
  @test cmd_await_jobs(suppliedJobArray04, "ID01"; option="-w", condition="done", tagSplit="#JGROUP", jobDate="YYYYMMDD_HHMMSS") == expectedCommand

  ## create_job_header_string(jobArray; tagHeader="#BSUB" prefix="#!/bin/bash\n", suffix="")
  suppliedJobArray = [];
  push!(suppliedJobArray, ["#JGROUP second first third fourth fifth"]);
  push!(suppliedJobArray, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray, ["#BSUB -J jobID"]);
  push!(suppliedJobArray, ["bash echo \"cmd 22\""]);
  push!(suppliedJobArray, ["#BSUB -P grantcode"]);
  push!(suppliedJobArray, ["#BSUB -w overriding"]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  expHeader = string( 
    "#!/bin/bash\n",
    '\n',
    "#BSUB -w \'done(\"root\")&&done(\"first\")&&done(\"third\")&&done(\"fourth\")&&done(\"fifth\")\'",
    "\nheader suffix string"
  );
  @test create_job_header_string(suppliedJobArray, ""; prefix="#!/bin/bash\n", suffix="\nheader suffix string", jobDate="", appendOptions=false) == expHeader
  expHeader = string( 
    "#!/bin/bash\n",
    '\n',
    "#BSUB -w \'done(\"root\")&&done(\"first\")&&done(\"third\")&&done(\"fourth\")&&done(\"fifth\")\'",
    ""
  )
  @test create_job_header_string(suppliedJobArray, ""; prefix="#!/bin/bash\n", suffix="", jobDate="", appendOptions=false) == expHeader
  expHeader = string( 
    "#!/bin/bash\n",
    '\n',
    "#BSUB -w \'done(\"YYYYMMDD_HHMMSS_ID001_root\")&&done(\"YYYYMMDD_HHMMSS_ID001_first\")&&done(\"YYYYMMDD_HHMMSS_ID001_third\")&&done(\"YYYYMMDD_HHMMSS_ID001_fourth\")&&done(\"YYYYMMDD_HHMMSS_ID001_fifth\")\'",
    ""
  )
  @test create_job_header_string(suppliedJobArray, "ID001"; prefix="#!/bin/bash\n", suffix="", jobDate="YYYYMMDD_HHMMSS", appendOptions=false) == expHeader

  # This call should not add a "\nsleep 2.5" command because the default value of rootSleepSeconds=nothing
  suppliedJobArray = [];
  push!(suppliedJobArray, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray, ["#BSUB -J jobID"]);
  push!(suppliedJobArray, ["bash echo \"cmd 22\""]);
  push!(suppliedJobArray, ["#BSUB -P grantcode"]);
  push!(suppliedJobArray, ["#BSUB -w overriding"]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  expHeader = string( 
    "#!/bin/bash\n",
    "suffixstuff"
  );
  @test create_job_header_string(suppliedJobArray, "ID001"; prefix="#!/bin/bash\n", suffix="suffixstuff", jobDate="YYYYMMDD_HHMMSS", appendOptions=false) == expHeader
  
  # This call should add a "\nsleep 2.5\n" command
  suppliedJobArray = [];
  push!(suppliedJobArray, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray, ["#BSUB -J jobID"]);
  push!(suppliedJobArray, ["bash echo \"cmd 22\""]);
  push!(suppliedJobArray, ["#BSUB -P grantcode"]);
  push!(suppliedJobArray, ["#BSUB -w overriding"]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  expHeader = string( 
    "#!/bin/bash\n",
    "\nsleep 2.5\n",
    "suffixstuff"
  );
  @test create_job_header_string(suppliedJobArray, "ID001"; rootSleepSeconds="2.5", prefix="#!/bin/bash\n", suffix="suffixstuff", jobDate="YYYYMMDD_HHMMSS", appendOptions=false) == expHeader
  
  # This call should add a "\nsleep 2.5\n" command
  suppliedJobArray = [];
  push!(suppliedJobArray, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray, ["#BSUB -J jobID"]);
  push!(suppliedJobArray, ["bash echo \"cmd 22\""]);
  push!(suppliedJobArray, ["#BSUB -P grantcode"]);
  push!(suppliedJobArray, ["#BSUB -w overriding"]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  expHeader = string( 
    "#!/bin/bash\n",
    "\n#BSUB -J YYYYMMDD_HHMMSS_ID001_root",
    "\n#BSUB -e YYYYMMDD_HHMMSS_ID001_root.error",
    "\n#BSUB -o YYYYMMDD_HHMMSS_ID001_root.output",
    "\n",
    "\nsleep 2.5\n",
    "suffixstuff"
  );
  @test create_job_header_string(suppliedJobArray, "ID001"; rootSleepSeconds="2.5", prefix="#!/bin/bash\n", suffix="suffixstuff", jobDate="YYYYMMDD_HHMMSS", appendOptions=true) == expHeader
  
  suppliedJobArray = [];
  push!(suppliedJobArray, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray, ["#BSUB -J jobID"]);
  push!(suppliedJobArray, ["bash echo \"cmd 22\""]);
  push!(suppliedJobArray, ["#BSUB -P grantcode"]);
  push!(suppliedJobArray, ["#BSUB -w overriding"]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  expHeader = string( 
    "#!/bin/bash\n",
    "\n#BSUB -J YYYYMMDD_HHMMSS_ID001",
    "\n#BSUB -e YYYYMMDD_HHMMSS_ID001.error",
    "\n#BSUB -o YYYYMMDD_HHMMSS_ID001.output",
    "\n",
    "\nsleep 2.5\n",
    "suffixstuff"
  );
  @test create_job_header_string(suppliedJobArray, "ID001"; root="", rootSleepSeconds="2.5", prefix="#!/bin/bash\n", suffix="suffixstuff", jobDate="YYYYMMDD_HHMMSS", appendOptions=true) == expHeader

  # This call should not add a sleep command because #JGROUP at the start of the suppliedJobArray indicates that this is not a root job
  suppliedJobArray = [];
  push!(suppliedJobArray, ["#JGROUP second first third fourth fifth"]);
  push!(suppliedJobArray, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray, ["#BSUB -J jobID"]);
  push!(suppliedJobArray, ["bash echo \"cmd 22\""]);
  push!(suppliedJobArray, ["#BSUB -P grantcode"]);
  push!(suppliedJobArray, ["#BSUB -w overriding"]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  expHeader = string( 
    "#!/bin/bash\n",
    '\n',
    "#BSUB -w \'done(\"YYYYMMDD_HHMMSS_ID001_root\")&&done(\"YYYYMMDD_HHMMSS_ID001_first\")&&done(\"YYYYMMDD_HHMMSS_ID001_third\")&&done(\"YYYYMMDD_HHMMSS_ID001_fourth\")&&done(\"YYYYMMDD_HHMMSS_ID001_fifth\")\'",
    "suffixstuff"
  );
  @test create_job_header_string(suppliedJobArray, "ID001"; rootSleepSeconds="2.5", prefix="#!/bin/bash\n", suffix="suffixstuff", jobDate="YYYYMMDD_HHMMSS", appendOptions=false) == expHeader

  ## identify_checkpoints
  suppliedJobArray = [];
  push!(suppliedJobArray, ["#JGROUP second first third fourth fifth"]);
  push!(suppliedJobArray, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray, ["jcheck_filesNotEmpty \"cmd 21\""]);
  push!(suppliedJobArray, ["#BSUB -J jobID"]);
  push!(suppliedJobArray, ["bash echo \"cmd 22\""]);
  push!(suppliedJobArray, ["jcheck_resume"]);
  push!(suppliedJobArray, ["#BSUB -P grantcode"]);
  push!(suppliedJobArray, ["#BSUB -w overriding"]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  push!(suppliedJobArray, ["jcheck_filesNotEmpty \"cmd 23\""]);
  checkpointsDict = Dict(
    "jcheck_filesNotEmpty" => "path/to/jcheck_filesNotEmpty.sh",
    "jcheck_resume" => "path/to/jcheck_resume.sh",
    "jcheck_something_else" => "path/to/jcheck_something_else.sh",
    "something_else_entierly" => "some/other/path"
  );
  expectedFileSet = Dict(
    "jcheck_filesNotEmpty" => "path/to/jcheck_filesNotEmpty.sh",
    "jcheck_resume" => "path/to/jcheck_resume.sh",
  );
  @test identify_checkpoints(suppliedJobArray, checkpointsDict; tagCheckpoint="jcheck_") == expectedFileSet

  ## function get_bash_functions(common_functions::Dict{Any,Any}, selected_functions::Dict{Any,Any})
  common_functions = Dict(
    "dummy1" => "jlang_function_test_files/dummy_bash_functions/dummy1.sh",
    "dummy2" => "jlang_function_test_files/dummy_bash_functions/dummy2.sh",
    "dummy2_1" => "jlang_function_test_files/dummy_bash_functions/dummy2.sh",
    "dummy3" => "jlang_function_test_files/dummy_bash_functions/dummy3.sh",
  );
  selected_functions = Dict(
    "dummy1" => "jlang_function_test_files/dummy_bash_functions/dummy1.sh",
    "dummy2" => "jlang_function_test_files/dummy_bash_functions/dummy2.sh",
    "dummy2_1" => "jlang_function_test_files/dummy_bash_functions/dummy2.sh",
    "dummy10" => "jlang_function_test_files/dummy_bash_functions/dummy10.sh",
    "dummy10_1" => "jlang_function_test_files/dummy_bash_functions/dummy10.sh",
    "dummy11" => "jlang_function_test_files/dummy_bash_functions/dummy11.sh",
    "dummy12" => "jlang_function_test_files/dummy_bash_functions/dummy12.sh",
  );
  output_dict = Dict(
    "jlang_function_test_files/dummy_bash_functions/dummy1.sh" => "function dummy1 {\necho Running_dummy_function_1\n}\n",
    "jlang_function_test_files/dummy_bash_functions/dummy2.sh" => "function dummy2 {\necho Running_dummy_function_2\n}\nfunction dummy2_1 {\necho Running_dummy_function_2_1\n}\nfunction dummy2_2 {\necho Running_dummy_function_2_2\n}\n",
    "jlang_function_test_files/dummy_bash_functions/dummy3.sh" => "function dummy3 {\necho Running_dummy_function_3\n}\n",
    "jlang_function_test_files/dummy_bash_functions/dummy10.sh" => "function dummy10 {\necho Running_dummy_function_10\n}\nfunction dummy10_1 {\necho Running_dummy_function_10_1\n}\n",
    "jlang_function_test_files/dummy_bash_functions/dummy11.sh" => "function dummy11 {\necho Running_dummy_function_11\n}\n",
    "jlang_function_test_files/dummy_bash_functions/dummy12.sh" => "function dummy12 {\necho Running_dummy_function_12\n}\n",
  );
  @test get_bash_functions(common_functions, selected_functions) == output_dict
  # dd = get_bash_functions(common_functions, selected_functions);
  # kd = sort(collect(keys(dd))); ko = sort(collect(keys(output_dict)));
  # vd = sort(collect(values(dd))); vo = sort(collect(values(output_dict)));
  # compare_arrays(kd, ko); 
  # compare_arrays(vd, vo);

  ## create_job_file_(filePath, jobArray, bash_functions::Dict; tagBegin="#JSUB<begin-job>", tagFinish="#JSUB<finish-job>", tagHeader="#BSUB", headerPrefix="#!/bin/bash\n" , headerSuffix="")
  filePath = "jlang_function_test_files/job_files/ut_generated_job.lsf";
  run(`rm $filePath`);
  headerString = string( 
    "#!/bin/bash\n",
    '\n',
    "#BSUB -w \'done(\"first\")&&done(\"third\")&&done(\"fourth\")&&done(\"fifth\")\'",
    "\nheader suffix string"
  );
  suppliedJobArray = [];
  push!(suppliedJobArray, ["#JGROUP second first third fourth fifth"]);
  push!(suppliedJobArray, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray, ["#BSUB -J jobID"]);
  push!(suppliedJobArray, ["bash echo \"cmd 22\""]);
  push!(suppliedJobArray, ["#BSUB -P grantcode"]);
  push!(suppliedJobArray, ["#BSUB -w overriding"]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  create_job_file_(filePath, suppliedJobArray, output_dict; jobID="", jobDate="", appendOptions=false)
  expected_file_contents = string( 
    string( 
      "#!/bin/bash\n",
      '\n',
      "#BSUB -w \'done(\"root\")&&done(\"first\")&&done(\"third\")&&done(\"fourth\")&&done(\"fifth\")\'",
      ""
    ),
    "\n",
    "\n# Job file variables:",
    "\nJSUB_PATH_TO_THIS_JOB=<to-be-replaced-by-the-path-to-this-file>",
    "\nJSUB_JOB_ID=\"second\"",                                   
    "\nJSUB_LOG_FILE=\"jlang_function_test_files/job_files/ut_generated_job.log\"",
    "\nJSUB_SUMMARY_COMPLETED=\"jlang_function_test_files/job_files/ut_generated_job.summary.completed\"",
    "\nJSUB_SUMMARY_INCOMPLETE=\"jlang_function_test_files/job_files/ut_generated_job.summary.incomplete\"",
    "\nJSUB_VERSION_CONTROL=true",
    "\nJSUB_JOB_TIMESTAMP=true",                                                                         
    "\n",
    "\n# Contents inserted from other files (this section is intended to be used only for functions):\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy1.sh", "\n",
    "function dummy1 {\necho Running_dummy_function_1\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy10.sh", "\n",
    "function dummy10 {\necho Running_dummy_function_10\n}\nfunction dummy10_1 {\necho Running_dummy_function_10_1\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy11.sh", "\n",
    "function dummy11 {\necho Running_dummy_function_11\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy12.sh", "\n",
    "function dummy12 {\necho Running_dummy_function_12\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy2.sh", "\n",
    "function dummy2 {\necho Running_dummy_function_2\n}\nfunction dummy2_1 {\necho Running_dummy_function_2_1\n}\nfunction dummy2_2 {\necho Running_dummy_function_2_2\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy3.sh", "\n",
    "function dummy3 {\necho Running_dummy_function_3\n}\n",
    "\n\n# Commands taken from summary file: ""\n",
    "\n#JSUB<begin-job>\n",
    "#JGROUP second first third fourth fifth", "\n",
    "bash echo \"cmd 21\"", "\n",
    "#BSUB -J jobID", "\n",
    "bash echo \"cmd 22\"", "\n",
    "#BSUB -P grantcode", "\n",
    "#BSUB -w overriding", "\n",
    "bash echo \"cmd 23\"", "\n",
    "\n#JSUB<finish-job>",
    "\nprocess_job",
    "\n"
  )
  @test expected_file_contents == readall(filePath)
  # arr1 = split(readall(filePath), '\n')
  # arr2 = split(expected_file_contents, '\n')
  # compare_arrays(arr1, arr2)
  
  # stream = open("/jlang_function_test_files/job_files/compare.txt", "w");
  # write(stream, expected_file_contents)
  # close(stream)

  filePath = "jlang_function_test_files/job_files/ut_generated_job.lsf";
  run(`rm $filePath`);
  headerString = string( 
    "#!/bin/bash\n",
    '\n',
    "#BSUB -w \'done(\"first\")&&done(\"third\")&&done(\"fourth\")&&done(\"fifth\")\'",
    "\nheader suffix string"
  );
  suppliedJobArray = [];
  push!(suppliedJobArray, ["#JGROUP second first third fourth fifth"]);
  push!(suppliedJobArray, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray, ["#BSUB -J jobID"]);
  push!(suppliedJobArray, ["bash echo \"cmd 22\""]);
  push!(suppliedJobArray, ["#BSUB -P grantcode"]);
  push!(suppliedJobArray, ["#BSUB -w overriding"]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  create_job_file_(filePath, suppliedJobArray, output_dict; jobID="ID002", jobDate="")
  expected_file_contents = string( 
    string( 
      "#!/bin/bash\n",
      '\n',
      "#BSUB -w \'done(\"ID002_root\")&&done(\"ID002_first\")&&done(\"ID002_third\")&&done(\"ID002_fourth\")&&done(\"ID002_fifth\")\'",
      string("\n", "#BSUB", " -J ID002_second\n", "#BSUB", " -e ID002_second.error\n", "#BSUB", " -o ID002_second.output\n"),
      ""
    ),
    "\n",
    "\n# Job file variables:",
    "\nJSUB_PATH_TO_THIS_JOB=<to-be-replaced-by-the-path-to-this-file>",
    "\nJSUB_JOB_ID=\"ID002_second\"",                                   
    "\nJSUB_LOG_FILE=\"jlang_function_test_files/job_files/ut_generated_job.log\"",
    "\nJSUB_SUMMARY_COMPLETED=\"jlang_function_test_files/job_files/ut_generated_job.summary.completed\"",
    "\nJSUB_SUMMARY_INCOMPLETE=\"jlang_function_test_files/job_files/ut_generated_job.summary.incomplete\"",
    "\nJSUB_VERSION_CONTROL=true",
    "\nJSUB_JOB_TIMESTAMP=true",                                                                         
    "\n",
    "\n# Contents inserted from other files (this section is intended to be used only for functions):\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy1.sh", "\n",
    "function dummy1 {\necho Running_dummy_function_1\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy10.sh", "\n",
    "function dummy10 {\necho Running_dummy_function_10\n}\nfunction dummy10_1 {\necho Running_dummy_function_10_1\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy11.sh", "\n",
    "function dummy11 {\necho Running_dummy_function_11\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy12.sh", "\n",
    "function dummy12 {\necho Running_dummy_function_12\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy2.sh", "\n",
    "function dummy2 {\necho Running_dummy_function_2\n}\nfunction dummy2_1 {\necho Running_dummy_function_2_1\n}\nfunction dummy2_2 {\necho Running_dummy_function_2_2\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy3.sh", "\n",
    "function dummy3 {\necho Running_dummy_function_3\n}\n",
    "\n\n# Commands taken from summary file: ""\n",
    "\n#JSUB<begin-job>\n",
    "#JGROUP second first third fourth fifth", "\n",
    "bash echo \"cmd 21\"", "\n",
    "#BSUB -J jobID", "\n",
    "bash echo \"cmd 22\"", "\n",
    "#BSUB -P grantcode", "\n",
    "#BSUB -w overriding", "\n",
    "bash echo \"cmd 23\"", "\n",
    "\n#JSUB<finish-job>",
    "\nprocess_job",
    "\n"
  )
  @test expected_file_contents == readall(filePath)
  # arr1 = split(readall(filePath), '\n')
  # arr2 = split(expected_file_contents, '\n')
  # compare_arrays(arr1, arr2)

  # Test to make sure create_job_file_ does not create a job file if the array of commands is empty
  filePath = "jlang_function_test_files/job_files/ut_generated_empty_job.lsf";
  if isfile(filePath)
    run(`rm $filePath`);
  end
  headerString = string( 
    "#!/bin/bash\n",
    '\n',
    "#BSUB -w \'done(\"first\")&&done(\"third\")&&done(\"fourth\")&&done(\"fifth\")\'",
    "\nheader suffix string"
  );
  suppliedJobArray = [];
  create_job_file_(filePath, suppliedJobArray, output_dict; )
  @test isfile(filePath) == false

  ## detect_option_conflicts(jobArray; tag="#BSUB", option="-J")
  suppliedJobArray = [];
  push!(suppliedJobArray, ["#JGROUP second first third fourth fifth"]);
  push!(suppliedJobArray, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray, ["#BSUB -J jobID"]);
  push!(suppliedJobArray, ["bash echo \"cmd 22\""]);
  push!(suppliedJobArray, ["#BSUB -P grantcode"]);
  push!(suppliedJobArray, ["#BSUB -w overriding"]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  @test detect_option_conflicts(suppliedJobArray; tag="#BSUB", option="-J") == false

  suppliedJobArray = [];
  push!(suppliedJobArray, ["#JGROUP second first third fourth fifth"]);
  push!(suppliedJobArray, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray, ["#BSUB -J jobID"]);
  push!(suppliedJobArray, ["bash echo \"cmd 22\""]);
  push!(suppliedJobArray, ["#BSUB -P grantcode"]);
  push!(suppliedJobArray, ["#BSUB -J jobID"]);
  push!(suppliedJobArray, ["#BSUB -w overriding"]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  @test detect_option_conflicts(suppliedJobArray; tag="#BSUB", option="-J") == false

  suppliedJobArray = [];
  push!(suppliedJobArray, ["#JGROUP second first third fourth fifth"]);
  push!(suppliedJobArray, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray, ["#BSUB -J jobID"]);
  push!(suppliedJobArray, ["bash echo \"cmd 22\""]);
  push!(suppliedJobArray, ["#BSUB -P grantcode"]);
  push!(suppliedJobArray, ["#BSUB -J hobID"]);
  push!(suppliedJobArray, ["#BSUB -w overriding"]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  @test detect_option_conflicts(suppliedJobArray; tag="#BSUB", option="-J") == true

  ## jobID_or_hash(jobArray; jobID=nothing)
  suppliedJobArray = [];
  push!(suppliedJobArray, ["#JGROUP second first third fourth fifth"]);
  push!(suppliedJobArray, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  @test jobID_or_hash(suppliedJobArray, jobID=nothing) == string(hash(suppliedJobArray))
  @test jobID_or_hash(suppliedJobArray, jobID="ID001") == "ID001"
  @test jobID_or_hash(suppliedJobArray, jobID="ID001", jobDate="YYYYMMDD_HHMMSS") == "YYYYMMDD_HHMMSS_ID001"

  ## get_groupname(jobArray; tagSplit="#JGROUP")
  suppliedJobArray = [];
  push!(suppliedJobArray, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  push!(suppliedJobArray, ["#JGROUP this one should be ignored by get_groupname"]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  @test get_groupname(suppliedJobArray; tagSplit="#JGROUP") == "root"

  suppliedJobArray = [];
  push!(suppliedJobArray, ["#JGROUP second first third fourth fifth"]);
  push!(suppliedJobArray, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  push!(suppliedJobArray, ["#JGROUP this one should be ignored by get_groupname"]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  @test get_groupname(suppliedJobArray; tagSplit="#JGROUP") == "second"

  ## generate_jobfilepath(summaryName, jobArray; tagSplit="#JGROUP", prefix="", suffix=".lsf")
  suppliedJobArray = [];
  push!(suppliedJobArray, ["#JGROUP second first third fourth fifth"]);
  push!(suppliedJobArray, ["bash echo \"cmd 21\""]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  push!(suppliedJobArray, ["#JGROUP this one should be ignored by get_groupname"]);
  push!(suppliedJobArray, ["bash echo \"cmd 23\""]);
  @test generate_jobfilepath("summaryName_0001", suppliedJobArray; tagSplit="#JGROUP", prefix="path/to/", suffix=".lsf") == "path/to/summaryName_0001_second.lsf"
  hashArr = string(hash(suppliedJobArray));
  @test generate_jobfilepath(nothing, suppliedJobArray; tagSplit="#JGROUP", prefix="path/to/", suffix=".lsf") == string("path/to/14662392462863753823_second.lsf")

  ## get_longname(pathProtocol, pathVars, pathFvars)
  pathProtocol = "path/to/protocol_file.protocol";
  pathVars = "path/to/vars_file.vars";
  pathFvars = "another/way/to/fvars_file.fvars";
  pathSummaryList = "not/used/here";
  pathJobList = "not/used/either";
  @test get_longname(pathProtocol, pathVars, pathFvars, pathSummaryList, pathJobList) == "protocol_file_vars_file_fvars_file"
  pathProtocol = "path/to/.protocol";
  pathVars = "path/to/vars_file.vars";
  pathFvars = "another/way/to/fvars_file.fvars";
  pathSummaryList = "not/used/here";
  pathJobList = "not/used/either";
  @test get_longname(pathProtocol, pathVars, pathFvars, pathSummaryList, pathJobList) == "vars_file_fvars_file"
  pathProtocol = "path/to/.protocol";
  pathVars = "path/to/.vars";
  pathFvars = "another/way/to/.fvars";
  pathSummaryList = "use/summarylist";
  pathJobList = "use/joblist";
  @test get_longname(pathProtocol, pathVars, pathFvars, pathSummaryList, pathJobList) == "summarylist_joblist"
  pathProtocol = "";
  pathVars = "";
  pathFvars = "";
  pathSummaryList = "use/summarylist.list-summaries";
  pathJobList = "use/joblist.list-jobs";
  @test get_longname(pathProtocol, pathVars, pathFvars, pathSummaryList, pathJobList) == "summarylist_joblist"
  pathProtocol = "";
  pathVars = "";
  pathFvars = "";
  pathSummaryList = "useA/sameString.list-summaries";
  pathJobList = "useB/sameString.list-jobs";
  @test get_longname(pathProtocol, pathVars, pathFvars, pathSummaryList, pathJobList) == "sameString"
  pathProtocol = "";
  pathVars = "";
  pathFvars = "";
  pathSummaryList = "use/.list-summaries";
  pathJobList = "use/.list-jobs";
  @test get_longname(pathProtocol, pathVars, pathFvars, pathSummaryList, pathJobList) == string(hash(pathProtocol * pathVars * pathFvars))

  # ## get_jobfile_name(summaryName, group; summaryFileExtension=".summary")

  ## create_jobs_from_summary_(summaryFilePath, dictSummaries::Dict, checkpointsDict::Dict; filePathOverride=nothing, root="root",
  ##     tagBegin="#JSUB<begin-job>", tagFinish="#JSUB<finish-job>", tagHeader="#BSUB", tagCheckpoint="jcheck_", headerPrefix="#!/bin/bash\n" , headerSuffix="", summaryFile="", jobID=nothing, jobDate=nothing, appendOptions=true
  ##   )
  checkpointsDict = Dict(
    "jcheck_filesNotEmpty" => "jlang_function_test_files/dummy_bash_functions/jcheck_filesNotEmpty.sh",
    "jcheck_resume" => "jlang_function_test_files/dummy_bash_functions/jcheck_resume.sh",
    "jcheck_something_else" => "jlang_function_test_files/dummy_bash_functions/jcheck_something_else.sh",
    "something_else_entierly" => "some/other/path"
  );
  commonFunctions = Dict(
    "dummy1" => "jlang_function_test_files/dummy_bash_functions/dummy1.sh",
    "dummy2" => "jlang_function_test_files/dummy_bash_functions/dummy2.sh",
    "dummy2_1" => "jlang_function_test_files/dummy_bash_functions/dummy2.sh",
    "dummy3" => "jlang_function_test_files/dummy_bash_functions/dummy3.sh",
  );
  headerString = string( 
    "#!/bin/bash\n",
    '\n',
    "#BSUB -w \'done(\"first\")&&done(\"third\")&&done(\"fourth\")&&done(\"fifth\")\'",
    "\nheader suffix string"
  );
  summaryFilePath = "dir/name/is/ignored/ut_create_jobs_from_summary.summary"
  @test isfile(summaryFilePath) == false
  # Supplied input
  suppliedSummaryArray = [];
  push!(suppliedSummaryArray, ["# This data would come from reading summary files."]);
  push!(suppliedSummaryArray, ["#JSUB<summary-name>ProtocolName"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 01\""]);
  push!(suppliedSummaryArray, ["jcheck_resume"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 02\""]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 03\""]);
  push!(suppliedSummaryArray, ["#JGROUP first"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 12\""]);
  push!(suppliedSummaryArray, ["jcheck_resume"]);
  push!(suppliedSummaryArray, ["jcheck_filesNotEmpty"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 13\""]);
  push!(suppliedSummaryArray, ["#JGROUP second first"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 21\""]);
  push!(suppliedSummaryArray, ["jcheck_resume"]);
  push!(suppliedSummaryArray, ["bash echo \"cmd 22\""]);
  root = [];
  push!(root, ["# This data would come from reading summary files."]);
  push!(root, ["#JSUB<summary-name>ProtocolName"]);
  push!(root, ["bash echo \"cmd 01\""]);
  push!(root, ["jcheck_resume"]);
  push!(root, ["bash echo \"cmd 02\""]);
  push!(root, ["dummy10 arg1 arg2"]);
  push!(root, ["bash echo \"cmd 03\""]);
  group1 = [];
  push!(group1, ["#JGROUP first"]);
  push!(group1, ["bash echo \"cmd 12\""]);
  push!(group1, ["jcheck_resume"]);
  push!(group1, ["dummy10_1 arg1_1 arg2_1"]);
  push!(group1, ["bash echo \"cmd 13\""]);
  group2 = [];
  push!(group2, ["#JGROUP second first"]);
  push!(group2, ["bash echo \"cmd 21\""]);
  push!(group2, ["jcheck_resume"]);
  push!(group2, ["dummy12 arg1 arg2"]);
  push!(group2, ["bash echo \"cmd 22\""]);
  suppliedSummaryDict = Dict(
    "root" => root,
    "first" => group1,
    "second" => group2
  )
  expectedFilePath01 = "jlang_function_test_files/job_files/ut_create_jobs_from_summary_root.lsf"
  try run(`rm $expectedFilePath01`) end
  expectedFileHeader01 = string( 
    "#!/bin/bash\n",
    "\n#BSUB -J JOBDATE0_000000_jobID0000_root",
    "\n#BSUB -e JOBDATE0_000000_jobID0000_root.error",
    "\n#BSUB -o JOBDATE0_000000_jobID0000_root.output",
    "\n"
  );
  expectedJobFileVariables = string(
    "\n",
    "\n# Job file variables:",
    "\nJSUB_PATH_TO_THIS_JOB=<to-be-replaced-by-the-path-to-this-file>",
    "\nJSUB_JOB_ID=\"jobID0000\"",                                   
    "\nJSUB_LOG_FILE=\"jlang_function_test_files/job_files/ut_create_jobs_from_summary.log\"",
    "\nJSUB_SUMMARY_COMPLETED=\"jlang_function_test_files/job_files/ut_create_jobs_from_summary.summary.completed\"",
    "\nJSUB_SUMMARY_INCOMPLETE=\"jlang_function_test_files/job_files/ut_create_jobs_from_summary.summary.incomplete\"",
    "\nJSUB_VERSION_CONTROL=true",
    "\nJSUB_JOB_TIMESTAMP=true",
  );
  expectedFileContents01 = string( 
    expectedFileHeader01,
    "\n",
    "\n# Job file variables:",
    "\nJSUB_PATH_TO_THIS_JOB=<to-be-replaced-by-the-path-to-this-file>",
    "\nJSUB_JOB_ID=\"jobID0000_root\"",                                   
    "\nJSUB_LOG_FILE=\"jlang_function_test_files/job_files/ut_create_jobs_from_summary.log\"",
    "\nJSUB_SUMMARY_COMPLETED=\"jlang_function_test_files/job_files/ut_create_jobs_from_summary.summary.completed\"",
    "\nJSUB_SUMMARY_INCOMPLETE=\"jlang_function_test_files/job_files/ut_create_jobs_from_summary.summary.incomplete\"",
    "\nJSUB_VERSION_CONTROL=true",
    "\nJSUB_JOB_TIMESTAMP=true",
    "\n\n# Contents inserted from other files (this section is intended to be used only for functions):\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy1.sh", "\n",
    "function dummy1 {\necho Running_dummy_function_1\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy2.sh", "\n",
    "function dummy2 {\necho Running_dummy_function_2\n}\nfunction dummy2_1 {\necho Running_dummy_function_2_1\n}\nfunction dummy2_2 {\necho Running_dummy_function_2_2\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy3.sh", "\n",
    "function dummy3 {\necho Running_dummy_function_3\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/jcheck_resume.sh", "\n",
    "contents of jcheck_resume.sh", "\n",
    "\n\n# Commands taken from summary file: dir/name/is/ignored/ut_create_jobs_from_summary.summary""\n",
    "\n#JSUB<begin-job>\n",
    "# This data would come from reading summary files.", "\n",
    "#JSUB<summary-name>ProtocolName", "\n",
    "bash echo \"cmd 01\"", "\n",
    "jcheck_resume", "\n",
    "bash echo \"cmd 02\"", "\n",
    "dummy10 arg1 arg2", "\n",
    "bash echo \"cmd 03\"", "\n",
    "\n#JSUB<finish-job>",
    "\nprocess_job\n"
  )
  expectedFilePath02 = "jlang_function_test_files/job_files/ut_create_jobs_from_summary_first.lsf"
  try run(`rm $expectedFilePath02`) end
  expectedFileHeader02 = string( 
      "#!/bin/bash\n",
      "\n#BSUB -w \'done(\"JOBDATE0_000000_jobID0000_root\")\'",
      "\n#BSUB -J JOBDATE0_000000_jobID0000_first",
      "\n#BSUB -e JOBDATE0_000000_jobID0000_first.error",
      "\n#BSUB -o JOBDATE0_000000_jobID0000_first.output",
      "\n"
    )
  expectedFileContents02 = string( 
    expectedFileHeader02,
    "\n",
    "\n# Job file variables:",
    "\nJSUB_PATH_TO_THIS_JOB=<to-be-replaced-by-the-path-to-this-file>",
    "\nJSUB_JOB_ID=\"jobID0000_first\"",                                   
    "\nJSUB_LOG_FILE=\"jlang_function_test_files/job_files/ut_create_jobs_from_summary.log\"",
    "\nJSUB_SUMMARY_COMPLETED=\"jlang_function_test_files/job_files/ut_create_jobs_from_summary.summary.completed\"",
    "\nJSUB_SUMMARY_INCOMPLETE=\"jlang_function_test_files/job_files/ut_create_jobs_from_summary.summary.incomplete\"",
    "\nJSUB_VERSION_CONTROL=true",
    "\nJSUB_JOB_TIMESTAMP=true",
    "\n\n# Contents inserted from other files (this section is intended to be used only for functions):\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy1.sh", "\n",
    "function dummy1 {\necho Running_dummy_function_1\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy2.sh", "\n",
    "function dummy2 {\necho Running_dummy_function_2\n}\nfunction dummy2_1 {\necho Running_dummy_function_2_1\n}\nfunction dummy2_2 {\necho Running_dummy_function_2_2\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy3.sh", "\n",
    "function dummy3 {\necho Running_dummy_function_3\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/jcheck_resume.sh", "\n",
    "contents of jcheck_resume.sh", "\n",
    "\n\n# Commands taken from summary file: dir/name/is/ignored/ut_create_jobs_from_summary.summary""\n",
    "\n#JSUB<begin-job>\n",
    "#JGROUP first", "\n",
    "bash echo \"cmd 12\"", "\n",
    "jcheck_resume", "\n",
    "dummy10_1 arg1_1 arg2_1", "\n",
    "bash echo \"cmd 13\"", "\n",
    "\n#JSUB<finish-job>",
    "\nprocess_job\n"
  )
  expectedFilePath03 = "jlang_function_test_files/job_files/ut_create_jobs_from_summary_second.lsf"
  try run(`rm $expectedFilePath03`) end
  expectedFileHeader03 = string( 
      "#!/bin/bash\n",
      "\n#BSUB -w \'done(\"JOBDATE0_000000_jobID0000_root\")&&done(\"JOBDATE0_000000_jobID0000_first\")\'",
      "\n#BSUB -J JOBDATE0_000000_jobID0000_second",
      "\n#BSUB -e JOBDATE0_000000_jobID0000_second.error",
      "\n#BSUB -o JOBDATE0_000000_jobID0000_second.output",
      "\n"
    )
  expectedFileContents03 = string( 
    expectedFileHeader03,
    "\n",
    "\n# Job file variables:",
    "\nJSUB_PATH_TO_THIS_JOB=<to-be-replaced-by-the-path-to-this-file>",
    "\nJSUB_JOB_ID=\"jobID0000_second\"",                                   
    "\nJSUB_LOG_FILE=\"jlang_function_test_files/job_files/ut_create_jobs_from_summary.log\"",
    "\nJSUB_SUMMARY_COMPLETED=\"jlang_function_test_files/job_files/ut_create_jobs_from_summary.summary.completed\"",
    "\nJSUB_SUMMARY_INCOMPLETE=\"jlang_function_test_files/job_files/ut_create_jobs_from_summary.summary.incomplete\"",
    "\nJSUB_VERSION_CONTROL=true",
    "\nJSUB_JOB_TIMESTAMP=true",
    "\n\n# Contents inserted from other files (this section is intended to be used only for functions):\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy1.sh", "\n",
    "function dummy1 {\necho Running_dummy_function_1\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy2.sh", "\n",
    "function dummy2 {\necho Running_dummy_function_2\n}\nfunction dummy2_1 {\necho Running_dummy_function_2_1\n}\nfunction dummy2_2 {\necho Running_dummy_function_2_2\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy3.sh", "\n",
    "function dummy3 {\necho Running_dummy_function_3\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/jcheck_resume.sh", "\n",
    "contents of jcheck_resume.sh", "\n",
    "\n\n# Commands taken from summary file: dir/name/is/ignored/ut_create_jobs_from_summary.summary""\n",
    "\n#JSUB<begin-job>\n",
    "#JGROUP second first", "\n",
    "bash echo \"cmd 21\"", "\n",
    "jcheck_resume", "\n",
    "dummy12 arg1 arg2", "\n",
    "bash echo \"cmd 22\"", "\n",
    "\n#JSUB<finish-job>",
    "\nprocess_job\n"
  )
  @test create_job_header_string(root, "JOBDATE0_000000_jobID0000") == expectedFileHeader01
  @test create_job_header_string(group1, "JOBDATE0_000000_jobID0000") == expectedFileHeader02
  @test create_job_header_string(group2, "JOBDATE0_000000_jobID0000") == expectedFileHeader03
  @test create_jobs_from_summary_(summaryFilePath, suppliedSummaryDict, commonFunctions, checkpointsDict; 
    jobFilePrefix="jlang_function_test_files/job_files/", filePathOverride=nothing, root="root", jobFileSuffix=".lsf",
    #tagBegin="#JSUB<begin-job>", tagFinish="#JSUB<finish-job>", tagCheckpoint="jcheck_", headerPrefix="#!/bin/bash\n" , headerSuffix="", summaryFile="", jobID=nothing, jobDate=nothing, appendOptions=true
    jobID="jobID0000", jobDate="JOBDATE0_000000"
  ) == Dict(
    "root"   => "jlang_function_test_files/job_files/ut_create_jobs_from_summary_root.lsf",
    "second" => "jlang_function_test_files/job_files/ut_create_jobs_from_summary_second.lsf",
    "first"  => "jlang_function_test_files/job_files/ut_create_jobs_from_summary_first.lsf",
  )
  @test expectedFileContents01 == readall(expectedFilePath01)
  # O=split(readall(expectedFilePath01), '\n')
  # E=split(expectedFileContents01, '\n')
  # compare_arrays(split(readall(expectedFilePath01), '\n'), split(expectedFileContents01, '\n'))
  @test expectedFileContents02 == readall(expectedFilePath02)
  # O=split(readall(expectedFilePath02), '\n')
  # E=split(expectedFileContents02, '\n')
  # compare_arrays(split(readall(expectedFilePath02), '\n'), split(expectedFileContents02, '\n'))
  @test expectedFileContents03 == readall(expectedFilePath03)
  # Observed03=split(readall(expectedFilePath03), '\n');
  # Expected03=split(expectedFileContents03, '\n');
  # compare_arrays(Expected03, Observed03);

  # Test for the rootSleepSeconds option
  create_jobs_from_summary_(summaryFilePath, suppliedSummaryDict, commonFunctions, checkpointsDict; 
    jobFilePrefix="jlang_function_test_files/job_files/", filePathOverride=nothing, root="root", jobFileSuffix=".lsf",
    #tagBegin="#JSUB<begin-job>", tagFinish="#JSUB<finish-job>", tagCheckpoint="jcheck_", headerPrefix="#!/bin/bash\n" , headerSuffix="", summaryFile="", jobID=nothing, jobDate=nothing, appendOptions=true
    jobID="jobID0000", jobDate="JOBDATE0_000000", rootSleepSeconds=nothing
  )
  @test expectedFileContents01 == readall(expectedFilePath01)
  @test expectedFileContents02 == readall(expectedFilePath02)
  @test expectedFileContents03 == readall(expectedFilePath03)
  expectedFilePath01 = "jlang_function_test_files/job_files/ut_create_jobs_from_summary_root.lsf"
  try run(`rm $expectedFilePath01`) end
  expectedFileHeader01 = string( 
      "#!/bin/bash\n",
      "\n#BSUB -J JOBDATE0_000000_jobID0000_root",
      "\n#BSUB -e JOBDATE0_000000_jobID0000_root.error",
      "\n#BSUB -o JOBDATE0_000000_jobID0000_root.output",
      "\n\nsleep 7.7",
      "\n"
    )
  expectedFileContents01 = string( 
    expectedFileHeader01,
    "\n",
    "\n# Job file variables:",
    "\nJSUB_PATH_TO_THIS_JOB=<to-be-replaced-by-the-path-to-this-file>",
    "\nJSUB_JOB_ID=\"jobID0000_root\"",                                   
    "\nJSUB_LOG_FILE=\"jlang_function_test_files/job_files/ut_create_jobs_from_summary.log\"",
    "\nJSUB_SUMMARY_COMPLETED=\"jlang_function_test_files/job_files/ut_create_jobs_from_summary.summary.completed\"",
    "\nJSUB_SUMMARY_INCOMPLETE=\"jlang_function_test_files/job_files/ut_create_jobs_from_summary.summary.incomplete\"",
    "\nJSUB_VERSION_CONTROL=true",
    "\nJSUB_JOB_TIMESTAMP=true",
    "\n\n# Contents inserted from other files (this section is intended to be used only for functions):\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy1.sh", "\n",
    "function dummy1 {\necho Running_dummy_function_1\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy2.sh", "\n",
    "function dummy2 {\necho Running_dummy_function_2\n}\nfunction dummy2_1 {\necho Running_dummy_function_2_1\n}\nfunction dummy2_2 {\necho Running_dummy_function_2_2\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/dummy3.sh", "\n",
    "function dummy3 {\necho Running_dummy_function_3\n}\n",
    "\n# --- From file: jlang_function_test_files/dummy_bash_functions/jcheck_resume.sh", "\n",
    "contents of jcheck_resume.sh", "\n",
    "\n\n# Commands taken from summary file: dir/name/is/ignored/ut_create_jobs_from_summary.summary""\n",
    "\n#JSUB<begin-job>\n",
    "# This data would come from reading summary files.", "\n",
    "#JSUB<summary-name>ProtocolName", "\n",
    "bash echo \"cmd 01\"", "\n",
    "jcheck_resume", "\n",
    "bash echo \"cmd 02\"", "\n",
    "dummy10 arg1 arg2", "\n",
    "bash echo \"cmd 03\"", "\n",
    "\n#JSUB<finish-job>",
    "\nprocess_job\n"
  )
  @test create_jobs_from_summary_(summaryFilePath, suppliedSummaryDict, commonFunctions, checkpointsDict; 
    jobFilePrefix="jlang_function_test_files/job_files/", filePathOverride=nothing, root="root", jobFileSuffix=".lsf",
    #tagBegin="#JSUB<begin-job>", tagFinish="#JSUB<finish-job>", tagCheckpoint="jcheck_", headerPrefix="#!/bin/bash\n" , headerSuffix="", summaryFile="", jobID=nothing, jobDate=nothing, appendOptions=true
    jobID="jobID0000", jobDate="JOBDATE0_000000", rootSleepSeconds="7.7"
  ) == Dict(
    "root"   => "jlang_function_test_files/job_files/ut_create_jobs_from_summary_root.lsf",
    "second" => "jlang_function_test_files/job_files/ut_create_jobs_from_summary_second.lsf",
    "first"  => "jlang_function_test_files/job_files/ut_create_jobs_from_summary_first.lsf",
  )
  @test expectedFileContents01 == readall(expectedFilePath01)
  # O=split(readall(expectedFilePath01), '\n')
  # E=split(expectedFileContents01, '\n')
  # compare_arrays(split(readall(expectedFilePath01), '\n'), split(expectedFileContents01, '\n'))
  @test expectedFileContents02 == readall(expectedFilePath02)
  # O=split(readall(expectedFilePath02), '\n')
  # E=split(expectedFileContents02, '\n')
  # compare_arrays(split(readall(expectedFilePath02), '\n'), split(expectedFileContents02, '\n'))
  @test expectedFileContents03 == readall(expectedFilePath03)

  ## get_jobpriorityarray(dictSummaries)
  # Supplied input
  root = [];
  push!(root, ["# This data would come from reading summary files."]);
  push!(root, ["#JSUB<summary-name>ProtocolName"]);
  push!(root, ["bash echo \"cmd 01\""]);
  group1 = [];
  push!(group1, ["#JGROUP first"]);
  push!(group1, ["jcheck_resume"]);
  push!(group1, ["dummy10_1 arg1_1 arg2_1"]);
  group2 = [];
  push!(group2, ["#JGROUP second"]);
  push!(group2, ["dummy12 arg1 arg2"]);
  push!(group2, ["bash echo \"cmd 22\""]);
  group3 = [];
  push!(group3, ["#JGROUP third second"]);
  push!(group3, ["bash echo \"cmd 21\""]);
  push!(group3, ["bash echo \"cmd 22\""]);
  group4 = [];
  push!(group4, ["#JGROUP fourth third"]);
  group5 = [];
  push!(group5, ["#JGROUP fifth fourth second"]);
  push!(group5, ["bash echo \"cmd 22\""]);
  group6 = [];
  push!(group6, ["#JGROUP sixths first fifth"]);
  push!(group6, ["bash echo \"cmd 22\""]);
  suppliedSummaryDict = Dict(
    "root" => root,
    "first" => group1,
    "second" => group2,
    "third" => group3,
    "fourth" => group4,
    "fifth" => group5,
    "sixths" => group6,
  );
  @test get_groupparents(root, ""; root="root", tagSplit="#JGROUP", jobDate="") == []
  @test get_groupparents(group1, ""; root="root", tagSplit="#JGROUP", jobDate="") == ["root"]
  @test get_groupparents(group2, ""; root="root", tagSplit="#JGROUP", jobDate="") == ["root"]
  @test get_groupparents(group3, ""; root="root", tagSplit="#JGROUP", jobDate="") == ["root", "second"]
  @test get_groupparents(group4, ""; root="root", tagSplit="#JGROUP", jobDate="") == ["root", "third"]
  @test get_groupparents(group5, ""; root="root", tagSplit="#JGROUP", jobDate="") == ["root", "fourth", "second"]
  @test get_groupparents(group6, ""; root="root", tagSplit="#JGROUP", jobDate="") == ["root", "first", "fifth"]
  expectedPriorities01 = Dict(
    "root" => 0,
    "first" => 1,
    "second" => 1,
    "third" => 2,
    "fourth" => 3,
    "fifth" => 4,
    "sixths" => 5,
  );
  suppliedDictPaths01 = Dict(
    "root" => "path/to/job_root.lsf",
    "first" => "path/to/job_first.lsf",
    "second" => "path/to/job_second.lsf",
    "third" => "path/to/job_third.lsf",
    "fourth" => "path/to/job_fourth.lsf",
    "fifth" => "path/to/job_fifth.lsf",
    "sixths" => "path/to/job_sixths.lsf",
  )
  @test get_priorities(suppliedSummaryDict, suppliedDictPaths01; root="root", tagSplit="#JGROUP") == expectedPriorities01

  # Test that an error is thrown if group names are repeated
  root = [];
  push!(root, ["# This data would come from reading summary files."]);
  push!(root, ["#JSUB<summary-name>ProtocolName"]);
  push!(root, ["bash echo \"cmd 01\""]);
  group1 = [];
  push!(group1, ["#JGROUP first"]);
  push!(group1, ["jcheck_resume"]);
  push!(group1, ["dummy10_1 arg1_1 arg2_1"]);
  group2 = [];
  push!(group2, ["#JGROUP second"]);
  push!(group2, ["dummy12 arg1 arg2"]);
  push!(group2, ["bash echo \"cmd 22\""]);
  group3 = [];
  push!(group3, ["#JGROUP third second"]);
  push!(group3, ["bash echo \"cmd 21\""]);
  push!(group3, ["bash echo \"cmd 22\""]);
  group4 = [];
  push!(group4, ["#JGROUP second third"]);
  group5 = [];
  push!(group5, ["#JGROUP fifth fourth second"]);
  push!(group5, ["bash echo \"cmd 22\""]);
  group6 = [];
  push!(group6, ["#JGROUP sixths first fifth"]);
  push!(group6, ["bash echo \"cmd 22\""]);
  suppliedSummaryDict = Dict(
    "root" => root,
    "first" => group1,
    "second" => group2,
    "third" => group3,
    "second" => group4,
    "fifth" => group5,
    "sixths" => group6,
  )
  suppliedDictPaths = Dict(
    "root" => "path/to/job_root.lsf",
    "first" => "path/to/job_first.lsf",
    "second" => "path/to/job_second.lsf",
    "third" => "path/to/job_third.lsf",
    "second" => "path/to/something.lsf",
    "fifth" => "path/to/job_fifth.lsf",
    "sixths" => "path/to/job_sixths.lsf",
  )
  @test_throws ErrorException get_priorities(suppliedSummaryDict, suppliedDictPaths; root="root", tagSplit="#JGROUP")

  # Test that an error is thrown if group names are repeated
  root = [];
  push!(root, ["# This data would come from reading summary files."]);
  push!(root, ["#JSUB<summary-name>ProtocolName"]);
  push!(root, ["bash echo \"cmd 01\""]);
  group1 = [];
  push!(group1, ["#JGROUP first"]);
  push!(group1, ["jcheck_resume"]);
  push!(group1, ["dummy10_1 arg1_1 arg2_1"]);
  group2 = [];
  push!(group2, ["#JGROUP second"]);
  push!(group2, ["dummy12 arg1 arg2"]);
  push!(group2, ["bash echo \"cmd 22\""]);
  group3 = [];
  push!(group3, ["#JGROUP third second"]);
  push!(group3, ["bash echo \"cmd 21\""]);
  push!(group3, ["bash echo \"cmd 22\""]);
  group4 = [];
  push!(group4, ["#JGROUP second third"]);
  group5 = [];
  push!(group5, ["#JGROUP fifth fourth second"]);
  push!(group5, ["bash echo \"cmd 22\""]);
  group6 = [];
  push!(group6, ["#JGROUP sixths first fifth"]);
  push!(group6, ["bash echo \"cmd 22\""]);
  suppliedSummaryDict = Dict(
    "root" => root,
    "first" => group1,
    "third" => group3,
    "fifth" => group5,
    "sixths" => group6,
  )
  suppliedDictPaths = Dict(
    "root" => "path/to/job_root.lsf",
    "first" => "path/to/job_first.lsf",
    "third" => "path/to/job_third.lsf",
    "fifth" => "path/to/job_fifth.lsf",
    "sixths" => "path/to/job_sixths.lsf",
  )
  @test_throws ErrorException get_priorities(suppliedSummaryDict, suppliedDictPaths; root="a", tagSplit="#JGROUP")

  # Many f-number entries are used to check that repetative values don't somehow inflate rank
  suppliedSummaryDict = Dict(
    "a" => ["##JGROUP this should be ignored"],
    "b" => ["#JGROUP b"],
    "c" => ["#JGROUP c"],
    "d" => ["#JGROUP d c"],
    "e" => ["#JGROUP e b c"],
    "f1" => ["#JGROUP f1 d"],
    "f2" => ["#JGROUP f2 d"],
    "f3" => ["#JGROUP f3 d"],
    "f4" => ["#JGROUP f4 d"],
    "f5" => ["#JGROUP f5 d"],
    "f6" => ["#JGROUP f6 d"],
    "f7" => ["#JGROUP f7 d"],
    "f8" => ["#JGROUP f8 d"],
    "f9" => ["#JGROUP f9 d"],
    "f10" => ["#JGROUP f10 d"],
    "f11" => ["#JGROUP f11 d"],
    "f12" => ["#JGROUP f12 d"],
    "f13" => ["#JGROUP f13 d"],
    "f14" => ["#JGROUP f14 d"],
    "f15" => ["#JGROUP f15 d"],
    "f16" => ["#JGROUP f16 d"],
    "f17" => ["#JGROUP f17 d"],
    "f18" => ["#JGROUP f18 d"],
    "f19" => ["#JGROUP f19 d"],
    "f20" => ["#JGROUP f20 d"],
    "f21" => ["#JGROUP f21 d"],
    "f22" => ["#JGROUP f22 d"],
    "f23" => ["#JGROUP f23 d"],
    "f24" => ["#JGROUP f24 d"],
    "f25" => ["#JGROUP f25 d"],
    "g" => ["#JGROUP g e"],
    "h" => ["#JGROUP h f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 f25"],
    "i" => ["#JGROUP i j l h"],
    "j" => ["#JGROUP j b"],
    "k" => ["#JGROUP k e d"],
    "l" => ["#JGROUP l b g"],
  )
  suppliedDictPaths02 = Dict(
    "f17" => "path/to/f17.lsf",
    "c" => "path/to/c.lsf",
    "e" => "path/to/e.lsf",
    "f13" => "path/to/f13.lsf",
    "f24" => "path/to/f24.lsf",
    "b" => "path/to/b.lsf",
    "f4" => "path/to/f4.lsf",
    "f2" => "path/to/f2.lsf",
    "f8" => "path/to/f8.lsf",
    "a" => "path/to/a.lsf",
    "h" => "path/to/h.lsf",
    "f18" => "path/to/f18.lsf",
    "f22" => "path/to/f22.lsf",
    "f11" => "path/to/f11.lsf",
    "f1" => "path/to/f1.lsf",
    "f5" => "path/to/f5.lsf",
    "d" => "path/to/d.lsf",
    "f9" => "path/to/f9.lsf",
    "f23" => "path/to/f23.lsf",
    "g" => "path/to/g.lsf",
    "i" => "path/to/i.lsf",
    "j" => "path/to/j.lsf",
    "f21" => "path/to/f21.lsf",
    "f20" => "path/to/f20.lsf",
    "k" => "path/to/k.lsf",
    "l" => "path/to/l.lsf",
    "f10" => "path/to/f10.lsf",
    "f14" => "path/to/f14.lsf",
    "f12" => "path/to/f12.lsf",
    "f19" => "path/to/f19.lsf",
    "f25" => "path/to/f25.lsf",
    "f3" => "path/to/f3.lsf",
    "f6" => "path/to/f6.lsf",
    "f7" => "path/to/f7.lsf",
    "f16" => "path/to/f16.lsf",
    "f15" => "path/to/f15.lsf",
  )
  expectedPriorities02 = Dict(
    "a" => 0,
    "b" => 1,
    "c" => 1,
    "d" => 2,
    "e" => 2,
    "f1" => 3,
    "f10" => 3,
    "f11" => 3,
    "f12" => 3,
    "f13" => 3,
    "f14" => 3,
    "f15" => 3,
    "f16" => 3,
    "f17" => 3,
    "f18" => 3,
    "f19" => 3,
    "f2" => 3,
    "f20" => 3,
    "f21" => 3,
    "f22" => 3,
    "f23" => 3,
    "f24" => 3,
    "f25" => 3,
    "f3" => 3,
    "f4" => 3,
    "f5" => 3,
    "f6" => 3,
    "f7" => 3,
    "f8" => 3,
    "f9" => 3,
    "g" => 3,
    "h" => 4,
    "i" => 5,
    "j" => 2,
    "k" => 3,
    "l" => 4,
  )
  @test get_priorities(suppliedSummaryDict, suppliedDictPaths02; root="a", tagSplit="#JGROUP") == expectedPriorities02

  problemSumamryDict = Dict(
    "first" => Any[UTF8String["#JGROUP first"],UTF8String["OUTFILE=\"results/outPrefix_\"sample0001A "],UTF8String["bash ../../bash_scripts/concat.sh \"\$OUTFILE\"_first.txt sub01X sub01Y"],UTF8String["bash ../../bash_scripts/concat.sh \"\$OUTFILE\"_first.txt sub01Y sub01Z"]],
    "last" => Any[UTF8String["#JGROUP last first second third"],UTF8String["OUTFILE=\"results/outPrefix_\"sample0001A"],UTF8String["bash ../../bash_scripts/catfiles.sh \"\$OUTFILE\".txt \"\$OUTFILE\"_first.txt \"\$OUTFILE\"_second.txt \"\$OUTFILE\"_third.txt"]],
    "root" => Any[UTF8String["# Basic integration test protocol involving only a call to a bash script that writes a single line to a text file."],UTF8String["#JSUB<summary-name> sample0001A"],UTF8String["echo \"Processing summary data from: \"sample0001A"],UTF8String["# root group "],UTF8String["OUTFILE=\"results/outPrefix_\"sample0001A # Note: this is an example of what not to do! After the protocol is split OUTFILE will be undeclared in subsequent groups unless it is declared there again using variables from vars and fvars but NOT variables from the top of the script."],UTF8String["bash ../../bash_scripts/trivial.sh \"\$OUTFILE\".txt"],UTF8String["bash ../../bash_scripts/trivial.sh \"\$OUTFILE\".txt"]],
    "second" => Any[UTF8String["#JGROUP second"],UTF8String["OUTFILE=\"results/outPrefix_\"sample0001A "],UTF8String["bash ../../bash_scripts/concat.sh \"\$OUTFILE\"_second.txt sub01Y sub01Z"],UTF8String["bash ../../bash_scripts/concat.sh \"\$OUTFILE\"_second.txt sub01Z sub01X"]],
    "third" => Any[UTF8String["#JGROUP third"],UTF8String["OUTFILE=\"results/outPrefix_\"sample0001A "],UTF8String["bash ../../bash_scripts/concat.sh \"\$OUTFILE\"_third.txt sub01Z sub01X"],UTF8String["bash ../../bash_scripts/concat.sh \"\$OUTFILE\"_third.txt sub01X sub01Y"]],
  )
  examplePathsDict = Dict(
    "first" => "path/example/first.lsf",
    "last" => "path/example/last.lsf",
    "root" => "path/example/root.lsf",
    "second" => "path/example/second.lsf",
    "third" => "path/example/third.lsf",
  )
  expectedPriorities03 = Dict(
    "first" => 1,
    "last" => 2,
    "root" => 0,
    "second" => 1,
    "third" => 1,
  )
  @test get_priorities(problemSumamryDict, examplePathsDict; root="root", tagSplit="#JGROUP") == expectedPriorities03;

  ## order_by_dictionary(ranks::Dict, toSort::Dict)
  suppliedRanks = Dict(
    "keyA1" => 0,
    "keyA2" => 0,
    "keyB1" => 1,
    "keyB2" => 1,
    "keyC" => 2,
    "keyD" => 3,
    "keyE1" => 4,
    "keyE2" => 4,
    "keyE3" => 4,
    "keyF" => 5,
  );
  suppliedToSort = Dict(
    "keyA1" => "out0a",
    "keyA2" => "out0b",
    "keyB1" => "out1a",
    "keyB2" => "out1b",
    "keyC" => "out2",
    "keyD" => "out3",
    "keyE1" => "out4a",
    "keyE2" => "out4b",
    "keyE3" => "out4c",
    "keyF" => "out5",
  );
  expectedSorted = [
    "out0b",
    "out0a",
    "out1a",
    "out1b",
    "out2",
    "out3",
    "out4b",
    "out4c",
    "out4a",
    "out5",
  ]
  @test order_by_dictionary(suppliedRanks, suppliedToSort) == expectedSorted

  ## map_flags_sjb(flagSummaries, flagJobs, flagSubmit)
  @test map_flags_sjb(false, false, false) == "111"

  ## get_argument(dictArguments::Dict, option; verbose=false)
  suppliedArguments = Dict(
    "suppress-warnings"  =>  false,
    "protocol"  =>  "basic.protocol",
    "fvars"  =>  nothing,
    "submit-jobs"  =>  false,
  );
  @test get_argument(suppliedArguments, "protocol", verbose=false) == "basic.protocol"
  @test_throws ErrorException get_argument(suppliedArguments, "fvars", verbose=false)
  @test get_argument(suppliedArguments, "submit-jobs", verbose=false) == false
  @test get_argument(suppliedArguments, "fvars", verbose=false, optional=true) == nothing
  @test get_argument(suppliedArguments, "submit-jobs", verbose=false, optional=true) == false
  @test get_argument(suppliedArguments, "fvars", verbose=false, optional=true, default="default.fvars") == "default.fvars"
  @test get_argument(suppliedArguments, "submit-jobs", verbose=false, optional=true, default=true) == false # optional but non-nothign so default value is not used

  ## arrArr2string
  arrArr = []
  push!(arrArr, ["a1", "a2", "a3"])
  push!(arrArr, ["b1", "b2", "b3"])
  push!(arrArr, ["c1", "c2", "c3"])
  push!(arrArr, ["d1", "d2", "d3"])
  @test arrArr2string(arrArr) == "a1\na2\na3\nb1\nb2\nb3\nc1\nc2\nc3\nd1\nd2\nd3"
  @test arrArr2string(arrArr, delim="___") == "a1___a2___a3___b1___b2___b3___c1___c2___c3___d1___d2___d3"

  ## get_zip_dir_path(dirJobs; suffix=".tar.gz")
  @test get_zip_dir_path("/") == "portable_jobs.tar.gz" # Test case when things are being done in the root directory (you never know)
  @test get_zip_dir_path("/absolute/dirA") == "/absolute/dirA.tar.gz" # Test case in a non-root directory
  @test get_zip_dir_path("relative/dirR") == "relative/dirR.tar.gz"

  @test get_portable_dir_path("/") == "portable_jobs" # Test case when things are being done in the root directory (you never know)
  @test get_portable_dir_path("/absolute/dirA") == "/absolute/dirA" # Test case in a non-root directory
  @test get_portable_dir_path("relative/dirR") == "relative/dirR"

  # # 
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




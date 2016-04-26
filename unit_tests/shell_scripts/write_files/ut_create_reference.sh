#!/bin/bash

# Read arguments
arg1="$1"
arg2="$2"
arg3="$3"

echo "Unit test shell script - Running ""$0"
echo "Joining two input files into a hypothetical \"reference\" file to be used for further tests."
echo "input file 1: ""$arg1"
echo "input file 2: ""$arg2"
echo "output file: ""$arg3"

echo "Test \"reference\" file:" > ${arg3}
cat ${arg3} ${arg1} ${arg2} > ${arg3}

echo "finished running $0"


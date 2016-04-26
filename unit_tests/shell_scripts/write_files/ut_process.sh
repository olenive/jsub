#!/bin/bash

# Read arguments
arg1="$1"
arg2="$2"
arg3="$3"

echo "Pretending to process data for each sample. Output file contains the sample ID followed by the reference file."
echo "Unit test shell script - Running $0 with arguments: "
echo "input file: ""$arg1"
echo "input data to append to file: ""$arg2"
echo "output file: ""$arg3"

echo "Imaginary prcoessing of sample ""$arg1" > ${arg3}
cat ${arg3}  ${arg2} > ${arg3}

echo "finished running $0" using inputs "




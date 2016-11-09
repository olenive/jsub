#!/bin/bash
jsub="julia ../../jsub.jl "

## Run example code
$jsub --protocol echo.protocol --header-from-file "../my_job_header.txt"

# Running this example should produce the following files:
# ./echo_1_1.completed
# ./echo_1_1.error
# ./echo_1_1.lsf
# ./echo_1_1.output
# ./echo_1.log
# ./echo_1.summary
# ./echo.list-jobs
# ./echo.list-jobs.submitted
# ./echo.list-summaries
# ./example_01_output.txt
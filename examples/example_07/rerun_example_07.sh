#!/bin/bash
jsub="julia ../../jsub.jl "

## Run example code
mkdir -p dummy_output # create the directory for job results as indicated in the vars07.vars file

cp dummy_data/missing/data_2B.txt dummy_data/data_2B.txt

echo progoress/incomplete/cat07_vars07_fvars07_2_2.incomplete > resumed.list-summaries

$jsub --generate-jobs \
     --list-summaries resumed.list-summaries \
     --header-from-file "../my_job_header.txt" \
     --job-prefix "re_jobs/re_" \
     --prefix-lsf-out "re_lsf_out/lsf_" \
     --prefix-completed "re_progoress/completed/" \
     --prefix-incomplete "re_progoress/incomplete/"

$jsub --submit-jobs --list-jobs re_jobs/re_resumed.list-jobs

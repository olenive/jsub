#!/bin/bash
jsub="julia ../../jsub.jl "

## Run example code
mkdir -p dummy_output # create the directory for job results as indicated in the vars07.vars file

$jsub --generate-summaries --generate-jobs \
     --protocol cat08.protocol \
     --vars vars07.vars \
     --fvars fvars07.fvars \
     --header-from-file "../my_job_header.txt" \
     --summary-prefix "summaries/" \
     --job-prefix "jobs/" \
     --prefix-lsf-out "lsf_out/" \
     --prefix-completed "progoress/completed/" \
     --prefix-incomplete "progoress/incomplete/"

$jsub --submit-jobs --list-jobs "jobs"/"cat08_vars07_fvars07.list-jobs"

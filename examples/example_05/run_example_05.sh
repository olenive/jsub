#!/bin/bash
jsub="julia ../../jsub.jl "

## Run example code
$jsub --generate-summaries \
     --protocol echo03.protocol \
     --vars vars02.vars \
     --fvars fvars03.fvars \
     --summary-prefix "summaries/sumpre_"

$jsub --generate-jobs \
     --list-summaries summaries/sumpre_echo03_vars02_fvars03.list-summaries \
     --header-from-file "../my_job_header.txt" \
     --job-prefix "jobs/jobpre_" \
     --prefix-lsf-out "lsf_out/lsf_" \
     --prefix-completed "progoress/completed/" \
     --prefix-incomplete "progoress/incomplete/"

$jsub --submit-jobs \
     --list-jobs jobs/jobpre_sumpre_echo03_vars02_fvars03.list-jobs

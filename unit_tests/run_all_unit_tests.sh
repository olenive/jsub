#!/bin/bash

cd jlang_functions
julia ut_jsub_common.jl
cd ..

cd bash_functions
bash ut_jsub_bash.sh
cd ..



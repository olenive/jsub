#!/bin/bash

# Unit tests for bash functions using the lehmannro/assert.sh framework

. assert.sh

source "../../common_functions/job_processing.sh"

echo "Running unit tests of bash functions..."

## EXAMPLES ##
# assert "echo test" "test"
# # `seq 3` is expected to print "1", "2" and "3" on different lines
# assert "seq 3" "1\n2\n3"
# # exit code of `true` is expected to be 0
# assert_raises "true"
# # exit code of `false` is expected to be 1
# assert_raises "false" 1
# # expect `exit 127` to terminate with code 128
# assert_raises "exit 127" 128
##############




# end of test suite
assert_end examples


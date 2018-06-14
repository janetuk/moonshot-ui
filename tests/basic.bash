#!/bin/bash
#
# This runs the basic test repeatedly - the multithreaded test is somewhat
# stochastic. When using the MT-unsafe dbus_glib libraries, it failed roughly
# a third of the time. Using that as a baseline, a few tens should be adequate
# to be confident that it is "never" failing.
set -e # script fails if any commands fail

N_REPS=100
TEST_SCRIPT=tests/basic

echo "Running $TEST_SCRIPT $N_REPS times."
for (( i=0; i < $N_REPS; i++ )); do
    $TEST_SCRIPT > /dev/null
done

exit 0

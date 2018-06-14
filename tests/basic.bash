#!/bin/bash
#
# This runs the basic test repeatedly - the multithreaded test is somewhat
# stochastic. When using the MT-unsafe dbus_glib libraries, it failed roughly
# a third of the time. Using that as a baseline, a few tens should be adequate
# to be confident that it is "never" failing.
set -e

N_REPS=100
TEST_SCRIPT=tests/basic

# Tests run before "make install", so we can't rely on DBus to autostart
# moonshot. Set up a private bus and run moonshot ourselves.
unset DBUS_SESSION_BUS_ADDRESS
readarray -t array < <(dbus-daemon --fork --nopidfile --print-pid --print-address --config-file org.janet.Moonshot.conf)
export DBUS_SESSION_BUS_ADDRESS=${array[0]}
export DBUS_SESSION_BUS_PID=${array[1]}

src/moonshot --dbus-launched &
MOONSHOT_PID=$!

# Ensure moonshot and dbus-proxy are closed when we exit
trap "kill ${MOONSHOT_PID}; kill ${DBUS_SESSION_BUS_PID}" EXIT

sleep 5 # let moonshot come up

echo "Running $TEST_SCRIPT $N_REPS times."
for (( i=0; i < $N_REPS; i++ )); do
    $TEST_SCRIPT > /dev/null
done

exit 0

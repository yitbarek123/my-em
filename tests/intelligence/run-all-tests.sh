#!/bin/bash
set -e

cd src
make || ls /test


# host ip v4 address
HOST_ADDRESS="0.0.0.0"

# identify the host port
HOST_PORT=7084

# number of times each test will be performed
EPOCHS_COUNT=10

# identify an acceptance threshold for the success rate, if it is not reached the test is rejected
ACCEPTANCE_THRESHOLD=0.8

# run all tests
for test in "../assets"/*.test
    do
        ./IntelligenceTest $test $HOST_ADDRESS $HOST_PORT $EPOCHS_COUNT $ACCEPTANCE_THRESHOLD
    done

#!/bin/bash
set -e

ls /home/protos
cd src

make || ls /test/src

# delay to allow session manager time to start
sleep 5
# run all tests
./IntegrationTest $SESSION_MANAGER_HOST $SESSION_MANAGER_PORT

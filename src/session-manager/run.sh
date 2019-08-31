#!/bin/bash

set -e

: ${DB_FILE:="data/sessions.db"}
: ${SERVER_PORT:=${INTERNAL_PORT_SESSION_MANAGER}}

. build_proto.sh

python3.6 session_manager_server.py --db-file ${DB_FILE} --port ${SERVER_PORT}

#!/bin/sh

cp -r ../../protos api/
docker build -t session-manager .
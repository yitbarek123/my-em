#!/bin/bash

python3.6 -m grpc_tools.protoc -I $PROTOS_PATH --python_out=./api --grpc_python_out=./api ${PROTOS_PATH}session_manager.proto
python3.6 -m grpc_tools.protoc -I $PROTOS_PATH --python_out=./api --grpc_python_out=./api ${PROTOS_PATH}opencog_services.proto

python3.6 -m grpc_tools.protoc -I $PROTOS_PATH --python_out=./api --grpc_python_out=./api ${PROTOS_PATH}named_entity_recognition.proto
python3.6 -m grpc_tools.protoc -I $PROTOS_PATH --python_out=./api --grpc_python_out=./api ${PROTOS_PATH}sentiment_analysis.proto

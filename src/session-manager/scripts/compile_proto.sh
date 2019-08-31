#!/bin/sh

PROTOS_DIR="../../protos"
if [ ! -d "$PROTOS_DIR" ]; then
    cp -r $PROTOS_DIR api/
fi

python3.6 -m grpc_tools.protoc -I ${PROTOS_DIR} --python_out=api/ --grpc_python_out=api/ session_manager.proto
python3.6 -m grpc_tools.protoc -I ${PROTOS_DIR} --python_out=api/ --grpc_python_out=api/ opencog_services.proto

python3.6 -m grpc_tools.protoc -I ${PROTOS_DIR} --python_out=api/ --grpc_python_out=api/ named_entity_recognition.proto
python3.6 -m grpc_tools.protoc -I ${PROTOS_DIR} --python_out=api/ --grpc_python_out=api/ sentiment_analysis.proto

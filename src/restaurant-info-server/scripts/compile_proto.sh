#!/bin/sh

cp -r ../protos api/

python3.6 -m grpc_tools.protoc -I api/protos/ --python_out=api/ --grpc_python_out=api/ restaurant_info.proto
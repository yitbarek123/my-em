#!/bin/sh

./scripts/compile_proto.sh

if python3.6 -m nose -v tests/; then
	echo "Session Manager tests succeeded"
else
	echo "Session Manager tests failed"
fi
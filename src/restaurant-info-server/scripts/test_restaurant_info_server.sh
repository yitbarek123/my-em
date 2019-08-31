#!/bin/sh

./scripts/compile_proto.sh

if python3.6 -m unittest tests/test_restaurant_info_server.py; then
	echo "Restaurant info server test succeeded"
else
	echo "Restaurant info server test failed"
fi
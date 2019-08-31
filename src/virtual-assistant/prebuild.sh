#!/bin/sh
set -e

mkdir -p lib/conceptnet
cp ../../external/conceptnet-server/api/scheme/conceptnet.scm lib/conceptnet/conceptnet.scm

mkdir -p lib/sumo
cp ../../external/sumo-server/api/scheme/sumo.scm lib/sumo/sumo.scm

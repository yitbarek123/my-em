#!/bin/bash

set -e

. build_proto.sh

nosetests -vs

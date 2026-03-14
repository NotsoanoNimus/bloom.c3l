#!/bin/bash
#
# Tests run with Stockfish by default. The submodule should always remain pinned to a stable release.
#
#
TEST_OPTS="-O${1:-0} --libdir .. --lib bloom"

echo -e "\n===== Running unit tests..."
c3c compile-test ${TEST_OPTS} ./test/ || { echo "Unit tests failed. Aborting." && exit 1; }

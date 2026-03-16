#!/bin/bash
#
# Test bloom filters library.
#   First, unit tests are always run.
#   Then, on the first test run, some testing artifacts are decompressed and a few static bloom filters are generated from this data.
#   Finally, on each run, the static filters will be imported and tested just a biiiiit more thoroughly.
#
#
TEST_OPTS="-O${1:-0} --libdir .. --lib bloom"

echo -e "\n===== Running unit tests..."
c3c compile-test ${TEST_OPTS} ./test/unit/ || { echo "Unit tests failed. Aborting." && exit 1; }

if [[ ! -d test/int/artifacts ]]; then
	tar zxvf ./test/int/artifacts.tgz || { echo "Failed to extract artifacts tarball. Aborting." && exit 1; }
fi
echo -e "\n\n\n===== Running integration tests..."
# note: set env var NON_INTERACTIVE=yes to forego interacting with these test applications
for x in `find ./test/int/ -maxdepth 1 -type f -name '*.c3'`; do
	c3c compile-run ${TEST_OPTS} $x -- "${NON_INTERACTIVE:-yes}" \
		|| { echo "Integration test '$(basename "$x")' failed. Aborting." && exit 1; }
done

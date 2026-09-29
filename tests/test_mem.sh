#!/bin/bash
# shellcheck disable=SC2034 # ignore seemingly unused test_invoke params
# shellcheck source=/dev/null
source "$TEST_SH"

php_bin=$(command -v "${PHP[0]}")
symbol_file=$php_bin
build_id=$(readelf -n "$php_bin" | awk '/Build ID/{print $3; exit}')
if [ "${#build_id}" -ge 2 ]; then
    debug_file="/usr/lib/debug/.build-id/${build_id:0:2}/${build_id:2}.debug"
    if [ -f "$debug_file" ]; then
        symbol_file=$debug_file
    fi
fi

if { $PHPSPY -v | grep -q USE_ZEND=y; }; then
    test_skip='alloc_globals not available in USE_ZEND=y build'
elif { objdump -tT "$symbol_file" | grep -q alloc_globals; }; then
    test_phpspy_opts=(--memory-usage -- "${PHP[@]}" -r 'sleep(1);')
    declare -A test_expected
    test_expected[mem]='^# mem \d+ \d+$'
else
    test_skip='alloc_globals symbol not found'
fi
test_invoke

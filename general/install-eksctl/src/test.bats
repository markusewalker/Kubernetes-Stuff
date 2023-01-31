#!/bin/bash

setup() {
    load "../test/test_helper/bats-support/load"
    load "../test/test_helper/bats-assert/load"
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    PATH="$DIR/../src:$PATH"
}

@test "run script's usage" {
    run install-eksctl.sh -h
}

@test "run script" {
    run install-eksctl.sh
}

@test "verify eksctl is installed" {
    eksctl version
    RESULT=$?
    [ "${RESULT}" -eq 0 ]
}
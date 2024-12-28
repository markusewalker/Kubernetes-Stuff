#!/bin/bash

setup() {
    load "../test/test_helper/bats-support/load"
    load "../test/test_helper/bats-assert/load"
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    PATH="$DIR/../src:$PATH"
}

@test "run script's usage" {
    run remove-worker.sh -h
}

@test "verify kubectl is installed" {
    kubectl version
    RESULT=$?
    [ "${RESULT}" -eq 0 ]
}

@test "verify ~/.kube/config exists" {
    [ -f ~/.kube/config ]
}
#!/bin/bash

setup() {
    load "../test/test_helper/bats-support/load"
    load "../test/test_helper/bats-assert/load"
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    PATH="$DIR/../src:$PATH"
}

@test "run script's usage" {
    run basic-k8s-commands.sh -h
}

@test "verify kubectl is installed" {
    kubectl version
    RESULT=$?
    [ "${RESULT}" -eq 0 ]
}

@test "verify ~/.kube/config exists" {
    [ -f ~/.kube/config ]
}

@test "get k8s nodes silently" {
    run basic-k8s-commands.sh -n
}

@test "get k8s nodes interactively" {
    run nodes-expect.sh
}

@test "get k8s pods interactively" {
    run pods-expect.sh
}
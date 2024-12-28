#!/bin/bash

setup() {
    load "../test/test_helper/bats-support/load"
    load "../test/test_helper/bats-assert/load"
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    PATH="$DIR/../src:$PATH"
}

@test "run script's usage" {
    run create-gke-cluster.sh -h
}

@test "run script with invalid argument" {
    run create-gke-cluster.sh -a
}

@test "run script" {
    skip
    run create-gke-cluster.sh
}

@test "verify gcloud is installed" {
    gcloud version
    RESULT=$?
    [ "${RESULT}" -eq 0 ]
}

@test "verify cluster is created" {
    kubectl get nodes
    RESULT=$?
    [ "${RESULT}" -eq 0 ]
}
#!/bin/bash

BIN_PATH=scratch/usr/local/bin
BASH_COMP=scratch/etc/bash_completion.d

[ -d "${BIN_PATH}" ] || mkdir -p "${BIN_PATH}"
[ -d "${BASH_COMP}" ] || mkdir -p "${BASH_COMP}"

PATH=${BIN_PATH}:${PATH}

# shellcheck disable=SC1091
. ../../../scripts/library/bin.sh

    bin_check oc
    bin_check helm
    bin_check odo
    bin_check opm
    bin_check tkn
    bin_check kn

    bin_check rhoas
    bin_check subctl
    bin_check kubevirt
    bin_check kustomize

    bin_check oc-mirror
    bin_check krew
    bin_check kubectl-operator
    bin_check rclone
    bin_check restic
    bin_check sops
    bin_check age

tar -czf tools-x86_64.tgz -C scratch .
rm scratch -rf

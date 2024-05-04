#!/bin/bash

BIN_PATH=scratch/usr/local/bin
BASH_COMP=scratch/etc/bash_completion.d

[ -d "${BIN_PATH}" ] || mkdir -p "${BIN_PATH}"
[ -d "${BASH_COMP}" ] || mkdir -p "${BASH_COMP}"

PATH=${BIN_PATH}:${PATH}

# shellcheck disable=SC1091
. bin.sh

# cleanup
rm -rf scratch .oc-mirror.log tools-x86_64.tgz

bin_check oc
bin_check helm
bin_check odo
bin_check tkn
bin_check kn

bin_check subctl
bin_check virtctl
bin_check kustomize

bin_check yq
bin_check oc-mirror
bin_check krew
bin_check kubectl-operator
bin_check rclone
bin_check restic
bin_check sops
bin_check age
bin_check crane

rm "${BIN_PATH}"/LICENSE
tar -czf tools-x86_64.tgz -C scratch . --owner=0 --group=0

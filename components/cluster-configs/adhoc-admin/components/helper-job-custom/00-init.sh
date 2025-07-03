#!/bin/bash
# set -x

usage(){
  echo "

    oc -n adhoc-admin \
      create cm demo-adhoc \
      --from-file=scratch/
  "
}

usage

exit 1

#!/bin/bash
# set -x

usage(){
  echo "

    oc -n adhoc-admin \
      create cm demo-adhoc \
      --dry-run=client \
      --from-file=scripts/ | oc apply -f -
  "
}

usage

exit 1

#!/bin/bash
# shellcheck disable=SC2015,SC1091
set -e

setup_venv(){
  python3 -m venv venv
  source venv/bin/activate
  pip install -q -U pip
  pip install -q awscli

  check_venv || return
}

check_venv(){
  # activate python venv
  [ -d venv ] && . venv/bin/activate || setup_venv
  [ -e requirements.txt ] && pip install -q -r requirements.txt
}

# activate python venv
check_venv

# chcek scripts
which shellcheck && shellcheck scripts/*.sh

# check spelling
pyspelling -c .pyspelling.yml

# check yaml
yamllint . && echo "YAML check passed :)"

# validate manifests
scripts/validate_manifests.sh

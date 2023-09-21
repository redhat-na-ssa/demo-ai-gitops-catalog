#!/bin/sh
# shellcheck disable=SC1091

check_venv(){
  # activate python venv
  [ -d venv ] || setup_venv 
  . venv/bin/activate
  [ -e requirements.txt ] && pip install -q -r requirements.txt
}

setup_venv(){
  python3 -m venv venv
  . venv/bin/activate
  pip install -q -U pip

  check_venv || usage
}

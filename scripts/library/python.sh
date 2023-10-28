#!/bin/bash
# shellcheck disable=SC1091

py_check_venv(){
  # activate python venv
  [ -d venv ] || py_setup_venv 
  . venv/bin/activate
  [ -e requirements.txt ] && pip install -q -r requirements.txt
}

py_setup_venv(){
  python3 -m venv venv
  . venv/bin/activate
  pip install -q -U pip

  py_check_venv || usage
}

#!/bin/bash
set -e

# activate python venv
[ -d venv ] && . venv/bin/activate || exit

# check spelling
pyspelling -c .spellcheck.yaml

# check yaml
yamllint . && echo "YAML check passed :)"
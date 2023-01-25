#!/bin/bash
# shellcheck disable=SC2034,SC2044,SC1091

source "$(dirname "$0")"/workshop.sh

USER=user
PASS=WorkshopPassword

echo "Workshop: Start Setup"

check_init

create_user_htpasswd
create_user_ns

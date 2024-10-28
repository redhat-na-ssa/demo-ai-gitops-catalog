#!/bin/bash

# shellcheck disable=SC1091

RED='\033[1;31m'
NC='\033[0m' # No Color
BLUE='\033[1;36m'
PURPLE='\033[1;35m'
ORANGE='\033[0;33m'

create_log_file() {
    LOG_FILE="runstep_$(date +"%Y%m%d:%H%M").log"
    echo "Log file: ${LOG_FILE}"
    if [ ! -d "logs" ]; then
        loginfo "Creating logs directory"
        mkdir logs
    fi
    touch logs/"${LOG_FILE}"
}

logbanner() {
    echo -e "${PURPLE}====${NC} ${1} ${PURPLE}====${NC}"
    if [ -f "${LOG_FILE}" ]; then
        echo "$(date +"%H:%M:%S") - INFO - $1" >> "${LOG_FILE}"
    fi
}

loginfo() {
    echo -e "${BLUE}INFO:${NC} ${1}"
    if [ -f "${LOG_FILE}" ]; then
        echo "$(date +"%H:%M:%S") - INFO - $1" >> "${LOG_FILE}"
    fi
}

logerror () {
    echo -e "${RED}ERROR:${NC} ${1}"
    if [ -f "${LOG_FILE}" ]; then
        echo "$(date +"%H:%M:%S") - ERROR - $1" >> "${LOG_FILE}"
    fi
}

logwarning () {
    echo -e "${ORANGE}WARNING:${NC} ${1}"
    if [ -f "${LOG_FILE}" ]; then
        echo "$(date +"%H:%M:%S") - WARNING - $1" >> "${LOG_FILE}"
    fi
}

log() {
    echo "$1"
}
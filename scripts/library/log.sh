#!/bin/bash

# shellcheck disable=SC1091

RED='\033[1;31m'
NC='\033[0m' # No Color
BLUE='\033[1;36m'
PURPLE='\033[1;35m'
ORANGE='\033[0;33m'

log(){
  echo "$1"
}

log_banner(){
  echo -e "${PURPLE}====${NC} ${1} ${PURPLE}====${NC}"
  if [ -f "${LOG_FILE}" ]; then
    echo "$(date +"%H:%M:%S") - INFO - $1" >> "${LOG_FILE}"
  fi
}

log_error(){
  echo -e "${RED}ERROR:${NC} ${1}"
  if [ -f "${LOG_FILE}" ]; then
    echo "$(date +"%H:%M:%S") - ERROR - $1" >> "${LOG_FILE}"
  fi
}

log_file_create(){
  LOG_FILE="${1:-step_$(date +"%Y%m%d:%H%M").log}"
  echo "Log file: ${LOG_FILE}"
  if [ ! -d "logs" ]; then
    log_info "Creating logs directory"
    mkdir logs
  fi
  touch logs/"${LOG_FILE}"
}

log_info(){
  echo -e "${BLUE}INFO:${NC} ${1}"
  if [ -f "${LOG_FILE}" ]; then
    echo "$(date +"%H:%M:%S") - INFO - $1" >> "${LOG_FILE}"
  fi
}

log_warning(){
  echo -e "${ORANGE}WARNING:${NC} ${1}"
  if [ -f "${LOG_FILE}" ]; then
    echo "$(date +"%H:%M:%S") - WARNING - $1" >> "${LOG_FILE}"
  fi
}


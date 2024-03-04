#!/bin/bash 

# Author: griznog
# Purpose: Push storage metrics to adafruit.

function die() {
  echo "ERROR: $1"
  usage
}

function usage() {
  echo "$(basename $0) FEEDNAME /path/to/monitor"
  exit 1
}

# Check for a credentials file.
[[ -f ~/.diskmonitor.credentials ]] || \
  die "Please create ~/.diskmonitor.credentials with X_AIO_KEY='YOURKEYVALUE'"


# Get values from credentials file.
source ~/.diskmonitor.credentials
[[ -z ${X_AIO_KEY} ]] && \
  die "X_AIO_KEY not found in ~/.diskmonitor.credentials"

feed=$1
shift
mountpoint=$1

# Some sanity checks. TO-DO: Check values for security issues.
[[ -z ${feed} ]] && die "Must pass name for feed as first argument."
[[ -z ${mountpoint} ]] && die "Must pass a mountpoint as an argument."
mountpoint ${mountpoint} > /dev/null 2>&1 || die "${mountpoint} is not a mountpoint."

# Collect metrics.
read avail < <(df --block-size=T --output=avail ${mountpoint} | tail -1 | tr -d 'T')

# Store size as a float with 1 decimal place.
avail=$(printf "%.1f" ${avail})

# Push metrics to adafruit.
URL="https://io.adafruit.com/api/v2/CZIIsensors/feeds/${feed}/data"
RESPONSE=$( curl -sS -F "value=${avail}" -H "X-AIO-Key: ${X_AIO_KEY}" "${URL}" )

echo ${RESPONSE} >> ${HOME}/$(basename $0).log


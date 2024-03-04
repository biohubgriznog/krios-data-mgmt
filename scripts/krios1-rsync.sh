#!/bin/bash

# Author: griznog
# Purpose: First drafts of data sync from Krios to storage.

SRC=/datasources/krios1
DEST1=/datapool/exports/hpc/instruments/czii.krios1
DEST2=/fastpool/exports/hpc/scratch/czii.krios1
INTERVAL=300

die () {
  [[ -n $1 ]] && echo $1
  exit 1
}

while true; do
  timestamp=$(date "+%Y-%m-%dT%H:%M:%SZ")
  echo "Starting sync at ${timestamp}"
  mountpoint ${SRC} || die "${SRC} not mounted."
  [[ -d ${SRC}/.athena ]] || die "${SRC}/.athena not found, suspect a broken CIFS mount."
  mountpoint ${DEST1} || die "${DEST1} not mounted."
  mountpoint ${DEST2} || die "${DEST2} not mounted."
  [[ -d ${DEST1}/OffloadData ]] || die "${DEST1}/OffloadData directory not found."
  [[ -d ${DEST2}/OffloadData ]] || die "${DEST2}/OffloadData directory not found."

  # Sync to DEST1
  rsync -av \
      --info=stats2 \
      --chown=svc.czii.krios1:group.czii \
      --chmod=D2750,F660 \
      --log-file=${HOME}/logs/krios1-dest1-${timestamp}.log \
      --itemize-changes \
      ${SRC}/ ${DEST1}/OffloadData > /dev/null &

  # Sync to DEST2
  rsync -av \
      --info=stats2 \
      --chown=svc.czii.krios1:group.czii \
      --chmod=D2750,F660 \
      --log-file=${HOME}/logs/krios1-dest2-${timestamp}.log \
      --itemize-changes \
      ${SRC}/ ${DEST2}/OffloadData > /dev/null &

  wait
  wait

  echo "syncs completed at $(date '+%Y-%m-%dT%H:%M:%SZ')"
  echo
  sleep ${INTERVAL}
done


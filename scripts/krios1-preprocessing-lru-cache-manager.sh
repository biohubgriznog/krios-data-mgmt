#!/bin/bash -l

# Author: griznog
# Purpose: First drafts of data sync from Krios to storage.

echo "DEPRECATED: we no longer maintain an LRU cache."
exit 1

# We need to use evn_parallel.
. env_parallel.bash

SRC=/datasources/krios1
DEST1_HOST=czii-gpu-b-1
DEST1_PATH=/local/scratch/czii.krios1
INTERVAL=10
NEW_RUN_PERIOD=2 # In days, max age of things considered to be "new runs"
NEW_RUN_PERIOD_FILE=/tmp/.NEW_RUN_PERIOD.krios1.${DEST1_HOST}
LRU_TTL=14 # In days, max age of things to leave in the cache.
LRU_TTL_FILE=/tmp/.LRU_TTL.krios1.${DEST1_HOST}

die () {
  [[ -n $1 ]] && echo $1
  exit 1
}

function sync_data {
  [[ -z $1 ]] && die "sync_data called without an argument."
  [[ -d $1 ]] || die "sync_data called with $1, which does not exist."

  rsync -a \
      --exclude=*.mdoc
      --info=stats2 \
      --chown=svc.czii.krios1:group.czii \
      --chmod=D2755,F664 \
      --itemize-changes \
      ${1} ${DEST1_HOST}:${DEST1_PATH}/OffloadData
}
export -f sync_data
function sync_final {
  [[ -z $1 ]] && die "sync_final called without an argument."
  [[ -d $1 ]] || die "sync_final called with $1, which does not exist."

  rsync -a \
      --info=stats2 \
      --chown=svc.czii.krios1:group.czii \
      --chmod=D2755,F664 \
      --itemize-changes \
      ${1} ${DEST1_HOST}:${DEST1_PATH}/OffloadData
}
export -f sync_final 

while sleep ${INTERVAL}; do
  clear
  timestamp=$(date "+%Y-%m-%dT%H:%M:%SZ")
  touch -d "${NEW_RUN_PERIOD} days ago" ${NEW_RUN_PERIOD_FILE}
  ssh ${DEST1_HOST} "touch -d '${LRU_TTL} days ago' ${LRU_TTL_FILE}"

  echo "Starting sync at ${timestamp}"

  # Sanity check out data source mount.
  if ! mountpoint ${SRC} > /dev/null 2>&1; then
    echo "${SRC} not mounted. Pausing sync for 15 minutes."
    sleep 900
    continue
  fi
  
  # Sanity check that the source mount is actually the right thing.
  if [[ ! -d ${SRC}/.athena ]]; then
    echo "${SRC}/.athena not found, suspect a broken CIFS mount. Pausing sync for 15 minutes."
    sleep 900
    continue
  fi

  # Check our target server is up and running.
  ssh ${DEST1_HOST} "[[ -d ${DEST1_PATH} ]]" || die "${DEST1_HOST}:${DEST1_PATH} does not exist."

  # Find our runs to be cached.
  activeruns=( $(find ${SRC} -mindepth 1 -maxdepth 1 -type d -newer ${NEW_RUN_PERIOD_FILE}) )
  expiredruns=( $(ssh ${DEST1_HOST} "find ${DEST1_PATH}/OffloadData -mindepth 1 -maxdepth 1 -type d -not -newer ${LRU_TTL_FILE}") )

  if [[ ${#expiredruns[*]} -gt 0 ]]; then
    echo "${#expiredruns[*]} expired runs found, you need to implement cache flushing."
    for run in ${expiredruns[*]}; do
      echo "ssh ${DEST1_HOST} rm -rf ${run}"
    done
  fi

  # Sometimes our data source goes away. Skip the sync until next time if that happens.
  if [[ ${#activeruns[*]} -eq 0 ]]; then
    echo "No runs found to sync, pausing for 15 minutes."
    sleep 900
    continue
  else
    # Sync without mdoc files.
    echo -n "Data sync for active runs: ${activeruns[*]} ... "
    env_parallel -j 4 --results=${HOME}/logs/gpu-kra-1-data sync_data {} ::: ${activeruns[*]}
    echo "done."
    echo -n "Final sync for active runs: ${activeruns[*]} ... " 
    env_parallel -j 4 --results=${HOME}/logs/gpu-kra-1-final sync_final {} ::: ${activeruns[*]}
    echo "done."
    echo "syncs completed at $(date '+%Y-%m-%dT%H:%M:%SZ')"
    echo
  fi
done


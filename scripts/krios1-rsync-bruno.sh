#!/bin/bash -l

# Author: griznog
# Purpose: Maintain a near-real-time LRU cache of recent runs on the
#          pre-processing server local scratch.

SRC=/datasources/krios1
DEST1_HOST=TO-BE-DETERMINED
DEST1_PATH=/datapool/exports/instruments/czii.krios1
INTERVAL=60
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
  timestamp=$(date "+%Y-%m-%dT%H:%M:%SZ")
  touch -d "${NEW_RUN_PERIOD} days ago" ${NEW_RUN_PERIOD_FILE}
  ssh ${DEST1_HOST} "touch -d '${LRU_TTL} days ago' ${LRU_TTL_FILE}"

  echo "Starting sync at ${timestamp}"
  mountpoint ${SRC} > /dev/null 2>&1 || die "${SRC} not mounted."
  [[ -d ${SRC}/.athena ]] || die "${SRC}/.athena not found, suspect a broken CIFS mount."
  ssh ${DEST1_HOST} "[[ -d ${DEST1_PATH} ]]" || die "${DEST1_HOST}:${DEST1_PATH} does not exist."

  # Find our runs to be cached.
  activeruns=( $(find ${SRC} -mindepth 1 -maxdepth 1 -type d -newer ${NEW_RUN_PERIOD_FILE}) )
  expiredruns=( $(ssh ${DEST1_HOST} "find ${DEST1_PATH}/OffloadData -mindepth 1 -maxdepth 1 -type d -not -newer ${LRU_TTL_FILE}") )

  if [[ ${#expiredruns[*]} -gt 0 ]]; then
    echo "${#expiredruns[*]} expired runs found, you need to implement cache flushing."
  fi

  # Sometimes our data source goes away. Skip the sync until next time if that happens.
  if [[ ${#activeruns[*]} -eq 0 ]]; then
    echo "No runs found to sync."
    continue
  else
    # Sync without mdoc files.
    echo -n "Data sync..."
    env_parallel -j 4 --results=${HOME}/logs/gpu-kra-1-data sync_data {} ::: ${activeruns[*]}
    echo "done."
    echo -n "Final sync..." 
    env_parallel -j 4 --results=${HOME}/logs/gpu-kra-1-final sync_final {} ::: ${activeruns[*]}
    echo "done."
    echo "syncs completed at $(date '+%Y-%m-%dT%H:%M:%SZ')"
    echo
  fi
done


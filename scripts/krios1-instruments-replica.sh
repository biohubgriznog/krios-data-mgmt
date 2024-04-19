#!/bin/bash

while true; do 
  echo "Starting sync at $(date)"
  if [[ -d /datasources/krios1/.athena ]]; then
    rsync -a \
  	  --info=progress2,stats2 \
	  --chown=svc.czii.krios1:group.czii \
	  --chmod=D2755,F664 \
	  --exclude=.athena \
	  --log-file=${HOME}/instrument-replica-sync.log \
	  /datasources/krios1/ \
	  /datapool/exports/hpc/instruments/czii.krios1/OffloadData 
    echo "Sync completeds at $(date)"
    sleep 5m
  else
    echo "Problem wtih /datasources/krios1, waiting 1 hour betfore retrying."
    sleep 1h
  fi
done

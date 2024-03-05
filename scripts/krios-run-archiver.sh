#!/bin/bash

# Author: griznog
# Purpose: First drafts of data sync from Krios to storage.

##########################################################################
####################### Configuration section ############################

##########################################################################
# Determine who we are, bail if not a Krios service account.
[[ $USER =~ svc.([a-z]*).(krios[0-9]*) ]] || die "This can only be ran by a Krios scope service account, svc.\${GROUP}.krios\${N}"
INSTRUMENT=${BASH_REMATCH[2]}
GROUP=${BASH_REMATCH[1]}

##########################################################################
# Root location where instrument data servers are mounted.
SRCROOT=/datasources

##########################################################################
# Root location where instruments archive storage is mounted.
DSTROOT=/datapool/exports/hpc/archives

##########################################################################
# Frequency for archiving, in seconds.
SYNC_INTERVAL=3600

##########################################################################
# Max age at which Runs are allowed to be "active", e.g. left on 
# instrument storage.
MAX_ACTIVE_RUN_AGE=$((60*60*24*120))  # Should eval to seconds.

##########################################################################
# Excluded Directory names, these will never be considered Runs for 
# archiving.
RUN_EXCLUDES=( 
    archive
    Service
    TemScripting
    serialem-data
    .athena
    ImagesForProcessing
  )



##########################################################################
############################### Functions ################################
##########################################################################

##########################################################################
# die
function die () {
  [[ -n $1 ]] && echo "ERROR: $1"
  exit 1
}

##########################################################################
# warn
function warn () {
  local message=
  [[ -n "$1" ]] && message="$1" || message="Unspecified issue."
  echo "Warning: ${message}"
}

###########################################################################
# Determine if a directory in OffLoadData is a RUN that should be managed.
function is_run () {
  local runDirectory=$1

  # Check not empty. Die on error.
  if [[ -z ${runDirectory} ]]; then
    die "missing argument, is_run() requires a single run name."
  fi

  # Check that we only got a run name, not a path. Die on error.
  if [[ $( basename ${runDirectory} ) != ${runDirectory} ]]; then
    die "is_run() takes only the run name, not a full path."
  fi

  # Check the run directory exists, warn if not found.
  if [[ ! -d ${srcpath}/${runDirectory} ]]; then
    warn "${srcpath}/${runDirectory} not found for run ${runDirectory}"
    return 1
  fi

  # Check for excluded Run names/directories.
  for exclude in ${RUN_EXCLUDES[*]}; do
    [[ ${runDirectory} == ${exclude} ]] && return 1
  done

  # If we made it here, it's probably a run. Probably.
  return 0
}


##########################################################################
############################ Main Script #################################
##########################################################################


# Paths
srcpath=${SRCROOT}/${INSTRUMENT}
dstpath=${DSTROOT}/${INSTRUMENT}

while true; do
  # Flush any lingering data from previous iteration
  unset runs current_time time_stamp

  # Declare associative arrays.
  declare -A runs

  # Note time this iteration started
  current_time=$(date "+%s")
  time_stamp=$(date -d @${current_time} "+%Y-%m-%dT%H:%M:%SZ")
  echo "Starting iteration at ${time_stamp}"
  
  # Safety/sanity checks, done at every interval.
  mountpoint ${srcpath} || die "${srcpath} not mounted."
  [[ -d ${srcpath}/.athena ]] || die "${srcpath}/.athena not found, suspect a broken CIFS mount."
  mountpoint ${dstpath} || die "${dstpath} not mounted."
  [[ -d ${dstpath} ]] || die "${dstpath} directory not found."
  [[ -d ${dstpath}/Runs ]] || mkdir ${dstpath}/Runs 

  # Collect the list of src runs.
  for item in $(find ${srcpath} -mindepth 1 -maxdepth 1 -type d -printf "%P\n"); do
    # Skip and move on if not a run.
    if ! is_run ${item}; then 
      warn "${item} is not a Run, skipping."
	continue
    fi

    # Get mtime and calculate age of Run.
    src_time=$(stat --format=%Y ${srcpath}/${item})
    src_age=$(( ${current_time} - ${src_time} ))

    # Decide how to handle the Run.
    if [[ ${src_age} -gt ${MAX_ACTIVE_RUN_AGE} ]]; then
      warn "${item} has exceeded MAX_ACTIVE_RUN_AGE and will be permently removed from falcon server."
	runs[${item}]="expired"
    elif [[ ! -d ${dstpath}/Runs/${item} ]]; then
	warn "${item} initial sync."
	runs[${item}]="initial"
    else 
      dst_time=$(stat --format=%Y ${dstpath}/Runs/${item})
      if [[ ${src_time} > ${dst_time} ]]; then
	  warn "${item} has been updated, re-syncing."
	  runs[${item}]="resync"
	else
        warn "${item} already synced."
	fi
    fi	
  done
  for run in ${!runs[*]}; do
    # Sync to archival location
    if ! rsync -a \
             --info=stats2,progress2 \
             --chown=${USER}:group.${GROUP} \
             --chmod=D2750,F640 \
             --log-file=${HOME}/logs/krios1-archiver.log \
             --itemize-changes \
             ${srcpath}/${run} ${dstpath}/Runs; then
      warn "Error $? with rsync of ${run}, skipping further processong of ${run}."
      continue
    else
      if [[ ${runs[${run}]} == "expired" ]]; then
        warn "$run is EXPIRED, please remove from falcon server: "
        warn "CMD: rm -rf ${srcpath}/${run}"
      fi
    fi
  done
  exit 0
done



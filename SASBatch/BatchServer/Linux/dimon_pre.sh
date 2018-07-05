#!/bin/ksh -p
# ---------------------------------------------------------------------
# program : dimon_pre.sh
# version : 3.1
# date    : 27nov16
# purpose : execute dimon_job_start.sas
#
# Uncomment the set -x to run in debug mode
# set -x
#
# Do NOT modify this file.  Any additions or changes should be made in
# dimon_usermods.sh.
#
# change history
# date     by      changes
# -------  ------  ----------------------------------------------------
# 29nov12  eombah  use less envvars
#                  added comments
# 27nov16  eombah  Updated for v3
# ---------------------------------------------------------------------

# only execute this code when LSF variables are set
if [[ ! -z "$LSB_JOBID" && ! -z "$LSB_JOBNAME" ]] ; then

  # Do NOT modify this file.  Any additions or changes should be made in
  # dimon_usermods.sh.

  # set default options
  DIMON_SASLOGFILE_RESOLVE_YMDHMS=YES
  DIMON_SASLOGFILE_PREPEND_JOBID_FLOWID_USER=NO
  DIMON_SASLOGFILE_APPEND_DATETIME=NO
  DIMON_CONTINUEONFAIL=YES
  DIMON_DEBUG=NO

  # overwrite default options with options from dimon_usermods.sh
  DIMON_USERMODS=$APPSERVER_ROOT/BatchServer/dimon_usermods.sh
  if [[ -e $DIMON_USERMODS ]] ; then
    . $DIMON_USERMODS
  fi

  DIMON_DATETIME="$(date '+%Y.%m.%d_%H.%M.%S')"

  DIMON_CMDLINEARGS_ORG="$@"
  DIMON_CMDLINEARGS="$@"

  if [ "$DIMON_SASLOGFILE_RESOLVE_YMDHMS" = "YES" ] ; then
    # resolve #Y.#m.#d_#H.#M.#s in the  command line arguments to a real datetime
    DIMON_CMDLINEARGS=$(echo "$DIMON_CMDLINEARGS" | sed "s/#Y.#m.#d_#H.#M.#s/${DIMON_DATETIME}/g")
  fi

  # get LSF FLOWID and JOBID
  DIMON_LSF_FLOWID=$(echo "$LSB_JOBNAME" | awk -F':' '{print $1}')
  DIMON_LSF_JOBID=${LSB_JOBID}

  # get -log parm from command line
  logparmpos=-1
  for parm in $DIMON_CMDLINEARGS; do
    ((index=index+1))
    if [ "$parm" = "-log" ] ; then
      logparmpos=$index
    fi
    # get logfile right after -log parm
    if [ "$index" = "$((logparmpos+1))" ] ; then
      DIMON_SASLOGFILE=$parm
      # No reason to continue this loop
      break
    fi
  done

  # get -print parm from command line
  printparmpos=-1
  for parm in $DIMON_CMDLINEARGS; do
    ((index=index+1))
    if [ "$parm" = "-print" ] ; then
      printparmpos=$index
    fi
    # get lstfile right after -lst parm
    if [ "$index" = "$((printparmpos+1))" ] ; then
      DIMON_SASLSTFILE=$parm
      # No reason to continue this loop
      break
    fi
  done

  # save for replace using sed later on
  DIMON_ORIGINAL_SASLOGFILE=$DIMON_SASLOGFILE

  DIMON_LOGDIR=$(dirname $DIMON_SASLOGFILE)
  DIMON_SCRIPTDIR=$CONFIGDIR/../SASEnvironment/SASCode/dimon

  # LSB_JOBNAME contains something like 59:lsfadmin:testflow21:testflow2:testjob2;
  # Replace : . \ by _ in LSB_JOBNAME
  DIMON_JOBNAME=$(echo "$LSB_JOBNAME" | sed 's/:/_/g' | sed 's/\\/_/g' | sed 's/\./_/g' | sed 's/__/_/g')

  if [ "$DIMON_SASLOGFILE_PREPEND_JOBID_FLOWID_USER" = "YES" ] ; then
    # prefix logfile name with jobid, flowid, and user
    DIMON_SASLOGFILE=${DIMON_LOGDIR}/${DIMON_LSF_JOBID}_${DIMON_LSF_FLOWID}_${USER}_$(basename ${DIMON_ORIGINAL_SASLOGFILE})
  fi

  # if logfile name ends with an underscore, append datetime to it
  if [ "$DIMON_SASLOGFILE_APPEND_DATETIME" = "YES" ] ; then
    if [[ "$DIMON_SASLOGFILE" = *_ ]] ; then
      # append {DIMON_DATETIME}.log to ${DIMON_SASLOGFILE}
      DIMON_SASLOGFILE=${DIMON_SASLOGFILE}${DIMON_DATETIME}.log
    fi
  fi

  # replace original sas logfile name in command line args with new composed name
  DIMON_CMDLINEARGS=$(echo "$DIMON_CMDLINEARGS" | sed "s:${DIMON_ORIGINAL_SASLOGFILE}:${DIMON_SASLOGFILE}:g")

  if [ ! -z "$DIMON_SASLOGFILE" ] ; then
    DIMON_SETSASLOGFILE="-set SASLOGFILE \"${DIMON_SASLOGFILE}\""
  fi
  if [ ! -z "$DIMON_SASLSTFILE" ] ; then
    DIMON_SETSASLSTFILE="-set SASLSTFILE \"${DIMON_SASLSTFILE}\""
  fi

  DIMON_LOGFILE=$(echo "$DIMON_SASLOGFILE" | sed "s:\.log$:_dimon_job_start.log:g")

  if [ "$DIMON_DEBUG" = "YES" ] ; then
    # output system variables to debug file
    set > /tmp/dimon-debug-${USER}.txt
  fi

  # -----------------------------------------------------------------
  # Execute dimon_job_start.sas
  # -----------------------------------------------------------------
  "$SAS_COMMAND" -sysin "${DIMON_SCRIPTDIR}/dimon_job_start.sas" -log "${DIMON_LOGFILE}" -set LSB_JOBNAME "${LSB_JOBNAME}" ${DIMON_SETSASLOGFILE} ${DIMON_SETSASLSTFILE} -set LSB_JOBID "${LSB_JOBID}"
  DIMON_RC=$?
  if [ $DIMON_RC -gt 1 ] ; then
    echo ERROR: Registering DIMON Job Start event failed for job \"${LSB_JOBNAME}\". RC=$DIMON_RC
    echo ERROR: See logfile $DIMON_LOGFILE
    if [ "$DIMON_CONTINUEONFAIL" != "YES" ] ; then
      # exit sasbatch.sh with non-zero return code if continue on fail = NO
      exit "$DIMON_RC"
    fi
  else
    if [ "$DIMON_DEBUG" != "YES" ] ; then
      # remove dimon_job_start logfile if we are not in debug mode
      rm -f "$DIMON_LOGFILE"
    fi
  fi

else
  DIMON_CMDLINEARGS="$@"

fi

#!/bin/ksh -p
# -----------------------------------------------------------------
# program : dimon_post.sh
# version : 3.1
# date    : 27nov16
# purpose : execute dimon_job_finish.sas
#
# Uncomment the set -x to run in debug mode
# set -x
#
# change history
# date     by      changes
# -------  ------  ------------------------------------------------
# 29nov12  eombah  use less envvars
#                  added comments
# 27nov16  eombah  Updated for v3
# -----------------------------------------------------------------

# only execute this code when LSF variables are set
if [[ ! -z "$LSB_JOBID" && ! -z "$LSB_JOBNAME" ]] ; then

  # -----------------------------------------------------------------
  # Execute dimon_job_finish.sas
  # -----------------------------------------------------------------
  DIMON_LOGFILE=$(echo "$DIMON_SASLOGFILE" | sed "s:\.log$:_dimon_job_finish.log:g")
  "$SAS_COMMAND" -sysin "${DIMON_SCRIPTDIR}/dimon_job_finish.sas" -log "${DIMON_LOGFILE}" -set LSB_JOBID "${LSB_JOBID}" -set JOB_RC "${DIMON_JOBRC}"
  DIMON_RC=$?
  if [ $DIMON_RC -gt 1 ] ; then
    echo ERROR: Registering DIMON Job Finish event failed for job \"${LSB_JOBNAME}\". RC=$DIMON_RC
    echo ERROR: See log file $DIMON_LOGFILE
    if [ "$DIMON_CONTINUEONFAIL" != "YES" ] ; then
      # exit sasbatch.sh with non-zero return code if continue on fail = NO
      exit "$DIMON_RC"
    fi
  else
    if [ "$DIMON_DEBUG" != "YES" ] ; then
      # remove dimonStartJob logfile if we are not in debug mode
      rm "$DIMON_LOGFILE"
    fi
  fi

fi


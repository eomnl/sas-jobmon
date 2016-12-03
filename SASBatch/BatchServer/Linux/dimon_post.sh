#!/bin/ksh -p
# -----------------------------------------------------------------
# program : dimon_post.sh
# version : 3.1
# date    : 27nov16
# purpose : execute dimonFinishJob.sas
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
dir=$(pwd)
cd $CONFIGDIR

# -----------------------------------------------------------------
# Execute dimonFinishJob.sas
# -----------------------------------------------------------------
DIMONLOGFILE=${DIMONLOGDIR}/${FILENAME_PREFIX}_${DATETIME}_dimonFinishJob.log
"$SASCMD" -lrecl 32767 -sysin "$DIMONSCRIPTDIR/dimonFinishJob.sas" -autoexec "$SASAUTOEXEC" -log "$DIMONLOGFILE" -set JOB_RC "$JOB_RC" -set LSB_JOBID "$LSB_JOBID"
rc_dimon=$?
if [ "$rc_dimon" -gt "1" ] ; then
  echo ERROR: Registering the Finish of the job failed. RC=$rc_dimon
  echo ERROR: See log file $DIMONLOGFILE
  if [ "$CONTINUEONDIMONFAIL" != "YES" ] ; then
    cd $dir
    exit "$rc_dimon"
  fi
else
  if [ "$DIMONDEBUG" != "YES" ] ; then
    rm "$DIMONLOGFILE"
  fi
fi

cd $dir


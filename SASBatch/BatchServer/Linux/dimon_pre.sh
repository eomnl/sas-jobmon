#!/bin/ksh -p
# -----------------------------------------------------------------
# program : dimon_pre.sh
# version : 3.1
# date    : 27nov16
# purpose : execute dimonStartJob.sas
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

DATETIME="`date '+%Y.%m.%d_%H.%M.%S'`"
SASENV=$APPSERVER_ROOT
SASCMD=$SAS_COMMAND
SASCFG=$SASENV/BatchServer/sasv9.cfg
SASLOGDIR=$SASENV/BatchServer/Logs
DIMONLOGDIR=$SASLOGDIR
DIMONSCRIPTDIR=$SASENV/SASEnvironment/SASCode/dimon
SASAUTOEXEC=$SASENV/BatchServer/autoexec.sas
CONTINUEONDIMONFAIL=YES
DIMONDEBUG=NO

# Set SASLOGFILE and SASLSTFILE
# Strip : . \ from LSB_JOBNAME
FILENAME_PREFIX=${LSB_JOBID}_$(echo "$LSB_JOBNAME" | sed 's/:/_/g' | sed 's/\\/_/g' | sed 's/\./_/g' | sed 's/__/_/g')
SASLOGFILE=$SASLOGDIR/${FILENAME_PREFIX}_${DATETIME}.log
SASLSTFILE=$SASLOGDIR/${FILENAME_PREFIX}_${DATETIME}.lst

dir=$(pwd)
cd $CONFIGDIR

if [ "$DIMONDEBUG" -eq "YES" ] ; then
  set > /tmp/dimon-debug.txt
fi

# -----------------------------------------------------------------
# Execute dimonStartJob.sas
# -----------------------------------------------------------------
DIMONLOGFILE=${DIMONLOGDIR}/${FILENAME_PREFIX}_${DATETIME}_dimonStartJob.log
"$SASCMD" -lrecl 32767 -sysin "$DIMONSCRIPTDIR/dimonStartJob.sas" -autoexec "$SASAUTOEXEC" -log "$DIMONLOGFILE" -set LSB_JOBNAME "$LSB_JOBNAME" -set SASLOGFILE "$SASLOGFILE" -set SASLSTFILE "$SASLSTFILE" -set LSB_JOBID "$LSB_JOBID" 
rc_dimon=$?
if [ "$rc_dimon" -gt "1" ] ; then
  echo ERROR: Could not register the Start of the Job. RC=$rc_dimon
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


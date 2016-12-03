REM -----------------------------------------------------------------
REM program : dimon_post.sh
REM version : 3.1
REM date    : 27nov16
REM purpose : execute dimonFinishJob.sas
REM
REM change history
REM date     by      changes
REM -------  ------  ------------------------------------------------
REM 30nov12  eombah  initial version
REM 27nov16  eombah  updated for v3
REM -----------------------------------------------------------------

set DIR=%CD%
cd %CONFIGDIR%

REM -----------------------------------------------------------------
REM Execute dimonFinishJob.sas
REM -----------------------------------------------------------------
set DIMONLOGFILE=%DIMONLOGDIR%\%FILENAME_PREFIX%_%DATETIME%_dimonFinishJob.log
"%SASCMD%" %CMD_OPTIONS% -sysin "%DIMONSCRIPTDIR%\dimonFinishJob.sas" -log "%DIMONLOGFILE%" -set JOB_RC "%JOB_RC%" -set LSB_JOBID "%LSB_JOBID%"
set RC_DIMON=%ERRORLEVEL%
if %RC_DIMON% GTR 1 (
  echo ERROR: Registering the Finish of the job failed. RC=%RC_DIMON%
  echo ERROR: See log file %DIMONLOGFILE%
  if  %CONTINUEONDIMONFAIL% NEQ YES (
      exit %RC_DIMON%
  )
) else (
  if %DIMONDEBUG% neq YES (
    del "%DIMONLOGFILE%"
  )
)

cd %DIR%

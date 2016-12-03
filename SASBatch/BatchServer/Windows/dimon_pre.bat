REM -----------------------------------------------------------------
REM program : dimon_pre.sh
REM version : 3.1
REM date    : 27nov16
REM purpose : execute dimonStartJob.sas
REM
REM change history
REM date     by      changes
REM -------  ------  ------------------------------------------------
REM 30nov12  eombah  initial version
REM 27nov16  eombah  updated for v3
REM -----------------------------------------------------------------

SET HOUR_TIME=%time:~0,2%
IF %HOUR_TIME% leq 9 (set HOUR_TIME=0%HOUR_TIME: =%) 
SET DATETIME=%date:~10,4%.%date:~4,2%.%date:~7,2%_%HOUR_TIME%.%time:~3,2%.%time:~6,2%
SET SASENV=%APPSERVER_ROOT%
SET SASCMD=%SAS_COMMAND%
SET SASCFG=%SASENV%\BatchServer\sasv9.cfg
SET SASLOGDIR=%SASENV%\BatchServer\Logs
SET DIMONLOGDIR=%SASLOGDIR%
SET DIMONSCRIPTDIR=%SASENV%\SASEnvironment\SASCode\dimon
SET SASAUTOEXEC=%SASENV%\BatchServer\autoexec.sas
SET CONTINUEONDIMONFAIL=YES
SET DIMONDEBUG=YES

REM Set SASLOGFILE and SASLSTFILE
REM Strip : . \ from LSB_JOBNAME
set FLOW_JOB_NAME=%LSB_JOBNAME::=_%
set FLOW_JOB_NAME=%FLOW_JOB_NAME:\=%
set FLOW_JOB_NAME=%FLOW_JOB_NAME:.=%
set FILENAME_PREFIX=%LSB_JOBID%_%FLOW_JOB_NAME%
SET SASLOGFILE=%SASLOGDIR%\%FILENAME_PREFIX%_%DATETIME%.log
SET SASLSTFILE=%SASLOGDIR%\%FILENAME_PREFIX%_%DATETIME%.lst

set DIR=%CD%
cd %CONFIGDIR%

if %DIMONDEBUG% equ YES (
  set > %TEMP%\dimon-debug.txt
)

REM -----------------------------------------------------------------
REM Execute dimonStartJob.sas
REM -----------------------------------------------------------------
set DIMONLOGFILE=%DIMONLOGDIR%\%FILENAME_PREFIX%_%DATETIME%_dimonStartJob.log
"%SASCMD%" %CMD_OPTIONS% -sysin "%DIMONSCRIPTDIR%\dimonStartJob.sas" -log "%DIMONLOGFILE%" -set LSB_JOBNAME "%LSB_JOBNAME%" -set SASLOGFILE "%SASLOGFILE%" -set SASLSTFILE "%SASLSTFILE%" -set LSB_JOBID "%LSB_JOBID%" 
set RC_DIMON=%ERRORLEVEL%
if %RC_DIMON% gtr 1 (
  echo ERROR: Registering the Start of the Job failed. RC=%RC_DIMON%
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

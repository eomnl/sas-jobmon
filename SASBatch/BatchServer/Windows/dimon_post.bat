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

SETLOCAL ENABLEDELAYEDEXPANSION

REM only execute this code when LSF variables are set
IF DEFINED LSB_JOBID (
  IF DEFINED LSB_JOBNAME (

    REM -----------------------------------------------------------------
    REM Execute dimon_job_finish.sas
    REM -----------------------------------------------------------------
    SET DIMON_JOB_FINISH_LOG=%DIMON_SASLOGFILE:.log=_dimon_job_finish.log%
    "%SAS_COMMAND%" %CMD_OPTIONS% -sysin "%DIMON_SCRIPTDIR%/dimon_job_finish.sas" -log "!DIMON_JOB_FINISH_LOG!" -set LSB_JOBID "%LSB_JOBID%" -set JOB_RC "%DIMON_JOBRC%"
    set DIMON_RC=%ERRORLEVEL%
    if !DIMON_RC! GTR 1 (
      echo ERROR: Registering DIMON Job Finish event failed for job "%LSB_JOBNAME%". RC=!DIMON_RC!
      echo ERROR: See log file !DIMON_JOB_FINISH_LOG!
      IF "%DIMON_CONTINUEONFAIL%" NEQ "YES" (
        REM exit sasbatch.sh with non-zero return code if continue on fail = NO
        exit /b !DIMON_RC!
      )
    ) else (
      if "%DIMON_DEBUG%" NEQ "YES" (
        REM remove file DIMON_JOB_FINISH_LOG if we are not in debug mode
        del "!DIMON_JOB_FINISH_LOG!"
      )
    )

  )
)

ENDLOCAL

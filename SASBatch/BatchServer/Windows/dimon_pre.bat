REM -----------------------------------------------------------------
REM program : dimon_pre.bat
REM version : 3.1
REM date    : 27nov16
REM purpose : execute dimon_job_start.sas
REM
REM change history
REM date     by      changes
REM -------  ------  ------------------------------------------------
REM 30nov12  eombah  initial version
REM 27nov16  eombah  updated for v3
REM -----------------------------------------------------------------

REM set default options
SET DIMON_SASLOGFILE_RESOLVE_YMDHMS=YES
SET DIMON_SASLOGFILE_PREPEND_JOBID_FLOWID_USER=YES
SET DIMON_SASLOGFILE_APPEND_DATETIME=YES
SET DIMON_CONTINUEONFAIL=YES
SET DIMON_DEBUG=NO

REM overwrite default options with options from dimon_usermods.sh (if it exists)
SET DIMON_USERMODS=%APPSERVER_ROOT%\BatchServer\dimon_usermods.bat
IF EXIST "%DIMON_USERMODS%" (
  CALL "%DIMON_USERMODS%"
) else (
  ECHO NOTE: %DIMON_USERMODS% was not executed because it does not exist.
)

SET DIMON_SCRIPTDIR=%CONFIGDIR%\..\SASEnvironment\SASCode\dimon

SETLOCAL ENABLEDELAYEDEXPANSION

REM only execute this code when LSF variables are set
IF DEFINED LSB_JOBID (
  IF DEFINED LSB_JOBNAME (

    REM Do NOT modify this file.  Any additions or changes should be made in
    REM dimon_usermods.bat.

    REM get LSF FLOWID
    FOR /f "tokens=1 delims=:" %%a IN ("%LSB_JOBNAME%") DO SET DIMON_LSF_FLOWID=%%a

    REM get LSF JOBID
    SET DIMON_LSF_JOBID=%LSB_JOBID%

    REM Get current date/time (locale-independent from PowerShell)
    FOR /F "delims=" %%# in ('powershell get-date -format "{yyyyMMdd_HHmmss}"') do @SET DIMON_DATETIME=%%#

    SET DIMON_SASLOGFILE=

    REM Set DIMON_CMDLINEARGS as a copy of all command line parameters
    SET DIMON_CMDLINEARGS_ORG=%DIMON_CMDLINEARGS%

    IF "!DIMON_CMDLINEARGS!" NEQ "" (
      IF "!DIMON_SASLOGFILE_RESOLVE_YMDHMS!" == "YES" (
        REM resolve #Y.#m.#d_#H.#M.#s to a real datetime in DIMON_CMDLINEARGS
        CALL SET DIMON_CMDLINEARGS=%%DIMON_CMDLINEARGS:#Y.#m.#d_#H.#M.#s=!DIMON_DATETIME!%%
      )
    )

    REM get -log parm from DIMON_CMDLINEARGS
    SET logparmindex=0
    SET DIMON_SASLOGFILE=
    SET /a index=0
    for %%a in (!DIMON_CMDLINEARGS!) DO (
      SET /a index+=1
      if "%%a" EQU "-log" (
        SET /a logparmindex=index+1
      )
      if !index! == !logparmindex! (
        SET DIMON_SASLOGFILE=%%a
      )
    )

    REM get -print parm from DIMON_CMDLINEARGS
    SET logparmindex=0
    SET DIMON_SASLSTFILE=
    SET /a index=0
    for %%a in (%dimon_cmdlineargs%) DO (
      SET /a index+=1
      if "%%a" EQU "-print" (
        SET /a logparmindex=index+1
      )
      if !index! == !logparmindex! (
        SET DIMON_SASLSTFILE=%%a
      )
    )

    REM save for replace later on
    SET DIMON_ORIGINAL_SASLOGFILE=!DIMON_SASLOGFILE!

    REM get logdir and logfile
    FOR %%A IN (!DIMON_SASLOGFILE!) DO (
      SET DIMON_LOGDIR=%%~dpA
      SET DIMON_LOGFILE=%%~nxA
    )

    REM LSB_JOBNAME contains something like 59:lsfadmin:testflow21:testflow2:testjob2
    REM Replace : . \ by _ in LSB_JOBNAME
    SET DIMON_JOBNAME=!LSB_JOBNAME::=_!
    SET DIMON_JOBNAME=!DIMON_JOBNAME:\=!
    SET DIMON_JOBNAME=!DIMON_JOBNAME:.=!

    IF "!DIMON_SASLOGFILE_PREPEND_JOBID_FLOWID_USER!" == "YES" (
      REM prefix logfile name with jobid, flowid, and user
      SET DIMON_SASLOGFILE=!DIMON_LOGDIR!!DIMON_LSF_JOBID!_!DIMON_LSF_FLOWID!_%USERNAME%_!DIMON_LOGFILE!
    )

    IF "!DIMON_SASLOGFILE_APPEND_DATETIME!" == "YES" (
      REM if logfile name ends with an underscore, append datetime to it
      IF "!DIMON_SASLOGFILE:~-1!" == "_" (
        SET DIMON_SASLOGFILE=!DIMON_SASLOGFILE!!DIMON_DATETIME!.log
      )
    )

    REM replace original sas logfile name in command line args with new composed name
    IF "!DIMON_ORIGINAL_SASLOGFILE!" NEQ "" (
      CALL SET DIMON_CMDLINEARGS=%%DIMON_CMDLINEARGS:!DIMON_ORIGINAL_SASLOGFILE!="!DIMON_SASLOGFILE!"%%
    )

    IF DEFINED DIMON_SASLOGFILE SET DIMON_SETSASLOGFILE=-set SASLOGFILE "!DIMON_SASLOGFILE!"
    IF DEFINED DIMON_SASLSTFILE SET DIMON_SETSASLSTFILE=-set SASLSTFILE "!DIMON_SASLSTFILE!"

    SET DIMON_JOB_START_LOG=!DIMON_SASLOGFILE:.log=_dimon_job_start.log!

    IF "%DIMON_DEBUG%" EQU "YES" (
      REM output system variables to debug file
      SET > "%TEMP%\dimon-debug-%USERNAME%.txt"
    )

    REM -----------------------------------------------------------------
    REM Execute dimon_job_start.sas
    REM -----------------------------------------------------------------
    "%SAS_COMMAND%" %CMD_OPTIONS% -sysin "%DIMON_SCRIPTDIR%\dimon_job_start.sas" -log "!DIMON_JOB_START_LOG!" -set LSB_JOBNAME "!LSB_JOBNAME!" !DIMON_SETSASLOGFILE! !DIMON_SETSASLSTFILE! -set LSB_JOBID "!DIMON_LSF_JOBID!"
    SET DIMON_RC=%ERRORLEVEL%
    IF !DIMON_RC! GTR 1 (
      ECHO ERROR: Registering DIMON Job Start event failed for job "%LSB_JOBNAME%". RC=!DIMON_RC!
      ECHO ERROR: See log file !DIMON_JOB_START_LOG!
      IF "%DIMON_CONTINUEONFAIL%" NEQ "YES" (
        REM exit sasbatch.sh with non-zero return code if continue on fail = NO
        EXIT /b !DIMON_RC!
      )
    ) ELSE (
      IF "!DIMON_DEBUG!" NEQ "YES" (
        REM remove file DIMON_JOB_START_LOG if we are not in debug mode
        DEL "!DIMON_JOB_START_LOG!"
      )
    )

  )
)

ENDLOCAL & SET DIMON_CMDLINEARGS=%DIMON_CMDLINEARGS%& SET DIMON_SASLOGFILE=%DIMON_SASLOGFILE%

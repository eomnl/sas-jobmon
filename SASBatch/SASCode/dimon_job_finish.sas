/************************************************************************** */
/* Program Name : dimonFinishJob.sas                                        */
/* Purpose      : This program records the end of a job in the DIMon tables */
/*                This Program updates the following tables;                */
/*                - DIMON.DIMON_JOB_RUNS                                    */
/*                This Program optionally updates the following tables;     */
/*                - DIMON.DIMON_FLOW_RUNS                                   */
/*                                                                          */
/* Author       : Suraj Bachoe, Bart Heinsius                               */
/* Company      : EOM Data Solutions                                        */
/* Version      : 3.1                                                       */
/* Date         : 27nov16                                                   */
/*                                                                          */
/* Change History                                                           */
/* Date     By      Changes                                                 */
/* -------  ------  ------------------------------------------------------- */
/* 19mar10  eomsub  Initial Creation                                        */
/* 20aug11  eombah  Updated for dimon                                       */
/* 17jul12  eomsub  Updated for use with FLOW_RUN_SEQ_NR                    */
/* 31okt12  eombah  Changed status FAILED to COMPLETED                      */
/* 27nov16  eombah  Updated for v3                                          */
/************************************************************************** */

options nosource;

%macro x;

  %let sysin = %sysfunc(getoption(sysin));
  %if ("&sysin." ne "") %then
  %do; /* check for dimon_usermods file and include it if exists */

       %let sysin_filename = %scan(&sysin,-1,/\);
       %let sysin_dirname  = %substr(&sysin,1,%length(&sysin)-1-%length(&sysin_filename));
       %let usermods       = &sysin_dirname/dimon_usermods.sas;
       %if (%sysfunc(fileexist(&usermods))) %then
       %do;
            %put NOTE: A usermods file was found at "&usermods.".;
            %let optSource2 = %sysfunc(getoption(source2));
            options source2;
            %include "&usermods.";
            options &optSource2;
       %end;
       %else
           %put NOTE: A usermods file was not found at "&usermods.".;

  %end;/* check for dimon_usermods file and include it if exists */

  %let job_run_id  = %sysget(LSB_JOBID);
  %let job_rc      = %sysget(JOB_RC);
  %put NOTE: JOB_RUN_ID = &job_run_id.;
  %put NOTE: JOB_RC     = &job_rc.;

  proc sql undo_policy=none noprint;

    /* insert post-job Statistics */
    update DIMON.DIMON_JOB_RUNS(cntllev=rec)
      set   JOB_STATUS_ID = ( select JOB_STATUS_ID
                              from   DIMON.DIMON_JOB_STATUS
                              where  JOB_STATUS_CODE = 'COMPLETED'
                             )
      ,     JOB_END_DTS   = datetime()
      ,     JOB_RC        = &job_rc.
      ,     UPDATE_USER   = "&sysuserid."
      ,     UPDATE_DTS    = "&sysdate9. &systime."dt
      where JOB_RUN_ID    = &job_run_id.
    ;

  quit;

%mend x;
%x;


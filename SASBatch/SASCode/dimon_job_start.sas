/************************************************************************** */
/* Program Name : dimonStartJob.sas                                         */
/* Purpose      : This program records the start of a job in the DIMon      */
/*                tables.                                                   */
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
/* 29nov12  eombah  Use less envvars                                        */
/* 13may13  eombah  Updated for MYSQL                                       */
/* 28sep14  eombah  Fixed bug when multiple jobs within the same flow start */
/*                  at the same time                                        */
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

  libname DIMON list;

  %let engine = ;
  proc sql noprint;
    select ENGINE into :engine
    from   SASHELP.VLIBNAM
    where  LIBNAME = 'DIMON'
    ;
  quit;

  /* Retrieve Flow and Job Information from Environment Variables */
  /* Example lsb_jobname=59:lsfadmin:testflow21:testflow2:testjob2; */
  %let lsb_jobname = %sysget(LSB_JOBNAME);
  %let lsb_jobid   = %sysget(LSB_JOBID);
  %let saslogfile  = %sysget(SASLOGFILE);
  %let saslstfile  = %sysget(SASLSTFILE);

  data _null_;
    length saslogfile saslstfile $1024;
    lsb_jobname   = symget('LSB_JOBNAME');
    lsb_jobid     = symget('LSB_JOBID');
    saslogfile    = symget('SASLOGFILE');
    saslstfile    = symget('SASLSTFILE');
    flow_run_id   = scan(lsb_jobname,1,':');
    lsf_user      = scan(lsb_jobname,2,':');
    flow_name     = scan(lsb_jobname,3,':');
    job_name      = scan(lsb_jobname,-1,':');
    job_run_id    = strip(lsb_jobid);
    flow_job_name = substr(lsb_jobname,index(lsb_jobname,':')+1);
    flow_job_name = substr(flow_job_name,index(flow_job_name,':')+1);
    call symput('flow_run_id',strip(flow_run_id));
    call symput('job_run_id',strip(job_run_id));

    if (symget('engine') = 'MYSQL') then
    do; /* escape backslashes for MYSQL */
        lsf_user   = tranwrd(strip(lsf_user),'\','\\');
        saslogfile = tranwrd(strip(saslogfile),'\','\\');
        saslstfile = tranwrd(strip(saslstfile),'\','\\');
    end;/* escape backslashes for MYSQL */

    call symput('saslogfile'   ,strip(saslogfile));
    call symput('saslstfile'   ,strip(saslstfile));
    call symput('lsf_user'     ,strip(lsf_user));
    call symput('flow_name'    ,strip(flow_name));
    call symput('job_name'     ,strip(job_name));
    call symput('flow_job_name',strip(flow_job_name));
  run;

  %put NOTE: LSB_JOBNAME   = &lsb_jobname.;
  %put NOTE: LSB_JOBID     = &lsb_jobid.;
  %put NOTE: FLOW_RUN_ID   = &flow_run_id.;
  %put NOTE: JOB_RUN_ID    = &job_run_id.;
  %put NOTE: LSF_USER      = &lsf_user.;
  %put NOTE: FLOW_NAME     = &flow_name.;
  %put NOTE: JOB_NAME      = &job_name.;
  %put NOTE: FLOW_JOB_NAME = &flow_job_name.;
  %put NOTE: SASLOGFILE    = &saslogfile.;
  %put NOTE: SASLSTFILE    = &saslstfile.;

  %let flow_run_id_count =  0;
  %let flow_job_id       = -1;
  %let flow_id           = -1;
  %let job_id            = -1;
  proc sql noprint;
    select FLOW_JOB_ID
    ,      FLOW_ID      into :flow_job_id
                        ,    :flow_id
    from   DIMON.DIMON_FLOW_JOB
    where  FLOW_JOB_NAME = symget('flow_job_name')
    and    CURRENT_IND   = 'Y'
    ;
  quit;
  %put NOTE: LSB_JOBNAME resolved to:;
  %put NOTE:   FLOW_JOB_ID = &flow_job_id.;
  %put NOTE:   FLOW_ID     = &flow_id.;

  %if ("&flow_job_id." ne "-1") %then
  %do; /* insert rows for this flow/job */

       %let flow_run_id_count = 0;
       proc sql undo_policy=none noprint;
         select strip(put(count(*),8.)) into :flow_run_id_count
         from   DIMON.DIMON_JOB_RUNS
         where  FLOW_RUN_ID = &flow_run_id.
         ;
       quit;

       %if (&flow_run_id_count. = 0) %then
           %let flow_run_seq_nr = 1;

       %if (&flow_run_id_count. > 0) %then
       %do; /* flow_run_id already exists : Check existence of flow_run_id and flow_job_id in table DIMON_JOB_RUNS */

            proc sql undo_policy=none noprint;
              select strip(put(count(*),8.)) into: count_run_id_job_id
              from   DIMON.DIMON_JOB_RUNS
              where  FLOW_RUN_ID = &flow_run_id.
              and    FLOW_JOB_ID = "&flow_job_id."
              ;
            quit;

            %if (&count_run_id_job_id. gt 0) %then
            %do; /* combination of flow_run_id and flow_job_id exists ==> check if seq_nr + 1 */

                 proc sql undo_policy=none noprint;
                   select max(FLOW_RUN_SEQ_NR) into :max_flow_run_seq_nr
                   from   DIMON.DIMON_JOB_RUNS
                   where  FLOW_RUN_ID = &flow_run_id.
                   ;
                 quit;

                 %if (&count_run_id_job_id >= &max_flow_run_seq_nr) %then
                     %let flow_run_seq_nr = %eval(&max_flow_run_seq_nr. + 1);
                 %else
                     %let flow_run_seq_nr = &max_flow_run_seq_nr.;

            %end;/* combination of flow_run_id and flow_job_id exists ==> check if seq_nr + 1 */

            %if (&count_run_id_job_id = 0) %then
            %do; /* flow_run_id exists, but job did not run before, get max(flow_run_seq_nr)*/

                 proc sql undo_policy=none noprint;
                   select max(FLOW_RUN_SEQ_NR) into :max_flow_run_seq_nr
                   from   DIMON.DIMON_JOB_RUNS
                   where  FLOW_RUN_ID = &flow_run_id.
                   ;
                 quit;
                 %let flow_run_seq_nr = &max_flow_run_seq_nr.;

            %end;/* flow_run_id exists, but job did not run before, get max(flow_run_seq_nr)*/

       %end;/* flow_run_id already exists : Check existence of flow_run_id and flow_job_id in table dimon_job_runs */

       proc sql undo_policy=none noprint;
         insert into DIMON.DIMON_JOB_RUNS(cntllev=rec)
           set JOB_RUN_ID      = &job_run_id.
           ,   FLOW_RUN_ID     = &flow_run_id.
           ,   FLOW_RUN_SEQ_NR = &flow_run_seq_nr.
           ,   FLOW_JOB_ID     = "%trim(%left(&flow_job_id.))"
           ,   JOB_START_DTS   = datetime()
           ,   JOB_END_DTS     = .
           ,   JOB_LOG_FILE    = "&saslogfile."
           ,   JOB_LST_FILE    = "&saslstfile."
           ,   JOB_STATUS_ID   = ( select JOB_STATUS_ID from DIMON.DIMON_JOB_STATUS where JOB_STATUS_CODE = 'RUNNING' )
           ,   JOB_RC          = .
           ,   UPDATE_USER     = "&sysuserid."
           ,   UPDATE_DTS      = datetime()
         ;
       quit;

  %end;/* insert rows for this flow/job */
  %else
  %do; /* print error message */

       %put ERROR: Failed to resolve "&lsb_jobname." to a FLOW_JOB_ID.;
       %put ERROR: No records were inserted/updated.;
       %abort;

  %end;/* print error message */

%mend x;
options mprint;
%x;


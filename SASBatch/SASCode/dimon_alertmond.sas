%macro alertmon;

  %if (&_debug > 0) %then
  %do;
       options notes mprint;
  %end;
  %else
  %do;
       options nonotes nomprint;
  %end;

%do %while(1);

%let loopstartdts = %sysfunc(datetime());




/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: woensdag 26 februari 2020     TIME: 10:48:23
PROJECT: DIMonRT3
PROJECT PATH: C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp
---------------------------------------- */

/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;


/* Build where clauses from stored process parameters */
%macro _eg_WhereParam( COLUMN, PARM, OPERATOR, TYPE=S, MATCHALL=_ALL_VALUES_, MATCHALL_CLAUSE=1, MAX= , IS_EXPLICIT=0, MATCH_CASE=1);

  %local q1 q2 sq1 sq2;
  %local isEmpty;
  %local isEqual isNotEqual;
  %local isIn isNotIn;
  %local isString;
  %local isBetween;

  %let isEqual = ("%QUPCASE(&OPERATOR)" = "EQ" OR "&OPERATOR" = "=");
  %let isNotEqual = ("%QUPCASE(&OPERATOR)" = "NE" OR "&OPERATOR" = "<>");
  %let isIn = ("%QUPCASE(&OPERATOR)" = "IN");
  %let isNotIn = ("%QUPCASE(&OPERATOR)" = "NOT IN");
  %let isString = (%QUPCASE(&TYPE) eq S or %QUPCASE(&TYPE) eq STRING );
  %if &isString %then
  %do;
	%if "&MATCH_CASE" eq "0" %then %do;
		%let COLUMN = %str(UPPER%(&COLUMN%));
	%end;
	%let q1=%str(%");
	%let q2=%str(%");
	%let sq1=%str(%'); 
	%let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq D or %QUPCASE(&TYPE) eq DATE %then 
  %do;
    %let q1=%str(%");
    %let q2=%str(%"d);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq T or %QUPCASE(&TYPE) eq TIME %then
  %do;
    %let q1=%str(%");
    %let q2=%str(%"t);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else %if %QUPCASE(&TYPE) eq DT or %QUPCASE(&TYPE) eq DATETIME %then
  %do;
    %let q1=%str(%");
    %let q2=%str(%"dt);
	%let sq1=%str(%'); 
    %let sq2=%str(%'); 
  %end;
  %else
  %do;
    %let q1=;
    %let q2=;
	%let sq1=;
    %let sq2=;
  %end;
  
  %if "&PARM" = "" %then %let PARM=&COLUMN;

  %let isBetween = ("%QUPCASE(&OPERATOR)"="BETWEEN" or "%QUPCASE(&OPERATOR)"="NOT BETWEEN");

  %if "&MAX" = "" %then %do;
    %let MAX = &parm._MAX;
    %if &isBetween %then %let PARM = &parm._MIN;
  %end;

  %if not %symexist(&PARM) or (&isBetween and not %symexist(&MAX)) %then %do;
    %if &IS_EXPLICIT=0 %then %do;
		not &MATCHALL_CLAUSE
	%end;
	%else %do;
	    not 1=1
	%end;
  %end;
  %else %if "%qupcase(&&&PARM)" = "%qupcase(&MATCHALL)" %then %do;
    %if &IS_EXPLICIT=0 %then %do;
	    &MATCHALL_CLAUSE
	%end;
	%else %do;
	    1=1
	%end;	
  %end;
  %else %if (not %symexist(&PARM._count)) or &isBetween %then %do;
    %let isEmpty = ("&&&PARM" = "");
    %if (&isEqual AND &isEmpty AND &isString) %then
       &COLUMN is null;
    %else %if (&isNotEqual AND &isEmpty AND &isString) %then
       &COLUMN is not null;
    %else %do;
	   %if &IS_EXPLICIT=0 %then %do;
           &COLUMN &OPERATOR 
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(&q1)%QUPCASE(&&&PARM)%unquote(&q2)
			%end;
			%else %do;
				%unquote(&q1)&&&PARM%unquote(&q2)
			%end;
	   %end;
	   %else %do;
	       &COLUMN &OPERATOR 
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM)%unquote(%nrstr(&sq2))
			%end;
			%else %do;
				%unquote(%nrstr(&sq1))&&&PARM%unquote(%nrstr(&sq2))
			%end;
	   %end;
       %if &isBetween %then 
          AND %unquote(&q1)&&&MAX%unquote(&q2);
    %end;
  %end;
  %else 
  %do;
	%local emptyList;
  	%let emptyList = %symexist(&PARM._count);
  	%if &emptyList %then %let emptyList = &&&PARM._count = 0;
	%if (&emptyList) %then
	%do;
		%if (&isNotin) %then
		   1;
		%else
			0;
	%end;
	%else %if (&&&PARM._count = 1) %then 
    %do;
      %let isEmpty = ("&&&PARM" = "");
      %if (&isIn AND &isEmpty AND &isString) %then
        &COLUMN is null;
      %else %if (&isNotin AND &isEmpty AND &isString) %then
        &COLUMN is not null;
      %else %do;
	    %if &IS_EXPLICIT=0 %then %do;
			%if "&MATCH_CASE" eq "0" %then %do;
				&COLUMN &OPERATOR (%unquote(&q1)%QUPCASE(&&&PARM)%unquote(&q2))
			%end;
			%else %do;
				&COLUMN &OPERATOR (%unquote(&q1)&&&PARM%unquote(&q2))
			%end;
	    %end;
		%else %do;
		    &COLUMN &OPERATOR (
			%if "&MATCH_CASE" eq "0" %then %do;
				%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM)%unquote(%nrstr(&sq2)))
			%end;
			%else %do;
				%unquote(%nrstr(&sq1))&&&PARM%unquote(%nrstr(&sq2)))
			%end;
		%end;
	  %end;
    %end;
    %else 
    %do;
       %local addIsNull addIsNotNull addComma;
       %let addIsNull = %eval(0);
       %let addIsNotNull = %eval(0);
       %let addComma = %eval(0);
       (&COLUMN &OPERATOR ( 
       %do i=1 %to &&&PARM._count; 
          %let isEmpty = ("&&&PARM&i" = "");
          %if (&isString AND &isEmpty AND (&isIn OR &isNotIn)) %then
          %do;
             %if (&isIn) %then %let addIsNull = 1;
             %else %let addIsNotNull = 1;
          %end;
          %else
          %do;		     
            %if &addComma %then %do;,%end;
			%if &IS_EXPLICIT=0 %then %do;
				%if "&MATCH_CASE" eq "0" %then %do;
					%unquote(&q1)%QUPCASE(&&&PARM&i)%unquote(&q2)
				%end;
				%else %do;
					%unquote(&q1)&&&PARM&i%unquote(&q2)
				%end;
			%end;
			%else %do;
				%if "&MATCH_CASE" eq "0" %then %do;
					%unquote(%nrstr(&sq1))%QUPCASE(&&&PARM&i)%unquote(%nrstr(&sq2))
				%end;
				%else %do;
					%unquote(%nrstr(&sq1))&&&PARM&i%unquote(%nrstr(&sq2))
				%end; 
			%end;
            %let addComma = %eval(1);
          %end;
       %end;) 
       %if &addIsNull %then OR &COLUMN is null;
       %else %if &addIsNotNull %then AND &COLUMN is not null;
       %do;)
       %end;
    %end;
  %end;
%mend _eg_WhereParam;



/*   START OF NODE: start   */
%LET _CLIENTTASKLABEL='start';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;


/*   START OF NODE: get active and finished flows   */
%LET _CLIENTTASKLABEL='get active and finished flows';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
%macro x;

  %if (not(%sysfunc(exist(work.notified)))) %then
  %do; /* create empty work.notified */
       data work.notified;
         if (0) then
         do; 
             set dimon.dimon_job_runs(keep=flow_run_id rename=(flow_run_id=flow_run_id1));
             set dimon.dimon_flows(keep=flow_id flow_name rename=(flow_id=flow_id1 flow_name=flow_name1));
             set dimon.dimon_flow_alerts(keep=alert_condition alert_action alert_action_details rename=(alert_action_details=alert_email_address));
             length scheduled_run_dts 8;
             length alert_email_message $ 200;
             length alert_email_message_details $ 1024;
         end;
         stop;
       run;
  %end;/* create empty work.notified */

  %if (not(%sysfunc(exist(work.flows_init)))) %then
  %do;

       /* get active flows */
       %let lsf_flow_active_dir = /apps/sas/thirdparty/pm/work/storage/flow_instance_storage/active;
       filename _folder_ "%bquote(&lsf_flow_active_dir)";
       data work.active_flows_init(keep=flow_run_id flow_status);
         handle  = dopen('_folder_');
         if (handle > 0) then
         do;
             count = dnum(handle);
             do i=1 to count;
                 memname = dread(handle,i);
                 flow_run_id = input(scan(memname,1,'.'),8.);
                 length flow_status $ 8;
                 flow_status = 'ACTIVE';
                 output;
             end;
         end;
         rc = dclose(handle);
         stop;
       run;
       filename _folder_ clear;

       /* get finished flows */
       %let lsf_flow_finished_dir  = /apps/sas/thirdparty/pm/work/storage/flow_instance_storage/finished;
       filename _folder_ "%bquote(&lsf_flow_finished_dir)";
       data work.finished_flows_init(keep=flow_run_id flow_status);
         handle  = dopen('_folder_');
         if (handle > 0) then
         do;
             count = dnum(handle);
             do i=1 to count;
                 memname = dread(handle,i);
                 flow_run_id = input(scan(memname,1,'.'),8.);
                 length flow_status $ 8;
                 flow_status = 'FINISHED';
                 output;
             end;
         end;
         rc = dclose(handle);
         stop;
       run;
       filename _folder_ clear;

       /* combine */
       proc sql;
         create table work.flows_init as
           select  coalesce(t1.flow_run_id,t2.flow_run_id) as flow_run_id
           ,       not(missing(t1.flow_run_id)) as is_active
           ,       not(missing(t2.flow_run_id)) as is_finished
           from      work.active_flows_init t1
           full join work.finished_flows_init t2 
           on        t1.flow_run_id = t2.flow_run_id
         ;
       quit;

  %end;
  %else
     %put NOTE: WORK.FINISHED_FLOWS_INIT not created because WORK.FLOWS_INIT already exists.;

%mend x;
%x

%let lsf_flow_active_dir  = /apps/sas/thirdparty/pm/work/storage/flow_instance_storage/active;

  /* get active flows */
  filename _folder_ "%bquote(&lsf_flow_active_dir)";
  data work.active_flows(keep=flow_run_id flow_status);
    handle  = dopen('_folder_');
    if (handle > 0) then
    do;
        count = dnum(handle);
        do i=1 to count;
            memname = dread(handle,i);
            flow_run_id = input(scan(memname,1,'.'),8.);
            length flow_status $ 8;
            flow_status = 'ACTIVE';
            output;
        end;
    end;
    rc = dclose(handle);
    stop;
  run;
  filename _folder_ clear;


%let lsf_flow_finished_dir  = /apps/sas/thirdparty/pm/work/storage/flow_instance_storage/finished;
  filename _folder_ "%bquote(&lsf_flow_finished_dir)";
  data work.finished_flows(keep=flow_run_id flow_status);
    handle  = dopen('_folder_');
    if (handle > 0) then
    do;
        count = dnum(handle);
        do i=1 to count;
            memname = dread(handle,i);
            flow_run_id = input(scan(memname,1,'.'),8.);
            length flow_status $ 8;
            flow_status = 'FINISHED';
            output;
        end;
    end;
    rc = dclose(handle);
    stop;
  run;
  filename _folder_ clear;

%_eg_conditional_dropds(WORK.FLOWS_NOW);

PROC SQL;
   CREATE TABLE WORK.FLOWS_NOW AS 
   SELECT /* flow_run_id */
            (coalesce(t1.flow_run_id,t2.flow_run_id)) AS flow_run_id, 
          /* is_active */
            (not(missing(t1.flow_run_id))) AS is_active, 
          /* is_finished */
            (not(missing(t2.flow_run_id))) AS is_finished
      FROM WORK.ACTIVE_FLOWS t1
           FULL JOIN WORK.FINISHED_FLOWS t2 ON (t1.flow_run_id = t2.flow_run_id);
QUIT;

%_eg_conditional_dropds(WORK.CHANGES);

PROC SQL;
   CREATE TABLE WORK.CHANGES AS 
   SELECT t1.flow_run_id, 
          t1.is_active, 
          t1.is_finished, 
          t2.flow_run_id AS flow_run_id1, 
          t2.is_active AS is_active1, 
          t2.is_finished AS is_finished1
      FROM WORK.FLOWS_INIT t1
           RIGHT JOIN WORK.FLOWS_NOW t2 ON (t1.flow_run_id = t2.flow_run_id)
      WHERE t1.is_active NOT = t2.is_active OR t1.is_finished NOT = t2.is_finished;
QUIT;

data work.flows_init;
  set work.flows_now;
run;


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;


/*   START OF NODE: get flow id   */
%LET SYSLAST=DIMON.DIMON_JOB_RUNS;
%LET _CLIENTTASKLABEL='get flow id';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
%macro x;

  %let nobs1 = 0;
  proc sql noprint;
    select count(*) into :nobs1
    from   WORK.CHANGES
    ;
  quit;

  %if (&nobs1 > 0) %then
  %do; /* the lsf file may be found before the flow is found in dimon --> loop until all are found */

       %let tries = 0;
       %do %until((&nobs2 = &nobs1) or (&tries > 10));

            %_eg_conditional_dropds(WORK.CHANGES_WITH_FLOW_ID);

            PROC SQL;
               CREATE TABLE WORK.CHANGES_WITH_FLOW_ID AS 
               SELECT DISTINCT t1.flow_run_id, 
                      t1.is_active, 
                      t1.is_finished, 
                      t1.flow_run_id1, 
                      t1.is_active1, 
                      t1.is_finished1, 
                      t3.flow_id AS flow_id1, 
                      t4.flow_name AS flow_name1
                  FROM DIMON.DIMON_JOB_RUNS t2, DIMON.DIMON_FLOW_JOB t3, DIMON.DIMON_FLOWS t4, WORK.CHANGES t1
                  WHERE (t2.flow_job_id = t3.flow_job_id AND (t3.current_ind = 'Y') AND t3.flow_id = t4.flow_id AND (t4.current_ind 
                       = 'Y') AND coalesce(t1.flow_run_id,t1.flow_run_id1) = t2.flow_run_id);
                  %let nobs2 = &sqlobs;
            QUIT;
            %put NOTE: SQLOBS=&nobs2;
     
            %if (&nobs1 ne &nobs2) %then
            %do; /* sleep 1 second */

                 %let tries = %sysevalf(&tries + 1);
                 data _null_;
                   rc = sleep(1,1);
                 run;

            %end;/* sleep 1 second */

       %end;/* do until */

       %if (&tries = 11) %then
       %do;
            %put WARNING: Not all flow_id%str(%')s were found.;
            proc sql;
              create table work.warnings as
                select    t1.flow_run_id  as changes_flow_run_id
                ,         t1.flow_run_id1 as changes_flow_run_id1
                ,         t2.flow_run_id  as job_runs_flow_run_id
                ,         t3.flow_job_id  as flow_job_flow_job_id
                ,         t4.flow_id      as flows_flow_id
                from      WORK.CHANGES t1
                left join DIMON.DIMON_JOB_RUNS t2
                on        coalesce(t1.flow_run_id,t1.flow_run_id1) = t2.flow_run_id
                left join DIMON.DIMON_FLOW_JOB t3
                on        t2.flow_job_id = t3.flow_job_id 
                and       t3.current_ind = 'Y'
                left join DIMON.DIMON_FLOWS t4
                on        t3.flow_id = t4.flow_id
                and       t4.current_ind = 'Y'
                where     missing(job_runs_flow_run_id)
                or        missing(flow_job_flow_job_id)
                or        missing(flows_flow_id)
              ;
            quit;
            data _null_;
              set work.warnings;
              put 'WARNING: ' changes_flow_run_id= job_runs_flow_run_id= flow_job_flow_job_id= flows_flow_id=;
            run;
       %end; 

  %end;/* the lsf file may be found before the flow is found in dimon --> loop until all are found */
  %else
  %do;
       %_eg_conditional_dropds(WORK.CHANGES_WITH_FLOW_ID);

       PROC SQL;
          CREATE TABLE WORK.CHANGES_WITH_FLOW_ID AS 
          SELECT DISTINCT t1.flow_run_id, 
                 t1.is_active, 
                 t1.is_finished, 
                 t1.flow_run_id1, 
                 t1.is_active1, 
                 t1.is_finished1, 
                 t3.flow_id AS flow_id1, 
                 t4.flow_name AS flow_name1
             FROM DIMON.DIMON_JOB_RUNS t2, DIMON.DIMON_FLOW_JOB t3, DIMON.DIMON_FLOWS t4, WORK.CHANGES t1
             WHERE (t2.flow_job_id = t3.flow_job_id AND (t3.current_ind = 'Y') AND t3.flow_id = t4.flow_id AND (t4.current_ind 
                  = 'Y') AND t1.flow_run_id1 = t2.flow_run_id);
       QUIT;
  %end;

%mend x;
%x


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;


/*   START OF NODE: lookup alerts   */
%LET _CLIENTTASKLABEL='lookup alerts';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.CHANGES_WITH_ALERTS);

PROC SQL;
   CREATE TABLE WORK.CHANGES_WITH_ALERTS AS 
   SELECT t1.flow_run_id, 
          t1.is_active, 
          t1.is_finished, 
          t1.flow_run_id1, 
          t1.is_active1, 
          t1.is_finished1, 
          t1.flow_id1 LABEL='', 
          t1.flow_name1 LABEL='', 
          t2.alert_condition LABEL='' AS alert_condition, 
          t2.alert_condition_operator LABEL='' AS alert_condition_operator, 
          t2.alert_condition_value LABEL='' AS alert_condition_value, 
          t2.alert_action LABEL='' AS alert_action, 
          t2.alert_action_details LABEL='' AS alert_action_details, 
          t2.dimon_user LABEL='' AS dimon_user
      FROM WORK.CHANGES_WITH_FLOW_ID t1
           INNER JOIN DIMON.DIMON_FLOW_ALERTS t2 ON (t1.flow_id1 = t2.flow_id);
QUIT;

GOPTIONS NOACCESSIBLE;



%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: filter finished   */
%LET _CLIENTTASKLABEL='filter finished';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.CHANGES_WITH_ALERTS_FINISHED);

PROC SQL;
   CREATE TABLE WORK.CHANGES_WITH_ALERTS_FINISHED AS 
   SELECT t1.flow_run_id, 
          t1.is_active, 
          t1.is_finished, 
          t1.flow_run_id1, 
          t1.is_active1, 
          t1.is_finished1, 
          t1.flow_id1, 
          t1.flow_name1, 
          t1.alert_condition AS alert_condition, 
          t1.alert_condition_operator AS alert_condition_operator, 
          t1.alert_condition_value AS alert_condition_value, 
          t1.alert_action AS alert_action, 
          t1.alert_action_details AS alert_action_details, 
          t1.dimon_user AS dimon_user
      FROM WORK.CHANGES_WITH_ALERTS t1
      WHERE t1.is_finished1 = 1 AND t1.alert_condition IN 
           (
           'ends_with_any_exit_code',
           'completes_successfully',
           'ends_with_exit_code',
           'runs_less_than'
           );
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: lookup flow_rc and runtime   */
%LET _CLIENTTASKLABEL='lookup flow_rc and runtime';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.CHANGES_WITH_ALERTS_AND_FLOW_RC);

PROC SQL;
   CREATE TABLE WORK.CHANGES_WITH_ALERTS_AND_FLOW_RC AS 
   SELECT t1.flow_run_id1, 
          t1.flow_id1, 
          t1.flow_name1, 
          t1.is_active1, 
          t1.is_finished1, 
          t1.alert_condition AS alert_condition, 
          t1.alert_condition_operator AS alert_condition_operator, 
          t1.alert_condition_value AS alert_condition_value, 
          t1.alert_action AS alert_action, 
          t1.alert_action_details AS alert_action_details, 
          /* flow_rc */
            (MAX(t2.job_rc)) FORMAT=6. AS flow_rc, 
          /* runtime */
            (max(t2.job_end_dts) - min(t2.job_start_dts)) AS runtime
      FROM WORK.CHANGES_WITH_ALERTS_FINISHED t1
           INNER JOIN DIMON.DIMON_JOB_RUNS t2 ON (t1.flow_run_id1 = t2.flow_run_id)
      GROUP BY t1.flow_run_id1,
               t1.flow_id1,
               t1.flow_name1,
               t1.is_active1,
               t1.is_finished1,
               t1.alert_condition,
               t1.alert_condition_operator,
               t1.alert_condition_value,
               t1.alert_action,
               t1.alert_action_details;
QUIT;

GOPTIONS NOACCESSIBLE;



%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: filter condition EWEC,EWAEC   */
%LET _CLIENTTASKLABEL='filter condition EWEC,EWAEC';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.ALERTS_EWEC);

PROC SQL;
   CREATE TABLE WORK.ALERTS_EWEC AS 
   SELECT t1.flow_run_id1, 
          t1.flow_id1, 
          t1.flow_name1, 
          t1.is_active1, 
          t1.is_finished1, 
          t1.alert_condition, 
          t1.alert_condition_operator, 
          t1.alert_condition_value, 
          t1.alert_action, 
          t1.alert_action_details, 
          t1.flow_rc
      FROM WORK.CHANGES_WITH_ALERTS_AND_FLOW_RC t1
      WHERE t1.alert_condition IN 
           (
           'ends_with_exit_code',
           'ends_with_any_exit_code'
           ) AND t1.is_finished1 = 1;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: evaluate condition   */
%LET SYSLAST=WORK.ALERTS_EWEC;
%LET _CLIENTTASKLABEL='evaluate condition';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
data work.alerts_ewec_eval;
  set work.alerts_ewec;
  if (alert_comparison = 'ends_with_exit_code') then
  do; /* apply alert condition */
      call symput('comparison',strip(strip(put(flow_rc,best.))!!' '!!strip(alert_condition_operator)!!' '!!strip(put(alert_condition_value,best.))));
      if (resolve('%sysevalf(&comparison)'));
  end;/* apply alert condition */
run;



GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;


/*   START OF NODE: filter email alerts   */
%LET _CLIENTTASKLABEL='filter email alerts';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.ALERTS_EWEC_EVAL_EMAIL);

PROC SQL;
   CREATE TABLE WORK.ALERTS_EWEC_EVAL_EMAIL AS 
   SELECT t1.flow_run_id1, 
          t1.flow_id1, 
          t1.flow_name1, 
          t1.alert_condition, 
          t1.alert_action AS alert_action, 
          t1.alert_action_details AS alert_email_address, 
          /* alert_email_message */
            (strip(t1.flow_name1)!!' ended with exit code '!!strip(put(t1.flow_rc,best.))) AS alert_email_message, 
          /* alert_email_message_details */
            ('') AS alert_email_message_details
      FROM WORK.ALERTS_EWEC_EVAL t1
      WHERE t1.alert_action = 'email';
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: filter condition CS   */
%LET _CLIENTTASKLABEL='filter condition CS';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.ALERTS_CS);

PROC SQL;
   CREATE TABLE WORK.ALERTS_CS AS 
   SELECT t1.flow_run_id1, 
          t1.flow_id1, 
          t1.flow_name1, 
          t1.is_active1, 
          t1.is_finished1, 
          t1.alert_condition AS alert_condition, 
          t1.alert_action AS alert_action, 
          t1.alert_action_details AS alert_action_details, 
          t1.flow_rc
      FROM WORK.CHANGES_WITH_ALERTS_AND_FLOW_RC t1
      WHERE t1.alert_condition = 'completes_successfully' AND t1.flow_rc = 0 AND t1.is_finished1 = 1;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: filter email alerts   */
%LET _CLIENTTASKLABEL='filter email alerts';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.ALERTS_CS_EMAIL);

PROC SQL;
   CREATE TABLE WORK.ALERTS_CS_EMAIL AS 
   SELECT t1.flow_run_id1, 
          t1.flow_id1, 
          t1.flow_name1, 
          t1.alert_condition AS alert_condition, 
          t1.alert_action AS alert_action, 
          t1.alert_action_details AS alert_email_address, 
          /* alert_email_message */
            (strip(t1.flow_name1)!!' completed successfully.') AS alert_email_message, 
          /* alert_email_message_details */
            ('') AS alert_email_message_details
      FROM WORK.ALERTS_CS t1
      WHERE t1.alert_action = 'email';
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: filter condition Runs less than   */
%LET _CLIENTTASKLABEL='filter condition Runs less than';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.ALERTS_RUNS_LESS_THAN);

PROC SQL;
   CREATE TABLE WORK.ALERTS_RUNS_LESS_THAN AS 
   SELECT t1.flow_run_id1, 
          t1.flow_id1, 
          t1.flow_name1, 
          t1.is_active1, 
          t1.is_finished1, 
          t1.alert_condition AS alert_condition, 
          t1.alert_condition_operator, 
          t1.alert_condition_value, 
          t1.alert_action AS alert_action, 
          t1.alert_action_details AS alert_action_details, 
          t1.flow_rc
      FROM WORK.CHANGES_WITH_ALERTS_AND_FLOW_RC t1
      WHERE t1.alert_condition = 'runs_less_than' AND t1.is_finished1 = 1 AND t1.runtime < (t1.alert_condition_value*60);
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: filter email alerts   */
%LET _CLIENTTASKLABEL='filter email alerts';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.ALERTS_RUNS_LESS_THAN_EMAIL);

PROC SQL;
   CREATE TABLE WORK.ALERTS_RUNS_LESS_THAN_EMAIL AS 
   SELECT t1.flow_run_id1, 
          t1.flow_id1, 
          t1.flow_name1, 
          t1.alert_condition, 
          t1.alert_action, 
          t1.alert_action_details AS alert_email_address, 
          /* alert_email_message */
            (strip(t1.flow_name1)!!' ran less than '!!strip(put(t1.alert_condition_value,best.))!!' minute(s).') AS 
            alert_email_message, 
          /* alert_email_message_details */
            ('') AS alert_email_message_details
      FROM WORK.ALERTS_RUNS_LESS_THAN t1
      WHERE t1.alert_action = 'email';
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: filter condition Starts   */
%LET _CLIENTTASKLABEL='filter condition Starts';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.ALERTS_STARTS);

PROC SQL;
   CREATE TABLE WORK.ALERTS_STARTS AS 
   SELECT t1.flow_run_id, 
          t1.is_active, 
          t1.is_finished, 
          t1.flow_run_id1, 
          t1.is_active1, 
          t1.is_finished1, 
          t1.flow_id1, 
          t1.flow_name1, 
          t1.alert_condition AS alert_condition, 
          t1.alert_condition_operator AS alert_condition_operator, 
          t1.alert_condition_value AS alert_condition_value, 
          t1.alert_action AS alert_action, 
          t1.alert_action_details AS alert_action_details
      FROM WORK.CHANGES_WITH_ALERTS t1
      WHERE t1.alert_condition = 'starts' AND t1.is_active1 = 1;
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: filter email alerts   */
%LET _CLIENTTASKLABEL='filter email alerts';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.ALERTS_STARTS_EMAIL);

PROC SQL;
   CREATE TABLE WORK.ALERTS_STARTS_EMAIL AS 
   SELECT t1.flow_run_id1, 
          t1.flow_id1, 
          t1.flow_name1, 
          t1.alert_condition AS alert_condition, 
          t1.alert_action AS alert_action, 
          t1.alert_action_details AS alert_email_address, 
          /* alert_email_message */
            (strip(t1.flow_name1)!!' started execution (Flow Run ID '!!strip(put(t1.flow_run_id1,8.))!!')') AS 
            alert_email_message, 
          /* alert_email_message_details */
            ('') AS alert_email_message_details
      FROM WORK.ALERTS_STARTS t1
      WHERE t1.alert_action = 'email';
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: lookup flow_id's   */
%LET _CLIENTTASKLABEL='lookup flow_id''s';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.FLOWS_NOW_WITH_FLOW_ID);

PROC SQL;
   CREATE TABLE WORK.FLOWS_NOW_WITH_FLOW_ID AS 
   SELECT t1.flow_run_id, 
          t1.is_active, 
          t1.is_finished, 
          t3.flow_id LABEL='' AS flow_id, 
          /* flow_start_dts */
            (MIN(t2.job_start_dts)) FORMAT=DATETIME25.6 AS flow_start_dts
      FROM WORK.FLOWS_NOW t1, DIMON.DIMON_JOB_RUNS t2, DIMON.DIMON_FLOW_JOB t3
      WHERE (t1.flow_run_id = t2.flow_run_id AND t2.flow_job_id = t3.flow_job_id)
      GROUP BY t1.flow_run_id,
               t1.is_active,
               t1.is_finished,
               t3.flow_id;
QUIT;

GOPTIONS NOACCESSIBLE;




%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: get flow startdts   */
%LET _CLIENTTASKLABEL='get flow startdts';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.ACTIVE_FLOWS_STARTDTS);

PROC SQL;
   CREATE TABLE WORK.ACTIVE_FLOWS_STARTDTS AS 
   SELECT t1.flow_run_id, 
          t3.flow_id LABEL='' AS flow_id, 
          t4.flow_name LABEL='' AS flow_name, 
          /* flow_start_dts */
            (MIN(t2.job_start_dts)) FORMAT=DATETIME25.6 AS flow_start_dts
      FROM WORK.ACTIVE_FLOWS t1, DIMON.DIMON_JOB_RUNS t2, DIMON.DIMON_FLOW_JOB t3, DIMON.DIMON_FLOWS t4
      WHERE (t1.flow_run_id = t2.flow_run_id AND t2.flow_job_id = t3.flow_job_id AND t3.flow_id = t4.flow_id) AND 
           (t3.current_ind = 'Y' AND t4.current_ind = 'Y')
      GROUP BY t1.flow_run_id,
               t3.flow_id,
               t4.flow_name;
QUIT;

GOPTIONS NOACCESSIBLE;





%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: lookup alerts   */
%LET _CLIENTTASKLABEL='lookup alerts';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.ALERTS_RUNTIME);

PROC SQL;
   CREATE TABLE WORK.ALERTS_RUNTIME AS 
   SELECT t1.flow_run_id, 
          t1.flow_id, 
          t1.flow_name, 
          t2.alert_condition LABEL='' AS alert_condition, 
          t2.alert_condition_value LABEL='' AS alert_condition_value, 
          t2.alert_action LABEL='' AS alert_action, 
          t2.alert_action_details LABEL='' AS alert_action_details, 
          t1.flow_start_dts
      FROM WORK.ACTIVE_FLOWS_STARTDTS t1
           INNER JOIN DIMON.DIMON_FLOW_ALERTS t2 ON (t1.flow_id = t2.flow_id)
      WHERE t2.alert_condition IN 
           (
           'runs_more_than'
           );
QUIT;

GOPTIONS NOACCESSIBLE;



%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: evaluate condition   */
%LET SYSLAST=WORK.ALERTS_RUNTIME;
%LET _CLIENTTASKLABEL='evaluate condition';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
data work.alerts_runtime_eval(drop=condition);
  set work.alerts_runtime;
  if (strip(alert_condition) = 'runs_more_than') then
  do; /* apply alert condition */
      condition = '('!!strip(put(datetime(),best.))!!' - '!!strip(put(flow_start_dts,best.))!!')/60 > '!!strip(put(alert_condition_value,best.));
      call symput('condition',strip(condition));
      if (resolve('%sysevalf(&condition)'));
  end;/* apply alert condition */
run;



GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;


/*   START OF NODE: filter email alerts   */
%LET _CLIENTTASKLABEL='filter email alerts';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.ALERTS_RUNTIME_EMAIL);

PROC SQL;
   CREATE TABLE WORK.ALERTS_RUNTIME_EMAIL AS 
   SELECT t1.flow_run_id AS flow_run_id1, 
          t1.flow_id AS flow_id1, 
          t1.flow_name AS flow_name1, 
          t1.alert_condition, 
          t1.alert_action AS alert_action, 
          t1.alert_action_details AS alert_email_address, 
          /* alert_email_message */
            (case t1.alert_condition
              when 'runs_more_than' then strip(t1.flow_name)!!' runs more than '
            !!strip(put(t1.alert_condition_value,best.))!!' minutes.'
              when 'runs_less_than' then strip(t1.flow_name)!!' runs less than '
            !!strip(put(t1.alert_condition_value,best.))!!' minutes.'
              else 'ERROR: Unknown alert_condition "'!!strip(t1.alert_condition)!!'"'
            end
            
            ) AS alert_email_message, 
          /* alert_email_message_details */
            ('') AS alert_email_message_details, 
          /* already_notified */
            (not(missing(t2.flow_run_id1))) AS already_notified
      FROM WORK.ALERTS_RUNTIME_EVAL t1
           LEFT JOIN WORK.NOTIFIED t2 ON (t1.flow_run_id = t2.flow_run_id1) AND (t1.alert_condition = 
          t2.alert_condition) AND (t1.alert_action = t2.alert_action)
      WHERE (CALCULATED already_notified) NOT = 1;
QUIT;

GOPTIONS NOACCESSIBLE;



%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: time events   */
%LET _CLIENTTASKLABEL='time events';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.FLOWS_WITH_CALENDARS);

PROC SQL;
   CREATE TABLE WORK.FLOWS_WITH_CALENDARS AS 
   SELECT t1.FLOW_ID LABEL='', 
          t2.FLOW_NAME LABEL='', 
          t1.TRIGGERING_EVENT_TRANSFER_ROLE LABEL='', 
          t1.TRIGGERING_EVENT_ROLE LABEL='', 
          t1.TRIGGERING_EVENT_CONDITION LABEL='', 
          t1.TIMEZONE LABEL='', 
          /* calendar_name */
            (case upcase(t1.TRIGGERING_EVENT_ROLE)
              when 'TIMEEVENT' then scan(t1.TRIGGERING_EVENT_CONDITION,1,':')
              else ''
            end) AS calendar_name, 
          /* calendar_hours */
            (case upcase(t1.TRIGGERING_EVENT_ROLE)
              when 'TIMEEVENT' then scan(t1.TRIGGERING_EVENT_CONDITION,2,':')
              else ''
            end) AS calendar_hours, 
          /* calendar_minutes */
            (case upcase(t1.TRIGGERING_EVENT_ROLE)
              when 'TIMEEVENT' then scan(t1.TRIGGERING_EVENT_CONDITION,3,':%')
              else ''
            end) AS calendar_minutes, 
          t1.VALID_FROM_DTS LABEL='' AS FLOW_SCHEDULE_VALID_FROM_DTS, 
          t1.VALID_UNTIL_DTS LABEL='' AS FLOW_SCHEDULE_VALID_UNTIL_DTS, 
          t2.VALID_FROM_DTS LABEL='' AS FLOW_VALID_FROM_DTS, 
          t2.VALID_UNTIL_DTS LABEL='' AS FLOW_VALID_UNTIL_DTS, 
          t3.alert_condition, 
          t3.alert_action, 
          t3.alert_action_details
      FROM DIMON.DIMON_FLOW_SCHEDULES t1, DIMON.DIMON_FLOWS t2, DIMON.DIMON_FLOW_ALERTS t3
      WHERE (t1.FLOW_ID = t2.FLOW_ID AND t1.flow_id = t3.flow_id) AND (t1.TRIGGERING_EVENT_ROLE IN 
           (
           'TimeEvent',
           'TIMEEVENT'
           ) AND t3.alert_condition = 'misses_scheduled_time');
QUIT;

GOPTIONS NOACCESSIBLE;




%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: scheduled flows on run_date   */
%LET SYSLAST=WORK.FLOWS_WITH_CALENDARS;
%LET _CLIENTTASKLABEL='scheduled flows on run_date';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
%let run_date_from = %sysfunc(date(),date7.);
%let run_date_until = &run_date_from;

data work.rundates;
  do d=("&run_date_from"d - 1) to ("&run_date_until"d + 1);
      output;
  end;
  format d date9.;
  stop;
run;
proc sql;
  create view work.v1 as
    select t1.*
    ,      t2.d
    from   work.flows_with_calendars t1
    ,      work.rundates t2
  ;
quit;

data _null_;
  if (_n_ = 1) then
  do;
      call execute('options nosource;');
      call execute('proc sql;');
      call execute('  create table work.flows_scheduled_on_run_date as');
      call execute('    select flow_id');
      call execute('    ,      flow_name');
      call execute('    ,      calendar_name');
      call execute('    ,      calendar_hours');
      call execute('    ,      calendar_minutes');
      call execute('    ,      timezone');
      call execute('    ,      d');
      call execute('    ,      case calendar_name');
  end;
  set dimon.dimon_calendars end=last;
      call execute('             when "' !! strip(calendar_name) !! '" then ( ' !! strip(calendar_sascode) !! ' )');
  if (last) then
  do;
      call execute('             else 0');
      call execute('           end as active');
      call execute('    ,      flow_schedule_valid_from_dts');
      call execute('    ,      flow_schedule_valid_until_dts');
      call execute('    ,      flow_valid_from_dts');
      call execute('    ,      flow_valid_until_dts');
      call execute('    ,      alert_condition');
      call execute('    ,      alert_action');
      call execute('    ,      alert_action_details');
      call execute('    from   work.v1');
      call execute('    where  calculated active = 1');
      call execute('   ;');

      call execute('  drop view work.v1;');

      call execute('quit;');
  end;
run;
proc sql;
  drop table work.rundates;
quit;


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;


/*   START OF NODE: add times   */
%LET SYSLAST=WORK.FLOWS_SCHEDULED_ON_RUN_DATE;
%LET _CLIENTTASKLABEL='add times';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
%let run_date = %sysfunc(date(),date7.);
data work.t1;
  set work.flows_scheduled_on_run_date;
  count = 1;
  onehour = scan(calendar_hours,count,',');
  do while(onehour ne '');
      if (strip(onehour) = '*') then
      do;
          do hour = 0 to 23;
              output;
          end;/* do hour */
      end;
      else if (index(onehour,'-') > 0) then
      do;
          hourloopFrom  = input(scan(onehour,1,'-'),best.);
          hourloopUntil = input(scan(onehour,2,'-'),best.);
          do hour = hourloopFrom to hourloopUntil;
              output;
          end;/* do hour */
      end;
      else
      do;
          hour = input(onehour,best.);
          output;
      end;
      count + 1;
      onehour = scan(calendar_hours,count,',');
  end;/* do while */
run;
data work.t1(keep=flow_id flow_name calendar_name d hour minute timezone
                  flow_schedule_valid_from_dts
                  flow_schedule_valid_until_dts
                  flow_valid_from_dts
                  flow_valid_until_dts
                  alert_condition alert_action alert_action_details
                  );
  set work.t1;
  count = 1;
  oneminute = scan(calendar_minutes,count,',');
  do while(oneminute ne '');
      if (strip(oneminute) = '*') then
      do;
          do minute = 0 to 59;
              output;
          end;/* do hour */
      end;
      else if (index(oneminute,'-') > 0) then
      do;
          minuteloopFrom  = input(scan(oneminute,1,'-'),best.);
          minuteloopUntil = input(scan(oneminute,2,'-'),best.);
          do minute = minuteloopFrom to minuteloopUntil;
              output;
          end;/* do hour */
      end;
      else
      do;
          minute = input(oneminute,best.);
          output;
      end;
      count + 1;
      oneminute = scan(calendar_minutes,count,',');
  end;/* do while */
run;
proc sort data=work.t1 nodupkey;
  by _all_;
run;

data _null_;

  call execute('options nosource;');
  call execute('proc sql;');

  call execute('  create table work.t2 as');
  call execute('    select *');
  call execute('    ,      dhms(d,hour,minute,0) as dts format=datetime18.');
  call execute('    from   work.t1');
  call execute('  ;');

  call execute('  create table work.scheduled_flows as');
  call execute('    select flow_id');
  call execute('    ,      flow_name');
  call execute('    ,      calendar_name');
  call execute('    ,      d as d_original');
  call execute('    ,      hour as hour_original');
  call execute('    ,      minute as minute_original');
  call execute('    ,      timezone');
  call execute('    ,      dts');
  call execute('    ,      case');
  call execute('             when 0 then 0 /* dummy clause */');

  do while (not(last));
      set dimon.dimon_timezones end=last;
          call execute('             when upcase(timezone) = "' !! upcase(strip(timezone)) !! '" and ( ' !! strip(condition_sascode) !! ' ) then dts + ' !! put(timediff,best.));
  end;

  call execute('             else dts');
  call execute('           end as dts_local format=datetime18.');
  call execute('    ,      datepart(calculated dts_local) as d format=date9.');
  call execute('    ,      hour(timepart(calculated dts_local)) as hour');
  call execute('    ,      minute(timepart(calculated dts_local)) as minute');
  call execute('    ,      alert_condition');
  call execute('    ,      alert_action');
  call execute('    ,      alert_action_details');
  call execute('    from   work.t2');
  call execute('    where  calculated d >= "&run_date_from"d');
  call execute('    and    calculated d <= "&run_date_until"d');
  call execute('    and    flow_schedule_valid_from_dts <= dhms("&run_date"d,hour,minute,0)'); 
  call execute('    and    flow_schedule_valid_until_dts > dhms("&run_date"d,hour,minute,0)'); 
  call execute('    and    flow_valid_from_dts <= dhms("&run_date"d,hour,minute,0)'); 
  call execute('    and    flow_valid_until_dts > dhms("&run_date"d,hour,minute,0)'); 
  call execute('   ;');

  call execute('quit;');
  stop;

run;

proc datasets lib=work nolist nowarn mt=(data view);
  delete t1;
  delete t2;
quit;



GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;


/*   START OF NODE: add datetimes and filter   */
%LET _CLIENTTASKLABEL='add datetimes and filter';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.QUERY_FOR_SCHEDULED_FLOWS1);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_SCHEDULED_FLOWS1(label="scheduled_flows_dts") AS 
   SELECT t1.FLOW_ID, 
          t1.FLOW_NAME, 
          t1.calendar_name AS CALENDAR_NAME, 
          /* SCHEDULED_RUN_DTS */
            (dhms(t1.d,t1.hour,t1.minute,0)) FORMAT=datetime18. AS SCHEDULED_RUN_DTS, 
          /* SCHEDULED_RUN_DTS_RANGE_MIN */
            (calculated SCHEDULED_RUN_DTS) FORMAT=datetime18. AS SCHEDULED_RUN_DTS_RANGE_MIN, 
          /* SCHEDULED_RUN_DTS_RANGE_MAX */
            (calculated SCHEDULED_RUN_DTS + coalesce(input(symget('FLOW_SCHEDULED_DTS_MATCH_SECONDS'),best.),60)) 
            FORMAT=datetime18. AS SCHEDULED_RUN_DTS_RANGE_MAX, 
          t1.alert_condition LABEL="alert_condition", 
          t1.alert_action LABEL="alert_action", 
          t1.alert_action_details LABEL="alert_action_details"
      FROM WORK.SCHEDULED_FLOWS t1
      WHERE (CALCULATED SCHEDULED_RUN_DTS) > "&sysdate9. &systime."dt AND (CALCULATED SCHEDULED_RUN_DTS_RANGE_MAX) <= 
           datetime();
QUIT;

GOPTIONS NOACCESSIBLE;


%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: get flows not started   */
%LET _CLIENTTASKLABEL='get flows not started';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.FLOWS_NOT_STARTED);

PROC SQL;
   CREATE TABLE WORK.FLOWS_NOT_STARTED AS 
   SELECT t1.flow_id, 
          t1.flow_name, 
          t1.CALENDAR_NAME, 
          t1.SCHEDULED_RUN_DTS, 
          t1.SCHEDULED_RUN_DTS_RANGE_MIN, 
          t1.SCHEDULED_RUN_DTS_RANGE_MAX, 
          t1.alert_condition, 
          t1.alert_action, 
          t1.alert_action_details
      FROM WORK.QUERY_FOR_SCHEDULED_FLOWS1 t1
           LEFT JOIN WORK.FLOWS_NOW_WITH_FLOW_ID t2 ON (t1.flow_id = t2.flow_id) AND (t1.SCHEDULED_RUN_DTS_RANGE_MIN <= 
          t2.flow_start_dts) AND (t1.SCHEDULED_RUN_DTS_RANGE_MAX >= t2.flow_start_dts)
      WHERE t2.flow_run_id IS MISSING;
QUIT;

GOPTIONS NOACCESSIBLE;



%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: filter email alerts   */
%LET _CLIENTTASKLABEL='filter email alerts';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.ALERTS_FLOWS_NOT_STARTED_EMAIL);

PROC SQL;
   CREATE TABLE WORK.ALERTS_FLOWS_NOT_STARTED_EMAIL AS 
   SELECT /* flow_run_id1 */
            (.) AS flow_run_id1, 
          t1.flow_id AS flow_id1, 
          t1.flow_name AS flow_name1, 
          t1.alert_condition, 
          t1.alert_action LABEL='' AS alert_action, 
          t1.alert_action_details LABEL='' AS alert_email_address, 
          t1.SCHEDULED_RUN_DTS, 
          /* alert_email_message */
            (strip(t1.flow_name)!!' missed scheduled time of '!!put(t1.SCHEDULED_RUN_DTS,datetime.)) AS 
            alert_email_message, 
          t2.flow_id1 AS flow_id11, 
          /* alert_email_message_details */
            ('') AS alert_email_message_details, 
          /* already_notified */
            (not(missing(t2.flow_id1))) AS already_notified
      FROM WORK.FLOWS_NOT_STARTED t1
           LEFT JOIN WORK.NOTIFIED t2 ON (t1.flow_id = t2.flow_id1) AND (t1.alert_condition = t2.alert_condition) AND 
          (t1.SCHEDULED_RUN_DTS = t2.scheduled_run_dts)
      WHERE (CALCULATED already_notified) NOT = 1;
QUIT;

GOPTIONS NOACCESSIBLE;



%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: Append Table   */
%LET _CLIENTTASKLABEL='Append Table';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';

GOPTIONS ACCESSIBLE;
%_eg_conditional_dropds(WORK.ALERTS_EMAIL);
PROC SQL;
CREATE TABLE WORK.ALERTS_EMAIL AS 
SELECT * FROM WORK.ALERTS_EWEC_EVAL_EMAIL
 OUTER UNION CORR 
SELECT * FROM WORK.ALERTS_CS_EMAIL
 OUTER UNION CORR 
SELECT * FROM WORK.ALERTS_STARTS_EMAIL
 OUTER UNION CORR 
SELECT * FROM WORK.ALERTS_RUNTIME_EMAIL
 OUTER UNION CORR 
SELECT * FROM WORK.ALERTS_RUNS_LESS_THAN_EMAIL
 OUTER UNION CORR 
SELECT * FROM WORK.ALERTS_FLOWS_NOT_STARTED_EMAIL
;
Quit;


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;


/*   START OF NODE: email alerts   */
%LET SYSLAST=WORK.ALERTS_EMAIL;
%LET _CLIENTTASKLABEL='email alerts';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
%macro x;

  %let nobs = 0;
  proc sql noprint;
    select count(*) into :nobs
    from WORK.ALERTS_EMAIL
    ;
  quit;

  %if (&nobs > 0) %then
  %do;

       filename mail email content_type="text/html" attach=("/tmp/eomalerts.png" inlined='eomalertslogo');
       data _null_;
         set WORK.ALERTS_EMAIL end=last;
         putlog 'DIMONNOTE: ' alert_email_message;
         file mail;
         put '!EM_TO!' alert_email_address;
         put '!EM_FROM!bheinsius@eom.nl';
         put '!EM_SUBJECT!' 'EOM Alert - ' flow_name1;
         put '<html>'
               '<head>'
                 '<meta content="text/html; charset=ISO-8859-1" http-equiv="content-type">'
                 '<title>EOM Alert</title>'
               '</head>'
               '<body>'
                 '<table style="border-collapse:collapse;border-left:1px solid #e4e4e4;border-right:1px solid #e4e4e4;border-bottom:1px solid #e4e4e4" width="100%">'
                   '<tbody>'
                     '<tr>'
                       '<td style="background-color:#f8f8f8;padding-left:1px;border-bottom:1px solid #e4e4e4;border-top:1px solid #e4e4e4"></td>'
                       '<td valign="middle" style="padding:13px 10px 8px 0px;background-color:#f8f8f8;border-top:1px solid #e4e4e4;border-bottom:1px solid #e4e4e4">'
                         '<a href="" style="text-decoration:none" target="_blank" alt="EOM" border="0" height="25">'
                         '<img src=cid:eomalertslogo></a></td>'
                       '<td style="background-color:#f8f8f8;padding-left:18px;border-top:1px solid #e4e4e4;border-bottom:1px solid #e4e4e4"></td>'
                     '</tr>'
                     '<tr>'
                       '<td style="padding-left:1px"></td>'
                       '<td style="padding:18px 0px 18px 0px;vertical-align:middle;line-height:18px;font-family:Arial">'
                         '<span style="color:#262626;font-size:18px">' alert_email_message '</span></td>'
                       '<td style="padding-left:32px"></td>'
                     '</tr>'
                   '</tbody>'
                 '</table>'
                 '<table style="padding-top:6px;font-size:12px;color:#252525;text-align:left;width:100%">'
                   '<tbody>'
                     '<tr>'
                       '<td style="font-family:Arial"> You receive this email because you have signed up for <b><span>EOM Alerts</span></b>.</td>'
                     '</tr>'
                    '</tbody>'
                  '</table>'
               '</body>'
             '</html>'
             ;
         put '!EM_SEND!' / '!EM_NEWMSG!';
         if (last) then put '!EM_ABORT!';
       run;

  %end;
  %else
      %put NOTE: No alerts to process.;

%mend;
%x


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;


/*   START OF NODE: save email notifications   */
%LET _CLIENTTASKLABEL='save email notifications';
%LET _CLIENTPROCESSFLOWNAME='alertmon';
%LET _CLIENTPROJECTPATH='C:\Users\bheinsius\Documents\GitHub\eom-sas-dimon\Webapp\EG\DIMonRT3.egp';
%LET _CLIENTPROJECTPATHHOST='BHEINSIUS-PC';
%LET _CLIENTPROJECTNAME='DIMonRT3.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
proc sql;
  insert into work.notified
    select flow_run_id1
    ,      flow_id1
    ,      flow_name1
    ,      alert_condition
    ,      alert_action
    ,      alert_email_address
    ,      scheduled_run_dts
    ,      alert_email_message
    ,      alert_email_message_details
    from   work.alerts_email
  ;
quit;


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;









/* sleep until the next full minute */
%let loopenddts = %sysfunc(datetime());
%let wakeuptime = %sysfunc(intnx(seconds10.,%sysfunc(datetime()),1),datetime18.);
%put DIMONNOTE: %sysfunc(datetime(),B8601DT15.) This alertmon run took %sysevalf(&loopenddts - &loopstartdts) seconds. Sleeping until &wakeuptime;
data _null_;
  sleeptime = "&wakeuptime"dt - datetime();
  slept = sleep(sleeptime,1);
run;

%end;/* do forever loop */

%mend alertmon;

%let _debug=0;
%alertmon
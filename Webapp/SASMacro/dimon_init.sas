/* ========================================================================= */
/* Program : dimon_init.sas                                                  */
/* Purpose : initialization for DI Monitor Stored Processes                  */
/*                                                                           */
/* Do NOT modify this file.  Any additions or changes should be made in      */
/* dimon_usermods.sas.                                                       */
/*                                                                           */
/* Change History                                                            */
/* Date    By     Changes                                                    */
/* 01jun10 eombah initial version                                            */
/* 30aug12 eombah added macvars jsroot and cssroot                           */
/* 19nov16 eombah updated for v3                                             */
/* ========================================================================= */
%macro dimon_init;

  /* save options */
  %let optNotes = %sysfunc(getoption(NOTES));
  %let optSource = %sysfunc(getoption(SOURCE));
  %let optSource2 = %sysfunc(getoption(SOURCE2));
  %let optMprint = %sysfunc(getoption(MPRINT));
  options nonotes nosource nosource2 nomprint;

  %let dts1 = %sysfunc(datetime());

  /* _debug parameter is passed on the url as &_debug= */
  %global _debug;
  %if (&_debug gt 0) %then
  %do;
       options notes source source2 mprint;
       %put NOTE: setting debug options because %nrstr(&)_DEBUG = &_DEBUG.;
       options msglevel=i;
       options sastrace=',,,d' sastraceloc=saslog nostsuffix;
  %end;

  %put NOTE: ====================================================================;
  %put NOTE: dimon_init macro started execution.;

  %macro _webout;
    %if (%sysfunc(fileref(_webout)) = 0) %then
        _webout;
    %else
        print;
  %mend _webout;

  %macro create_table_or_view;
    CREATE %if (&engine = SAS) %then TABLE; %else VIEW;
  %mend create_table_or_view;

  %global urlspa sproot webroot _odsstyle viewlog_maxfilesize gantt_width trend_days autorefresh_interval_min
          sparkline_max_flows
          flow_completion_mode flow_completion_mode_2_idle_time lsf_flow_finished_dir
          lsf_flow_active_dir flow_scheduled_dts_match_seconds
          scheduled_flows_lookahead_time
          ;

  /* ------------------------------------------------------------------------- */
  /* Default settings, to be overriden by %dimon_usermods                      */
  /* Do NOT modify this file.  Any additions or changes should be made in      */
  /* dimon_usermods.sas.                                                       */
  /* ------------------------------------------------------------------------- */

  /* URL to the SAS Stored Process Web Application */
  %let urlspa               = /SASStoredProcess/do;

  /* Metadata folder where the dimon stored processes are located */
  %let sproot               = /My Company/Application Support/EOM DI Job Monitor/Stored Processes;

  /* Relative URL path where the js, css, and images components are located */
  %let webroot              = /eom/dimon;

  /* ODS style */
  %let _odsstyle            = dimon;

  /* For SAS log files beyond this filesize, you are prompted to download. This is an IE setting, for Chrome and Firefox this value is doubled */
  %let viewlog_maxfilesize  = 2097152; /* in bytes */

  /* Width of the gantt charts in pixels */
  %let gantt_width          = 150;

  /* Default numer of days to show elapsed time trend for */
  %let trend_days           = 90;

  /* Minimum value for autorefresh_interval */
  %let autorefresh_interval_min = 10;

  /* Max number of flows to show sparklines for */
  %let sparkline_max_flows = 20;

  /* Flow completion mode - When is a flow marked as completed? */
  /* 1 : when #jobs_completed = #jobs_in_flow (default) */
  /* 2 : when #jobs_completed < #jobs_in_flow and nothing has been running for &flow_completion_mode_2_idle_time. seconds */
  /* 3 : when file <flow-id> exists in the &lsf_flow_finished_dir. Subflows use mode 1 */
  /* 4 : when file <flow-id> exists in the &lsf_flow_finished_dir. Subflows use mode 2 */
  /* 5 : when file <flow-id> does not exist in the &lsf_flow_active_dir. Subflows use mode 1 */
  /* 6 : when file <flow-id> does not exist in the &lsf_flow_active_dir. Subflows use mode 2 */
  %let flow_completion_mode             = 1;
  %let flow_completion_mode_2_idle_time = 60; /* idle seconds before marking flow COMPLETED in mode 2     */
  %let lsf_flow_finished_dir            = ;   /* for modes 3 and 4 */
  %let lsf_flow_active_dir              = ;   /* for modes 5 and 6 */

  /* The maximum time between scheduled start and actual start of a flow to be matched */
  %let flow_scheduled_dts_match_seconds = 60;

  /* Whether to apply metadata security to webapp results. yes or no */
  %let apply_metadata_security = no;

  %let scheduled_flows_lookahead_time   = 86400; /* seconds to look ahead for scheduled flows */

  /* Include dimon_usermods */
  %dimon_usermods

  /* Get dimon engine. When it is  something other than SAS, dimon creates SQL */
  /* views instead of tables, where applicable, to let SQL  pass through.      */
  %global engine;
  proc sql noprint;
    select case
             when engine in ('BASE','V9','REMOTE') then 'SAS'
             else engine
           end into :engine
    from   sashelp.vlibnam
    where  libname = 'DIMON'
    ;
  quit;

  options notes;
  %put NOTE: ENGINE                           = &engine.;
  %put NOTE: URLSPA                           = &urlspa.;
  %put NOTE: SPROOT                           = &sproot.;
  %put NOTE: WEBROOT                          = &webroot.;
  %put NOTE: _ODSSTYLE                        = &_odsstyle.;
  %put NOTE: VIEWLOG_MAXFILESIZE              = &viewlog_maxfilesize.;
  %put NOTE: GANTT_WIDTH                      = &gantt_width.;
  %put NOTE: TREND_DAYS                       = &trend_days.;
  %put NOTE: AUTOREFRESH_INTERVAL_MIN         = &autorefresh_interval_min;
  %put NOTE: SPARKLINE_MAX_FLOWS              = &sparkline_max_flows;
  %put NOTE: FLOW_COMPLETION_MODE             = &flow_completion_mode.;
  %put NOTE: FLOW_COMPLETION_MODE_2_IDLE_TIME = &flow_completion_mode_2_idle_time.;
  %put NOTE: LSF_FLOW_FINISHED_DIR            = &lsf_flow_finished_dir.;
  %put NOTE: LSF_FLOW_ACTIVE_DIR              = &lsf_flow_active_dir.;
  %put NOTE: FLOW_SCHEDULED_DTS_MATCH_SECONDS = &flow_scheduled_dts_match_seconds.;
  %put NOTE: SCHEDULED_FLOWS_LOOKAHEAD_TIME   = &scheduled_flows_lookahead_time.;
  options nonotes;


  ods path WORK.TAGSETS(UPDATE) SASHELP.TMPLMST(READ);
  proc template;
    define style styles.dimon;
      parent = styles.sasweb;
        notes "DI Monitor Style";
        class body /
          fontfamily = 'Roboto,Open Sans,Verdana,Arial'
          fontsize   = 9pt
          color      = #808080
        ;
        class systemtitle /
          fontfamily = 'Roboto,Open Sans,Verdana,Arial'
          fontsize   = 9pt
          fontstyle  = roman
          color      = #0288d1
        ;
        class systemfooter /
          fontfamily = 'Roboto,Open Sans,Verdana,Arial'
          fontsize   = 9pt
          fontstyle  = roman
          color      = #0288d1
        ;
        class table /
          fontfamily  = 'Roboto,Open Sans,Verdana,Arial'
          fontsize    = 9pt
          cellspacing = 1
          cellpadding = 10
          background  = #f0f0f0
        ;
        style table from output /
          frame = void
          rules = none
        ;
        style Header from HeadersAndFooters /
          /*background = #0066cc*/
          background = #0288d1
          fontfamily = 'Roboto,Open Sans,Verdana,Arial'
          fontsize   = 9pt
        ;
        style Footer from HeadersAndFooters /
          background = #0288d1
          fontfamily = 'Roboto,Open Sans,Verdana,Arial'
          fontsize   = 9pt
        ;
        class data /
          fontfamily = 'Roboto,Open Sans,Verdana,Arial'
          fontsize   = 9pt
          color      = #404040
        ;
        class notecontent /
          fontfamily = 'Roboto,Open Sans,Verdana,Arial'
          fontsize   = 8pt
          color      = #0288d1
        ;
    end;
  run;


  

  %if ("&apply_metadata_security" = "yes") %then
  %do; /* apply metadata security to dimon.dimon_flows */
  
       data work.dimon_flows(keep=flow_id flow_name flow_desc valid_from_dts valid_until_dts current_ind update_user update_dts)
           /view=work.dimon_flows;
         length uri1 $ 256 flow_id $20;
         /* Get rid of compile time messages */
         uri1=uri1; flow_id=flow_id;
         if (_n_ = 1) then
         do; /* store flows in hash */
             declare hash h();
             h.defineKey('flow_id');
             h.defineData('flow_id');
             h.defineDone();
             num1=metadata_getnobj("omsobj:JFJob?@TransformRole='SCHEDULER_FLOW'",1,uri1);
             do i=1 to num1;
                 num1 = metadata_getnobj("omsobj:JFJob?@TransformRole='SCHEDULER_FLOW'",i,uri1);
                 rc = metadata_getattr(uri1,'Id',flow_id);
                 if (h.find() ne 0) then h.add();
             end;/* do i */
         end;/* store flows in hash */
         last = 0;
         do while(not(last));
             set dimon.dimon_flows end=last;
             if (h.find() = 0) then output;
         end;/* do while */
         stop;
       run;
  
  %end;/* apply metadata security to dimon.dimon_flows */
  %else
  %do; /* don't apply metadata security to dimon.dimon_flows */
  
       proc sql;
	       create view work.dimon_flows as
		     select *
		     from   dimon.dimon_flows
		   ;
	   quit;
	   
  %end;/* don't apply metadata security to dimon.dimon_flows */
  
  %let dts2 = %sysfunc(datetime());
  %let elapsed = %sysfunc(putn(%sysevalf(&dts2. - &dts1.),8.2));
  %put NOTE: dimon_init macro completed execution in &elapsed. seconds.;
  %put NOTE: ====================================================================;

  options &optNotes &optSource &optSource2 &optMprint;

%mend dimon_init;

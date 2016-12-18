/* ========================================================================= */
/* Program : dimon_init.sas                                                  */
/* Purpose : initialization for DI Monitor Stored Processes                  */
/*                                                                           */
/* Change History                                                            */
/* Date    By     Changes                                                    */
/* 01jun10 eombah initial version                                            */
/* 30aug12 eombah added macvars jsroot and cssroot                           */
/* 19nov16 eombah updated for v3                                             */
/* ========================================================================= */
%macro dimon_init;

  options nonotes nosource nosource2 nomprint;

  %let dts1 = %sysfunc(datetime());

  %global _debug;
  %if (&_debug. ne 0) %then
  %do;
       options notes source source2 mprint;
       %put NOTE: setting debug options because %nrstr(&)_DEBUG = &_DEBUG.;
	   options msglevel=i;
       options sastrace=',,,d' sastraceloc=saslog nostsuffix;
  %end;

  %put NOTE: ====================================================================;
  %put NOTE: dimon_init macro started execution.;

  %if (%sysfunc(libref(dimon)) ne 0) %then
  %do; /* assign dimon library */
       %put NOTE: Assigning library DIMON;
       libname dimon (dimonsql);
  %end;/* assign dimon library */
  libname dimon list;

  %macro _webout;
    %if (%sysfunc(fileref(_webout)) = 0) %then
        _webout;
    %else
        print;
  %mend _webout;

  %macro create_table_or_view;
    CREATE %if (&engine = SAS) %then TABLE; %else VIEW;
  %mend create_table_or_view;

  /* Get Dimon engine. When it is  something other than SAS, dimon creates SQL */
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

  %global urlspa sproot webroot _odsstyle viewlog_maxfilesize gantt_width trend_days
          flow_completion_mode flow_completion_mode_2_idle_time lsf_flow_finished_dir
          ;
  %let urlspa               = /SASStoredProcess/do;
  %let sproot               = /My Company/Application Support/EOM DI Job Monitor/Stored Processes;
  %let webroot              = /eom/dimon;
  %let _odsstyle            = dimon;
  %let viewlog_maxfilesize  = 2097152; /* logs beyond this filesize (2MiB) are opened in external viewer */
                                       /* this is an IE setting, for chrome and ff this value is doubled */
  %let gantt_width          = 150;     /* width in pixels of Gantt column                                */
  %let trend_days           = 90;      /* default numer of days to show elapsed time trend for           */

  %let flow_completion_mode = 1;       /* 1 = #jobs_completed < #jobs_in_flow then flow is RUNNING        */
                                       /* 2 = #jobs_completed < #jobs_in_flow then flow is COMPLETED      */
                                       /* 3 = base flows on lsf_flow_finished_dir, subflows use 1         */
                                       /* 4 = base flows on lsf_flow_finished_dir, subflows use 2         */
  %let flow_completion_mode_2_idle_time = 60; /* idle seconds before marking flow COMPLETED in mode 2     */
  %let lsf_flow_finished_dir =                                                                  /* mode 3 */

  %put NOTE: ENGINE                           = &engine.;
  %put NOTE: URLSPA                           = &urlspa.;
  %put NOTE: SPROOT                           = &sproot.;
  %put NOTE: WEBROOT                          = &webroot.;
  %put NOTE: _ODSSTYLE                        = &_odsstyle.;
  %put NOTE: VIEWLOG_MAXFILESIZE              = &viewlog_maxfilesize.;
  %put NOTE: GANTT_WIDTH                      = &gantt_width.;
  %put NOTE: TREND_DAYS                       = &trend_days.;
  %put NOTE: FLOW_COMPLETION_MODE             = &flow_completion_mode.;
  %put NOTE: FLOW_COMPLETION_MODE_2_IDLE_TIME = &flow_completion_mode_2_idle_time.;
  %put NOTE: LSF_FLOW_FINISHED_DIR            = &lsf_flow_finished_dir.;

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

  %let dts2 = %sysfunc(datetime());
  %let elapsed = %sysfunc(putn(%sysevalf(&dts2. - &dts1.),8.2));
  %put NOTE: dimon_init macro completed execution in &elapsed. seconds.;
  %put NOTE: ====================================================================;

%mend dimon_init;

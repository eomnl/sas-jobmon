%macro dimon_usermods;

  libname dimon (dimonpos);

  %let urlspa               = /SASStoredProcess/do;
  %let sproot               = /Wikker/Application Support/EOM DI Monitor/Stored Processes;
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
  %let lsf_flow_finished_dir            = ;                                                     /* mode 3 */
  %let flow_scheduled_dts_match_seconds = 60;
%mend dimon_usermods;


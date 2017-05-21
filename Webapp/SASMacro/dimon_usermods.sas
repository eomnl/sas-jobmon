%macro dimon_usermods;

  /* If you use a library other than the default DIMON, allocate it here */
  /* %libname dimon (dimonpos); */

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

  /* Flow completion mode - When is a flow marked as completed? */
  /* 1 : when #jobs_completed = #jobs_in_flow (default) */
  /* 2 : when #jobs_completed < #jobs_in_flow and nothing has been running for &flow_completion_mode_2_idle_time. seconds */
  /* 3 : when file <flow-id> exists in the &lsf_flow_finished_dir. Subflows use mode 1 */
  /* 4 : when file <flow-id> exists in the &lsf_flow_finished_dir. Subflows use mode 2 */
  %let flow_completion_mode             =  1;
  %let flow_completion_mode_2_idle_time = 60; /* idle seconds before marking flow COMPLETED in mode 2    */
  %let lsf_flow_finished_dir            =   ; /* for modes 3 and 4 */

  /* The maximum time between scheduled start and actual start of a flow to be matched */
  %let flow_scheduled_dts_match_seconds = 60;

%mend dimon_usermods;

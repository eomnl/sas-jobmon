%macro dimon_usermods;

  /* =================================================================================== */
  /*   This config file extends options set in dimon_inti.sas.  Place your site-specific */
  /*   options in this file.                                                             */
  /*                                                                                     */
  /*   Do NOT modify the sasv9.cfg file.                                                 */
  /* =================================================================================== */

  /* If you use a library other than the default DIMON, allocate it here */
  /* libname dimon (dimonpos); */

  %put NOTE: Including dimon_usermods.sas;
  %let flow_completion_mode     = 5;
  %let lsf_flow_active_dir      = /apps/sas/thirdparty/pm/work/storage/flow_instance_storage/active;
  %let lsf_flow_finished_dir    = /apps/sas/thirdparty/pm/work/storage/flow_instance_storage/finished;
  %let alert_email_from_address = bheinsius@eom.nl;

%mend dimon_usermods;

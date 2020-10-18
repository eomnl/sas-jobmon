%macro dimon_usermods;

  /* =================================================================================== */
  /*   This config file extends options set in dimon_init.sas.  Place your site-specific */
  /*   options in this file.                                                             */
  /*                                                                                     */
  /*   Do NOT modify the dimon_init.sas file.                                            */
  /* =================================================================================== */

  /* If you use a library other than the default DIMON, allocate it here */
  /* libname dimon (dimonpos); */

  %put NOTE: Including dimon_usermods.sas;
  %let flow_completion_mode     = 5;
  %let lsf_flow_active_dir      = /apps/sas/thirdparty/pm/work/storage/flow_instance_storage/active;
  %let lsf_flow_finished_dir    = /apps/sas/thirdparty/pm/work/storage/flow_instance_storage/finished;
  %let apply_metadata_security  = yes;

%mend dimon_usermods;

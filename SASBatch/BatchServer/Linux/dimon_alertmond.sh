/apps/sas/SASConfig/Lev1/SASApp/BatchServer/sasbatch-nodimon.sh \
  -sysin /apps/sas/SASConfig/Lev1/SASApp/SASEnvironment/SASCode/dimon/dimon_alertmond.sas \
  -log /apps/sas/SASConfig/Lev1/SASApp/BatchServer/Logs/dimon_alertmond.log \
  -set lsf_flow_active_dir '/apps/sas/thirdparty/pm/work/storage/flow_instance_storage/active' \
  -set lsf_flow_finished_dir '/apps/sas/thirdparty/pm/work/storage/flow_instance_storage/finishe'
CREATE TABLE dbo.dimon_calendars
(
  calendar_name varchar(100) NOT NULL,
  calendar_sascode varchar(1024),
  update_user varchar(32),
  update_dts datetime,
  CONSTRAINT pk_dimon_calendar PRIMARY KEY (calendar_name)
);

CREATE TABLE dbo.dimon_flow_job
(
  flow_job_id varchar(255) NOT NULL,
  flow_job_name varchar(1024),
  flow_id varchar(20),
  job_id varchar(20),
  job_seq_nr smallint,
  valid_from_dts datetime NOT NULL,
  valid_until_dts datetime,
  current_ind varchar(1),
  update_user varchar(32),
  update_dts datetime,
  CONSTRAINT pk_dimon_flow_job PRIMARY KEY (flow_job_id, valid_from_dts)
);

  CREATE TABLE dbo.dimon_flow_schedules
(
  flow_id varchar(20) NOT NULL,
  triggering_event_transfer_role varchar(10),
  triggering_event_role varchar(20),
  triggering_event_condition varchar(100),
  timezone varchar(32),
  valid_from_dts datetime NOT NULL,
  valid_until_dts datetime,
  current_ind varchar(1),
  update_user varchar(32),
  update_dts datetime,
  CONSTRAINT pk_dimon_flow_schedules PRIMARY KEY (flow_id, triggering_event_condition, valid_from_dts)
);

CREATE TABLE dbo.dimon_flows
(
  flow_id varchar(20) NOT NULL,
  flow_name varchar(100),
  flow_desc varchar(200),
  valid_from_dts datetime NOT NULL,
  valid_until_dts datetime,
  current_ind varchar(1),
  update_user varchar(32),
  update_dts datetime,
  CONSTRAINT pk_dimon_flows PRIMARY KEY (flow_id, valid_from_dts)
);

CREATE TABLE dbo.dimon_hide_flows
(
  flow_id varchar(20) NOT NULL,
  hide_ind varchar(1),
  valid_from_dts datetime NOT NULL,
  valid_until_dts datetime,
  current_ind varchar(1),
  update_user varchar(32),
  update_dts datetime,
  CONSTRAINT pk_dimon_hide_flows PRIMARY KEY (flow_id, valid_from_dts)
);

CREATE TABLE dbo.dimon_job_runs
(
  job_run_id int NOT NULL,
  flow_run_id int,
  flow_run_seq_nr smallint,
  flow_job_id varchar(255),
  job_start_dts datetime,
  job_end_dts datetime,
  job_log_file varchar(1024),
  job_lst_file varchar(1024),
  job_status_id smallint,
  job_rc smallint,
  update_user varchar(32),
  update_dts datetime,
  CONSTRAINT pk_dimon_job_runs PRIMARY KEY (job_run_id)
);
CREATE NONCLUSTERED INDEX idx_dimon_job_runs_1 ON dbo.dimon_job_runs
(
	flow_run_id ASC
)

CREATE TABLE dbo.dimon_job_status
(
  job_status_id smallint NOT NULL,
  job_status_code varchar(12),
  job_status_desc varchar(32),
  job_status_sequence_nr smallint,
  CONSTRAINT pk_dimon_job_status PRIMARY KEY (job_status_id)
);

CREATE TABLE dbo.dimon_jobs
(
  job_id varchar(20) NOT NULL,
  job_name varchar(100),
  valid_from_dts datetime NOT NULL,
  valid_until_dts datetime,
  current_ind varchar(1),
  update_user varchar(32),
  update_dts datetime,
  CONSTRAINT pk_dimon_jobs PRIMARY KEY (job_id, valid_from_dts)
);

CREATE TABLE dbo.dimon_run_stats
(
  flow_job_id varchar(255),
  stats_dts_from datetime,
  stats_dts_until datetime,
  stats_date date,
  elapsed_time real,
  elapsed_time_q1 real,
  elapsed_time_median real,
  elapsed_time_q3 real,
  elapsed_time_iqr real,
  elapsed_time_outlier_ind real,
  elapsed_time_outlier real,
  elapsed_time_non_outlier real,
  elapsed_time_movavg real,
  elapsed_time_movstd real,
  elapsed_time_lcl95 real,
  elapsed_time_ucl95 real,
  interpolated_ind varchar(1),
  update_user varchar(32),
  update_dts datetime,
  CONSTRAINT pk_dimon_run_stats PRIMARY KEY (flow_job_id, stats_dts_from)
  );

CREATE TABLE dbo.dimon_timezones
(
  timezone varchar(32) NOT NULL,
  condition_sascode varchar(1024),
  condition_desc varchar(100),
  timediff smallint,
  update_user varchar(32),
  update_dts datetime,
  CONSTRAINT pk_dimon_timezones PRIMARY KEY (timezone, timediff)
);

INSERT INTO dimon_calendars (calendar_name,calendar_sascode,update_user,update_dts) VALUES
  ('Daily@Sys','1', current_user, current_timestamp),
  ('First_day_of_year@Sys', 'd = intnx(''year'',d,0,''beginning'')', current_user, current_timestamp),
  ('Last_day_of_year@Sys', 'd = intnx(''year'',d,0,''end'')', current_user, current_timestamp),
  ('First_day_of_month@Sys', 'd = intnx(''month'',d,0,''beginning'')', current_user, current_timestamp),
  ('Last_day_of_month@Sys', 'd = intnx(''month'',d,0,''end'')', current_user, current_timestamp),
  ('Weekdays@Sys', 'weekday(d) in (2,3,4,5,6)', current_user, current_timestamp),
  ('Weekends@Sys', 'weekday(d) in (1,7)', current_user, current_timestamp), 
  ('Sundays@Sys', 'weekday(d) = 1', current_user, current_timestamp),
  ('Mondays@Sys', 'weekday(d) = 2', current_user, current_timestamp),
  ('Tuesdays@Sys', 'weekday(d) = 3', current_user, current_timestamp),
  ('Wednesdays@Sys', 'weekday(d) = 4', current_user, current_timestamp),
  ('Thursdays@Sys', 'weekday(d) = 5', current_user, current_timestamp),
  ('Fridays@Sys', 'weekday(d) = 6', current_user, current_timestamp),
  ('Saturdays@Sys', 'weekday(d) = 7', current_user, current_timestamp),
  ('First_weekday_of_month@Sys', 'd = (intnx(''month'',d,0,''beginning'') + 2*(weekday(intnx(''month'',d,0,''beginning'')) = 7) + (weekday(intnx(''month'',d,0,''beginning'')) = 1) )', current_user, current_timestamp),
  ('Last_weekday_of_month@Sys', 'd = (intnx(''month'',d,0,''end'') - 2*(weekday(intnx(''month'',d,0,''end'')) = 1) - 1*(weekday(intnx(''month'',d,0,''end'')) = 7) )', current_user, current_timestamp),
  ('First_sunday_of_month@Sys', 'weekday(d) = 1 and day(d) <= 7', current_user, current_timestamp), 
  ('First_monday_of_month@Sys', 'weekday(d) = 2 and day(d) <= 7', current_user, current_timestamp),
  ('First_tuesday_of_month@Sys', 'weekday(d) = 3 and day(d) <= 7', current_user, current_timestamp),
  ('First_wednesday_of_month@Sys', 'weekday(d) = 4 and day(d) <= 7', current_user, current_timestamp),
  ('First_thursday_of_month@Sys', 'weekday(d) = 5 and day(d) <= 7', current_user, current_timestamp),
  ('First_friday_of_month@Sys', 'weekday(d) = 6 and day(d) <= 7', current_user, current_timestamp),
  ('First_saturday_of_month@Sys', 'weekday(d) = 7 and day(d) <= 7', current_user, current_timestamp),
  ('Last_sunday_of_month@Sys', 'weekday(d) = 1 and d >= (intnx(''month'',d,0,''end'') - 6)', current_user, current_timestamp),
  ('Last_monday_of_month@Sys', 'weekday(d) = 2 and d >= (intnx(''month'',d,0,''end'') - 6)', current_user, current_timestamp),
  ('Last_tuesday_of_month@Sys', 'weekday(d) = 3 and d >= (intnx(''month'',d,0,''end'') - 6)', current_user, current_timestamp),
  ('Last_wednesday_of_month@Sys', 'weekday(d) = 4 and d >= (intnx(''month'',d,0,''end'') - 6)', current_user, current_timestamp),
  ('Last_thursday_of_month@Sys', 'weekday(d) = 5 and d >= (intnx(''month'',d,0,''end'') - 6)', current_user, current_timestamp),
  ('Last_friday_of_month@Sys', 'weekday(d) = 6 and d >= (intnx(''month'',d,0,''end'') - 6)', current_user, current_timestamp),
  ('Last_saturday_of_month@Sys', 'weekday(d) = 7 and d >= (intnx(''month'',d,0,''end'') - 6)', current_user, current_timestamp),
  ('Businessdays@Sys', 'weekday(d) >= 1 and weekday(d) <= 6', current_user, current_timestamp)
  ;
  
INSERT INTO dimon_job_status (job_status_id,job_status_code,job_status_desc,job_status_sequence_nr) VALUES
  (0,'NOT STARTED','Not Started',1),
  (1,'RUNNING','Running',2),
  (2,'COMPLETED','Completed',3)
  ;

INSERT INTO dimon_timezones (timezone,condition_sascode,condition_desc,timediff,update_user,update_dts) VALUES 
 ('UTC','dts > dhms(intnx(''week.1'',intnx(''month'',mdy(3,1,year(datepart(dts))),0,''E''),0,''B''),2,0,0) and dts < dhms(intnx(''week.1'',intnx(''month'',mdy(10,1,year(datepart(dts))),0,''E''),0,''B''),2,0,0)','UTC Daylight Saving Time',7200,current_user,current_timestamp),
 ('UTC','dts <= dhms(intnx(''week.1'',intnx(''month'',mdy(3,1,year(datepart(dts))),0,''E''),0,''B''),2,0,0) or dts >= dhms(intnx(''week.1'',intnx(''month'',mdy(10,1,year(datepart(dts))),0,''E''),0,''B''),2,0,0)','UTC No Daylight Saving Time',3600,current_user,current_timestamp)
 ;

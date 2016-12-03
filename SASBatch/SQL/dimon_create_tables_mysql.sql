CREATE TABLE `DIMON_CALENDARS` (
  `CALENDAR_NAME` varchar(100) NOT NULL DEFAULT '',
  `CALENDAR_SASCODE` varchar(1024) DEFAULT NULL,
  `UPDATE_USER` varchar(32) DEFAULT NULL,
  `UPDATE_DTS` datetime DEFAULT NULL,
  PRIMARY KEY (`CALENDAR_NAME`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `DIMON_FLOW_JOB` (
  `FLOW_JOB_ID` varchar(255) NOT NULL DEFAULT '',
  `FLOW_JOB_NAME` varchar(1024) DEFAULT NULL,
  `FLOW_ID` varchar(20) DEFAULT NULL,
  `JOB_ID` varchar(20) DEFAULT NULL,
  `JOB_SEQ_NR` smallint(6) DEFAULT NULL,
  `VALID_FROM_DTS` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `VALID_UNTIL_DTS` datetime DEFAULT NULL,
  `CURRENT_IND` varchar(1) DEFAULT NULL,
  `UPDATE_USER` varchar(32) DEFAULT NULL,
  `UPDATE_DTS` datetime DEFAULT NULL,
  PRIMARY KEY (`FLOW_JOB_ID`,`VALID_FROM_DTS`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `DIMON_FLOW_SCHEDULES` (
  `FLOW_ID` varchar(20) NOT NULL DEFAULT '',
  `TRIGGERING_EVENT_TRANSFER_ROLE` varchar(10) DEFAULT NULL,
  `TRIGGERING_EVENT_ROLE` varchar(20) DEFAULT NULL,
  `TRIGGERING_EVENT_CONDITION` varchar(100) DEFAULT NULL,
  `TIMEZONE` varchar(32) DEFAULT NULL,
  `VALID_FROM_DTS` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `VALID_UNTIL_DTS` datetime DEFAULT NULL,
  `CURRENT_IND` varchar(1) DEFAULT NULL,
  `UPDATE_USER` varchar(32) DEFAULT NULL,
  `UPDATE_DTS` datetime DEFAULT NULL,
  PRIMARY KEY (`FLOW_ID`,`VALID_FROM_DTS`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `DIMON_FLOWS` (
  `FLOW_ID` varchar(20) NOT NULL DEFAULT '',
  `FLOW_NAME` varchar(100) DEFAULT NULL,
  `FLOW_DESC` varchar(200) DEFAULT NULL,
  `VALID_FROM_DTS` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `VALID_UNTIL_DTS` datetime DEFAULT NULL,
  `CURRENT_IND` varchar(1) DEFAULT NULL,
  `UPDATE_USER` varchar(32) DEFAULT NULL,
  `UPDATE_DTS` datetime DEFAULT NULL,
  PRIMARY KEY (`FLOW_ID`,`VALID_FROM_DTS`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `DIMON_HIDE_FLOWS` (
  `FLOW_ID` varchar(20) NOT NULL DEFAULT '',
  `HIDE_IND` varchar(1) DEFAULT NULL,
  `VALID_FROM_DTS` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `VALID_UNTIL_DTS` datetime DEFAULT NULL,
  `CURRENT_IND` varchar(1) DEFAULT NULL,
  `UPDATE_USER` varchar(32) DEFAULT NULL,
  `UPDATE_DTS` datetime DEFAULT NULL,
  PRIMARY KEY (`FLOW_ID`,`VALID_FROM_DTS`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `DIMON_JOB_RUNS` (
  `JOB_RUN_ID` float NOT NULL DEFAULT '0',
  `FLOW_RUN_ID` float DEFAULT NULL,
  `FLOW_RUN_SEQ_NR` float DEFAULT NULL,
  `FLOW_JOB_ID` varchar(255) DEFAULT NULL,
  `JOB_START_DTS` datetime DEFAULT NULL,
  `JOB_END_DTS` datetime DEFAULT NULL,
  `JOB_LOG_FILE` varchar(1024) DEFAULT NULL,
  `JOB_LST_FILE` varchar(1024) DEFAULT NULL,
  `JOB_STATUS_ID` smallint(6) DEFAULT NULL,
  `JOB_RC` smallint(6) DEFAULT NULL,
  `UPDATE_USER` varchar(32) DEFAULT NULL,
  `UPDATE_DTS` datetime DEFAULT NULL,
  PRIMARY KEY (`JOB_RUN_ID`),
  KEY `IDX_DIMON_JOB_RUNS_1` (`FLOW_RUN_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `DIMON_JOB_STATUS` (
  `JOB_STATUS_ID` smallint(6) NOT NULL DEFAULT '0',
  `JOB_STATUS_CODE` varchar(12) DEFAULT NULL,
  `JOB_STATUS_DESC` varchar(32) DEFAULT NULL,
  `JOB_STATUS_SEQUENCE_NR` float DEFAULT NULL,
  PRIMARY KEY (`JOB_STATUS_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `DIMON_JOBS` (
  `JOB_ID` varchar(20) NOT NULL DEFAULT '',
  `JOB_NAME` varchar(100) DEFAULT NULL,
  `VALID_FROM_DTS` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `VALID_UNTIL_DTS` datetime DEFAULT NULL,
  `CURRENT_IND` varchar(1) DEFAULT NULL,
  `UPDATE_USER` varchar(32) DEFAULT NULL,
  `UPDATE_DTS` datetime DEFAULT NULL,
  PRIMARY KEY (`JOB_ID`,`VALID_FROM_DTS`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `DIMON_RUN_STATS` (
  `FLOW_JOB_ID` varchar(255) NOT NULL DEFAULT '',
  `STATS_DTS_FROM` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `STATS_DTS_UNTIL` datetime DEFAULT NULL,
  `STATS_DATE` date DEFAULT NULL,
  `ELAPSED_TIME` float DEFAULT NULL,
  `ELAPSED_TIME_Q1` float DEFAULT NULL,
  `ELAPSED_TIME_MEDIAN` float DEFAULT NULL,
  `ELAPSED_TIME_Q3` float DEFAULT NULL,
  `ELAPSED_TIME_IQR` float DEFAULT NULL,
  `ELAPSED_TIME_OUTLIER_IND` float DEFAULT NULL,
  `ELAPSED_TIME_OUTLIER` float DEFAULT NULL,
  `ELAPSED_TIME_NON_OUTLIER` float DEFAULT NULL,
  `ELAPSED_TIME_MOVAVG` float DEFAULT NULL,
  `ELAPSED_TIME_MOVSTD` float DEFAULT NULL,
  `ELAPSED_TIME_LCL95` float DEFAULT NULL,
  `ELAPSED_TIME_UCL95` float DEFAULT NULL,
  `INTERPOLATED_IND` varchar(1) DEFAULT NULL,
  `UPDATE_USER` varchar(32) DEFAULT NULL,
  `UPDATE_DTS` datetime DEFAULT NULL,
  PRIMARY KEY (`FLOW_JOB_ID`,`STATS_DTS_FROM`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `DIMON_TIMEZONES` (
  `TIMEZONE` varchar(32) NOT NULL DEFAULT '',
  `CONDITION_SASCODE` varchar(1024) DEFAULT NULL,
  `CONDITION_DESC` varchar(100) DEFAULT NULL,
  `TIMEDIFF` smallint(6) DEFAULT NULL,
  `UPDATE_USER` varchar(32) DEFAULT NULL,
  `UPDATE_DTS` datetime DEFAULT NULL,
  PRIMARY KEY (`TIMEZONE`,`TIMEDIFF`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


INSERT INTO `DIMON_JOB_STATUS` (`JOB_STATUS_ID`,`JOB_STATUS_CODE`,`JOB_STATUS_DESC`,`JOB_STATUS_SEQUENCE_NR`) VALUES
  (0,'NOT STARTED','Not Started',1),
  (1,'RUNNING','Running',2),
  (2,'COMPLETED','Completed',3)
  ;

INSERT INTO `DIMON_CALENDARS` (`CALENDAR_NAME`,`CALENDAR_SASCODE`,`UPDATE_USER`,`UPDATE_DTS`) VALUES
  ('Daily@Sys','1', current_user(), current_timestamp()),
  ('First_day_of_year@Sys', 'd = intnx(''year'',d,0,''beginning'')', current_user(), current_timestamp()),
  ('Last_day_of_year@Sys', 'd = intnx(''year'',d,0,''end'')', current_user(), current_timestamp()),
  ('First_day_of_month@Sys', 'd = intnx(''month'',d,0,''beginning'')', current_user(), current_timestamp()),
  ('Last_day_of_month@Sys', 'd = intnx(''month'',d,0,''end'')', current_user(), current_timestamp()),
  ('Weekdays@Sys', 'weekday(d) in (2,3,4,5,6)', current_user(), current_timestamp()),
  ('Weekends@Sys', 'weekday(d) in (1,7)', current_user(), current_timestamp()), 
  ('Sundays@Sys', 'weekday(d) = 1', current_user(), current_timestamp()),
  ('Mondays@Sys', 'weekday(d) = 2', current_user(), current_timestamp()),
  ('Tuesdays@Sys', 'weekday(d) = 3', current_user(), current_timestamp()),
  ('Wednesdays@Sys', 'weekday(d) = 4', current_user(), current_timestamp()),
  ('Thursdays@Sys', 'weekday(d) = 5', current_user(), current_timestamp()),
  ('Fridays@Sys', 'weekday(d) = 6', current_user(), current_timestamp()),
  ('Saturdays@Sys', 'weekday(d) = 7', current_user(), current_timestamp()),
  ('First_weekday_of_month@Sys', 'd = (intnx(''month'',d,0,''beginning'') + 2*(weekday(intnx(''month'',d,0,''beginning'')) = 7) + (weekday(intnx(''month'',d,0,''beginning'')) = 1) )', current_user(), current_timestamp()),
  ('Last_weekday_of_month@Sys', 'd = (intnx(''month'',d,0,''end'') - 2*(weekday(intnx(''month'',d,0,''end'')) = 1) - 1*(weekday(intnx(''month'',d,0,''end'')) = 7) )', current_user(), current_timestamp()),
  ('First_sunday_of_month@Sys', 'weekday(d) = 1 and day(d) <= 7', current_user(), current_timestamp()), 
  ('First_monday_of_month@Sys', 'weekday(d) = 2 and day(d) <= 7', current_user(), current_timestamp()),
  ('First_tuesday_of_month@Sys', 'weekday(d) = 3 and day(d) <= 7', current_user(), current_timestamp()),
  ('First_wednesday_of_month@Sys', 'weekday(d) = 4 and day(d) <= 7', current_user(), current_timestamp()),
  ('First_thursday_of_month@Sys', 'weekday(d) = 5 and day(d) <= 7', current_user(), current_timestamp()),
  ('First_friday_of_month@Sys', 'weekday(d) = 6 and day(d) <= 7', current_user(), current_timestamp()),
  ('First_saturday_of_month@Sys', 'weekday(d) = 7 and day(d) <= 7', current_user(), current_timestamp()),
  ('Last_sunday_of_month@Sys', 'weekday(d) = 1 and d >= (intnx(''month'',d,0,''end'') - 6)', current_user(), current_timestamp()),
  ('Last_monday_of_month@Sys', 'weekday(d) = 2 and d >= (intnx(''month'',d,0,''end'') - 6)', current_user(), current_timestamp()),
  ('Last_tuesday_of_month@Sys', 'weekday(d) = 3 and d >= (intnx(''month'',d,0,''end'') - 6)', current_user(), current_timestamp()),
  ('Last_wednesday_of_month@Sys', 'weekday(d) = 4 and d >= (intnx(''month'',d,0,''end'') - 6)', current_user(), current_timestamp()),
  ('Last_thursday_of_month@Sys', 'weekday(d) = 5 and d >= (intnx(''month'',d,0,''end'') - 6)', current_user(), current_timestamp()),
  ('Last_friday_of_month@Sys', 'weekday(d) = 6 and d >= (intnx(''month'',d,0,''end'') - 6)', current_user(), current_timestamp()),
  ('Last_saturday_of_month@Sys', 'weekday(d) = 7 and d >= (intnx(''month'',d,0,''end'') - 6)', current_user(), current_timestamp()),
  ('Businessdays@Sys', 'weekday(d) >= 1 and weekday(d) <= 6', current_user(), current_timestamp())
  ;

INSERT INTO `DIMON_TIMEZONES` (`TIMEZONE`,`CONDITION_SASCODE`,`CONDITION_DESC`,`TIMEDIFF`,`UPDATE_USER`,`UPDATE_DTS`) VALUES 
 ('UTC','dts > dhms(intnx(''week.1'',intnx(''month'',mdy(3,1,year(datepart(dts))),0,''E''),0,''B''),2,0,0) and dts < dhms(intnx(''week.1'',intnx(''month'',mdy(10,1,year(datepart(dts))),0,''E''),0,''B''),2,0,0)','UTC Daylight Saving Time',7200,current_user(),current_timestamp()),
 ('UTC','dts <= dhms(intnx(''week.1'',intnx(''month'',mdy(3,1,year(datepart(dts))),0,''E''),0,''B''),2,0,0) or dts >= dhms(intnx(''week.1'',intnx(''month'',mdy(10,1,year(datepart(dts))),0,''E''),0,''B''),2,0,0)','UTC No Daylight Saving Time',3600,current_user(),current_timestamp())
 ;

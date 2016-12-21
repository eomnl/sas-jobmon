PROC SQL;
  CREATE TABLE DIMON.DIMON_FLOWS
    (  FLOW_ID CHAR(20)
    ,  FLOW_NAME CHAR(100)
    ,  FLOW_DESC CHAR(200)
    ,  VALID_FROM_DTS NUM FORMAT=DATETIME19.
    ,  VALID_UNTIL_DTS NUM FORMAT=DATETIME19.
    ,  CURRENT_IND CHAR(1)
    ,  UPDATE_USER CHAR(32)
    ,  UPDATE_DTS NUM FORMAT=DATETIME19.
    )
  ;
  CREATE UNIQUE INDEX PK_DIMON_FLOWS ON DIMON.DIMON_FLOWS(FLOW_ID,VALID_FROM_DTS);
QUIT;

PROC SQL;
  CREATE TABLE DIMON.DIMON_FLOW_JOB
    (  FLOW_JOB_ID CHAR(255)
    ,  FLOW_JOB_NAME CHAR(255)
    ,  FLOW_ID CHAR(20)
    ,  JOB_ID CHAR(20)
    ,  JOB_SEQ_NR NUM
    ,  VALID_FROM_DTS NUM FORMAT=DATETIME19.
    ,  VALID_UNTIL_DTS NUM FORMAT=DATETIME19.
    ,  CURRENT_IND CHAR(1)
    ,  UPDATE_USER CHAR(32)
    ,  UPDATE_DTS NUM FORMAT=DATETIME19.
    )
  ;
  CREATE UNIQUE INDEX PK_DION_FLOW_JOB ON DIMON.DIMON_FLOW_JOB(FLOW_JOB_ID,VALID_FROM_DTS);
QUIT;

PROC SQL;
  CREATE TABLE DIMON.DIMON_JOBS
    (  JOB_ID CHAR(20)
    ,  JOB_NAME CHAR(100)
    ,  VALID_FROM_DTS NUM FORMAT=DATETIME19.
    ,  VALID_UNTIL_DTS NUM FORMAT=DATETIME19.
    ,  CURRENT_IND CHAR(1)
    ,  UPDATE_USER CHAR(32)
    ,  UPDATE_DTS NUM FORMAT=DATETIME19.
    )
  ;
  CREATE UNIQUE INDEX PK_DIMON_JOBS ON DIMON.DIMON_JOBS(JOB_ID,VALID_FROM_DTS);
QUIT;

PROC SQL;
  CREATE TABLE DIMON.DIMON_JOB_RUNS
    (  JOB_RUN_ID NUM
    ,  FLOW_RUN_ID NUM
    ,  FLOW_RUN_SEQ_NR NUM
    ,  FLOW_JOB_ID CHAR(255)
    ,  JOB_START_DTS NUM FORMAT=DATETIME19. INFORMAT=DATETIME19.
    ,  JOB_END_DTS NUM FORMAT=DATETIME19. INFORMAT=DATETIME19.
    ,  JOB_LOG_FILE CHAR(1024)
    ,  JOB_LST_FILE CHAR(1024)
    ,  JOB_STATUS_ID NUM
    ,  JOB_RC NUM
    ,  UPDATE_USER CHAR(32)
    ,  UPDATE_DTS NUM FORMAT=DATETIME19. INFORMAT=DATETIME19.
    )
  ;
  CREATE UNIQUE INDEX JOB_RUN_ID ON DIMON.DIMON_JOB_RUNS(JOB_RUN_ID);
  CREATE INDEX FLOW_RUN_ID       ON DIMON.DIMON_JOB_RUNS(FLOW_RUN_ID);
  CREATE INDEX JOB_START_DTS     ON DIMON.DIMON_JOB_RUNS(JOB_START_DTS);
QUIT;

PROC SQL;
  CREATE TABLE DIMON.DIMON_RUN_STATS
    (  FLOW_JOB_ID CHAR(255)
    ,  STATS_DTS_FROM NUM FORMAT=DATETIME19. INFORMAT=DATETIME19.
    ,  STATS_DTS_UNTIL NUM FORMAT=DATETIME19. INFORMAT=DATETIME19.
    ,  STATS_DATE NUM FORMAT=DATE9. INFORMAT=DATE9.
    ,  ELAPSED_TIME NUM
    ,  ELAPSED_TIME_Q1 NUM
    ,  ELAPSED_TIME_MEDIAN NUM
    ,  ELAPSED_TIME_Q3 NUM
    ,  ELAPSED_TIME_IQR NUM
    ,  ELAPSED_TIME_OUTLIER_IND NUM
    ,  ELAPSED_TIME_OUTLIER NUM
    ,  ELAPSED_TIME_NON_OUTLIER NUM
    ,  ELAPSED_TIME_MOVAVG NUM
    ,  ELAPSED_TIME_MOVSTD NUM
    ,  ELAPSED_TIME_LCL95 NUM
    ,  ELAPSED_TIME_UCL95 NUM
    ,  INTERPOLATED_IND CHAR(1)
    ,  UPDATE_DTS NUM FORMAT=DATETIME19. INFORMAT=DATETIME19.
    )
  ;
  CREATE UNIQUE INDEX PK_DIMON_RUN_STATS ON DIMON.DIMON_RUN_STATS(FLOW_JOB_ID,STATS_DTS_FROM);
QUIT;

PROC SQL;
  CREATE TABLE DIMON.DIMON_JOB_STATUS
    (  JOB_STATUS_ID NUM
    ,  JOB_STATUS_CODE CHAR(12)
    ,  JOB_STATUS_DESC CHAR(32)
    ,  JOB_STATUS_SEQUENCE_NR NUM
    )
  ;
  CREATE UNIQUE INDEX JOB_STATUS_ID ON DIMON.DIMON_JOB_STATUS(JOB_STATUS_ID);
QUIT;

PROC SQL;
  CREATE TABLE DIMON.DIMON_CALENDARS
    (  CALENDAR_NAME CHAR(100)
    ,  CALENDAR_SASCODE CHAR(1024)
	,  UPDATE_USER CHAR(32)
    ,  UPDATE_DTS NUM FORMAT=DATETIME19. INFORMAT=DATETIME19.
    )
  ;
  CREATE UNIQUE INDEX CALENDAR_NAME ON DIMON.DIMON_CALENDARS(CALENDAR_NAME);
QUIT;

PROC SQL;
  CREATE TABLE DIMON.DIMON_FLOW_SCHEDULES
    (  FLOW_ID CHAR(20)
    ,  TRIGGERING_EVENT_TRANSFER_ROLE CHAR(10)
    ,  TRIGGERING_EVENT_ROLE CHAR(20)
    ,  TRIGGERING_EVENT_CONDITION CHAR(100)
    ,  TIMEZONE CHAR(32)
    ,  VALID_FROM_DTS NUM FORMAT=DATETIME19. INFORMAT=DATETIME19.
    ,  VALID_UNTIL_DTS NUM FORMAT=DATETIME19. INFORMAT=DATETIME19.
    ,  CURRENT_IND CHAR(1)
    ,  UPDATE_USER CHAR(32)
    ,  UPDATE_DTS NUM FORMAT=DATETIME19. INFORMAT=DATETIME19.
    )
  ;
  CREATE UNIQUE INDEX PK_DIMON_FLOW_SCHEDULES ON DIMON.DIMON_FLOW_SCHEDULES(FLOW_ID,TRIGGERING_EVENT_CONDITION,VALID_FROM_DTS);
QUIT;

PROC SQL;
  CREATE TABLE DIMON.DIMON_HIDE_FLOWS
    (  FLOW_ID CHAR(20)
    ,  HIDE_IND CHAR(1)
    ,  VALID_FROM_DTS NUM FORMAT=DATETIME19. INFORMAT=DATETIME19.
    ,  VALID_UNTIL_DTS NUM FORMAT=DATETIME19. INFORMAT=DATETIME19.
    ,  CURRENT_IND CHAR(1)
    ,  UPDATE_USER CHAR(32)
    ,  UPDATE_DTS NUM FORMAT=DATETIME19. INFORMAT=DATETIME19.
    )
  ;
  CREATE UNIQUE INDEX PK_DIMON_HIDE_FLOWS ON DIMON.DIMON_HIDE_FLOWS(FLOW_ID,VALID_FROM_DTS);
QUIT;

PROC SQL;
  CREATE TABLE DIMON.DIMON_TIMEZONES
    (  TIMEZONE CHAR(32)
    ,  CONDITION_SASCODE CHAR(1024)
    ,  CONDITION_DESC CHAR(100)
    ,  TIMEDIFF NUM FORMAT=TIME8.
    ,  UPDATE_USER CHAR(32)
    ,  UPDATE_DTS NUM FORMAT=DATETIME19. INFORMAT=DATETIME19.
    )
  ;
  CREATE UNIQUE INDEX PK_DIMON_TIMEZONES ON DIMON.DIMON_TIMEZONES(TIMEZONE,TIMEDIFF);
QUIT;

PROC SQL;
  INSERT INTO DIMON.DIMON_CALENDARS (CALENDAR_NAME,CALENDAR_SASCODE,UPDATE_USER,UPDATE_DTS)
    VALUES ('Daily@Sys','1', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('First_day_of_year@Sys', 'd = intnx(''year'',d,0,''beginning'')', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Last_day_of_year@Sys', 'd = intnx(''year'',d,0,''end'')', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('First_day_of_month@Sys', 'd = intnx(''month'',d,0,''beginning'')', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Last_day_of_month@Sys', 'd = intnx(''month'',d,0,''end'')', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Weekdays@Sys', 'weekday(d) in (2,3,4,5,6)', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Weekends@Sys', 'weekday(d) in (1,7)', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Sundays@Sys', 'weekday(d) = 1', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Mondays@Sys', 'weekday(d) = 2', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Tuesdays@Sys', 'weekday(d) = 3', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Wednesdays@Sys', 'weekday(d) = 4', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Thursdays@Sys', 'weekday(d) = 5', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Fridays@Sys', 'weekday(d) = 6', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Saturdays@Sys', 'weekday(d) = 7', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('First_weekday_of_month@Sys', 'd = (intnx(''month'',d,0,''beginning'') + 2*(weekday(intnx(''month'',d,0,''beginning'')) = 7) + (weekday(intnx(''month'',d,0,''beginning'')) = 1) )', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Last_weekday_of_month@Sys', 'd = (intnx(''month'',d,0,''end'') - 2*(weekday(intnx(''month'',d,0,''end'')) = 1) - 1*(weekday(intnx(''month'',d,0,''end'')) = 7) )', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('First_sunday_of_month@Sys', 'weekday(d) = 1 and day(d) <= 7', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('First_monday_of_month@Sys', 'weekday(d) = 2 and day(d) <= 7', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('First_tuesday_of_month@Sys', 'weekday(d) = 3 and day(d) <= 7', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('First_wednesday_of_month@Sys', 'weekday(d) = 4 and day(d) <= 7', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('First_thursday_of_month@Sys', 'weekday(d) = 5 and day(d) <= 7', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('First_friday_of_month@Sys', 'weekday(d) = 6 and day(d) <= 7', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('First_saturday_of_month@Sys', 'weekday(d) = 7 and day(d) <= 7', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Last_sunday_of_month@Sys', 'weekday(d) = 1 and d >= (intnx(''month'',d,0,''end'') - 6)', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Last_monday_of_month@Sys', 'weekday(d) = 2 and d >= (intnx(''month'',d,0,''end'') - 6)', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Last_tuesday_of_month@Sys', 'weekday(d) = 3 and d >= (intnx(''month'',d,0,''end'') - 6)', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Last_wednesday_of_month@Sys', 'weekday(d) = 4 and d >= (intnx(''month'',d,0,''end'') - 6)', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Last_thursday_of_month@Sys', 'weekday(d) = 5 and d >= (intnx(''month'',d,0,''end'') - 6)', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Last_friday_of_month@Sys', 'weekday(d) = 6 and d >= (intnx(''month'',d,0,''end'') - 6)', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Last_saturday_of_month@Sys', 'weekday(d) = 7 and d >= (intnx(''month'',d,0,''end'') - 6)', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
    VALUES ('Businessdays@Sys', 'weekday(d) >= 1 and weekday(d) <= 6', "&SYSUSERID.", "&SYSDATE9. &SYSTIME."dt)
	;
QUIT;
PROC SQL;
  INSERT INTO DIMON.DIMON_JOB_STATUS (JOB_STATUS_ID,JOB_STATUS_CODE,JOB_STATUS_DESC,JOB_STATUS_SEQUENCE_NR)
    VALUES (0,'NOT STARTED','Not Started',1)
    VALUES (1,'RUNNING','Running',2)
    VALUES (2,'COMPLETED','Completed',3)
	;
QUIT;

PROC SQL;
  INSERT INTO DIMON.DIMON_TIMEZONES (TIMEZONE,CONDITION_SASCODE,CONDITION_DESC,TIMEDIFF,UPDATE_USER,UPDATE_DTS)
   VALUES ('UTC','dts > dhms(intnx(''week.1'',intnx(''month'',mdy(3,1,year(datepart(dts))),0,''E''),0,''B''),2,0,0) and dts < dhms(intnx(''week.1'',intnx(''month'',mdy(10,1,year(datepart(dts))),0,''E''),0,''B''),2,0,0)','UTC Daylight Saving Time',7200,"&SYSUSERID.","&SYSDATE9. &SYSTIME."dt)
   VALUES ('UTC','dts <= dhms(intnx(''week.1'',intnx(''month'',mdy(3,1,year(datepart(dts))),0,''E''),0,''B''),2,0,0) or dts >= dhms(intnx(''week.1'',intnx(''month'',mdy(10,1,year(datepart(dts))),0,''E''),0,''B''),2,0,0)','UTC No Daylight Saving Time',3600,"&SYSUSERID.","&SYSDATE9. &SYSTIME."dt)
   ;
QUIT;

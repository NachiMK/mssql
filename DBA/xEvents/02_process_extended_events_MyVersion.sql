USE mnDBA
GO

/* (c) 2014 Brent Ozar Unlimited */


/* Create tables for intermediate processing */
/*
IF OBJECT_ID('xevents') IS NULL
   CREATE TABLE xevents (
       event_time DATETIME2,
       event_type NVARCHAR(128),
       query_hash decimal(38,0),
       event_data XML,
	   RecordCreatedDtTm DATETIME2 DEFAULT (GETDATE())
   );

IF OBJECT_ID('waits') IS NULL
   CREATE TABLE waits (
       event_time DATETIME2,
       event_interval DATETIME2,
       query_hash DECIMAL(38,0),
       query_plan_hash DECIMAL(38,0),
       session_id INT,
       client_hostname NVARCHAR(MAX),
       database_name NVARCHAR(MAX),
       statement NVARCHAR(MAX),
       wait_type NVARCHAR(MAX),
       duration_ms INT,
       signal_duration_ms INT
   );


IF OBJECT_ID('query_stats') IS NULL
   CREATE TABLE query_stats (
       event_time DATETIME2,
       event_interval DATETIME2, 
       query_hash DECIMAL(38,0),
       query_plan_hash DECIMAL(38,0),
       session_id INT,
       client_hostname NVARCHAR(MAX),
       database_name NVARCHAR(MAX),
       statement NVARCHAR(MAX),
       duration_ms INT,
       cpu_time_ms INT,
       physical_reads INT,
       logical_reads INT,
       writes INT,
       row_count INT
   );

--TRUNCATE TABLE xevents;
--TRUNCATE TABLE waits;
--TRUNCATE TABLE query_stats;
*/
IF OBJECT_ID('tempdb..#FileList') IS NOT NULL
	DROP TABLE #FileList
CREATE TABLE #FileList
(
	 ID		INT NOT NULL IDENTITY(1, 1)
	,XelFile NVARCHAR(500) NOT NULL
)
INSERT INTO #FileList
SELECT 'F:\xEvents\LASQL09\09122016\LASQL09_xEvents_09122016_0600PMPT_0_131182521671120000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL09\09122016\LASQL09_xEvents_09122016_0600PMPT_0_131182526826820000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL09\09122016\LASQL09_xEvents_09122016_0600PMPT_0_131182532456120000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL09\09122016\LASQL09_xEvents_09122016_0600PMPT_0_131182537287600000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL09\09122016\LASQL09_xEvents_09122016_0600PMPT_0_131182542104700000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL09\09122016\LASQL09_xEvents_09122016_0600PMPT_0_131182546853680000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL09\09122016\LASQL09_xEvents_09122016_0600PMPT_0_131182552896580000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL09\09122016\LASQL09_xEvents_09122016_0600PMPT_0_131182558920270000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL09\09122016\LASQL09_xEvents_09122016_0600PMPT_0_131182564206600000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL09\09122016\LASQL09_xEvents_09122016_0600PMPT_0_131182570235590000.xel'

UNION ALL SELECT 'F:\xEvents\LASQL10\09122016\LASQL10_xEvents_09122016_0600PMPT_0_131182545349420000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL10\09122016\LASQL10_xEvents_09122016_0600PMPT_0_131182558079530000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL10\09122016\LASQL10_xEvents_09122016_0600PMPT_0_131182572070440000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL10\09122016\LASQL10_xEvents_09122016_0600PMPT_0_131182589039850000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL10\09122016\LASQL10_xEvents_09122016_0600PMPT_0_131182602539500000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL10\09122016\LASQL10_xEvents_09122016_0600PMPT_0_131182615983370000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL10\09122016\LASQL10_xEvents_09122016_0600PMPT_0_131182629621620000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL10\09122016\LASQL10_xEvents_09122016_0600PMPT_0_131182641810780000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL10\09122016\LASQL10_xEvents_09122016_0600PMPT_0_131182655090110000.xel'
UNION ALL SELECT 'F:\xEvents\LASQL10\09122016\LASQL10_xEvents_09122016_0600PMPT_0_131182665019850000.xel'

--UNION ALL SELECT 'F:\xEvents\LASQL09\09132016\LASQL09_xEvents_09132016_0600PMPT_0_131183613077210000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL09\09132016\LASQL09_xEvents_09132016_0600PMPT_0_131183618833270000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL09\09132016\LASQL09_xEvents_09132016_0600PMPT_0_131183624524950000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL09\09132016\LASQL09_xEvents_09132016_0600PMPT_0_131183629369270000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL09\09132016\LASQL09_xEvents_09132016_0600PMPT_0_131183635016580000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL09\09132016\LASQL09_xEvents_09132016_0600PMPT_0_131183640205280000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL09\09132016\LASQL09_xEvents_09132016_0600PMPT_0_131183646383540000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL09\09132016\LASQL09_xEvents_09132016_0600PMPT_0_131183652412110000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL09\09132016\LASQL09_xEvents_09132016_0600PMPT_0_131183658483330000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL09\09132016\LASQL09_xEvents_09132016_0600PMPT_0_131183664520180000.xel'

--UNION ALL SELECT 'F:\xEvents\LASQL10\09132016\LASQL10_xEvents_09132016_0600PMPT_0_131183574078690000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL10\09132016\LASQL10_xEvents_09132016_0600PMPT_0_131183584245680000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL10\09132016\LASQL10_xEvents_09132016_0600PMPT_0_131183596472730000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL10\09132016\LASQL10_xEvents_09132016_0600PMPT_0_131183606823630000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL10\09132016\LASQL10_xEvents_09132016_0600PMPT_0_131183617349500000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL10\09132016\LASQL10_xEvents_09132016_0600PMPT_0_131183626817130000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL10\09132016\LASQL10_xEvents_09132016_0600PMPT_0_131183634460930000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL10\09132016\LASQL10_xEvents_09132016_0600PMPT_0_131183641375020000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL10\09132016\LASQL10_xEvents_09132016_0600PMPT_0_131183654423960000.xel'
--UNION ALL SELECT 'F:\xEvents\LASQL10\09132016\LASQL10_xEvents_09132016_0600PMPT_0_131183662741370000.xel'



DECLARE @XELFile NVARCHAR(500)

DECLARE OBJECT_CURSOR CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

SELECT		XelFile
FROM		#FileList

OPEN OBJECT_CURSOR

FETCH NEXT FROM OBJECT_CURSOR
INTO @XELFile

WHILE (@@FETCH_STATUS = 0)
BEGIN
	PRINT '------------------------'
	PRINT 'Process started for File:' + @XELFile

	INSERT INTO xevents (event_time, event_type, query_hash, event_data)
	SELECT  DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP), x.event_data.value('(event/@timestamp)[1]', 'datetime2')) AS event_time,
		   x.event_data.value('(/event/@name)[1]', 'nvarchar(max)'),
		   x.event_data.value('(event/action[@name="query_hash"])[1]', 'decimal(38,0)'),
		   x.event_data
	FROM    sys.fn_xe_file_target_read_file (@XELFile, null, null, null)
			   CROSS APPLY (SELECT CAST(event_data AS XML) AS event_data) as x ;
    
	PRINT 'Processed File:' + @XELFile
	PRINT '------------------------'

	FETCH NEXT FROM OBJECT_CURSOR
	INTO @XELFile
END

CLOSE OBJECT_CURSOR
DEALLOCATE OBJECT_CURSOR


INSERT INTO waits
SELECT  DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP), x.event_data.value('(event/@timestamp)[1]', 'datetime2')) AS event_time,
       DATEADD(MINUTE, DATEDIFF(MINUTE, 0, event_time), 0) AS event_interval,
       x.event_data.value('(event/action[@name="query_hash"])[1]', 'decimal(38,0)') AS query_hash,
       x.event_data.value('(event/action[@name="query_plan_hash"])[1]', 'decimal(38,0)') AS query_plan_hash,
       x.event_data.value('(event/action[@name="session_id"])[1]', 'int') AS session_id,
       x.event_data.value('(event/action[@name="client_hostname"])[1]', 'nvarchar(max)') AS client_hostname,
       x.event_data.value('(event/action[@name="database_name"])[1]', 'nvarchar(max)') AS database_name,
       x.event_data.value('(event/action[@name="sql_text"])[1]', 'nvarchar(max)') AS statement,
       x.event_data.value('(event/data[@name="wait_type"]/text)[1]', 'nvarchar(max)') AS wait_type,
       x.event_data.value('(event/data[@name="duration"])[1]', 'int') AS duration_ms,
       x.event_data.value('(event/data[@name="signal_duration"])[1]', 'int') AS signal_duration_ms
FROM    xevents AS x 
WHERE   x.query_hash > 0
       AND x.event_type = 'wait_info';


INSERT INTO query_stats 
SELECT  
       DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP), x.event_data.value('(event/@timestamp)[1]', 'datetime2')) AS event_time,
       DATEADD(MINUTE, DATEDIFF(MINUTE, 0, event_time), 0) AS event_interval,
       x.event_data.value('(event/action[@name="query_hash"])[1]', 'decimal(38,0)') AS query_hash,
       x.event_data.value('(event/action[@name="query_plan_hash"])[1]', 'decimal(38,0)') AS query_plan_hash,
       x.event_data.value('(event/action[@name="session_id"])[1]', 'int') AS session_id,
       x.event_data.value('(event/action[@name="client_hostname"])[1]', 'nvarchar(max)') AS client_hostname,
       x.event_data.value('(event/action[@name="database_name"])[1]', 'nvarchar(max)') AS database_name,
       x.event_data.value('(event/data[@name="statement"])[1]', 'nvarchar(max)') AS statement,
       x.event_data.value('(event/data[@name="duration"])[1]', 'int') AS duration_ms,
       x.event_data.value('(event/data[@name="cpu_time"])[1]', 'int') AS cpu_time_ms,
       x.event_data.value('(event/data[@name="physical_reads"])[1]', 'int') AS physical_reads,
       x.event_data.value('(event/data[@name="logical_reads"])[1]', 'int') AS logical_reads,
       x.event_data.value('(event/data[@name="writes"])[1]', 'int') AS writes,
       x.event_data.value('(event/data[@name="row_count"])[1]', 'int') AS row_count
FROM   xevents AS x
WHERE  x.query_hash > 0
       AND (x.event_type = 'sp_statement_completed' OR x.event_type = 'sql_statement_completed') ;



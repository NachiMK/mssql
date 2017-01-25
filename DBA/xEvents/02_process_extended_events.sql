/* (c) 2014 Brent Ozar Unlimited */


/* Create tables for intermediate processing */
IF OBJECT_ID('xevents') IS NULL
   CREATE TABLE xevents (
       event_time DATETIME2,
       event_type NVARCHAR(128),
       query_hash decimal(38,0),
       event_data XML
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

TRUNCATE TABLE xevents;
TRUNCATE TABLE waits;
TRUNCATE TABLE query_stats;

INSERT INTO xevents (event_time, event_type, query_hash, event_data)
SELECT  DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP), x.event_data.value('(event/@timestamp)[1]', 'datetime2')) AS event_time,
       x.event_data.value('(/event/@name)[1]', 'nvarchar(max)'),
       x.event_data.value('(event/action[@name="query_hash"])[1]', 'decimal(38,0)'),
       x.event_data
FROM    sys.fn_xe_file_target_read_file ('C:\temp\XEventSessions\query_performance*.xel', 'C:\temp\XEventSessions\query_performance*.xem', null, null)
           CROSS APPLY (SELECT CAST(event_data AS XML) AS event_data) as x ;


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
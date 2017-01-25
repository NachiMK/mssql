SELECT	*
FROM	DBAUtil.dbo.WhoIsActive_Output WITH (READUNCOMMITTED)
WHERE	collection_time > '1/7/2015'
--AND		wait_info LIKE '%RESOURCE_SEMA%'
AND		host_name IN ('CABIDBP-N1', 'CABIPV1')
AND		database_name = 'QnA'
AND		login_name = 'ASM\cadbp_2k8r2_SSAS'
ORDER BY collection_time DESC

-- IO WAITS
SELECT	*
FROM	DBAUtil.dbo.WhoIsActive_Output WITH (READUNCOMMITTED)
WHERE	collection_time > '1/7/2015'
AND		(
			(wait_info LIKE '%PAGEIOLATCH%')
		OR	(wait_info LIKE '%ASYNC_IO_COMPLETION%')
		)

-- PARTICULAR DB PERF
SELECT	*
FROM	DBAUtil.dbo.WhoIsActive_Output WITH (READUNCOMMITTED)
WHERE	collection_time > '1/6/2015'
AND		database_name = 'PTS'
AND		program_name = 'SSIS-PTS003 - ETL PTS'
ORDER BY collection_time

-- What happened between given time
IF OBJECT_ID('tempdb..#WhoIsActive') IS NOT NULL 
	DROP TABLE #WhoIsActive
SELECT	*
		,Wait_info_type	= SUBSTRING(wait_info, CHARINDEX(')', wait_info) + 1, LEN(wait_info) - CHARINDEX(')', wait_info))
		,Wait_ms		= LEFT(wait_info, CHARINDEX(')', wait_info))
INTO	#WhoIsActive
FROM	DBAUtil.dbo.WhoIsActive_Output WITH (READUNCOMMITTED)
WHERE	collection_time BETWEEN '1/7/2015 17:00' AND '1/7/2015 20:26'

SELECT	*
FROM	#WhoIsActive AS WIA
WHERE	1 = 1
AND		host_name IN ('CABIDBP-N1', 'CABIPV1')
ORDER BY collection_time

SELECT	*
FROM	#WhoIsActive AS WIA
WHERE	1 = 1
AND		host_name IN ('CABIDBP-N1', 'CABIPV1')
AND		database_name = 'PTS'
ORDER BY collection_time


SELECT		host_name, program_name, database_name, Cnt = COUNT(*), StartTime = MIN(collection_time), EndTime = MAX(collection_time)
FROM		#WhoIsActive AS WIA
WHERE		1 = 1
AND			host_name IN ('CABIDBP-N1', 'CABIPV1')
GROUP BY	host_name, program_name, database_name
ORDER BY	host_name, program_name, database_name

SELECT		host_name, program_name, database_name, wait_info_type, Cnt = COUNT(*)
FROM		#WhoIsActive AS WIA
GROUP BY	host_name, program_name, database_name, wait_info_type
ORDER BY	host_name, program_name, database_name, wait_info_type


-- Blocked Sessions
SELECT	collection_time1 = collection_time,*
FROM	DBAUtil.dbo.WhoIsActive_Output WITH (READUNCOMMITTED)
WHERE	collection_time BETWEEN '1/6/2015 19:42' AND '1/7/2015 06:00'
--AND		wait_info LIKE '%RESOURCE_SEMA%'
AND		host_name IN ('CABIDBP-N1', 'CABIPV1')
AND		blocking_session_id IS NOT NULL

UNION ALL

SELECT	collection_time1 = collection_time, *
FROM	DBAUtil.dbo.WhoIsActive_Output BS WITH (READUNCOMMITTED)
WHERE	host_name IN ('CABIDBP-N1', 'CABIPV1')
AND		collection_time BETWEEN '1/6/2015 19:42' AND '1/7/2015 06:00'
AND		session_id IN 
(
SELECT	DISTINCT blocking_session_id
FROM	DBAUtil.dbo.WhoIsActive_Output WITH (READUNCOMMITTED)
WHERE	collection_time BETWEEN '1/6/2015 19:42' AND '1/7/2015 06:00'
AND		host_name IN ('CABIDBP-N1', 'CABIPV1')
AND		blocking_session_id IS NOT NULL
)
ORDER BY collection_time, session_id

SELECT [log_reuse_wait_desc] FROM sys.databases WHERE [name] = N'PTS'

SELECT	 YEAR	=	YEAR(collection_time)
		,MONTH	=	MONTH(collection_time)
		,DAY	=	DAY(collection_time)
		,HOUR	=	DATEPART(HOUR, collection_time)
		,host_name
		,database_name
		,program_name
		,Cnt = COUNT(*)
FROM	DBAUtil.dbo.WhoIsActive_Output WITH (READUNCOMMITTED)
WHERE	collection_time > '1/7/2015'
AND		wait_info LIKE '%RESOURCE_SEMA%'
AND		host_name IN ('CABIDBP-N1', 'CABIPV1')
GROUP BY
		 YEAR(collection_time)
		,MONTH(collection_time)
		,DAY(collection_time)
		,DATEPART(HOUR, collection_time)
		,host_name, database_name, program_name
ORDER BY
		 YEAR
		,MONTH
		,DAY
		,HOUR
		,host_name, database_name, program_name

SELECT	*
FROM	DBAUtil.dbo.WhoIsActive_Output WITH (READUNCOMMITTED)
WHERE	collection_time > '1/6/2015'
AND		wait_info LIKE '%CXPACKET%'
ORDER BY collection_time DESC
SELECT * FROM sys.dm_exec_query_resource_semaphores

SELECT * FROM sys.dm_exec_query_memory_grants  where grant_time is null

-- current WAITS
SELECT TOP 10
        wait_type ,
        max_wait_time_ms wait_time_ms ,
        signal_wait_time_ms ,
        wait_time_ms - signal_wait_time_ms AS resource_wait_time_ms ,
        100.0 * wait_time_ms / SUM(wait_time_ms) OVER ( )
                                    AS percent_total_waits ,
        100.0 * signal_wait_time_ms / SUM(signal_wait_time_ms) OVER ( )
                                    AS percent_total_signal_waits ,
        100.0 * ( wait_time_ms - signal_wait_time_ms )
        / SUM(wait_time_ms) OVER ( ) AS percent_total_resource_waits
FROM    sys.dm_os_wait_stats
WHERE   wait_time_ms > 0
        AND wait_type NOT IN
( 'SLEEP_TASK', 'BROKER_TASK_STOP', 'BROKER_TO_FLUSH',
  'SQLTRACE_BUFFER_FLUSH','CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT', 
  'LAZYWRITER_SLEEP', 'SLEEP_SYSTEMTASK', 'SLEEP_BPOOL_FLUSH',
  'BROKER_EVENTHANDLER', 'XE_DISPATCHER_WAIT', 'FT_IFTSHC_MUTEX',
  'CHECKPOINT_QUEUE', 'FT_IFTS_SCHEDULER_IDLE_WAIT', 
  'BROKER_TRANSMITTER', 'FT_IFTSHC_MUTEX', 'KSOURCE_WAKEUP',
  'LAZYWRITER_SLEEP', 'LOGMGR_QUEUE', 'ONDEMAND_TASK_QUEUE',
  'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT', 'BAD_PAGE_PROCESS',
  'DBMIRROR_EVENTS_QUEUE', 'BROKER_RECEIVE_WAITFOR',
  'PREEMPTIVE_OS_GETPROCADDRESS', 'PREEMPTIVE_OS_AUTHENTICATIONOPS',
  'WAITFOR', 'DISPATCHER_QUEUE_SEMAPHORE', 'XE_DISPATCHER_JOIN',
  'RESOURCE_QUEUE' )
ORDER BY wait_time_ms DESC


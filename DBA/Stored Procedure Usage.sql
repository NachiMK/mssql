/*
	Purpose	: Find Stored Proc Usage and other SP reltaed details
	CREDIT	: http://www.databasejournal.com/features/mssql/article.php/3687186/Monitoring-Stored-Procedure-Usage.htm
*/

-- GET SPs by most USED count
SELECT	DBName			= DB_NAME(st.dbid)
	   ,SchemaName		= OBJECT_SCHEMA_NAME(st.objectid, dbid)
	   ,StoredProcedure	= OBJECT_NAME(st.objectid, dbid)
	   ,Execution_count	= MAX(cp.usecounts)
FROM	sys.dm_exec_cached_plans				cp
CROSS
APPLY	sys.dm_exec_sql_text(cp.plan_handle)	st
WHERE	DB_NAME(st.dbid) IS NOT NULL
AND		cp.objtype = 'proc'
--AND		OBJECT_NAME(st.objectid, dbid) = 'up_MemberAttribute_Save_Multiple'
--AND		DB_NAME(st.dbid) like 'mnMember%'
GROUP BY
		cp.plan_handle
	   ,DB_NAME(st.dbid)
	   ,OBJECT_SCHEMA_NAME(objectid, st.dbid)
	   ,OBJECT_NAME(objectid, st.dbid)
ORDER BY
		Execution_count DESC


-- SP that consumes the most CPU resources

SELECT	DBName			= DB_NAME(st.dbid)
	   ,SchemaName		= OBJECT_SCHEMA_NAME(st.objectid, dbid)
	   ,StoredProcedure	= OBJECT_NAME(st.objectid, dbid)
	   ,Execution_count	= MAX(cp.usecounts)
	   ,total_cpu_time	= SUM(qs.total_worker_time)
	   ,avg_cpu_time	= SUM(qs.total_worker_time) / (MAX(cp.usecounts) * 1.0)
FROM	sys.dm_exec_cached_plans cp
JOIN	sys.dm_exec_query_stats qs ON cp.plan_handle = qs.plan_handle
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
WHERE	DB_NAME(st.dbid) IS NOT NULL
		AND cp.objtype = 'proc'
GROUP BY
		DB_NAME(st.dbid)
	   ,OBJECT_SCHEMA_NAME(objectid, st.dbid)
	   ,OBJECT_NAME(objectid, st.dbid)
ORDER BY
		total_cpu_time DESC
 
 -- SP with most I/O requests
SELECT	DBName					= DB_NAME(st.dbid)
	   ,SchemaName				= OBJECT_SCHEMA_NAME(objectid, st.dbid)
	   ,StoredProcedure			= OBJECT_NAME(objectid, st.dbid)
	   ,execution_count			= MAX(cp.usecounts)
	   ,total_IO				= SUM(qs.total_physical_reads + qs.total_logical_reads + qs.total_logical_writes)
	   ,avg_total_IO			= SUM(qs.total_physical_reads + qs.total_logical_reads + qs.total_logical_writes) / (MAX(cp.usecounts))
	   ,total_physical_reads	= SUM(qs.total_physical_reads)
	   ,avg_physical_read		= SUM(qs.total_physical_reads) / (MAX(cp.usecounts) * 1.0)
	   ,total_logical_reads		= SUM(qs.total_logical_reads)
	   ,avg_logical_read		= SUM(qs.total_logical_reads) / (MAX(cp.usecounts) * 1.0)
	   ,total_logical_writes	= SUM(qs.total_logical_writes)
	   ,avg_logical_writes		= SUM(qs.total_logical_writes) / (MAX(cp.usecounts) * 1.0)
	   ,CallsPerMinute			= ((MAX(CP.usecounts)/(SELECT DATEDiff(dd, sqlserver_start_time, GETDATE()) FROM sys.dm_os_sys_info))/24.00)/60.0
FROM	sys.dm_exec_query_stats					qs
CROSS
APPLY	sys.dm_exec_sql_text(qs.plan_handle)	st
JOIN	sys.dm_exec_cached_plans				cp ON qs.plan_handle = cp.plan_handle
WHERE	DB_NAME(st.dbid) IS NOT NULL
AND		cp.objtype = 'proc'
AND		DB_NAME(st.dbid) like 'mnMOnitor%'
GROUP BY
		DB_NAME(st.dbid)
	   ,OBJECT_SCHEMA_NAME(objectid, st.dbid)
	   ,OBJECT_NAME(objectid, st.dbid)
ORDER BY
		total_IO DESC

-- Long Running PROC
SELECT	DBName				= DB_NAME(st.dbid)
	   ,SchemaName			= OBJECT_SCHEMA_NAME(objectid, st.dbid)
	   ,StoredProcedure		= OBJECT_NAME(objectid, st.dbid)
	   ,execution_count		= MAX(cp.usecounts)
	   ,total_elapsed_time	= SUM(qs.total_elapsed_time)
	   ,avg_elapsed_time	= SUM(qs.total_elapsed_time) / MAX(cp.usecounts)
FROM	sys.dm_exec_query_stats					qs
CROSS
APPLY	sys.dm_exec_sql_text(qs.plan_handle)	st
JOIN	sys.dm_exec_cached_plans				cp ON qs.plan_handle = cp.plan_handle
WHERE	DB_NAME(st.dbid) IS NOT NULL
AND		cp.objtype = 'proc'
--AND		DB_NAME(st.dbid) like 'mnMember1%'
GROUP BY DB_NAME(st.dbid)
	   ,OBJECT_SCHEMA_NAME(objectid, st.dbid)
	   ,OBJECT_NAME(objectid, st.dbid)
ORDER BY
		--total_elapsed_time DESC
		avg_elapsed_time desc
-- 9/13
SELECT * FROM sys.dm_os_sys_info
EXEC xp_ReadErrorLog 0, 1
--Reads current SQL Server error log

-- Find Past session details if it is still available (if server was restarted since the session ran then don't use this it will be incorrect)
SELECT  *
FROM    sys.dm_exec_sessions S
        FULL OUTER JOIN sys.dm_exec_connections C ON C.session_id = S.session_id
        CROSS APPLY sys.dm_exec_sql_text(C.most_recent_sql_handle) ST
WHERE   S.session_id IN ( 154 )

SELECT * FROM sys.databases WHERE database_id IN (31, 9)



SELECT  *
FROM    sys.dm_exec_query_stats QS
        CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) ST
WHERE QS.total_physical_reads > 500000

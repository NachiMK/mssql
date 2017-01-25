SELECT  
    d.PERCENT_COMPLETE AS [%Complete],
    d.TOTAL_ELAPSED_TIME/60000 AS ElapsedTimeMin,
    d.ESTIMATED_COMPLETION_TIME/60000   AS TimeRemainingMin,
    d.TOTAL_ELAPSED_TIME*0.00000024 AS ElapsedTimeHours,
    d.ESTIMATED_COMPLETION_TIME*0.00000024  AS TimeRemainingHours,
    s.text AS Command
FROM    sys.dm_exec_requests d 
CROSS APPLY sys.dm_exec_sql_text(d.sql_handle)as s
WHERE  d.COMMAND LIKE 'RESTORE DATABASE%'
ORDER   BY 2 desc, 3 DESC
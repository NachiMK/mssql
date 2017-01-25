
-- FIND Stored Proc Plan
SELECT  deqp.dbid ,
		DBName = DB_NAME(deqp.dbid),
		ObjectName = OBJECT_NAME(deqp.objectid, deqp.dbid),
        deqp.objectid ,
		deqs.plan_handle,
        CAST(deqp.query_plan AS XML) AS singleStatementPlan ,
        deqp.query_plan AS batch_query_plan ,
        ROW_NUMBER() OVER ( ORDER BY statement_start_offset ) AS query_position ,
        CASE WHEN deqs.statement_start_offset = 0
                  AND deqs.statement_end_offset = -1
             THEN '-- see objectText column--'
             ELSE '-- query --' + CHAR(13) + CHAR(10)
                  + SUBSTRING(execText.text, deqs.statement_start_offset / 2,
                              ( ( CASE WHEN deqs.statement_end_offset = -1
                                       THEN DATALENGTH(execText.text)
                                       ELSE deqs.statement_end_offset
                                  END ) - deqs.statement_start_offset ) / 2)
        END AS queryText,
		deqs.last_execution_time,
		deqs.execution_count,
		deqs.creation_time
FROM    sys.dm_exec_query_stats deqs WITH (READUNCOMMITTED)
        CROSS APPLY sys.dm_exec_text_query_plan(deqs.plan_handle,
                                                deqs.statement_start_offset,
                                                deqs.statement_end_offset) AS detqp
        CROSS APPLY sys.dm_exec_query_plan(deqs.plan_handle) AS deqp
        CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText
WHERE   1 = 1
AND		execText.text LIKE '%up_Promo_List_All%' -- CHANGE here for your stored procedure !!
AND		DB_NAME(deqp.dbid) LIKE 'mnSubscription%'
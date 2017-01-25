-- Currently Running Jobs
SELECT
    ja.job_id,
    j.name AS job_name,
    ja.start_execution_date,      
	DATEDIFF(mi, ja.start_execution_date, GETDATE()) AS Duration,
    ISNULL(last_executed_step_id,0)+1 AS current_executed_step_id,
    Js.step_name
FROM msdb.dbo.sysjobactivity ja WITH (READUNCOMMITTED)
LEFT JOIN msdb.dbo.sysjobhistory jh WITH (READUNCOMMITTED)
    ON ja.job_history_id = jh.instance_id
JOIN msdb.dbo.sysjobs j WITH (READUNCOMMITTED)
    ON ja.job_id = j.job_id
JOIN msdb.dbo.sysjobsteps js WITH (READUNCOMMITTED)
    ON ja.job_id = js.job_id
    AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions WITH (READUNCOMMITTED) ORDER BY agent_start_date DESC)
AND start_execution_date is not null
AND stop_execution_date is null;

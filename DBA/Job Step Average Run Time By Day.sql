USE msdb
go

SELECT	 JobName				= J.name
		,JobId					= h.job_id
		,ServerName				= server
		,StepID					= H.step_id
		,StepName				= H.step_name
		,StartDatetime			= CONVERT (DATETIME, RTRIM(run_date))
								+ (
									run_time * 9
									+ run_time % 10000 * 6
									+ run_time % 100 * 10
								) / 216e4
		,EndDateTime			=	dateadd(ss,
											(CAST(SUBSTRING((right('0000000' + convert(varchar(7), run_duration), 7)),1,3) AS INT) * 60 * 60
											 + CAST(SUBSTRING((right('0000000' + convert(varchar(7), run_duration), 7)),4,2) AS INT) * 60
											 + CAST(SUBSTRING((right('0000000' + convert(varchar(7), run_duration), 7)),6,2) AS INT)
											)
											,
											(CONVERT (DATETIME, RTRIM(run_date))
											+ (
												run_time * 9
												+ run_time % 10000 * 6
												+ run_time % 100 * 10
											) / 216e4 ))
		,RunDurationFormatted	= STUFF(STUFF(REPLACE(STR(run_duration, 6, 0), ' ', '0'), 3, 0, ':'), 6, 0, ':')
		,DurationInSeconds=
				(CAST(SUBSTRING((right('0000000' + convert(varchar(7), run_duration), 7)),1,3) AS INT) * 60 * 60
				 + CAST(SUBSTRING((right('0000000' + convert(varchar(7), run_duration), 7)),4,2) AS INT) * 60
				 + CAST(SUBSTRING((right('0000000' + convert(varchar(7), run_duration), 7)),6,2) AS INT)
				)/1.
		,Failed					= CASE H.run_Status WHEN 0 THEN 1 ELSE 0 END
		,Succeeded				= CASE H.run_Status WHEN 1 THEN 1 ELSE 0 END
		,Retry					= CASE H.run_Status WHEN 2 THEN 1 ELSE 0 END
		,Cancelled				= CASE H.run_Status WHEN 3 THEN 1 ELSE 0 END
		,MessageGenerated		= H.message
		,CategoryID				= J.category_id
		,RetriesAttempted		= H.retries_attempted
		,RunStatus				= run_status
		,RunTime				= run_time
		,RunDuration			= run_duration
		,RunDate				= run_date
FROM	msdb.dbo.sysjobhistory h	WITH (READUNCOMMITTED)
JOIN	msdb.dbo.sysjobs J			WITH (READUNCOMMITTED)	ON J.job_id = H.job_id
--WHERE	H.run_date				> CONVERT(VARCHAR, GETDATE(), 112)
ORDER BY 
		 JobName
		,H.run_date DESC
		,H.run_time desc
		,H.step_id

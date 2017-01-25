-- Check Job Status. 
SELECT
	DISTINCT
		[Job Name] = J.Name
		,[Job Description]	= J.DESCRIPTION
		,RunDate		= H.run_date
		,StatusTime		= H.run_time
		,Duration		= H.run_duration
		,JobStatus		= CASE h.run_status 
							WHEN 0 THEN 'Failed' 
							WHEN 1 THEN 'Successful' 
							WHEN 3 THEN 'Cancelled' 
							WHEN 4 THEN 'In Progress' 
							END
FROM	msdb.dbo.sysJobHistory H
JOIN	msdb.dbo.sysJobs J			ON J.job_id = H.job_id
--LEFT	JOIN	msdb.dbo.sysJobHistory HI where H.job_id = HI.job_id
--LEFT	JOIN	msdb..sysJobHistory HJ where H.job_id = HJ.job_id
where	H.step_id = 1
--AND		J.Name		= 'A3 ETL - CRM_EXT'
ORDER BY 1

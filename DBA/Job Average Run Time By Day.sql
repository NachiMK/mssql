use msdb;

-- EXEC sp_help_jobActivity @job_name = 'A3 ETL - EventSale'

select
	d.jobname
	,d.servername
	, avgDurationMinutes=avg(d.durationMinutes)
	, daydate=convert(char(10),startdatetime,101)
	,startdatetime
	,enddatetime = DATEADD(mi, avg(d.durationMinutes), startdatetime)
	, Failed		= SUM(CASE run_Status WHEN 0 THEN 1 ELSE 0 END)
	, Succeeded		= SUM(CASE run_Status WHEN 1 THEN 1 ELSE 0 END)
	, Retry			= SUM(CASE run_Status WHEN 2 THEN 1 ELSE 0 END)
	, Cancelled		= SUM(CASE run_Status WHEN 3 THEN 1 ELSE 0 END)
from (
	select
		jobname=j.name
		,servername=server
		,startdatetime=
			CONVERT (DATETIME, RTRIM(run_date))
			+ (
				run_time * 9
				+ run_time % 10000 * 6
				+ run_time % 100 * 10
			) / 216e4
		, durationMinutes=
				(CAST(SUBSTRING((right('0000000' + convert(varchar(7), run_duration), 7)),1,3) AS INT) * 60 * 60
				 + CAST(SUBSTRING((right('0000000' + convert(varchar(7), run_duration), 7)),4,2) AS INT) * 60
				 + CAST(SUBSTRING((right('0000000' + convert(varchar(7), run_duration), 7)),6,2) AS INT)
				)/60.

		,enddatetime =
		dateadd
			(ss,
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
			) / 216e4 )
			)
		, retries_attempted
		, run_Status
	from sysjobs j (nolock)
	join sysjobhistory h  on
		h.job_id = j.job_id
		and h.step_id = 0 -- look only at the job outcome step for the total job runtime
	WHERE 1 = 1
	--AND	j.category_id = 110
	--and	j.name in ('&lt;strong&gt;JobName&lt;/strong&gt;')  -- Set the jobname here
	AND j.NAME IN ('mnActivity - _Realtime - Activity - _Load Data Into Partitions')
	--AND j.NAME IN ('A3 ETL - PTS DS Analytical')

) d
WHERE 1 = 1
--and	datepart(dw,startdatetime)=7 -- Set  your day of week here if desired. 7=Saturday
--and startdatetime >= DATEADD(dd, -5, CONVERT(DATE, GETDATE()))
-- Failed Jobs only
 --AND run_Status = 0
group by
	d.jobname
	,servername
	,convert(char(10),startdatetime,101)
	,startdatetime
order by
	d.jobname
	,servername
	,cast(convert(char(10),startdatetime,101)as datetime) DESC
	,startdatetime DESC


select
	 d.jobname
	,d.servername
	,DurationMinutes	= d.durationMinutes
	,daydate			= convert(char(10),startdatetime,101)
	,startdatetime
	,enddatetime	= DATEADD(mi, d.durationMinutes, startdatetime)
	,Failed			= CASE run_Status WHEN 0 THEN 1 ELSE 0 END
	,Succeeded		= CASE run_Status WHEN 1 THEN 1 ELSE 0 END
	,Retry			= CASE run_Status WHEN 2 THEN 1 ELSE 0 END
	,Cancelled		= CASE run_Status WHEN 3 THEN 1 ELSE 0 END
	,run_duration
from (
	select
		jobname=j.name
		,servername=server
		,startdatetime=
			CONVERT (DATETIME, RTRIM(run_date))
			+ (
				run_time * 9
				+ run_time % 10000 * 6
				+ run_time % 100 * 10
			) / 216e4
		, durationMinutes=
				(CAST(SUBSTRING((right('0000000' + convert(varchar(7), run_duration), 7)),1,3) AS INT) * 60 * 60
				 + CAST(SUBSTRING((right('0000000' + convert(varchar(7), run_duration), 7)),4,2) AS INT) * 60
				 + CAST(SUBSTRING((right('0000000' + convert(varchar(7), run_duration), 7)),6,2) AS INT)
				)/60.

		,enddatetime =
		dateadd
			(ss,
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
			) / 216e4 )
			)
		, retries_attempted
		, run_Status
	from sysjobs j (nolock)
	join sysjobhistory h  on
		h.job_id = j.job_id
		and h.step_id = 0 -- look only at the job outcome step for the total job runtime
	WHERE 1 = 1
	AND	j.category_id = 110
) d
WHERE 1 = 1
--and	datepart(dw,startdatetime)=7 -- Set  your day of week here if desired. 7=Saturday
--and startdatetime >= DATEADD(dd, -5, CONVERT(DATE, GETDATE()))
--AND JobName LIKE '%PTS%'
-- Failed Jobs only
 --AND run_Status = 0
order by
	d.jobname
	,servername
	,cast(convert(char(10),startdatetime,101)as datetime) DESC
	,startdatetime DESC
		

select 
 j.name as 'JobName',
 s.step_id as 'Step',
 s.step_name as 'StepName',
 run_date,
 msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime',
 ((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) 
         as 'RunDurationMinutes'
From msdb.dbo.sysjobs j 
INNER JOIN msdb.dbo.sysjobsteps s 
 ON j.job_id = s.job_id
INNER JOIN msdb.dbo.sysjobhistory h 
 ON s.job_id = h.job_id 
 AND s.step_id = h.step_id 
 AND h.step_id <> 0
where j.enabled = 1   --Only Enabled Jobs
--and j.name = 'A3 ETL - PTS DS Analytical' --Uncomment to search for a single job
and j.name IN ('mnActivity - _Realtime - Activity - _Load Data Into Partitions') --Uncomment to search for a single job
/*
and msdb.dbo.agent_datetime(run_date, run_time) 
BETWEEN '12/08/2012' and '12/10/2012'  --Uncomment for date range queries
*/
order by JobName, run_date desc, RunDateTime ASC, Step

-- FAILED JOBS, and Last Failed Date time
select
	 d.jobname
	,d.servername
	,daydate=convert(char(10),MAX(startdatetime),101)
	,LastStartDtTime = MAX(startdatetime)
from (
	select
		jobname=j.name
		,servername=server
		,startdatetime=
			CONVERT (DATETIME, RTRIM(run_date))
			+ (
				run_time * 9
				+ run_time % 10000 * 6
				+ run_time % 100 * 10
			) / 216e4
		, durationMinutes=
				(CAST(SUBSTRING((right('0000000' + convert(varchar(7), run_duration), 7)),1,3) AS INT) * 60 * 60
				 + CAST(SUBSTRING((right('0000000' + convert(varchar(7), run_duration), 7)),4,2) AS INT) * 60
				 + CAST(SUBSTRING((right('0000000' + convert(varchar(7), run_duration), 7)),6,2) AS INT)
				)/60.

		,enddatetime =
		dateadd
			(ss,
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
			) / 216e4 )
			)
		, retries_attempted
		, run_Status
	from sysjobs j (nolock)
	join sysjobhistory h  on
		h.job_id = j.job_id
		and h.step_id = 0 -- look only at the job outcome step for the total job runtime
	WHERE 1 = 1
	--and	j.name in ('&lt;strong&gt;JobName&lt;/strong&gt;')  -- Set the jobname here
	--AND j.NAME IN ('mnActivity - _Realtime - Activity - _Load Data Into Partitions')

) d
WHERE 1 = 1
--and	datepart(dw,startdatetime)=7 -- Set  your day of week here if desired. 7=Saturday
and startdatetime >= DATEADD(dd, -1, CONVERT(DATE, GETDATE()))
-- Failed Jobs only
 AND run_Status = 0
group by
	d.jobname
	,servername
order by
	d.jobname
	,servername
	,StartDatetime

-- Currently Running jobs and steps.
SELECT
    ja.job_id,
    j.name AS job_name,
    ja.start_execution_date,      
    ISNULL(last_executed_step_id,0)+1 AS current_executed_step_id,
    Js.step_name
FROM msdb.dbo.sysjobactivity ja 
LEFT JOIN msdb.dbo.sysjobhistory jh 
    ON ja.job_history_id = jh.instance_id
JOIN msdb.dbo.sysjobs j 
    ON ja.job_id = j.job_id
JOIN msdb.dbo.sysjobsteps js
    ON ja.job_id = js.job_id
    AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY agent_start_date DESC)
AND start_execution_date is not null
AND stop_execution_date is null;
USE distribution
GO

DECLARE @StartOrStop		sysname = N'START' -- or should be 'START' or 'STOP'
DECLARE @SubscriberServer	sysname = N'LADBREPORT'
DECLARE	@Publisher			sysname = N'ANY'

IF OBJECT_ID('tempdb..#AgentJobs') IS NOT NULL
	DROP TABLE #AgentJobs

SELECT	d.publication
	   ,d.local_job
	   ,d.publisher_db
	   ,d.job_id
	   ,ServerName = s.name
	   ,JObName = j.name
	   ,JobEnabled = j.enabled
INTO	#AgentJobs
FROM	distribution.dbo.MSdistribution_agents d
JOIN	master.sys.servers s ON d.subscriber_id = s.server_id
JOIN	msdb..sysjobs J ON J.job_id = d.job_id
WHERE	1 = 1
AND		((s.name = @SubscriberServer) OR (@SubscriberServer = N'ANY' AND s.name IS NOT NULL))
ORDER BY d.publication
	   ,s.name

DECLARE
	@publication sysname
   ,@subscriber sysname
   ,@local_job INT
   ,@publisher_db sysname
   ,@job_id UNIQUEIDENTIFIER
   ,@job_name sysname
   ,@sql VARCHAR(2000)
   ,@isRunning BIT
   ,@job_enabled BIT

DECLARE @StartStopProcName sysname

IF @StartOrStop = 'START'
	SET @StartStopProcName = N'sp_start_job'
ELSE IF @StartOrStop = 'STOP'
	SET @StartStopProcName = N'sp_stop_job'

IF OBJECT_ID('tempdb..#sql') IS NOT NULL
	DROP TABLE #sql
CREATE TABLE #sql (s VARCHAR(2000))

IF OBJECT_ID('tempdb..#xp_results') IS NOT NULL
	DROP TABLE #xp_results
CREATE TABLE #xp_results(
	 job_id UNIQUEIDENTIFIER NOT NULL
	,last_run_date INT NOT NULL
	,last_run_time INT NOT NULL
	,next_run_date INT NOT NULL
	,next_run_time INT NOT NULL
	,next_run_schedule_id INT NOT NULL
	,requested_to_run INT NOT NULL
	,request_source INT NOT NULL
	,request_source_id sysname COLLATE database_default NULL
	,running INT NOT NULL
	,current_step INT NOT NULL
	,current_retry_attempt INT NOT NULL
	,job_state INT NOT NULL)
 
DECLARE cr CURSOR FAST_FORWARD READ_ONLY LOCAL FOR
SELECT	publication
	   ,local_job
	   ,publisher_db
	   ,job_id
	   ,ServerName
	   ,JObName
	   ,JobEnabled
FROM	#AgentJobs
ORDER BY publication
	   ,ServerName
 
OPEN cr
FETCH NEXT FROM cr INTO @publication, @local_job, @publisher_db, @job_id, @subscriber, @job_name, @job_enabled
 
WHILE @@fetch_status = 0
BEGIN

	BEGIN TRY
		SET @isRunning = 0;
     
		INSERT	INTO #xp_results
		EXECUTE master.dbo.xp_sqlagent_enum_jobs 1 ,'sa', @job_id = @job_id
 
		SELECT	@isRunning = xpr.running                
		FROM	#xp_results xpr
		INNER	JOIN msdb.dbo.sysjobs_view sjv ON xpr.job_id = sjv.job_id
		WHERE	sjv.name = @job_name

	END TRY
	BEGIN CATCH
	END CATCH

	IF @local_job = 0
		SELECT	@sql = '
					SELECT 
						''EXECUTE ' + @subscriber + '.msdb.dbo.' + @StartStopProcName + ' '''''' + j.name + ''''''''
					FROM	distribution.dbo.MSdistribution_agents d 
					JOIN	msdb.dbo.sysjobs j ON d.job_id = j.job_id
					JOIN	master.sys.servers p on d.publisher_id	= p.server_id
					JOIN	master.sys.servers s ON s.server_id		= d.subscriber_id
					WHERE	d.publication = ''' + @publication + ''''
					+ CASE WHEN @Publisher = N'ANY' THEN ' AND p.name IS NOT NULL' ELSE ' and p.name = ''' + @Publisher + N'''' END
					+ CASE WHEN @SubscriberServer = N'ANY' THEN ' AND s.name IS NOT NULL' ELSE ' and s.name = ''' + @SubscriberServer + N'''' END
					+ ' and d.publisher_db = ''' + @publisher_db + ''''

	ELSE
		SELECT	@sql = '
					SELECT 
						''EXECUTE msdb.dbo.' + @StartStopProcName + ' '''''' + j.name + ''''''''
					FROM	distribution.dbo.MSdistribution_agents d 
					JOIN	msdb.dbo.sysjobs j ON d.job_id = j.job_id
					JOIN	master.sys.servers p on d.publisher_id	= p.server_id
					JOIN	master.sys.servers s ON s.server_id		= d.subscriber_id
					WHERE	d.publication = ''' + @publication + ''''
					+ CASE WHEN @Publisher = N'ANY' THEN ' AND p.name IS NOT NULL' ELSE ' and p.name = ''' + @Publisher + N'''' END
					+ CASE WHEN @SubscriberServer = N'ANY' THEN ' AND s.name IS NOT NULL' ELSE ' and s.name = ''' + @SubscriberServer + N'''' END
					+ ' and d.publisher_db = ''' + @publisher_db + ''''
  
  	IF @isRunning = 1
	BEGIN
		PRINT 'Job is Running:' + @job_name
		PRINT 'SQL:' + @sql
	END
	ELSE
		PRINT '**Job is NOT Running:' + @job_name

	IF @StartOrStop = 'STOP' AND @isRunning = 1
		INSERT	#sql
		EXECUTE (@sql)
	ELSE IF @StartOrStop = 'START' AND @isRunning = 0
		INSERT	#sql
		EXECUTE (@sql)
		  
	FETCH NEXT FROM cr INTO @publication, @local_job, @publisher_db, @job_id, @subscriber, @job_name, @job_enabled
  
END
CLOSE cr
DEALLOCATE cr

-- LIST OF JOBS to Start or STOP 
SELECT	*
FROM	#sql

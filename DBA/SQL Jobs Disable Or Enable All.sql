USE [msdb]
GO

DECLARE	@BatchName				VARCHAR(100)	= 'Repl Issue 10052015-2'
DECLARE @OnlyReplicationJobs	BIT				= 0 -- SET TO 1 to Enable/Disable only Replication Jobs
DECLARE	@Action					VARCHAR(100)	= 'ENABLE' -- SET to 'ENABLE' to enable Jobs or 'DISABLE' to Disable jobs
DECLARE @Debug					BIT				= 0 -- SET To 1 to see the script outputed instead of being applied

DECLARE @JobID UNIQUEIDENTIFIER

-- TRUNCATE TABLE mnDBA.dbo._NM_JobDisableLog

IF @Action = 'DISABLE'
BEGIN
	-- DROP TABLE mnDBA.dbo._NM_JobDisableLog
	IF OBJECT_ID('mnDBA.dbo._NM_JobDisableLog') IS NULL
	BEGIN
		CREATE TABLE mnDBA.dbo._NM_JobDisableLog
		(
			 JobEnableDisableLogId	INT			NOT NULL	IDENTITY(1, 1)
			,BatchName				SYSNAME		NOT NULL
			,ServerName				SYSNAME		NOT NULL
			,job_id					UNIQUEIDENTIFIER	NOT NULL
			,PrevEnabled			BIT			NOT NULL
			,jobName				SYSNAME		NOT NULL
			,category_id			INT			NOT NULL
			,category				sysname		NOT NULL
			,DisabledTime			DATETIME	NULL
			,EnableTime				DATETIME	NULL
			,CreatedDtTm			DATETIME	NOT NULL	CONSTRAINT DF_JobDisableEnableLog_CreatedtTm	DEFAULT GETDATE()
		)
		CREATE UNIQUE NONCLUSTERED INDEX [UNQ_DisableEnableJob] ON mnDBA.dbo._NM_JobDisableLog(BatchName, ServerName, job_id)
	END

	IF OBJECT_ID('tempdb..#Jobs') IS NOT NULL
		DROP TABLE #Jobs
	SELECT	job_id, enabled, SJ.name, SJ.category_id, category = SC.name
			,ReplicationJobs = CASE WHEN SC.name LIKE 'REPL%' THEN 1 ELSE 0 END
	INTO	#Jobs
	FROM	msdb.dbo.sysjobs	SJ
	JOIN	msdb.dbo.syscategories	SC	ON	SC.category_id = SJ.category_id
	WHERE	enabled = 1

	DECLARE @SQL VARCHAR(MAX)
	DECLARE OBJECT_CURSOR CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

	SELECT		job_id
	FROM		#Jobs
	WHERE		(
					((@OnlyReplicationJobs = 1) AND (ReplicationJobs = 1))
					OR
					(@OnlyReplicationJobs = 0)
				)

	OPEN OBJECT_CURSOR

	FETCH NEXT FROM OBJECT_CURSOR
	INTO @JobID

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SET @SQL = 'EXEC msdb.dbo.sp_update_job @job_id= N''' + CONVERT(VARCHAR(256), @JobID) + ''', @enabled=0'
		PRINT @SQL

		IF @Debug = 0	
			EXEC(@SQL)

		INSERT INTO mnDBA.dbo._NM_JobDisableLog
		SELECT	 BatchName		=	@BatchName
				,ServerName		=   @@SERVERNAME
				,job_id			=	job_id
				,PrevEnabled	=	Enabled
				,jobName		=	name
				,category_id
				,category
				,DisabledTime	=	GETDATE()
				,EnableTime		=	NULL
				,CreatedDtTm	=	GETDATE()
		FROM	#Jobs
		WHERE	Job_id = @JobID

		FETCH NEXT FROM OBJECT_CURSOR
		INTO @JobID
	END

	CLOSE OBJECT_CURSOR
	DEALLOCATE OBJECT_CURSOR

	SELECT 'DISABLED' AS Comments, * FROM mnDBA.dbo._NM_JobDisableLog WHERE BatchName = @BatchName AND ServerName = @@SERVERNAME
END
ELSE IF @Action = 'ENABLE'
BEGIN

	IF OBJECT_ID('mnDBA.dbo._NM_JobDisableLog') IS NULL
	BEGIN
		PRINT 'First Disable jobs to create logs'
		RAISERROR('First Disable jobs to create logs',1, 1)
	END
	ELSE
	BEGIN
		DECLARE @JobEnableDisableLogId INT

		IF OBJECT_ID('tempdb..#EnableJobs') IS NOT NULL
			DROP TABLE #EnableJobs
		SELECT	job_id, JobEnableDisableLogId
		INTO	#EnableJobs
		FROM	mnDBA.dbo._NM_JobDisableLog
		WHERE	BatchName	=	@BatchName
		AND		EnableTime IS NULL
		AND		PrevEnabled = 1
		AND		ServerName = @@SERVERNAME

		DECLARE @EnableSQL VARCHAR(1000)
		DECLARE OBJECT_CURSOR CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

		SELECT		job_id, JobEnableDisableLogId
		FROM		#EnableJobs


		OPEN OBJECT_CURSOR

		FETCH NEXT FROM OBJECT_CURSOR
		INTO @JobID, @JobEnableDisableLogId

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			SET @EnableSQL = 'EXEC msdb.dbo.sp_update_job @job_id=N''' + CONVERT(VARCHAR(256), @JobID) + ''', @enabled=1'
			PRINT @EnableSQL
	
			IF @Debug = 0	
				EXEC(@EnableSQL)

			UPDATE	mnDBA.dbo._NM_JobDisableLog
			SET		EnableTime		=	GETDATE()
			FROM	mnDBA.dbo._NM_JobDisableLog
			WHERE	JobEnableDisableLogId = @JobEnableDisableLogId

			FETCH NEXT FROM OBJECT_CURSOR
			INTO @JobID, @JobEnableDisableLogId
		END

		CLOSE OBJECT_CURSOR
		DEALLOCATE OBJECT_CURSOR

		SELECT 'Enabled' AS Comments, * FROM mnDBA.dbo._NM_JobDisableLog WHERE BatchName = @BatchName AND ServerName = @@SERVERNAME
	END
END

SELECT	*
FROM	msdb.dbo.sysjobs SJ
WHERE	EXISTS (SELECT 1 FROM mnDBA.dbo._NM_JobDisableLog WHERE ServerName = @@SERVERNAME AND SJ.job_id = job_id)
GO

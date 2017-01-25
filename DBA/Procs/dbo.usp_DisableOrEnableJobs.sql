USE mnDBA
GO
IF OBJECT_ID('dbo.usp_DisableOrEnableJobs') IS NOT NULL
	DROP PROCEDURE dbo.usp_DisableOrEnableJobs
--SET QUOTED_IDENTIFIER ON|OFF
--SET ANSI_NULLS ON|OFF
GO
CREATE PROCEDURE dbo.usp_DisableOrEnableJobs
(
	 @Reason				VARCHAR(100)	
	,@OnlyReplicationJobs	BIT						-- SET TO 1 to Enable/Disable only Replication Jobs
	,@EnableOrDisableJobs	VARCHAR(100)			-- SET to 'ENABLE' to enable Jobs or 'DISABLE' to Disable jobs
	,@Debug					BIT				= NULL	-- SET To 1 to see the script outputed instead of being applied

)
AS
EXECUTE AS CALLER
BEGIN

/*
	This script creates a table in mnDBA and stores the jobs that are being disabled or enabled. Make sure you change the Reason, Action and Debug flag to properly run.

	Example usage: Say you want to disable jobs do replace Network card. Then
		1. Set @Reason = 'Network card replacement'
		2. Set @OnlyReplicationJobs to 0
		3. Set @Action = 'Disable'
		4. Set @Debug = 0

	After maintanance is complete, you can  use same script except, Set @Action = 'Enable', to enable jobs that you 
	disabled for "replacing network card" then make sure your BatchName is set to "Network card replacement". If you use different Batch name then you might be enabling jobs
	based on some other days data.

	-- IN case you want to replace Network card again on the server on a different date , then make sure to update the @BatchName to something other than "Network Card replacement"

	-- The batch name should be unique between every pair of Disable/Enable to get consistent results.
*/

	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE  @ServerName		SYSNAME		= @@SERVERNAME
			,@Today				DATETIME	= GETDATE()

	DECLARE	@BatchName				VARCHAR(100)	= ISNULL(@Reason, '')
	DECLARE	@Action					VARCHAR(100)	= ISNULL(@EnableOrDisableJobs, '')
	DECLARE	@CreatedBy				SYSNAME			= COALESCE(SYSTEM_USER, CURRENT_USER, '')

	--DECLARE @OnlyReplicationJobs	BIT				= 0 -- SET TO 1 to Enable/Disable only Replication Jobs
	--DECLARE @Debug				BIT				= 0 -- SET To 1 to see the script outputed instead of being applied


	SET @OnlyReplicationJobs	= ISNULL(@OnlyReplicationJobs, 0)
	SET @Debug					= ISNULL(@Debug, 0)

	DECLARE @JobID UNIQUEIDENTIFIER

	IF ((LEN(@Action) = 0) OR (LEN(@Reason) = 0))
	BEGIN
		PRINT 'Please provide a valid Action and/or Reason'
		RAISERROR('Please provide a valid Action and/or Reason',1, 1)
		RETURN
	END


	IF EXISTS (SELECT * FROM dbo.DisableOrEnableJobLog WHERE Reason = @BatchName AND ServerName = @ServerName AND @Action = 'DISABLE')
	BEGIN
		PRINT 'Jobs are being disabled for same Reason : {' + @BatchName + '}. Please provide a different reason to disable/enable jobs'
		RAISERROR('Jobs were disabled for same Reason. Please provide a different reason to disable/enable jobs',1, 1)
		RETURN
	END

	IF @Action = 'DISABLE'
	BEGIN
		-- DROP TABLE mnDBA.dbo.DisableOrEnableJobLog
		IF OBJECT_ID('mnDBA.dbo.DisableOrEnableJobLog') IS NULL
		BEGIN
			CREATE TABLE mnDBA.dbo.DisableOrEnableJobLog
			(
				 JobEnableDisableLogId	INT					NOT NULL	IDENTITY(1, 1)
				,Reason					SYSNAME				NOT NULL
				,ServerName				SYSNAME				NOT NULL
				,job_id					UNIQUEIDENTIFIER	NOT NULL
				,PrevEnabled			BIT					NOT NULL
				,jobName				SYSNAME				NOT NULL
				,category_id			INT					NOT NULL
				,category				sysname				NOT NULL
				,DisabledTime			DATETIME			NULL
				,EnabledBy				SYSNAME				NULL
				,EnableTime				DATETIME			NULL
				,CreatedDtTm			DATETIME			NOT NULL	CONSTRAINT DF_DisableOrEnableJobLog_CreatedtTm	DEFAULT GETDATE()
				,CreatedBy				SYSNAME				NOT NULL
			)
			CREATE UNIQUE NONCLUSTERED INDEX [UNQ_DisableEnableJob] ON mnDBA.dbo.DisableOrEnableJobLog(Reason, ServerName, job_id)
		END

		IF OBJECT_ID('tempdb..#Jobs') IS NOT NULL
			DROP TABLE #Jobs
		SELECT	 job_id
				,enabled
				,SJ.name
				,SJ.category_id
				,category = SC.name
				,ReplicationJobs = CASE WHEN SC.name LIKE 'REPL%' THEN 1 ELSE 0 END
		INTO	#Jobs
		FROM	msdb.dbo.sysjobs	SJ
		JOIN	msdb.dbo.syscategories	SC	ON	SC.category_id = SJ.category_id
		WHERE	enabled = 1

		DECLARE @SQL VARCHAR(1000)
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
			SET @SQL = 'EXEC msdb.dbo.sp_update_job @job_id=''' + CONVERT(VARCHAR(256), @JobID) + ''', @enabled=0'
			PRINT @SQL

			IF @Debug = 0	
				EXEC(@SQL)

			INSERT INTO mnDBA.dbo.DisableOrEnableJobLog
			SELECT	 Reason			=	@BatchName
					,ServerName		=   @SERVERNAME
					,job_id			=	job_id
					,PrevEnabled	=	Enabled
					,jobName		=	name
					,category_id
					,category
					,DisabledTime	=	@TODAY
					,EnabledBy		=	NULL
					,EnableTime		=	NULL
					,CreatedDtTm	=	@TODAY
					,CreatedBy		=	@CreatedBy
			FROM	#Jobs
			WHERE	Job_id = @JobID

			FETCH NEXT FROM OBJECT_CURSOR
			INTO @JobID
		END

		CLOSE OBJECT_CURSOR
		DEALLOCATE OBJECT_CURSOR

		IF @Debug = 1
			SELECT 'DISABLED' AS Comments, * FROM mnDBA.dbo.DisableOrEnableJobLog WHERE Reason = @BatchName AND ServerName = @@SERVERNAME

	END
	ELSE IF @Action = 'ENABLE'
	BEGIN

		IF OBJECT_ID('mnDBA.dbo.DisableOrEnableJobLog') IS NULL
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
			FROM	mnDBA.dbo.DisableOrEnableJobLog
			WHERE	Reason	=	@BatchName
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
				SET @EnableSQL = 'EXEC msdb.dbo.sp_update_job @job_id=''' + CONVERT(VARCHAR(256), @JobID) + ''', @enabled=1'
				PRINT @EnableSQL
	
				IF @Debug = 0	
					EXEC(@EnableSQL)

				UPDATE	mnDBA.dbo.DisableOrEnableJobLog
				SET		EnableTime		=	@TODAY
						,EnabledBy		=	@CreatedBy
				FROM	mnDBA.dbo.DisableOrEnableJobLog
				WHERE	JobEnableDisableLogId = @JobEnableDisableLogId

				FETCH NEXT FROM OBJECT_CURSOR
				INTO @JobID, @JobEnableDisableLogId
			END

			CLOSE OBJECT_CURSOR
			DEALLOCATE OBJECT_CURSOR

			IF @Debug = 1
				SELECT 'Enabled' AS Comments, * FROM mnDBA.dbo.DisableOrEnableJobLog WHERE Reason = @BatchName AND ServerName = @@SERVERNAME
		END
	END
	ELSE
	BEGIN
			PRINT 'INVALID Actio passed in. Action can be either DISABLE or ENABLE'
			RAISERROR('INVALID Actio passed in. Action can be either DISABLE or ENABLE',1, 1)
	END

	IF @Debug = 1
		SELECT	sComments = 'Current state of jobs', *
		FROM	msdb.dbo.sysjobs SJ
		WHERE	EXISTS (SELECT 1 FROM mnDBA.dbo.DisableOrEnableJobLog WHERE Reason = @BatchName AND ServerName = @@SERVERNAME AND SJ.job_id = job_id)

END
GO

/*
	Testing code

	-- TO DISABLE
	EXEC dbo.usp_DisableOrEnableJobs @Reason = 'ADD MORE RAM2', -- varchar(100)
		@OnlyReplicationJobs = 0, -- bit
		@EnableOrDisableJobs = 'DISABLE', -- varchar(100)
		@Debug = 0 -- bit

	-- TO ENABLE
	EXEC dbo.usp_DisableOrEnableJobs @Reason = 'ADD MORE RAM2', -- varchar(100)
		@OnlyReplicationJobs = 0, -- bit
		@EnableOrDisableJobs = 'ENABLE', -- varchar(100)
		@Debug = 0 -- bit

*/
GO

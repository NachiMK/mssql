/*
	Purpose: Disable/Enable Prod Flat Jobs

	generally used when a new attribute is added.

*/
USE [msdb]
GO

DECLARE @Action		VARCHAR(100)	=	'ENABLE'
--DECLARE @Action		VARCHAR(100)	=	'ENABLE'
DECLARE @StopJob	BIT				=	0
DECLARE @Debug		BIT				=	0

DECLARE	@ActionTaken	BIT				=	0

IF OBJECT_ID('tempdb..#TmpJobs') IS NOT NULL
	DROP TABLE #TmpJobs
SELECT	job_id, JobName = name, enabled, ActionTaken = CONVERT(BIT, NULL), ActionTakeDtTm = CONVERT(DATETIME, NULL), JobStopped = CONVERT(BIT, NULL)
INTO	#TmpJobs
FROM	msdb.dbo.sysjobs
WHERE	name LIKE 'Flat mnMember%'


SELECT 'BEFORE Taking any action' AS Comment,* FROM #TmpJobs

DECLARE	 @Job_Id				UNIQUEIDENTIFIER
		,@JobName				sysname
		,@JobEnabled			TINYINT

DECLARE OBJECT_CURSOR CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

SELECT		 job_id, JobName, enabled
FROM		#TmpJobs

OPEN OBJECT_CURSOR

FETCH NEXT FROM OBJECT_CURSOR
INTO @Job_Id, @JobName, @JobEnabled

WHILE (@@FETCH_STATUS = 0)
BEGIN

	PRINT '------------------------'
	PRINT 'Job ID:' + CONVERT(VARCHAR(256), @Job_Id) + ' Job Name:' + @JobName + ' Enabled:' + CONVERT(VARCHAR, @JobEnabled)


	-- DISABLE JOB IF REQUESTED AND AS WELL IF ENABLED
	IF @Action = 'DISABLE'
	BEGIN
		IF @JobEnabled = 1
		BEGIN
			IF @Debug = 0
			BEGIN
				EXEC msdb.dbo.sp_update_job @job_id=@Job_Id, @enabled = 0
				SET @ActionTaken = 1
			END
			PRINT 'Job ID:' + CONVERT(VARCHAR(256), @Job_Id) + ' Job Name:' + @JobName + ' called Update job Proc to Disable.'
		END
		ELSE
			PRINT 'Job ID:' + CONVERT(VARCHAR(256), @Job_Id) + ' Job Name:' + @JobName + ' Already disabled.'
	END


	-- ENABLE JOB IF REQUESTED AND AS WELL IF DISABLED
	IF @Action = 'ENABLE'
	BEGIN
		IF @JobEnabled = 0
		BEGIN
			IF @Debug = 0
			BEGIN
				EXEC msdb.dbo.sp_update_job @job_id=@Job_Id, @enabled = 1
				SET @ActionTaken = 1
			END
			PRINT 'Job ID:' + CONVERT(VARCHAR(256), @Job_Id) + ' Job Name:' + @JobName + ' called Update job Proc to Enable.'
		END
		ELSE
			PRINT 'Job ID:' + CONVERT(VARCHAR(256), @Job_Id) + ' Job Name:' + @JobName + ' already ENABLED.'
	END

	IF @Action NOT IN ('DISABLE', 'ENABLE')
		PRINT 'Job ID:' + CONVERT(VARCHAR(256), @Job_Id) + ' Job Name:' + @JobName + ' WAS NOT ENABLED OR DISABLED. PLEASE SPECIFIY CORRECT OPTION'


	IF @StopJob = 1
	BEGIN
		PRINT 'Stopping JOB Job ID:' + CONVERT(VARCHAR(256), @Job_Id) + ' Job Name:' + @JobName
		IF @Debug = 0
		BEGIN
			EXEC msdb.dbo.sp_stop_job @job_id = @Job_Id
			UPDATE #TmpJobs SET JobStopped = 1 WHERE job_id = @Job_Id
		END
		PRINT 'Job ID:' + CONVERT(VARCHAR(256), @Job_Id) + ' Job Name:' + @JobName + ' WAS STOPPED'
	END

	IF @ActionTaken = 1
	BEGIN
		UPDATE #TmpJobs SET ActionTaken = 1, ActionTakeDtTm = GETDATE() WHERE job_id = @Job_Id
		SET @ActionTaken = 0
	END

	PRINT '------------------------'
    
	FETCH NEXT FROM OBJECT_CURSOR
	INTO @Job_Id, @JobName, @JobEnabled
END

CLOSE OBJECT_CURSOR
DEALLOCATE OBJECT_CURSOR


-- RESULTS
SELECT 'RESULT' AS Comment, * FROM #TmpJobs
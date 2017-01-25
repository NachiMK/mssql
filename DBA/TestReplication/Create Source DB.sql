/*

USE TestRepl
GO

IF OBJECT_ID('dbo.ProdFlat') IS NOT NULL

	DROP TABLE dbo.ProdFlat
CREATE TABLE dbo.ProdFlat
(
	 ProdFlatId	INT					IDENTITY(1, 1)
	,IntValue	BIGINT				NOT NULL
	,DateValue	DATETIMEOFFSET		NOT NULL
)

IF OBJECT_ID('dbo.usp_Insert_ProdFlat') IS NOT NULL
	DROP PROCEDURE dbo.usp_Insert_ProdFlat
GO
CREATE PROCEDURE dbo.usp_Insert_ProdFlat
AS
BEGIN
	SET NOCOUNT ON
	INSERT INTO dbo.ProdFlat
			(IntValue, DateValue)
	SELECT	CONVERT(BIGINT, HASHBYTES('SHA1', CONVERT(VARCHAR(256), NEWID()))), GETDATE()
END
GO

CREATE PROCEDURE dbo.usp_DELETE_ProdFlat
AS
BEGIN
	SET NOCOUNT ON

	DELETE	dbo.ProdFlat 
	FROM	dbo.ProdFlat P1
	WHERE	EXISTS (SELECT TOP 1 * FROM dbo.ProdFlat P2 WHERE P1.ProdFlatId = P2.ProdFlatId AND P2.DateValue < DATEADD(mi, -10, GETDATE()))

END


USE [msdb]
GO

--/****** Object:  Job [Test Repl dbo.usp_Insert_ProdFlat]    Script Date: 11/3/2015 8:20:09 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
--/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 11/3/2015 8:20:09 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Test Repl dbo.usp_Insert_ProdFlat', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
--/****** Object:  Step [Call SP dbo.usp_Insert_ProdFlat to Test Replication]    Script Date: 11/3/2015 8:20:10 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Call SP dbo.usp_Insert_ProdFlat to Test Replication', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.usp_Insert_ProdFlat', 
		@database_name=N'TestRepl', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

*/

/*
USE [msdb]
GO

/****** Object:  Job [TestRepl Delete ProdFlat]    Script Date: 11/3/2015 8:55:02 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 11/3/2015 8:55:02 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'TestRepl Delete ProdFlat', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [TestRepl Delete Rows Run SP dbo.usp_DELETE_ProdFlat]    Script Date: 11/3/2015 8:55:02 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'TestRepl Delete Rows Run SP dbo.usp_DELETE_ProdFlat', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.usp_DELETE_ProdFlat', 
		@database_name=N'TestRepl', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 10 minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20151103, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'9518644c-1064-423f-a79d-0ef5a27c9dc8'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
*/

SELECT * FROM ProdFlat
SELECT TOP 10 * FROM LADATAMART01.TestRepl_Archive.dbo.ProdFlat ORDER BY 1 desc
SELECT * FROM LADATAMART01.TestRepl.dbo.ProdFlat

-- TRUNCATE TABLE ProdFlat
/*

USE TestRepl
GO

EXEC sp_dropsubscription 
  @publication = N'TestRepl ProdFlat to LADataMart01', 
  @article = N'all',
  @subscriber = N'LADataMart01';
GO

exec mnDBA.dbo.[usp_replication_config_subscriber] 
@p_pubserver  = 'LACubeData01', 
@p_subserver  = 'LADataMart01',
@p_pubdb   = 'TestRepl',
@p_subdb   = 'TestRepl',
@p_sublogin  = 'sql_replication',
@p_subpassword  = '~BHGj0Kr',
@p_publication   = 'TestRepl ProdFlat to LADataMart01',
@p_sync_replication_support_only = 'YES'

*/
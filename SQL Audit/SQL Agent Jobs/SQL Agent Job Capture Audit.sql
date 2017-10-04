USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'DataSeed Audit Table Usage', 
		@enabled=0, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'This job will enable auditing on few databases at a time, monitor data, and enable audit as required on remaining databases.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'DataSeed Audit Table Usage', @server_name = N'739781-SQLCLUS'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'DataSeed Audit Table Usage', @step_name=N'Run SP - usp_DataSeed_SQLAuditing_AllDatabases', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
DECLARE @Debug		BIT		= 0
DECLARE @ArchivePath		NVARCHAR(MAX)	= N''\\server\prod_audit\Archive\ ''
DECLARE @NewAuditPath		NVARCHAR(300)	= N''G:\SQL_AUDIT\TableUsage\''
DECLARE @MaxFileSizeInMB	INT		= 100
DECLARE @MaxFiles			INT		= 10
DECLARE @MinNumberOfDBAuditAllowed	TINYINT	= 3

EXEC [dbo].[usp_DataSeed_SQLAuditing_AllDatabases]
	 @ArchivePath		= @ArchivePath
	,@NewAuditPath		= @NewAuditPath
	,@MaxFileSizeInMB	= @MaxFileSizeInMB
	,@MaxFiles			= @MaxFiles
	,@MinNumberOfDBAuditAllowed	= @MinNumberOfDBAuditAllowed
	,@Debug				= @Debug
', 
		@database_name=N'DBATools', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'DataSeed Audit Table Usage', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'This job will enable auditing on few databases at a time, monitor data, and enable audit as required on remaining databases.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'', 
		@notify_netsend_operator_name=N'', 
		@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DataSeed Audit Table Usage', @name=N'Run Every 3 minutes - Starting at 2.03am PT', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=3, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20170929, 
		@active_end_date=20171016, 
		@active_start_time=20300, 
		@active_end_time=15959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO

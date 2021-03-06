USE [msdb]
GO
--EXEC msdb.dbo.sp_delete_job @job_name=N'DBA Collect Server Stats - Blitz', @delete_history = 1, @delete_unused_schedule = 1
--GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'DBA Collect Server Stats - Blitz', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'This job runs sp_BlitzFirst and saves the output to Tables in mnDBA.', 
		@category_name=N'Data Collector', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Database Engineers', @job_id = @jobId OUTPUT
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'DBA Collect Server Stats - Blitz', @server_name = @@SERVERNAME
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'DBA Collect Server Stats - Blitz', @step_name=N'Call SP - Collect Blitz Output', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC Perf.usp_CollectBlitzFirst
', 
		@database_name=N'mnDBA', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'DBA Collect Server Stats - Blitz', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'This job runs sp_BlitzFirst and saves the output to Tables in mnDBA.', 
		@category_name=N'Data Collector', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Database Engineers', 
		@notify_netsend_operator_name=N'', 
		@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DBA Collect Server Stats - Blitz', @name=N'Collect Server Stats Every 30 minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20160914, 
		@active_end_date=99991231, 
		@active_start_time=500, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO

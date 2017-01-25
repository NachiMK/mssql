CREATE EVENT SESSION [LASQL09_xEvents_PerfMetrics] ON SERVER 
ADD EVENT sqlos.wait_info(
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text)
    WHERE (((([package0].[greater_than_uint64]([sqlserver].[database_id],(4)))) AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))) AND ([sqlserver].[database_id]>(4)))),
ADD EVENT sqlserver.rpc_completed(
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text)
    WHERE (((([package0].[greater_than_uint64]([sqlserver].[database_id],(4)))) AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))) AND ([sqlserver].[database_id]>(4)))),
ADD EVENT sqlserver.sp_statement_completed(SET collect_object_name=(1),collect_statement=(1)
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text)
    WHERE (((([package0].[greater_than_uint64]([sqlserver].[database_id],(4)))) AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))) AND ([sqlserver].[database_id]>(4)))),
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text)
    WHERE (((([package0].[greater_than_uint64]([sqlserver].[database_id],(4)))) AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))) AND ([sqlserver].[database_id]>(4)))) 
ADD TARGET package0.event_file(SET FILENAME=N'C:\DBA\xEvents\LASQL09_xEvents_09142016_0600PMPT.xel',MAX_ROLLOVER_FILES=(10))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=10 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
GO

ALTER EVENT SESSION [LASQL09_xEvents_PerfMetrics] ON SERVER 
STATE = START;
GO

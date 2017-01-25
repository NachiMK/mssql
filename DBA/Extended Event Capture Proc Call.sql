CREATE EVENT SESSION [CaptureMessageSaveProc] ON SERVER 
ADD EVENT sqlserver.module_end(SET collect_statement=(1)
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text)
    WHERE ((([package0].[greater_than_uint64]([sqlserver].[database_id],(4))) AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))) AND (([sqlserver].[like_i_sql_unicode_string]([sqlserver].[database_name],N'mnMember')) AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'up_MemberAttribute_Save_Multiple'))))),
ADD EVENT sqlserver.rpc_completed(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text)
    WHERE ((([package0].[greater_than_uint64]([sqlserver].[database_id],(4))) AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))) AND (([sqlserver].[like_i_sql_unicode_string]([sqlserver].[database_name],N'mnMember')) AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'up_MemberAttribute_Save_Multiple'))))),
ADD EVENT sqlserver.sp_statement_completed(SET collect_object_name=(1)
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text)
    WHERE ((([package0].[greater_than_uint64]([sqlserver].[database_id],(4))) AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))) AND (([sqlserver].[like_i_sql_unicode_string]([sqlserver].[database_name],N'mnMember')) AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'up_MemberAttribute_Save_Multiple'))))),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text)
    WHERE ((([package0].[greater_than_uint64]([sqlserver].[database_id],(4))) AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))) AND (([sqlserver].[like_i_sql_unicode_string]([sqlserver].[database_name],N'mnMember')) AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'up_MemberAttribute_Save_Multiple'))))),
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text)
    WHERE ((([package0].[greater_than_uint64]([sqlserver].[database_id],(4))) AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))) AND (([sqlserver].[like_i_sql_unicode_string]([sqlserver].[database_name],N'mnMember')) AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'up_MemberAttribute_Save_Multiple'))))) 
ADD TARGET package0.event_file(SET FILENAME=N'Z:\up_MemberAttribute_Save_Multiple.xel',max_file_size=(100),max_rollover_files=(10)),
ADD TARGET package0.ring_buffer
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
GO



ALTER EVENT SESSION [CaptureMessageSaveProc] ON SERVER 
DROP EVENT sqlserver.module_end, DROP EVENT sqlserver.sp_statement_completed, DROP EVENT sqlserver.sp_statement_starting
ALTER EVENT SESSION [CaptureMessageSaveProc] ON SERVER 
ADD EVENT sqlserver.module_end(SET collect_statement=(1)
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text)
    WHERE ((([package0].[greater_than_uint64]([sqlserver].[database_id],(4))) AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))) AND (([sqlserver].[like_i_sql_unicode_string]([sqlserver].[database_name],N'mnMember%')) AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%up_MemberAttribute_Save_Multiple%'))))), ADD EVENT sqlserver.sp_statement_completed(SET collect_object_name=(1)
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text)
    WHERE ((([package0].[greater_than_uint64]([sqlserver].[database_id],(4))) AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))) AND (([sqlserver].[like_i_sql_unicode_string]([sqlserver].[database_name],N'mnMember%')) AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%up_MemberAttribute_Save_Multiple%'))))), ADD EVENT sqlserver.sp_statement_starting(SET collect_statement=(1)
    WHERE (([sqlserver].[like_i_sql_unicode_string]([sqlserver].[database_name],N'mnMember%')) AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'up_MemberAttribute_Save_Multiple%'))))
GO



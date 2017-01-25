CREATE EVENT SESSION [CLSQL76.Logins] ON SERVER 
ADD EVENT sqlserver.connectivity_ring_buffer_recorded(
    ACTION(sqlserver.client_app_name,sqlserver.client_connection_id,sqlserver.client_hostname,sqlserver.context_info,sqlserver.database_name,sqlserver.is_system,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.username)
    WHERE ([sqlserver].[username]<>N'sql_replication')),
ADD EVENT sqlserver.login(SET collect_options_text=(1)
    ACTION(sqlserver.client_app_name,sqlserver.client_connection_id,sqlserver.client_hostname,sqlserver.context_info,sqlserver.database_name,sqlserver.is_system,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.username)
    WHERE ([sqlserver].[client_hostname]<>N'CLSQL76')) 
ADD TARGET package0.event_file(SET filename=N'G:\SQL_Profiler\CLSQL76.Logins',max_rollover_files=(3)),
ADD TARGET package0.ring_buffer
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
GO


ALTER EVENT SESSION [CLSQL76.Logins]
ON SERVER
STATE = START

ALTER EVENT SESSION [CLSQL76.Logins]
ON SERVER
STATE = STOP

DROP EVENT SESSION [CLSQL76.Logins]
ON SERVER

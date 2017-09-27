USE [master]
GO

-- Check the audit for the filtered content  
SELECT	 database_principal_id
		,database_name
		,schema_name
		,object_name
		,statement
		,file_name
		,succeeded
		,action_id
FROM	fn_get_audit_file('C:\SQL\SQL_AUDIT\ServerAudit_Test_TableUsuage_*.sqlaudit', default, default)
WHERE	1 = 1
-- Database
AND		database_name	=	'Project'
-- Schema
AND		schema_name		=	'dbo'
-- DB Operation was done by some DB user
AND		database_principal_id > 0
;  
GO

USE Assets
GO
DECLARE  @Sql_DB_LogFileNamePath	NVARCHAR(500)
SELECT	 @Sql_DB_LogFileNamePath	= REPLACE(SFA.log_file_path + SFA.log_file_name, N'.sqlaudit', '*.sqlaudit')
FROM	sys.database_audit_specifications	DBAS
JOIN	sys.server_audits							SA	ON	SA.audit_guid	= DBAS.audit_guid
JOIN	sys.dm_server_audit_status					SAS	ON	SAS.audit_id	= SA.audit_id
JOIN	sys.server_file_audits						SFA	ON	SFA.audit_id	= SAS.audit_id
WHERE	1 = 1
AND		SA.type		= N'FL'
AND		DBAS.name	= N'DB_Audit_Assets_TableUsuage'
AND		DBAS.is_state_enabled	= 1

SELECT	 database_name
		,schema_name
		,object_name
		,AuditDate	 = CONVERT(DATE, event_time)
		,SelectCount = SUM(CASE WHEN action_id = 'SL' THEN 1 ELSE 0 END)
		,InsertCount = SUM(CASE WHEN action_id = 'IN' THEN 1 ELSE 0 END)
		,DeleteCount = SUM(CASE WHEN action_id = 'DL' THEN 1 ELSE 0 END)
		,UpdateCount = SUM(CASE WHEN action_id = 'UP' THEN 1 ELSE 0 END)
		,OtherCount  = SUM(CASE WHEN action_id NOT IN ('SL','IN','DL','UP') THEN 1 ELSE 0 END)
FROM	sys.fn_get_audit_file(@Sql_DB_LogFileNamePath, default, default) AR
WHERE	1 = 1
GROUP BY
		database_name, schema_name, object_name, convert(date,  event_time)
ORDER BY
		database_name, schema_name, object_name, AuditDate

USE Assets
GO
SELECT	 DatabaseName			= DB_NAME()
		,DatabaseId				= DB_ID()
		,AuditStatus			= CASE WHEN SAS.status_desc = N'STARTED' THEN 'RUNNING' ELSE 'STOPPED' END

		,AllowedMaxFileSizeInBytes	= SFA.max_file_size * 1000.0 * 1000.0
		,LatestFileSize				= SAS.audit_file_size
		,SpaceRemainingInLastFile	= CASE WHEN (SFA.max_file_size * 1000.0 * 1000.0) - SAS.audit_file_size > 0 
											THEN (SFA.max_file_size * 1000.0 * 1000.0) - SAS.audit_file_size
											ELSE 0 END

		,NOofFilesAllowed		= SFA.max_files
		,NoOfLogFilesCreated	= F.NoOfFiles
		,MaxFileCountReached	= CASE WHEN ISNULL(F.NoOfFiles, 0) = SFA.max_files THEN 'YES' ELSE 'NO' END
		,CanAuditGrow			= CASE WHEN (SAS.status_desc != N'STARTED') OR (ISNULL(F.NoOfFiles, 0) = SFA.max_files)
										OR (((SFA.max_file_size * 1000.0 * 1000.0) - SAS.audit_file_size) <= 0 )
										THEN 'NO'
										ELSE 'Yes'
								  END
		,DBAuditName			= DBAS.name
		,DBAuditCreateDate		= DBAS.create_date
		,DBAuditEnabled			= DBAS.is_state_enabled
		,ServerAuditName		= SA.name
		,ServerAuditEnabled		= SA.is_state_enabled
		,LogFilePath			= SFA.log_file_path
		,LogFile				= SFA.log_file_name
		,LogFileFullPath		= REPLACE(SFA.log_file_path + SFA.log_file_name, N'.sqlaudit', '*.sqlaudit')
		,AuditStatusTime		= SAS.status_time
		,LatestFileFullPath		= SAS.audit_file_path

FROM	sys.database_audit_specifications	DBAS
JOIN	sys.server_audits							SA	ON	SA.audit_guid	= DBAS.audit_guid
JOIN	sys.dm_server_audit_status					SAS	ON	SAS.audit_id	= SA.audit_id
JOIN	sys.server_file_audits						SFA	ON	SFA.audit_id	= SAS.audit_id
OUTER	APPLY
		(
			SELECT  NoOfFiles	=	COUNT(DISTINCT file_name)
			FROM	sys.fn_get_audit_file(REPLACE(SFA.log_file_path + SFA.log_file_name, N'.sqlaudit', '*.sqlaudit'), default, default)

		)	F
WHERE	SA.type		= N'FL'
AND		DBAS.name	= N'DB_Audit_Assets_TableUsuage'
AND		DBAS.is_state_enabled	= 1


SELECT * FROM sys.server_audits
SELECT * FROM sys.server_file_audits
SELECT * FROM sys.dm_server_audit_status

SELECT  DISTINCT file_name
FROM	sys.fn_get_audit_file('C:\SQL\SQL_AUDIT\TableUsage\*.sqlaudit', default, default)


SELECT  *
FROM	sys.fn_get_audit_file('C:\SQL\SQL_AUDIT\TableUsage\*.sqlaudit', default, default)



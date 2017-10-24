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

-- What was audited so far, from all files in a given audit/database.
USE Carteasy
GO
DECLARE  @Sql_DB_LogFileNamePath	NVARCHAR(500)
SELECT	 @Sql_DB_LogFileNamePath	= REPLACE(SFA.log_file_path + SFA.log_file_name, N'.sqlaudit', '*.sqlaudit')
FROM	sys.database_audit_specifications	DBAS
JOIN	sys.server_audits							SA	ON	SA.audit_guid	= DBAS.audit_guid
JOIN	sys.dm_server_audit_status					SAS	ON	SAS.audit_id	= SA.audit_id
JOIN	sys.server_file_audits						SFA	ON	SFA.audit_id	= SAS.audit_id
WHERE	1 = 1
AND		SA.type		= N'FL'
AND		DBAS.name	LIKE N'DB_Audit_%_TableUsuage'
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

-- Summary information of the audit
USE CartEasy
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
AND		DBAS.name	LIKE N'DB_Audit_%_TableUsuage'
AND		DBAS.is_state_enabled	= 1

-- Tables Audited.
SELECT	 TableName = T.name
		,TableType = T.type
		,Cnt	   = ISNULL(DASD.Cnt, 0)
		,AuditEnabled = CASE WHEN DASD.Cnt > 0 THEN 'YES' ELSE 'NO' END
		,InAuditSummary	= CASE WHEN DS.Id IS NOT NULL THEN 'YES' ELSE 'NO' END
		,DS.SelectCount
		,DS.InsertCount
		,DS.DeleteCount
		,DS.UpdateCount
FROM	sys.tables	T
OUTER	APPLY
		(
			SELECT	 Cnt = Count(s.audit_action_id)
			FROM	sys.database_audit_specification_details	S
			WHERE	S.major_id = T.object_id
		)	DASD
OUTER	APPLY
		(
			SELECT	*
			FROM	DBA.dbo.DataSeedAuditSummary	D1
			WHERE	D1.DatabaseName = DB_NAME()
			AND		D1.ObjectName	= T.name
		) DS
WHERE	T.name NOT LIKE 'MSpeer%'
AND		T.name NOT LIKE 'sys%'
ORDER BY
	 AuditEnabled DESC
	,TableName


-- individual audit tables
SELECT * FROM sys.server_audits
SELECT * FROM sys.server_file_audits
SELECT * FROM sys.dm_server_audit_status

SELECT * FROM sys.database_audit_specifications
SELECT * FROM sys.database_audit_specification_details

-- GEt only distinct audit files details of a server audit
SELECT  DISTINCT file_name
FROM	sys.fn_get_audit_file('C:\SQL\SQL_AUDIT\TableUsage\*Assets*.sqlaudit', default, default)

-- GEt all audit details of a server audit
SELECT  *
FROM	sys.fn_get_audit_file('C:\SQL\SQL_AUDIT\TableUsage\*Assets*.sqlaudit', default, default)


-- View Percentage of tables being audited right now
use master
IF OBJECT_ID('tempdb..#TblPct') IS NOT NULL
	DROP TABLE #TblPct
CREATE TABLE #TblPct
(
	 DatabaseName	SYSNAME
	,Pct			NUMERIC(22, 2)
)
DECLARE @SQL NVARCHAR(MAX) = 
N'
USE ?
;WITH CTETables
AS
(
	SELECT	T.object_id
	FROM	sys.tables				AS	T
	JOIN	sys.schemas				AS	S	ON S.schema_id = T.schema_id
	LEFT
	JOIN	sys.extended_properties	AS	EP	ON EP.major_id = T.[object_id]
	WHERE	(
				EP.class_desc IS NULL 
			OR (
					EP.class_desc <> ''OBJECT_OR_COLUMN''
				AND EP.[name] <> ''microsoft_database_tools_support''
				)
			)

)
INSERT INTO #TblPct
SELECT	DatabaseName = DB_NAME(), CONVERT(NUMERIC(22, 2), COUNT(distinct major_id)) / (SELECT CONVERT(NUMERIC(22, 2), COUNT(*)) FROM CTETables) * 100.00
FROM	sys.database_audit_specification_details	S
WHERE	EXISTS (SELECT * FROM CTETables T WHERE T.object_id = s.major_id)
'
EXEC dbo.sp_foreachdb @command = @SQL, @user_only = 1, @database_list = N'Amazon,ASPNetServices,ASPState,Assets,Carteasy,CentennialDesks,ColoExternalActivation'


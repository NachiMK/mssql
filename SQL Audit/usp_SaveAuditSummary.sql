--USE DBATools
--GO
--IF OBJECT_ID('dbo.usp_SaveAuditSummary') IS NOT NULL
--	DROP PROCEDURE dbo.usp_SaveAuditSummary
--GO
CREATE PROCEDURE dbo.usp_SaveAuditSummary
(
	 @DatabaseName		NVARCHAR(1000)
	,@DBAuditName		NVARCHAR(300)
	,@Debug				BIT	=	NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @AuditDisableSQL NVARCHAR(MAX)

	IF OBJECT_ID('DBA.dbo.DataSeedAuditSummary') IS NULL
		CREATE TABLE DBA.dbo.DataSeedAuditSummary
		(
			 Id				BIGINT	NOT NULL IDENTITY(1, 1)
			,DatabaseName	SYSNAME	NOT NULL
			,SchemaName		SYSNAME	NOT NULL
			,ObjectName		SYSNAME	NOT NULL
			,LastAudidDate	DATE	NOT NULL
			,SelectCount	BIGINT	NOT NULL
			,InsertCount	BIGINT	NOT NULL
			,DeleteCount	BIGINT	NOT NULL
			,UpdateCount	BIGINT	NOT NULL
			,OtherCount		BIGINT	NOT NULL
			,PRIMARY KEY CLUSTERED (DatabaseName, SchemaName, ObjectName)
		)
	
	IF OBJECT_ID('DBA.dbo.DataSeedAuditFiles') IS NULL
		CREATE TABLE DBA.dbo.DataSeedAuditFiles
		(
			 Id				BIGINT			NOT NULL IDENTITY(1, 1)
			,DatabaseName	SYSNAME			NOT NULL
			,AuditName		NVARCHAR(500)	NOT NULL
			,FileName		NVARCHAR(500)	NOT NULL
		)

	SET @AuditDisableSQL = 
	N'
	USE [?]

	DECLARE @NameOfAudit NVARCHAR(300) = ''@DBAuditName''

	DECLARE  @Sql_DB_LogFileNamePath	NVARCHAR(500)

	SELECT	 @Sql_DB_LogFileNamePath	= REPLACE(SFA.log_file_path + SFA.log_file_name, N''.sqlaudit'', ''*.sqlaudit'')
	FROM	sys.database_audit_specifications	DBAS
	JOIN	sys.server_audits							SA	ON	SA.audit_guid	= DBAS.audit_guid
	JOIN	sys.dm_server_audit_status					SAS	ON	SAS.audit_id	= SA.audit_id
	JOIN	sys.server_file_audits						SFA	ON	SFA.audit_id	= SAS.audit_id
	WHERE	1 = 1
	AND		SA.type		= N''FL''
	AND		DBAS.name	= @NameOfAudit

	IF @Debug = 1
		PRINT ''Audit File Path:'' + @Sql_DB_LogFileNamePath

	INSERT INTO
			DBA.dbo.DataSeedAuditFiles
			(
			 DatabaseName
			,AuditName
			,FileName
			)
	SELECT	 DISTINCT 
			 DatabaseName = database_name
			,@NameOfAudit
			,FileName = AR.file_name
	FROM	sys.fn_get_audit_file(@Sql_DB_LogFileNamePath, default, default) AR

	;MERGE DBA.dbo.DataSeedAuditSummary TGT	USING (			SELECT	 DatabaseName = database_name
					,SchemaName   = schema_name
					,ObjectName   = object_name
					,LastAuditDate= MAX(CONVERT(DATE, event_time))
					,SelectCount = ISNULL(SUM(CASE WHEN action_id = ''SL'' THEN 1 ELSE 0 END), 0)
					,InsertCount = ISNULL(SUM(CASE WHEN action_id = ''IN'' THEN 1 ELSE 0 END), 0)
					,DeleteCount = ISNULL(SUM(CASE WHEN action_id = ''DL'' THEN 1 ELSE 0 END), 0)
					,UpdateCount = ISNULL(SUM(CASE WHEN action_id = ''UP'' THEN 1 ELSE 0 END), 0)
					,OtherCount  = ISNULL(SUM(CASE WHEN action_id NOT IN (''SL'',''IN'',''DL'',''UP'') THEN 1 ELSE 0 END), 0)
			FROM	sys.fn_get_audit_file(@Sql_DB_LogFileNamePath, default, default) AR
			WHERE	1 = 1
			GROUP BY
					database_name, schema_name, object_name
		)	SRC		(			 DatabaseName			,SchemaName			,ObjectName			,LastAudidDate			,SelectCount			,InsertCount			,DeleteCount			,UpdateCount			,OtherCount		)		ON	TGT.DatabaseName = SRC.DatabaseName		AND	TGT.SchemaName	 = SRC.SchemaName		AND TGT.ObjectName	 = SRC.ObjectName		WHEN MATCHED AND (			(SRC.LastAudidDate	<>	TGT.LastAudidDate)		OR	(SRC.SelectCount	<>	TGT.SelectCount)		OR	(SRC.InsertCount	<>	TGT.InsertCount)		OR	(SRC.DeleteCount	<>	TGT.DeleteCount)		OR	(SRC.UpdateCount	<>	TGT.UpdateCount)		OR	(SRC.OtherCount		<>	TGT.OtherCount)		) THEN		UPDATE SET			 TGT.LastAudidDate	=	SRC.LastAudidDate			,TGT.SelectCount	=	TGT.SelectCount + SRC.SelectCount			,TGT.InsertCount	=	TGT.InsertCount + SRC.InsertCount			,TGT.DeleteCount	=	TGT.DeleteCount + SRC.DeleteCount			,TGT.UpdateCount	=	TGT.UpdateCount + SRC.UpdateCount			,TGT.OtherCount		=	TGT.OtherCount  + SRC.OtherCount		WHEN NOT MATCHED BY TARGET THEN		INSERT ( 			 DatabaseName			,SchemaName			,ObjectName			,LastAudidDate			,SelectCount			,InsertCount			,DeleteCount			,UpdateCount			,OtherCount		)	VALUES ( 			 SRC.DatabaseName			,SRC.SchemaName			,SRC.ObjectName			,SRC.LastAudidDate			,SRC.SelectCount			,SRC.InsertCount			,SRC.DeleteCount			,SRC.UpdateCount			,SRC.OtherCount		)		;'
	
	SET @AuditDisableSQL = REPLACE(@AuditDisableSQL, '?', @DatabaseName)
	SET @AuditDisableSQL = REPLACE(@AuditDisableSQL, '@Debug', @Debug)
	SET @AuditDisableSQL = REPLACE(@AuditDisableSQL, '@DBAuditName', @DBAuditName)

	IF @Debug = 1
	BEGIN
		PRINT '--- Save Audit Summary ----'
		PRINT @AuditDisableSQL
		PRINT '--- Save Audit Summary  ----'
	END

	EXEC sp_executesql @AuditDisableSQL

END
GO

/*
	-- Testing code
	DECLARE  @DatabaseName	NVARCHAR(1000)	= 'Products'
			,@DBAuditName	NVARCHAR(300)	= 'DB_Audit_Products_TableUsuage'
			,@Debug			BIT				= 1

	EXEC dbo.usp_SaveAuditSummary	 @DatabaseName	= @DatabaseName
									,@DBAuditName	= @DBAuditName
									,@Debug			= @Debug

	SELECT	*
	FROM	DBA.dbo.DataSeedAuditSummary
	WHERE	DatabaseName = @DatabaseName

*/

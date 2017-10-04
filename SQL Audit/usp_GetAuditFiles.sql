--USE DBATools
--GO
--IF OBJECT_ID('dbo.usp_GetAuditFiles') IS NOT NULL
--	DROP PROC dbo.usp_GetAuditFiles
--GO
CREATE PROCEDURE dbo.usp_GetAuditFiles
(
	 @DatabaseName			SYSNAME
	,@DBAuditName			NVARCHAR(300)
	,@ResultsOutputTable	SYSNAME			= NULL
	,@Debug					BIT				= NULL
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @RetVal INT = 0
	DECLARE @AuditFileSQL NVARCHAR(MAX)

	IF OBJECT_ID('tempdb..#AuditFiles_0927') IS NOT NULL
		DROP TABLE #AuditFiles_0927
	CREATE TABLE #AuditFiles_0927
	(
		 DatabaseName	SYSNAME
		,AuditName		NVARCHAR(300)
		,DirectoryPath	NVARCHAR(400)
		,FilePattern	NVARCHAR(400)
		,FileName		NVARCHAR(400)
	)

	SET @AuditFileSQL = 
	N'
	USE [?]

	DECLARE @NameOfAudit NVARCHAR(300) = ''@DBAuditName''

	DECLARE  @Sql_DB_LogFileNamePath	NVARCHAR(500)
			,@FilePattern				NVARCHAR(500)

	SELECT	 @Sql_DB_LogFileNamePath	= SFA.log_file_path
			,@FilePattern				= REPLACE(SFA.log_file_name, N''.sqlaudit'', ''*.sqlaudit'')
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
			#AuditFiles_0927
	SELECT	 DISTINCT 
			 DatabaseName	= database_name
			,AuditName		= @NameOfAudit
			,DirectoryPath	= @Sql_DB_LogFileNamePath
			,FilePattern	= @FilePattern
			,FileName		= AR.file_name
	FROM	sys.fn_get_audit_file(@Sql_DB_LogFileNamePath + @FilePattern, default, default) AR
	WHERE	database_name = ''?''
	'

	SET @AuditFileSQL = REPLACE(@AuditFileSQL, '?', @DatabaseName)
	SET @AuditFileSQL = REPLACE(@AuditFileSQL, '@DBAuditName', @DBAuditName)
	SET @AuditFileSQL = REPLACE(@AuditFileSQL, '@Debug', @Debug)

	IF @Debug = 1
	BEGIN
		PRINT '--- Enable or Disable Audit Query ----'
		PRINT @AuditFileSQL
		PRINT '--- Enable or Disable Audit Query ----'
	END

	EXEC sp_executesql @AuditFileSQL

	IF LEN(@ResultsOutputTable) > 0
	BEGIN
		IF OBJECT_ID('tempdb..' + @ResultsOutputTable) IS NOT NULL
		BEGIN
			DECLARE @OutputSQL NVARCHAR(MAX) = ''
			SET @OutputSQL = 'INSERT INTO ' + @ResultsOutputTable
								+ ' SELECT * FROM #AuditFiles_0927'
			
			IF @Debug = 1
			BEGIN
				PRINT '--- output table ---'
				PRINT 'SQL:' + ISNULL(@OutputSQL, '<NULL>')
			END
			
			EXEC(@OutputSQL)

		END
	END


	RETURN @RetVal

END
GO

/*
	IF OBJECT_ID('tempdb..#AuditFiles') IS NOT NULL
		DROP TABLE #AuditFiles
	CREATE TABLE #AuditFiles
	(
		 DatabaseName	SYSNAME
		,AuditName		NVARCHAR(300)
		,DirectoryPath	NVARCHAR(400)
		,FilePattern	NVARCHAR(400)
		,FileName		NVARCHAR(400)
	)

	-- Testing code
	DECLARE  @DatabaseName			SYSNAME			= 'Assets'
			,@DBAuditName			NVARCHAR(300)	= 'DB_Audit_Assets_TableUsuage'
			,@ResultsOutputTable	SYSNAME			= '#AuditFiles'
		    ,@Debug					BIT				= 0

	EXEC dbo.usp_GetAuditFiles @DatabaseName = @DatabaseName, @DBAuditName = @DBAuditName, @ResultsOutputTable = @ResultsOutputTable, @Debug = @Debug
	SELECT * FROM #AuditFiles

*/

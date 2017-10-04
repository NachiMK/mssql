--USE DBATools
--GO
--IF OBJECT_ID('dbo.usp_GetAuditStatus') IS NOT NULL
--	DROP PROC dbo.usp_GetAuditStatus
--GO
CREATE PROCEDURE dbo.usp_GetAuditStatus
(
	 @Databases				NVARCHAR(1000)	= NULL
	,@ResultsOutputTable	SYSNAME			= NULL
	,@Debug					INT				= NULL
)
AS
BEGIN

	SET NOCOUNT ON;

	SET @Databases = ISNULL(@Databases, 'ALL')
	SET @Debug = ISNULL(@Debug, 1)

	IF OBJECT_ID('tempdb..#AuditStatus') IS NOT NULL
		DROP TABLE #AuditStatus
	CREATE TABLE #AuditStatus
	(
		 DatabaseName				SYSNAME
		,DatabaseId					BIGINT
		,AuditStatus				NVARCHAR(50)
		,AllowedMaxFileSizeInBytes	DECIMAL
		,LatestFileSize				DECIMAL
		,SpaceRemainingInLastFile	DECIMAL
		,NOofFilesAllowed			DECIMAL
		,NoOfLogFilesCreated		DECIMAL
		,MaxFileCountReached		NVARCHAR(5)
		,CanAuditGrow				NVARCHAR(5)
		,DBAuditName				NVARCHAR(300)
		,DBAuditCreateDate			DATETIME
		,DBAuditEnabled				BIT
		,ServerAuditName			SYSNAME
		,ServerAuditEnabled			TINYINT
		,LogFilePath				NVARCHAR(350)
		,LogFile					NVARCHAR(350)
		,LogFileFullPath			NVARCHAR(700)
		,AuditStatusTime			DATETIME2
		,LatestFileFullPath			NVARCHAR(350)
	)

	DECLARE @SqlAuditStatus NVARCHAR(MAX)

	IF ((@Databases = 'ALL') OR LEN(@Databases) = 0)
	BEGIN
		SET @Databases = N''
		SELECT	@Databases += ',' + DatabaseName
		FROM	dbo.udf_GetDatabasesForAuditing() T

		SET @Databases = STUFF(@Databases, 1, 1, '')
	END

	IF @Debug >= 1
		SELECT ListOfDBsToAudit = @Databases

	SET @SqlAuditStatus = '
USE ?;

INSERT INTO
		#AuditStatus
SELECT	 DatabaseName			= DB_NAME()
		,DatabaseId				= DB_ID()
		,AuditStatus			= CASE WHEN SAS.status_desc = N''STARTED'' THEN ''RUNNING'' ELSE ''STOPPED'' END

		,AllowedMaxFileSizeInBytes	= SFA.max_file_size * 1000.0 * 1000.0
		,LatestFileSize				= SAS.audit_file_size
		,SpaceRemainingInLastFile	= CASE WHEN (SFA.max_file_size * 1000.0 * 1000.0) - SAS.audit_file_size > 0 
											THEN (SFA.max_file_size * 1000.0 * 1000.0) - SAS.audit_file_size
											ELSE 0 END

		,NOofFilesAllowed		= SFA.max_files
		,NoOfLogFilesCreated	= F.NoOfFiles
		,MaxFileCountReached	= CASE WHEN ISNULL(F.NoOfFiles, 0) = SFA.max_files THEN ''YES'' ELSE ''NO'' END
		,CanAuditGrow			= CASE WHEN (SAS.status_desc != N''STARTED'') OR (ISNULL(F.NoOfFiles, 0) = SFA.max_files)
										OR (((SFA.max_file_size * 1000.0 * 1000.0) - SAS.audit_file_size) <= 0 )
										THEN ''NO''
										ELSE ''Yes''
								  END
		,DBAuditName			= DBAS.name
		,DBAuditCreateDate		= DBAS.create_date
		,DBAuditEnabled			= DBAS.is_state_enabled
		,ServerAuditName		= SA.name
		,ServerAuditEnabled		= SA.is_state_enabled
		,LogFilePath			= SFA.log_file_path
		,LogFile				= SFA.log_file_name
		,LogFileFullPath		= REPLACE(SFA.log_file_path + SFA.log_file_name, N''.sqlaudit'', ''*.sqlaudit'')
		,AuditStatusTime		= SAS.status_time
		,LatestFileFullPath		= SAS.audit_file_path

FROM	sys.database_audit_specifications	DBAS
JOIN	sys.server_audits							SA	ON	SA.audit_guid	= DBAS.audit_guid
JOIN	sys.dm_server_audit_status					SAS	ON	SAS.audit_id	= SA.audit_id
JOIN	sys.server_file_audits						SFA	ON	SFA.audit_id	= SAS.audit_id
OUTER	APPLY
		(
			SELECT  NoOfFiles	=	COUNT(DISTINCT file_name)
			FROM	sys.fn_get_audit_file(REPLACE(SFA.log_file_path + SFA.log_file_name, N''.sqlaudit'', ''*.sqlaudit''), default, default)

		)	F
WHERE	SA.type		= N''FL''
AND		DBAS.name	= N''DB_Audit_'' + REPLACE(REPLACE(''?'', ''['', ''''), '']'', '''') + ''_TableUsuage''
'
	DECLARE @printonly BIT = 0
	IF @Debug = 2
		SET @printonly = 1

	EXEC master.dbo.sp_foreachdb @command = @SqlAuditStatus, @print_Command_only = @printonly, @user_only = 1, @database_list = @Databases

	IF ((LEN(@ResultsOutputTable) = 0) OR (@Debug >= 1))
		SELECT *
		FROM   #AuditStatus

	IF LEN(@ResultsOutputTable) > 0
	BEGIN
		IF OBJECT_ID('tempdb..' + @ResultsOutputTable) IS NOT NULL
		BEGIN
			DECLARE @OutputSQL NVARCHAR(MAX) = ''
			SET @OutputSQL = 'INSERT INTO ' + @ResultsOutputTable
								+ ' SELECT * FROM #AuditStatus'
			
			IF @Debug = 1
			BEGIN
				PRINT '--- output table ---'
				PRINT 'SQL:' + ISNULL(@OutputSQL, '<NULL>')
			END
			
			EXEC(@OutputSQL)

		END
	END

END
GO

/*
	-- Testing code
	DECLARE  @Databases				NVARCHAR(1000)	= 'ASPNetServices'
			,@ResultsOutputTable	SYSNAME			= NULL
		    ,@Debug					BIT				= 1
	EXEC dbo.usp_GetAuditStatus @Databases = @Databases, @ResultsOutputTable = @ResultsOutputTable, @Debug = @Debug
*/

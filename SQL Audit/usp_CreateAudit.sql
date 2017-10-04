--USE DBATools
--GO
--IF OBJECT_ID('dbo.usp_CreateAudit') IS NOT NULL
--	DROP PROC dbo.usp_CreateAudit
--GO
CREATE PROCEDURE dbo.usp_CreateAudit
(
	 @DatabaseName			NVARCHAR(1000)
	,@DBAuditName			NVARCHAR(300)
	,@ServerAuditName		NVARCHAR(300)
	,@AuditPath				NVARCHAR(300)
	,@MaxFileSizeInMB		INT				= 100
	,@MaxFiles				INT				= 10
	,@AddTableAuditScript	NVARCHAR(MAX)	= NULL
	,@print_command_only	BIT				= 1
	,@Debug					BIT				= NULL
)
AS
BEGIN

	SET NOCOUNT ON;

	--DECLARE @AddTableSyntax NVARCHAR(400) = N',ADD (SELECT, INSERT, UPDATE, DELETE, REFERENCES ON OBJECT::<@TableName> BY [public])'
	--DECLARE @TableScript	NVARCHAR(MAX) = N''
	DECLARE @CreateAuditSQL NVARCHAR(MAX) = N''

	SET @DatabaseName			= ISNULL(@DatabaseName, N'')
	SET @DBAuditName			= ISNULL(@DBAuditName, N'')
	SET @ServerAuditName		= ISNULL(@ServerAuditName, N'')
	SET @AuditPath				= ISNULL(@AuditPath, N'')
	SET @MaxFileSizeInMB		= ISNULL(@MaxFileSizeInMB, 100)
	SET @MaxFiles				= ISNULL(@MaxFiles, 10)

	IF @MaxFileSizeInMB < 2
		SET @MaxFileSizeInMB = 2
	IF @MaxFileSizeInMB > 1000
		SET @MaxFileSizeInMB = 1000
	IF @MaxFiles <= 2
		SET @MaxFiles = 2
	IF @MaxFiles > 20
		SET @MaxFiles = 20

	SET @AddTableAuditScript	= ISNULL(@AddTableAuditScript, N'')
	SET @print_command_only		= ISNULL(@print_command_only, 1)
	SET @Debug					= ISNULL(@Debug, 0)

	IF @Debug = 1
		SELECT DatabaseName = @DatabaseName, DBAuditName = @DBAuditName, AddTableAuditScript = @AddTableAuditScript, ServerAuditName = @ServerAuditName
				,MaxFiles = @MaxFiles, MaxFileSizeInMB = @MaxFileSizeInMB

	SET @CreateAuditSQL = 
	N'
	USE [master]
	IF NOT EXISTS (SELECT * FROM sys.server_audits WHERE name = N''@ServerAuditName'')
	BEGIN
		-- Create the server audit in the master database  
		CREATE SERVER AUDIT [@ServerAuditName]
		TO FILE 
		(	FILEPATH = N''@AuditPath''
			,MAXSIZE = @MaxFileSizeInMB MB
			,MAX_FILES = @MaxFiles
			,RESERVE_DISK_SPACE = OFF
		)
		WITH
		(	QUEUE_DELAY = 1000
			,ON_FAILURE = CONTINUE
		);
	END
	ALTER SERVER AUDIT [@ServerAuditName] WITH (STATE = ON); 

	USE [?];  

	IF EXISTS (SELECT * FROM sys.database_audit_specifications WHERE name = ''@DBAuditName'')
	BEGIN
		ALTER DATABASE AUDIT SPECIFICATION [@DBAuditName] 
		WITH (STATE = OFF);

		DROP DATABASE AUDIT SPECIFICATION [@DBAuditName]
	END
	CREATE DATABASE AUDIT SPECIFICATION [@DBAuditName]
		FOR SERVER AUDIT [@ServerAuditName] 
		ADD (DATABASE_OBJECT_CHANGE_GROUP)
		@TableScript
		WITH (STATE = ON);  
	'

	IF LEN(@AddTableAuditScript) = 0
		SET @AddTableAuditScript = N',ADD (SELECT, INSERT, UPDATE, DELETE, REFERENCES ON SCHEMA::[dbo] BY [public])  '

	SET @CreateAuditSQL = REPLACE(@CreateAuditSQL, '?', @DatabaseName)
	SET @CreateAuditSQL = REPLACE(@CreateAuditSQL, '@ServerAuditName', @ServerAuditName)
	SET @CreateAuditSQL = REPLACE(@CreateAuditSQL, '@AuditPath', @AuditPath)
	SET @CreateAuditSQL = REPLACE(@CreateAuditSQL, '@DBAuditName', @DBAuditName)
	SET @CreateAuditSQL = REPLACE(@CreateAuditSQL, '@TableScript', @AddTableAuditScript)
	SET @CreateAuditSQL = REPLACE(@CreateAuditSQL, '@MaxFileSizeInMB', @MaxFileSizeInMB)
	SET @CreateAuditSQL = REPLACE(@CreateAuditSQL, '@MaxFiles', @MaxFiles)

	IF (@Debug = 1) OR (@print_command_only = 1)
	BEGIN
		PRINT '---- Command to Create Audit ------'
		PRINT '@CreateAuditSQL:' + ISNULL(@CreateAuditSQL, 'IS <NULL>')
		PRINT '---- Command to Create Audit ------'
	END	

	IF @print_command_only = 0
		EXEC (@CreateAuditSQL)

	IF @Debug = 1
		EXEC dbo.usp_GetAuditStatus @Databases = @DatabaseName

END
GO

/*
	-- Testing code
	DECLARE  @DatabaseName			NVARCHAR(1000)	= 'Assets'
			,@DBAuditName			NVARCHAR(300)	= 'DB_Audit_Assets_TableUsuage'
			,@ServerAuditName		NVARCHAR(300)	= 'ServerAudit_TableUsuage_Assets'
			,@AuditPath				NVARCHAR(300)	= 'D:\SQL_AUDIT\TableUsage\Assets\'
			,@MaxFileSizeInMB		INT				= 2
			,@MaxFiles				INT				= 2
			,@AddTableAuditScript	NVARCHAR(MAX)	= ''
			,@print_command_only	BIT				= 1
			,@Debug					BIT				= 1

	EXEC dbo.usp_CreateAudit @DatabaseName			= @DatabaseName
							,@DBAuditName			= @DBAuditName
							,@ServerAuditName		= @ServerAuditName
							,@AuditPath				= @AuditPath
							,@MaxFileSizeInMB		= @MaxFileSizeInMB
							,@MaxFiles				= @MaxFiles
							,@AddTableAuditScript	= @AddTableAuditScript
							,@print_command_only	= @print_command_only
							,@Debug					= @Debug

	EXEC dbo.usp_GetAuditStatus @Databases = @DatabaseName
*/

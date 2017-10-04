--USE DBATools
--GO
--IF OBJECT_ID('dbo.usp_DisableEnableAudit') IS NOT NULL
--	DROP PROC dbo.usp_DisableEnableAudit
--GO
CREATE PROCEDURE dbo.usp_DisableEnableAudit
(
	 @DatabaseName		NVARCHAR(1000)
	,@DBAuditName		NVARCHAR(300)
	,@ServerAuditName	NVARCHAR(300)
	,@EnableAudit		BIT				= NULL
	,@Debug				BIT				= NULL
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @AuditDisableSQL NVARCHAR(MAX) = N''


	SET @ServerAuditName = ISNULL(@ServerAuditName, '')
	SET @DBAuditName     = ISNULL(@DBAuditName, '')
	SET @EnableAudit = ISNULL(@EnableAudit, 0)
	SET @Debug = ISNULL(@Debug, 0)

	SET @AuditDisableSQL = 
	N'
	USE [?]

	DECLARE @AuditStatus BIT
	DECLARE @NameOfAudit NVARCHAR(300) = ''@DBAuditName''

	SELECT	@AuditStatus = DBAS.is_state_enabled
	FROM	sys.database_audit_specifications	DBAS
	JOIN	sys.server_audits					SA	ON	SA.audit_guid	= DBAS.audit_guid
	JOIN	sys.dm_server_audit_status			SAS	ON	SAS.audit_id	= SA.audit_id
	JOIN	sys.server_file_audits				SFA	ON	SFA.audit_id	= SAS.audit_id
	WHERE	DBAS.name = @NameOfAudit
	AND		SA.name   = @ServerAuditName
	AND		DBAS.is_state_enabled = 1

	IF NOT EXISTS (SELECT * FROM sys.server_audits WHERE name = ''@ServerAuditName'')
	BEGIN
		IF @EnableAudit = 1
			ALTER SERVER AUDIT @ServerAuditName WITH (STATE = ON);
		ELSE
			ALTER SERVER AUDIT @ServerAuditName WITH (STATE = OFF);

		WAITFOR DELAY (''00:00:10'')
	END

	IF EXISTS (SELECT * FROM sys.database_audit_specifications WHERE name = @NameOfAudit)
	BEGIN
		IF @EnableAudit = 1
			ALTER DATABASE AUDIT SPECIFICATION @DBAuditName
			WITH (STATE = ON);
		ELSE
			ALTER DATABASE AUDIT SPECIFICATION @DBAuditName
			WITH (STATE = OFF);
	END

	IF @Debug = 1
	BEGIN

		SELECT	sComments = ''After Disabling Audit'', EnableAudit = @EnableAudit, *
		FROM	sys.database_audit_specifications	DBAS
		JOIN	sys.server_audits					SA	ON	SA.audit_guid	= DBAS.audit_guid
		JOIN	sys.dm_server_audit_status			SAS	ON	SAS.audit_id	= SA.audit_id
		JOIN	sys.server_file_audits				SFA	ON	SFA.audit_id	= SAS.audit_id
		WHERE	DBAS.name = @NameOfAudit
		AND		SA.name   = @ServerAuditName
	END

	'
	SET @AuditDisableSQL = REPLACE(@AuditDisableSQL, '?', @DatabaseName)
	SET @AuditDisableSQL = REPLACE(@AuditDisableSQL, '@Debug', @Debug)
	SET @AuditDisableSQL = REPLACE(@AuditDisableSQL, '@DBAuditName', @DBAuditName)
	SET @AuditDisableSQL = REPLACE(@AuditDisableSQL, '@ServerAuditName', @ServerAuditName)

	IF @Debug = 1
	BEGIN
		PRINT '--- Enable or Disable Audit Query ----'
		PRINT @AuditDisableSQL
		PRINT '--- Enable or Disable Audit Query ----'
	END

	EXEC sp_executesql @AuditDisableSQL, N'@EnableAudit BIT', @EnableAudit = @EnableAudit

END
GO

/*
	-- Testing code
	DECLARE  @DatabaseName	NVARCHAR(1000)	= 'Assets'
			,@DBAuditName	NVARCHAR(300)	= 'DB_Audit_Assets_TableUsuage'
			,@EnableAudit	BIT				= 1
			,@Debug			BIT				= 1

	EXEC dbo.usp_DisableEnableAudit @DatabaseName = @DatabaseName, @DBAuditName = @DBAuditName, @EnableAudit = @EnableAudit, @Debug = @Debug
*/

--USE DBATools
--GO
--IF OBJECT_ID('dbo.usp_IsAuditEnabled') IS NOT NULL
--	DROP PROCEDURE dbo.usp_IsAuditEnabled
--GO
CREATE PROCEDURE dbo.usp_IsAuditEnabled
(
	 @DatabaseName		NVARCHAR(1000)
	,@DBAuditName		NVARCHAR(300)
	,@Debug				BIT	=	NULL
)
AS
BEGIN

	DECLARE @RetVal INT = 0
	DECLARE @AuditDisableSQL NVARCHAR(MAX)

	SET @AuditDisableSQL = 
	N'
	USE [?]

	DECLARE @NameOfAudit NVARCHAR(300) = ''@DBAuditName''

	SELECT	@RetVal = DBAS.is_state_enabled
	FROM	sys.database_audit_specifications	DBAS
	JOIN	sys.server_audits					SA	ON	SA.audit_guid	= DBAS.audit_guid
	JOIN	sys.dm_server_audit_status			SAS	ON	SAS.audit_id	= SA.audit_id
	JOIN	sys.server_file_audits				SFA	ON	SFA.audit_id	= SAS.audit_id
	WHERE	DBAS.name = @NameOfAudit

	'
	SET @AuditDisableSQL = REPLACE(@AuditDisableSQL, '?', @DatabaseName)
	SET @AuditDisableSQL = REPLACE(@AuditDisableSQL, '@DBAuditName', @DBAuditName)

	IF @Debug = 1
	BEGIN
		PRINT '--- Enable or Disable Audit Query ----'
		PRINT @AuditDisableSQL
		PRINT '--- Enable or Disable Audit Query ----'
	END

	EXEC sp_executesql @AuditDisableSQL, N'@RetVal INT OUTPUT', @RetVal = @RetVal OUTPUT

	RETURN @RetVal

END
GO

/*
	-- Testing code
	DECLARE  @DatabaseName	NVARCHAR(1000)	= 'Assets'
			,@DBAuditName	NVARCHAR(300)	= 'DB_Audit_Assets_TableUsuage'
			,@Debug			BIT				= 0
			,@RetVal		INT

	EXEC @RetVal = dbo.usp_IsAuditEnabled	 @DatabaseName	= @DatabaseName
											,@DBAuditName	= @DBAuditName
											,@Debug			= @Debug
	SELECT RetVal = @RetVal
*/

--USE DBATools
--GO
--IF OBJECT_ID('dbo.usp_DeleteAudit') IS NOT NULL
--	DROP PROCEDURE dbo.usp_DeleteAudit
--GO
CREATE PROCEDURE dbo.usp_DeleteAudit
(
	 @Databases			NVARCHAR(1000)	= NULL
	,@AuditNamePattern	NVARCHAR(300)	= ''
	,@Debug				INT				= NULL
)
AS
BEGIN

	SET @Databases = ISNULL(@Databases, N'')
	IF @Databases = N'ALL'
		SET @Databases = ''
	SET @AuditNamePattern = N'%' + ISNULL(@AuditNamePattern, N'') + N'%'
	SET @Debug = ISNULL(@Debug, 0)
 
	DECLARE @SqlDeleteAudit NVARCHAR(MAX) =
	N'
	USE ?;

	DECLARE @DBAuditName nvarchar(300)
	DECLARE @ServerAuditName nvarchar(300)
	DECLARE @ErrorMessage	NVARCHAR(4000);  
	DECLARE @ErrorProc		NVARCHAR(4000);
	DECLARE @ErrorLine		BIGINT; 
	DECLARE @ErrorSeverity	INT;  
	DECLARE @ErrorState		INT;  

	DECLARE DeleteAudit_Cursor CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

	SELECT	 DBAuditName = DBAS.name
			,ServerAuditName = SA.name
	FROM	sys.database_audit_specifications	DBAS
	JOIN	sys.server_audits							SA	ON	SA.audit_guid	= DBAS.audit_guid
	JOIN	sys.dm_server_audit_status					SAS	ON	SAS.audit_id	= SA.audit_id
	WHERE	DBAS.name LIKE ''@AuditNamePattern''

	OPEN DeleteAudit_Cursor

	FETCH NEXT FROM DeleteAudit_Cursor
	INTO @DBAuditName, @ServerAuditName

	WHILE (@@FETCH_STATUS = 0)
	BEGIN

		BEGIN TRY

		IF EXISTS (SELECT * FROM sys.database_audit_specifications WHERE name = @DBAuditName)
		BEGIN
			EXEC (''ALTER DATABASE AUDIT SPECIFICATION '' + @DBAuditName + '' WITH (STATE = OFF);'');
			EXEC (''DROP DATABASE AUDIT SPECIFICATION '' + @DBAuditName)
		END

		END TRY
		BEGIN CATCH

		SELECT   
			 @ErrorMessage	= ERROR_MESSAGE()
			,@ErrorSeverity	= ERROR_SEVERITY()
			,@ErrorState	= ERROR_STATE()
			,@ErrorProc		= ERROR_PROCEDURE()
			,@ErrorLine		= ERROR_LINE()

			IF @Debug = 1
			BEGIN
				RAISERROR (@ErrorMessage, @ErrorSeverity,@ErrorState, @ErrorProc, @ErrorLine); 
			END

		END CATCH

		FETCH NEXT FROM DeleteAudit_Cursor
		INTO @DBAuditName, @ServerAuditName
	END

	CLOSE DeleteAudit_Cursor
	DEALLOCATE DeleteAudit_Cursor

	USE master;
	IF EXISTS (SELECT * FROM sys.server_audits WHERE name = @ServerAuditName)
	BEGIN
		EXEC (''ALTER SERVER AUDIT '' + @ServerAuditName + '' WITH (STATE = OFF);  '')
		EXEC (''DROP SERVER AUDIT '' + @ServerAuditName)
	END
	'
	SET @SqlDeleteAudit = REPLACE(@SqlDeleteAudit, '@AuditNamePattern', @AuditNamePattern)
	SET @SqlDeleteAudit = REPLACE(@SqlDeleteAudit, '@Debug', @Debug)

	DECLARE @printonly BIT = 0
	IF @Debug = 2
		SET @printonly = 1

	IF @Debug = 1
	BEGIN
		PRINT '--- SQL To delete Audit ----'
		PRINT '-- @SqlDeleteAudit:' + ISNULL(@SqlDeleteAudit, ' IS <NULL>')
		PRINT '--- SQL To delete Audit ----'
	END
	EXEC master.dbo.sp_foreachdb @command = @SqlDeleteAudit, @print_Command_only = @printonly, @user_only = 1, @database_list = @Databases
END
GO

/*
	-- Testing code
	DECLARE @Databases NVARCHAR(1000)
	DECLARE @AuditNamePattern nvarchar(300)
	DECLARE @Debug INT = 1

	EXEC dbo.usp_DeleteAudit	 @Databases	= @Databases
								,@AuditNamePattern = @AuditNamePattern
								,@Debug			= @Debug
*/

--USE DBATools
--GO
--IF OBJECT_ID('dbo.usp_GetTablesToBeAudited') IS NOT NULL
--	DROP PROC dbo.usp_GetTablesToBeAudited
--GO
CREATE PROCEDURE dbo.usp_GetTablesToBeAudited
(
	 @DatabaseName		  NVARCHAR(1000)
	,@DBAuditName		  NVARCHAR(300)
	,@OutputTableList	  NVARCHAR(1000)	OUTPUT
	,@RemainingTablePct	  NUMERIC(22, 2)	OUTPUT
	,@AddTableAuditScript NVARCHAR(MAX)		OUTPUT
	,@Debug				  BIT				= NULL
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @AuditDisableSQL NVARCHAR(MAX) = N''

	SET @RemainingTablePct = 0.0
	SET @OutputTableList = N''
	SET @Debug = ISNULL(@Debug, 0)

	SET @AuditDisableSQL = 
	N'
	USE [?]

	SET @OutputTableList = N''''
	SET @AddTableAuditScript = N''''

	DECLARE @AddTableSyntax NVARCHAR(400) = N'',ADD (SELECT, INSERT, UPDATE, DELETE, REFERENCES ON OBJECT::<@TableName> BY [public])''
	DECLARE @NameOfAudit NVARCHAR(300) = ''@DBAuditName''
	DECLARE @RemainingTableCnt DECIMAL = 0.0
	DECLARE @TotalTableCnt     DECIMAL = 0.0

	-- Get All Tables Audited so far
	-- Get all tables in Database
	-- Exclude tables in audit
	-- Save to output
	SELECT	 @OutputTableList		+= '',['' + S.name + ''].['' + T.name + '']''
			,@RemainingTableCnt		+= 1.0
			,@AddTableAuditScript	+= REPLACE(@AddTableSyntax, ''<@TableName>'', ''['' + S.name + ''].['' + T.name + '']'') + '' '' + CHAR(13)
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
	AND		NOT EXISTS (SELECT 1 FROM DBA.dbo.DataSeedAuditSummary D WHERE D.SchemaName = S.name AND D.ObjectName = T.name)

	SELECT	 @TotalTableCnt = COUNT(*)
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

	SET @RemainingTablePct = (@RemainingTableCnt / @TotalTableCnt) * 100.00

	IF @Debug = 1
	BEGIN
		SELECT	 RemainingTableCnt = @RemainingTableCnt
				,TotalTableCnt = @TotalTableCnt
				,RemainingTablePct = @RemainingTableCnt / @TotalTableCnt
				,RemainingTablePct1 = @RemainingTablePct

		SELECT	sComments = ''Tables to Exclude'', SchemaName = S.name, TableName = T.name
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
		AND		NOT EXISTS (SELECT 1 FROM DBA.dbo.DataSeedAuditSummary D WHERE D.SchemaName = S.name AND D.ObjectName = T.name)
	END

	'
	SET @AuditDisableSQL = REPLACE(@AuditDisableSQL, '?', @DatabaseName)
	SET @AuditDisableSQL = REPLACE(@AuditDisableSQL, '@Debug', @Debug)
	SET @AuditDisableSQL = REPLACE(@AuditDisableSQL, '@DBAuditName', @DBAuditName)

	IF @Debug = 1
	BEGIN
		PRINT '--- Get Tables to exclude from Audit ----'
		PRINT @AuditDisableSQL
		PRINT '--- Get Tables to exclude from Audit ----'
	END

	EXEC sp_executesql @AuditDisableSQL, N'@OutputTableList NVARCHAR(2000) OUTPUT, @RemainingTablePct NUMERIC(22, 2) OUTPUT, @AddTableAuditScript NVARCHAR(MAX) OUTPUT'
	, @OutputTableList = @OutputTableList OUTPUT
	, @RemainingTablePct = @RemainingTablePct OUTPUT
	, @AddTableAuditScript = @AddTableAuditScript OUTPUT

	SET @OutputTableList = ISNULL(@OutputTableList, N'')
	SET @OutputTableList = STUFF(@OutputTableList, 1, 1, N'')
	SET @AddTableAuditScript = ISNULL(@AddTableAuditScript, N'')

	IF @Debug = 1
	BEGIN
		PRINT 'Tables to Include:' + @OutputTableList
		PRINT 'Script to Include:' + @AddTableAuditScript
	END
END
GO

/*
	-- Testing code
	DECLARE  @DatabaseName	NVARCHAR(1000)	= 'Assets'
			,@DBAuditName	NVARCHAR(300)	= 'DB_Audit_Assets_TableUsuage'
			,@OutputTableList	NVARCHAR(1000)
			,@RemainingTablePct	NUMERIC(22, 2)
			,@AddTableAuditScript NVARCHAR(MAX)
			,@Debug			BIT				= 1

	EXEC dbo.usp_GetTablesToBeAudited @DatabaseName = @DatabaseName
	, @DBAuditName = @DBAuditName
	, @OutputTableList = @OutputTableList OUTPUT
	, @RemainingTablePct = @RemainingTablePct OUTPUT
	, @AddTableAuditScript = @AddTableAuditScript OUTPUT
	, @Debug = @Debug

	SELECT OutputTableList = @OutputTableList, RemainingTablePct = @RemainingTablePct, AddTableAuditScript = @AddTableAuditScript
	
*/

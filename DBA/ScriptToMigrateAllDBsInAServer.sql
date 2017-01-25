USE mnDBA
GO

DECLARE @SQLCmd NVARCHAR(MAX)		= 
'EXEC mnDBA.dbo.usp_NimbleUpgrade
	 @DBName						= ''@DB_NAME''
	,@ServerName					= ''' + @@SERVERNAME + '''
	,@PrintCommandsDoNotApply		= 0
	,@OfflineWithRollback			= 0
	,@DataDrive						= N''I:''
	,@LogDrive						= N''J:''
	,@DataDriveFolder				= N''SQL_DATA''
	,@LogDriveFolder				= N''SQL_LOG''
	,@Recipients					= N''db@spark.net''
'


;WITH CTEDBs
AS
(
SELECT	DISTINCT db_name = S.name
FROM	sys.databases	S
JOIN	sys.master_files	MF	ON	MF.database_id = S.database_id
WHERE	S.database_id > 4
AND		S.name NOT IN ('mnDBA')
AND		((MF.physical_name LIKE 'H:%') OR (MF.physical_name LIKE 'L:%'))

)
SELECT	CTEDBs.db_name
		,ScriptToMigrate = REPLACE(@SQLCmd, '@DB_NAME', CTEDBs.db_name)
FROM	CTEDBs
ORDER BY
		CTEDBs.db_name
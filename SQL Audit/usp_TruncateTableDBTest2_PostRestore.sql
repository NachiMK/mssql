CREATE PROCEDURE dbo.usp_TruncateTableDBTest2_PostRestore
(
	 @DBToTruncate	SYSNAME = NULL
	,@Debug			BIT		= NULL
)
AS
BEGIN

	SET NOCOUNT ON;

	SET @Debug = ISNULL(@Debug, 1)

	IF OBJECT_ID('tempdb..#TablesToTruncate') IS NOT NULL
		DROP TABLE #TablesToTruncate;
	CREATE TABLE #TablesToTruncate
	(
		 DatabaseName	SYSNAME NOT NULL
		,TableName		SYSNAME NOT NULL
	)

	IF OBJECT_ID('tempdb..#dependencies') IS NOT NULL
		DROP TABLE #dependencies
	CREATE TABLE #dependencies
	(
		 DatabaseId		BIGINT
		,SchemaId		BIGINT
		,Child_Table	SYSNAME
		,Child_Table_Id	BIGINT
		,Parent_Table	SYSNAME
		,Parent_TableId	BIGINT
		,sComments		NVARCHAR(800)
	);

	IF OBJECT_ID('tempdb..#TablesInDB') IS NOT NULL
		DROP TABLE #TablesInDB
	CREATE TABLE #TablesInDB
	(
		 DatabaseName	SYSNAME
		,TableName		SYSNAME
		,TableId		BIGINT
		,schema_id		BIGINT
	)

	IF @@SERVERNAME NOT IN ('COD7NMUTHUKUMAR', 'DBTest2')
		RETURN

	-- Truncate only for given tables
	INSERT INTO #TablesToTruncate
	SELECT	DBName, TableName
	FROM	DBATools.dbo.vw_TablesToTruncateInDBTest2_PostRestore
	WHERE	DBName	=	ISNULL(@DBToTruncate, DBName)

	-- SELECT * FROM #TablesToTruncate

	DECLARE @OrigSqlCommand	NVARCHAR(MAX)
	SET     @OrigSqlCommand =
	N'
	USE [<DatabaseName>];

	INSERT	INTO	
			#TablesInDB
	SELECT	DatabaseName = DB_NAME(), TableName = ST.name, TableId = ST.object_id, schema_id
	FROM	sys.tables ST
	WHERE	EXISTS (SELECT 1 FROM #TablesToTruncate TT WHERE TT.TableName = ST.name AND DatabaseName = ''<DatabaseName>'')


	INSERT INTO 
			#dependencies 
	SELECT	 DatabaseId					= DB_ID()
			,SchemaId					= ST.schema_id
			,Child_Table				= TT.TableName
			,Child_Table_Id				= TT.TableId

			,Parent_Table				= ST.name
			,Parent_TableId				= SR.rkeyid

			,sComments					= ''I am a Child.'' + TT.TableName + '' is child table of '' + ST.Name
	FROM	sys.sysreferences	sr
	JOIN	#TablesInDB			TT	ON	TT.TableId		= fkeyid
	JOIN	sys.tables			st	ON	ST.object_id	= SR.rkeyid
	JOIN	#TablesInDB			TT1	ON	TT1.TableId		= SR.rkeyid

	INSERT INTO 
			#dependencies 
	SELECT	 DatabaseId					= DB_ID()
			,SchemaId					= TT.schema_id
			,Child_Table				= ST.name
			,Child_Table_Id				= SR.rkeyid

			,Parent_Table				= TT.TableName
			,Parent_TableId				= TT.TableId
			,sComments					= ''I am a Parent.'' + ST.name + '' is child table of '' + TT.TableName
	FROM	sys.sysreferences	sr
	JOIN	#TablesInDB			TT	ON	TT.TableId		= SR.rkeyid
	JOIN	sys.tables			st	ON	ST.object_id	= SR.fkeyid
	'

	DECLARE @SqlCommand	NVARCHAR(MAX)
	DECLARE @DBName		SYSNAME

	DECLARE DBList CURSOR  LOCAL FORWARD_ONLY STATIC READ_ONLY FOR 

	SELECT	
			DISTINCT DatabaseName
	FROM	#TablesToTruncate
	ORDER BY 
			DatabaseName
	OPEN DBList;
	FETCH NEXT FROM DBList INTO @DBName;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRY
			IF @Debug = 1
				PRINT 'DBName:' + @DBName
		
			SET @SqlCommand = Replace(@OrigSqlCommand, '<DatabaseName>', @DBName)
			
			IF @Debug = 1
				PRINT @SqlCommand
			EXEC(@SqlCommand)
		END TRY
		BEGIN CATCH
			PRINT '-------Error in Running Query on DB:' + @dbName
			PRINT 'Error Message: ' + ERROR_MESSAGE()
			PRINT 'Error #: '		+ CONVERT(NVARCHAR, ERROR_NUMBER())
			PRINT 'Error Line: '	+ CONVERT(NVARCHAR, ERROR_LINE())
			PRINT 'Error Proc: '	+ ERROR_PROCEDURE()
			PRINT '-------Error in Running Query on DB:' + @dbName
		END CATCH
		FETCH NEXT FROM DBList INTO @DBName;
	END

	IF OBJECT_ID('tempdb..#DependentTables') IS NOT NULL
		DROP TABLE #DependentTables

	;WITH CTEDependentTable
	AS
	(
		SELECT	 DISTINCT	
				 DatabaseId
				,SchemaId
				,TableName			= Parent_Table
				,Parent_TableName	= CONVERT(SYSNAME, '')
				,[Level] = 1 
		FROM	#dependencies D1
		WHERE	Parent_Table in (SELECT TableName FROM #TablesToTruncate)
		AND		NOT EXISTS (SELECT * FROM #dependencies D2 WHERE D2.Child_Table = D1.Parent_Table)

		UNION ALL

		SELECT	 D.DatabaseId
				,D.SchemaId
				,TableName			= D.Child_Table
				,Parent_TableName	= Parent_Table
				,[Level] = [Level] + 1 
				--,D.sComments
		FROM	#dependencies D
		JOIN	CTEDependentTable C ON	C.TableName = D.Parent_Table
		WHERE	D.DatabaseId = C.DatabaseId
	)
	SELECT	 DatabaseName = DB_NAME(DatabaseId)
			,TableName
			,Parent_TableName
			,Script = 'DELETE FROM ' + QUOTENAME(DB_NAME(DatabaseId)) + '.dbo.' + QUOTENAME(TableName) + ';'
			,[Level] = MAX([Level])
	INTO	#DependentTables
	FROM	CTEDependentTable
	GROUP   BY
			 DatabaseId
			,SchemaId
			,TableName
			,Parent_TableName
	ORDER	BY
			 DatabaseName
			,[Level] DESC

	IF OBJECT_ID('tempdb..#ScriptToCleanUp') IS NOT NULL
		DROP TABLE #ScriptToCleanUp
	SELECT	 DatabaseName
			,TableName = Parent_TableName
			,Script = 'EXEC DBATools.dbo.sp_TruncateParentAndChild @DBName = ''' + DatabaseName
								+ ''', @ParentTableName=''' +  Parent_TableName 
								+ ''', @ChildTableList = ''' + 
								STUFF 
								( 
									( 
												SELECT DISTINCT 
													', ' + tempT.TableName AS ChildTables 
												FROM	#DependentTables AS tempT 
												WHERE	tempT.Parent_TableName = D.Parent_TableName
												ORDER BY 
														ChildTables
												FOR XML PATH, TYPE 
									).value('.[1]', 'nvarchar(MAX)') 
									, 1, 2, '' 
								)
								+ ''''
								+ ', @PrintOnly = 0'
								+ ', @Debug = ' + CONVERT(NVARCHAR(1), @Debug)
			,[Level]  = MAX([LEVEL])
	INTO	#ScriptToCleanUp
	FROM	#DependentTables D
	WHERE	[LEVEL] > 1
	GROUP	BY
			DatabaseName, Parent_TableName

	UNION ALL

	SELECT	 DatabaseName, TableName, Script = 'TRUNCATE TABLE ' + QUOTENAME(DatabaseName) + '.dbo.' + QUOTENAME(TableName) + ';'
			,[Level]  = 99
	FROM	#TablesInDB T
	WHERE	NOT EXISTS 
			(
				SELECT	*
				FROM	#dependencies D
				WHERE	DB_NAME(D.DatabaseId) = T.DatabaseName
				AND		T.schema_id = D.SchemaId
				AND		(T.TableName = D.Parent_Table)
			)

	ORDER	BY
			DatabaseName, [Level] DESC, TableName

	IF @Debug = 1
		SELECT * FROM #ScriptToCleanUp

	DECLARE  @DatabaseName	SYSNAME
			,@TableName		SYSNAME
			,@Script		NVARCHAR(MAX)

	DECLARE ScriptToExecute CURSOR LOCAL READ_ONLY FAST_FORWARD FOR

	SELECT	DatabaseName, TableName, Script
	FROM	#ScriptToCleanUp

	OPEN ScriptToExecute

	FETCH NEXT FROM ScriptToExecute INTO @DatabaseName, @TableName, @Script
	WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRY
			SET @Script = 'USE ' + QUOTENAME(@DatabaseName) + CHAR(13) + @Script
			
			IF @Debug = 1
			BEGIN
				PRINT '----- Script to Truncate ----'
				PRINT @Script
				PRINT '----- Script to Truncate ----'
			END
			ELSE
				EXEC(@Script)
		END TRY
		BEGIN CATCH
			PRINT '-------Error in Running Query on DB:' + @DatabaseName
			PRINT '-------Table   :'+ @TableName
			PRINT 'QUERY:         ' + @Script
			PRINT 'Error Message: ' + ERROR_MESSAGE()
			PRINT 'Error #: '		+ CONVERT(NVARCHAR, ERROR_NUMBER())
			PRINT 'Error Line: '	+ CONVERT(NVARCHAR, ERROR_LINE())
			PRINT 'Error Proc: '	+ ERROR_PROCEDURE()
			PRINT '-------Error in Running Query on DB:' + @DatabaseName
		END CATCH
			
		FETCH NEXT FROM ScriptToExecute INTO @DatabaseName, @TableName, @Script
	END
END

USE master
GO

/*
	This script can come up with order to delete tables for any clean  up reasons.
	
	Just add the Database and table name to the temp table #TablesToTruncate
*/

SET NOCOUNT ON;

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

INSERT INTO #TablesToTruncate SELECT DBName = 'somedb', TableName = 'Parent'
INSERT INTO #TablesToTruncate SELECT DBName = 'somedb', TableName = 'Child'
INSERT INTO #TablesToTruncate SELECT DBName = 'somedb', TableName = 'GrandChild'
INSERT INTO #TablesToTruncate SELECT DBName = 'somedb', TableName = 'Orphan'

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
		PRINT 'DBName:' + @DBName
	SET @SqlCommand = Replace(@OrigSqlCommand, '<DatabaseName>', @DBName)
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

-- Returns Truncate script for Tables that has not relations
SELECT	 DatabaseName
		,TableName
		,Script = 'TRUNCATE TABLE ' + QUOTENAME(DatabaseName) + '.dbo.' + QUOTENAME(TableName) + ';'
		,[Level] = 99
FROM	#TablesInDB T
WHERE	NOT EXISTS 
		(
			SELECT	*
			FROM	#dependencies D
			WHERE	DB_NAME(D.DatabaseId) = T.DatabaseName
			AND		T.schema_id = D.SchemaId
			AND		(T.TableName = D.Parent_Table)
		)

-- Returns delete script for tables that has parent/child relation in the correct order to be deleted.
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
		,Script = 'DELETE FROM ' + QUOTENAME(DB_NAME(DatabaseId)) + '.dbo.' + QUOTENAME(TableName) + ';'
		,[Level] = MAX([Level])
FROM	CTEDependentTable
GROUP   BY
		 DatabaseId
		,SchemaId
		,TableName
		,Parent_TableName

ORDER	BY
		 DatabaseName
		,[Level] DESC


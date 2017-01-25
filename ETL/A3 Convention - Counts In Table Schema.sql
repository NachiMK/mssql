/*==================================================
PULL ROW COUNTS FOR ALL TABLES IN THE ETL SCHEMA
ALSO PRINT SELECT COUNT(*) STATEMENTS FOR DIGGING
==================================================*/

DECLARE @SchemaFilter VARCHAR(1024) = '[DM]' --3,742,615CB

IF OBJECT_ID('tempdb..#RowCounts') IS NOT NULL DROP TABLE #RowCounts

CREATE TABLE #RowCounts ([Schema]		VARCHAR(1024) NOT NULL 
						,[TableName]	VARCHAR(1024) NOT NULL 
						,[SchemaTable]	VARCHAR(1024) NOT NULL 
						,[RowCount]		INT			  NOT NULL)

SET NOCOUNT ON

DECLARE @SchemaName		VARCHAR(1024)
DECLARE @TableName		VARCHAR(1024)
DECLARE @SQLInsertCmd	VARCHAR(1024)
DECLARE @SQLCountCmd	VARCHAR(1024)
DECLARE @SQLSelectAll	VARCHAR(1024)

DECLARE OBJECT_CURSOR CURSOR FOR

SELECT		 QUOTENAME(OBJECT_SCHEMA_NAME(T.object_id)) SchemaName 
			,QUOTENAME(OBJECT_NAME(T.object_id))		TableName
FROM		SYS.tables T
WHERE		QUOTENAME(OBJECT_SCHEMA_NAME(T.object_id)) = @SchemaFilter
ORDER BY	QUOTENAME(OBJECT_NAME(T.object_id))

OPEN OBJECT_CURSOR

FETCH NEXT FROM OBJECT_CURSOR
INTO @SchemaName, @TableName

WHILE (@@FETCH_STATUS = 0)
BEGIN
	SELECT @SQLInsertCmd = 'INSERT INTO #RowCounts SELECT ''' + @SchemaName + '''[SchemaName]
								, ''' + @TableName + ''' [TableName]
								, ''' + @SchemaName + '.' + @TableName + ''' [SchemaTable]
								, COUNT(*) [RowCount] 
								FROM ' + @SchemaName + '.' + @TableName + ' WITH(NOLOCK)'
	SELECT @SQLCountCmd  = 'SELECT COUNT(*) FROM ' + @TableName 
	SELECT @SQLSelectAll = 'SELECT *        FROM ' + @TableName
	PRINT  @SQLInsertCmd
	PRINT  @SQLCountCmd
	PRINT  @SQLSelectAll
	EXEC  (@SQLInsertCmd)
    
	FETCH NEXT FROM OBJECT_CURSOR
	INTO @SchemaName, @TableName
END

CLOSE OBJECT_CURSOR
DEALLOCATE OBJECT_CURSOR

GO

SELECT * FROM #RowCounts ORDER BY TableName


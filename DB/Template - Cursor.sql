DECLARE @SchemaName VARCHAR(100), @TableName VARCHAR(100)
DECLARE @SqlCountCmd VARCHAR(MAX)
DECLARE @SqlInsertCmd varchar(MAX)
DECLARE @SqlSelectAllCmd varchar(MAX)
DECLARE @SqlSelectAll varchar(MAX)

DECLARE OBJECT_CURSOR CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

SELECT		 QUOTENAME(OBJECT_SCHEMA_NAME(T.object_id)) SchemaName 
			,QUOTENAME(OBJECT_NAME(T.object_id))		TableName
FROM		SYS.tables T
WHERE		QUOTENAME(OBJECT_SCHEMA_NAME(T.object_id)) = '[DM]'
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


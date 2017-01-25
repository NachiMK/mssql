IF OBJECT_ID('tempdb..##LatestRows') IS NOT NULL
	DROP TABLE ##LatestRows
CREATE TABLE ##LatestRows
(
	 DBName		VARCHAR(75)	NOT NULL
	,TableName	VARCHAR(75)	NOT NULL
	,KeyID		VARCHAR(75)	NOT NULL
	,Value		VARCHAR(75)
	,KeyID2		VARCHAR(75)
	,Value2		VARCHAR(75)
	,PRIMARY KEY (DBName, TableName, KeyID)
)

DECLARE	@strSQLUseDB	VARCHAR(1000)
DECLARE @DBName			VARCHAR(100)


DECLARE @TableName		VARCHAR(200)
DECLARE @IdentityCol	VARCHAR(75)
DECLARE @UpdateDateCol	VARCHAR(75)
DECLARE @CreateDateCol	VARCHAR(75)
DECLARE @PKCols			VARCHAR(155)
DECLARE @PKCol1			VARCHAR(75)
DECLARE @PKCol2			VARCHAR(75)
DECLARE @SortCols		VARCHAR(200)
DECLARE @intPos			INT
DECLARE @PKColCnt		INT

DECLARE @strIDColSQL	VARCHAR(2000)
DECLARE @strCountSQL	VARCHAR(2000)
DECLARE @strPKColsSQL	VARCHAR(2000)

DECLARE @strUpdateColSQL	VARCHAR(2000)
DECLARE @strCreateColSQL	VARCHAR(2000)

DECLARE Database_Cursor CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

SELECT		name
FROM		msdb.sys.databases
WHERE		database_id > 4
AND			name NOT IN ('LiteSpeedLocal', 'LiteSpeedCentral', 'mnRegion', 'mnSystem', 'mnDBA')
ORDER BY	database_id

OPEN Database_Cursor

FETCH NEXT FROM Database_Cursor
INTO @DBName

WHILE (@@FETCH_STATUS = 0)
BEGIN
	SET @strSQLUseDB = 'USE ' + @DBName
	EXEC  (@strSQLUseDB)

	DECLARE TABLE_Cursor CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

	SELECT		S.name + '.' + T.Name AS TableName
	FROM		SYS.tables T
	JOIN		SYS.schemas	S	ON	S.schema_id = T.schema_id
	ORDER BY	T.name

	OPEN TABLE_Cursor

	FETCH NEXT FROM TABLE_Cursor
	INTO @TableName

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
    
		SET @IdentityCol	=	''
		SET @UpdateDateCol	=	''
		SET @CreateDateCol	=	''
		SET	@PKCols			=	''
		SET @PKCol1			=	''
		SET @PKCol2			=	''
		SET @SortCols		=	''
		SET @PKColCnt		=	0

		SET @strPKColsSQL	=	''

		SET @strUpdateColSQL	=	''
		SET @strCreateColSQL	=	''

		SELECT @IdentityCol		=	name FROM sys.columns WHERE OBJECT_ID = OBJECT_ID(@TableName) AND is_identity = 1
		SELECT @UpdateDateCol	=	name FROM sys.columns WHERE OBJECT_ID = OBJECT_ID(@TableName) AND name LIKE 'Updatedate'
		SELECT @CreateDateCol	=	name FROM sys.columns WHERE OBJECT_ID = OBJECT_ID(@TableName) AND name LIKE 'InsertDate'


		SELECT	@PKCols = @PKCols + SC.name + ','
				,@SortCols	=	@SortCols + SC.name + ' DESC' + ','
				,@PKColCnt	=	@PKColCnt + 1
		FROM	sys.indexes	SI
		JOIN	sys.index_columns	SIC	ON	SIC.index_id = SI.index_id
										AND SIC.object_id = SI.object_id
		JOIN	sys.columns			SC	ON	SC.object_id = SIC.object_id
										AND	SC.column_id = SIC.column_id
		WHERE	SI.OBJECT_ID = OBJECT_ID(@TableName) 
		AND		SI.is_primary_key = 1
		ORDER BY SIC.index_column_id ASC

		IF (@PKColCnt = 0) AND (LEN(ISNULL(@IdentityCol, '')) = 0)
		BEGIN
			SELECT	@PKCols = @PKCols + SC.name + ','
					,@SortCols	=	@SortCols + SC.name + ' DESC' + ','
					,@PKColCnt	=	@PKColCnt + 1
			FROM	sys.indexes	SI
			JOIN	sys.index_columns	SIC	ON	SIC.index_id = SI.index_id
											AND SIC.object_id = SI.object_id
			JOIN	sys.columns			SC	ON	SC.object_id = SIC.object_id
											AND	SC.column_id = SIC.column_id
			WHERE	SI.OBJECT_ID = OBJECT_ID(@TableName) 
			AND		SI.is_unique = 1
			ORDER BY SIC.index_column_id ASC
		END


		IF (LEN(ISNULL(@SortCols, '')) > 1) AND (RIGHT(ISNULL(@SortCols, ''), 1) = ',')
			SET @SortCols = LEFT(@SortCols, LEN(@SortCols) - 1)

		IF (LEN(ISNULL(@PKCols, '')) > 1) AND (RIGHT(ISNULL(@PKCols, ''), 1) = ',')
			SET @PKCols = LEFT(@PKCols, LEN(@PKCols) - 1)

		IF @PKColCnt >= 1
		BEGIN
			SET @intPos =	0
			SET @intPos =	CHARINDEX(',', @PKCols)

			IF @intPos > 0
				SET @PKCol1	= LEFT(@PKCols, @intPos-1)
			ELSE
				SET @PKCol1	= @PKCols

			IF @PKColCnt = 2
				SET @PKCol2	=	SUBSTRING(@PKCols, @intPos + 1, LEN(@PKCols) - @intPos)
		END

		PRINT '@TableName		:'	+ @TableName
		PRINT '@IdentityCol	:'		+ @IdentityCol
		PRINT '@UpdateDateCol	:'	+ @UpdateDateCol
		PRINT '@CreateDateCol	:'	+ @CreateDateCol
		PRINT '@PKCols			:'	+ @PKCols
		PRINT '@PKCol1			:'	+ @PKCol1
		PRINT '@PKCol2			:'	+ @PKCol2
		PRINT '@SortCols		:'	+ @SortCols

		IF LEN(ISNULL(@IdentityCol, '')) > 0 
		BEGIN
			SET @strIDColSQL = 'INSERT INTO ##LatestRows (DBName, TableName, KeyID, Value) '
			SET @strIDColSQL = @strIDColSQL + 'SELECT  ''' + @DBName + ''',''' + @TableName + ''', ''MaxIdentityCol'', ' + ' MAX(' + @IdentityCol + ') FROM ' + @TableName + ' WITH (READUNCOMMITTED)'
			PRINT @strIDColSQL
			EXEC (@strIDColSQL)
		END --LEN(ISNULL(@IdentityCol, '')) > 0 
		
		IF @PKColCnt = 2
		BEGIN
			SET @strPKColsSQL = 'INSERT INTO ##LatestRows (DBName, TableName, KeyID, Value, KeyID2, Value2) '
			SET @strPKColsSQL = @strPKColsSQL + 'SELECT TOP 1 ''' + @DBName + ''',''' + @TableName + ''', ''PKCol1'', ' + @PKCol1 + ', ''PKCol2'',  ' + @PKCol2 + ' FROM ' + @TableName + ' WITH (READUNCOMMITTED) ORDER BY '  + @SortCols
			PRINT @strPKColsSQL
			EXEC (@strPKColsSQL)
		END --LEN(ISNULL(@PKCol2, '')) > 0 

		ELSE IF @PKColCnt = 1
		BEGIN
			SET @strPKColsSQL = 'INSERT INTO ##LatestRows (DBName, TableName, KeyID, Value) '
			SET @strPKColsSQL = @strPKColsSQL + 'SELECT TOP 1 ''' + @DBName + ''',''' + @TableName + ''', ''PKCol1'', ' + @PKCol1 + ' FROM ' + @TableName + ' WITH (READUNCOMMITTED) ORDER BY '  + @SortCols
			PRINT @strPKColsSQL
			EXEC (@strPKColsSQL)
		END --LEN(ISNULL(@PKCol1, '')) > 0 


		IF LEN(ISNULL(@UpdateDateCol, '')) > 0 
		BEGIN
			SET @strUpdateColSQL = 'INSERT INTO ##LatestRows (DBName, TableName, KeyID, Value) '
			SET @strUpdateColSQL = @strUpdateColSQL + 'SELECT  ''' + @DBName + ''',''' + @TableName + ''', ''MaxUpdatedDate'', ' + ' CONVERT(VARCHAR, MAX(' + @UpdateDateCol + '), 101) + '' ''' + ' + CONVERT(VARCHAR, MAX(' + @UpdateDateCol + '),114) FROM ' + @TableName + ' WITH (READUNCOMMITTED)'
			PRINT @strUpdateColSQL
			EXEC (@strUpdateColSQL)
		END --LEN(ISNULL(@UpdateDateCol, '')) > 0 
	
		IF LEN(ISNULL(@CreateDateCol, '')) > 0 
		BEGIN
			SET @strCreateColSQL = 'INSERT INTO ##LatestRows (DBName, TableName, KeyID, Value) '
			SET @strCreateColSQL = @strCreateColSQL + 'SELECT  ''' + @DBName + ''',''' + @TableName + ''', ''MaxCreatedDate'', ' + ' CONVERT(VARCHAR, MAX(' + @CreateDateCol + '), 101) + '' ''' + ' + CONVERT(VARCHAR, MAX(' + @CreateDateCol + '),114) FROM ' + @TableName + ' WITH (READUNCOMMITTED)'
			PRINT @strCreateColSQL
			EXEC (@strCreateColSQL)
		END --LEN(ISNULL(@CreateDateCol, '')) > 0 

		-- GET COUNT
		SET @strCountSQL = 'INSERT INTO ##LatestRows (DBName, TableName, KeyID, Value) '
		SET @strCountSQL = @strCountSQL + 'SELECT  ''' + @DBName + ''',''' + @TableName + ''', ''RowCount'', ' + ' COUNT(*) FROM ' + @TableName + ' WITH (READUNCOMMITTED)'
		PRINT @strCountSQL
		EXEC (@strCountSQL)

		FETCH NEXT FROM TABLE_Cursor
		INTO @TableName
	END

	CLOSE TABLE_Cursor
	DEALLOCATE TABLE_Cursor

	FETCH NEXT FROM Database_Cursor
	INTO @DBName

END

CLOSE Database_Cursor
DEALLOCATE Database_Cursor

IF ((SELECT COUNT(*) FROM mnDBA.sys.tables WHERE NAME = '_NM_LASQL01_LatestRow') = 0)
BEGIN
	CREATE TABLE mnDBA.dbo._NM_LASQL01_LatestRow
	(
		 DBName		VARCHAR(75)	NOT NULL
		,TableName	VARCHAR(75)	NOT NULL
		,KeyID		VARCHAR(75)	NOT NULL
		,Value		VARCHAR(75)
		,KeyID2		VARCHAR(75)
		,Value2		VARCHAR(75)
		,CreatedDtTm	DATETIME2 NOT NULL CONSTRAINT DF_NM_LASQL01_LatestRow_CreatedDtTm DEFAULT GETDATE()
		,PRIMARY KEY (DBName, TableName, KeyID)		
	)
END

IF 0 = 0
	TRUNCATE TABLE mnDBA.dbo.[_NM_LASQL01_LatestRow]

IF 0 = 0
	INSERT INTO mnDBA.dbo.[_NM_LASQL01_LatestRow](
				 DBName
				,TableName
				,KeyID
				,Value
				,KeyID2
				,Value2)
	SELECT		 DBName
				,TableName
				,KeyID
				,Value
				,KeyID2
				,Value2 
	FROM	##LatestRows
	ORDER BY DBName, TableName, KeyID


SELECT * FROM ##LatestRows
SELECT * FROM mnDBA.dbo.[_NM_LASQL01_LatestRow]

SELECT * FROM ##LatestRows L1 WHERE KeyID = 'RowCount' AND NOT EXISTS (SELECT * FROM ##LatestRows L2 WHERE L2.DBName = L1.DBName AND L2.TableName = L1.TableName AND L2.KeyID != 'RowCount') AND Value != '0'


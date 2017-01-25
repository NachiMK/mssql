/*
	Find Drive Space Total Occupied and Total Available
*/

IF OBJECT_ID('tempdb..#DBOwner') IS NOT NULL
	DROP TABLE #DBOwner
CREATE TABLE #DBOwner
(
	 ServerName		SYSNAME
	,DatabaseName	SYSNAME
	,Finding		VARCHAR(100)
	,CurrentOwner	SYSNAME
	,Details		VARCHAR(500)
	--,InsertDtTm		DATETIME		CONSTRAINT DF_TMP_DBOwner DEFAULT GETDATE()
)

DECLARE @ServerName SYSNAME
DECLARE	@SQLCommand	NVARCHAR(MAX)

DECLARE OBJECT_CURSOR CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

SELECT		name
FROM		SYS.servers
WHERE		1 = 1
--AND			name	IN ('LASQL09', 'LASQL10')
AND			name	NOT IN ('CLSQL41', 'CLSQL44', 'CLSQL75', 'repl_distributor', 'TEMPSQL4STAGE')
ORDER BY	server_id

OPEN OBJECT_CURSOR

FETCH NEXT FROM OBJECT_CURSOR
INTO @ServerName

WHILE (@@FETCH_STATUS = 0)
BEGIN

	PRINT	'--------------------'
	PRINT	'Server: ' + @ServerName

	SET @SQLCommand = ' EXECUTE('''
	SET	@SQLCommand	=	@SQLCommand + 'SELECT ServerName = @@SERVERNAME , DatabaseName	=	[name]' + CHAR(13)
	SET	@SQLCommand	=	@SQLCommand + '		,Finding		=	''''Database Owner <> SA'''''  + CHAR(13)
	SET	@SQLCommand	=	@SQLCommand + '		,CurrentOwner	=	SUSER_SNAME(owner_sid)'  + CHAR(13)
	SET	@SQLCommand	=	@SQLCommand + '		,Details		=	( ''''Database name: '''' + [name] + ''''   '''' + ''''Owner name: '''' + SUSER_SNAME(owner_sid) )'  + CHAR(13)
	SET	@SQLCommand	=	@SQLCommand + 'FROM    SYS.DATABASES'  + CHAR(13)
	SET	@SQLCommand	=	@SQLCommand + 'WHERE   SUSER_SNAME(owner_sid) <> SUSER_SNAME(0x01)'  + CHAR(13)
	SET	@SQLCommand	=	@SQLCommand + 'AND		[NAME] NOT IN (''''model'''', ''''master'''', ''''tempdb'''', ''''msdb'''', ''''distribution'''')'  + CHAR(13)
	SET	@SQLCommand	=	@SQLCommand + ''') AT ' + @ServerName

	IF @ServerName = @@SERVERNAME
	BEGIN
		SET @SQLCommand = REPLACE(@SQLCommand, ' AT ', '')
		SET @SQLCommand = REPLACE(@SQLCommand, @@SERVERNAME, '')
	END

	PRINT  @SQLCommand

	BEGIN TRY	
		INSERT INTO #DBOwner
		EXEC(@SQLCommand)
	END TRY
	BEGIN CATCH
		SELECT ERROR_LINE(), ERROR_MESSAGE(), ERROR_NUMBER(), ServerName = @ServerName, Comments = 'ERROR in getting Owner information from Server'
	END CATCH

	PRINT	'--------------------'
	    
	FETCH NEXT FROM OBJECT_CURSOR
	INTO @ServerName
END

CLOSE OBJECT_CURSOR
DEALLOCATE OBJECT_CURSOR


-- RESULTS
SELECT *
		,Script  = 'EXEC(''ALTER AUTHORIZATION ON DATABASE:: [' + V.DatabaseName + '] TO sa'') ' + CASE WHEN V.ServerName != @@SERVERNAME THEN ' AT ' + V.ServerName ELSE '' END
FROM	#DBOwner V
WHERE	1 = 1
ORDER BY
		V.ServerName, V.DatabaseName


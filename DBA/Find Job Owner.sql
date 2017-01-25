/*
	Find Jobs without SA as the owner
*/

IF OBJECT_ID('tempdb..#JobOwner') IS NOT NULL
	DROP TABLE #JobOwner
CREATE TABLE #JobOwner
(
	 ServerName		SYSNAME
	,Finding		VARCHAR(100)
	,CurrentOwner	SYSNAME
	,JobName		SYSNAME
	,JobEnabled		CHAR(1)
	,Scheduled		CHAR(1)
	,JobCategory	SYSNAME
	,Details		VARCHAR(500)
	--,InsertDtTm		DATETIME		CONSTRAINT DF_TMP_DBOwner DEFAULT GETDATE()
)

DECLARE @ServerName SYSNAME
DECLARE	@SQLCommand	NVARCHAR(MAX)

DECLARE OBJECT_CURSOR CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

SELECT		name
FROM		SYS.servers
WHERE		1 = 1
--AND			name	IN ('CLSQL43', 'LASQL10')
AND			name	NOT IN ('CLSQL41', 'CLSQL44', 'CLSQL43', 'CLSQL75', 'repl_distributor', 'TEMPSQL4STAGE')
ORDER BY	server_id

OPEN OBJECT_CURSOR

FETCH NEXT FROM OBJECT_CURSOR
INTO @ServerName

WHILE (@@FETCH_STATUS = 0)
BEGIN

	PRINT	'--------------------'
	PRINT	'Server: ' + @ServerName

	SET @SQLCommand = ''
	SET @SQLCommand = @SQLCommand + 'EXECUTE('''
	SET @SQLCommand = @SQLCommand + CHAR(13) + 'SELECT  ServerName	= @@SERVERNAME'
	SET @SQLCommand = @SQLCommand + CHAR(13) + '		,Finding		= ''''Jobs Owned By Users'''''
	SET @SQLCommand = @SQLCommand + CHAR(13) + '		,CurrentOwner	= SUSER_SNAME(j.owner_sid)'
	SET @SQLCommand = @SQLCommand + CHAR(13) + '		,JobName		= J.name'
	SET @SQLCommand = @SQLCommand + CHAR(13) + '		,JobEnabled		= CASE WHEN J.enabled = 1 THEN ''''Y'''' ELSE ''''N'''' END'
	SET @SQLCommand = @SQLCommand + CHAR(13) + '		,Scheduled		= CASE WHEN S.job_id IS NOT NULL	THEN  ''''Y'''' ELSE ''''N'''' END'
	SET @SQLCommand = @SQLCommand + CHAR(13) + '		,JobCategory	= C.name'
	SET @SQLCommand = @SQLCommand + CHAR(13) + '		,Details		= ''''Job ['''' + j.name + ''''] is owned by ['''' + SUSER_SNAME(j.owner_sid) + ''''] - meaning if their login is disabled or not available due to Active Directory problems, the job will stop working.'''''
	SET @SQLCommand = @SQLCommand + CHAR(13) + 'FROM    msdb.dbo.sysjobs			j'
	SET @SQLCommand = @SQLCommand + CHAR(13) + 'LEFT'
	SET @SQLCommand = @SQLCommand + CHAR(13) + 'JOIN	msdb.dbo.syscategories		C	ON	C.category_id = j.category_id'
	SET @SQLCommand = @SQLCommand + CHAR(13) + 'LEFT'
	SET @SQLCommand = @SQLCommand + CHAR(13) + 'JOIN	msdb.dbo.sysjobschedules	S	ON	S.job_id = j.job_id'
	SET @SQLCommand = @SQLCommand + CHAR(13) + 'WHERE   SUSER_SNAME(j.owner_sid) <> SUSER_SNAME(0x01)'
	SET	@SQLCommand	=	@SQLCommand + ''') AT ' + @ServerName


	IF @ServerName = @@SERVERNAME
	BEGIN
		SET @SQLCommand = REPLACE(@SQLCommand, ' AT ', '')
		SET @SQLCommand = REPLACE(@SQLCommand, @@SERVERNAME, '')
	END

	PRINT  'SQL:' + @SQLCommand

	BEGIN TRY	
		INSERT INTO #JobOwner
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
FROM	#JobOwner V
WHERE	1 = 1
--AND		(V.JobEnabled = 'Y' OR V.Scheduled = 'Y')
AND		V.CurrentOwner NOT IN ('distributor_admin', '##MS_SSISServerCleanupJobLogin##')
--AND		V.ServerName != 'CLSQL76'
ORDER BY
		V.ServerName, V.JobName

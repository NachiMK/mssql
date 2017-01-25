USE mnDBA
GO
IF OBJECT_ID('dbo.usp_StopOrStartLogReaderAgents') IS NOT NULL
	DROP PROCEDURE dbo.usp_StopOrStartLogReaderAgents
GO
CREATE PROCEDURE dbo.usp_StopOrStartLogReaderAgents
	 @Publisher						SYSNAME						-- Any DB server that publishes
	,@Databases						SYSNAME			=	NULL	-- COULD BE 'ALL' (All will stop/start replication on list of replicated DBs on the server)  or Comma separated list of DB
	,@StopOrStart					VARCHAR(5)		=	NULL	-- STOP/START/NONE
	,@PrintCommandsAndDoNotApply	BIT				=	NULL	-- 1 or 0
	,@Recipients					NVARCHAR(250)	=	NULL	-- Any email address
AS EXECUTE AS CALLER
BEGIN

	SET NOCOUNT ON;

	DECLARE	@CRLF				NVARCHAR(4)	= CHAR(13) + CHAR(10)
	DECLARE @AllDB				NVARCHAR(5)	= N'ALL'
	
	DECLARE	@query				NVARCHAR(MAX)
	DECLARE	@SqlCmd				NVARCHAR(MAX)
	DECLARE	@body				VARCHAR(4000)
	DECLARE	@subject			NVARCHAR(250)
	DECLARE	@subject1			NVARCHAR(250)
	DECLARE	@i_recipients		NVARCHAR(1000)
	DECLARE	@publication_server NVARCHAR(250)
	DECLARE	@publisher_db		NVARCHAR(250)
	DECLARE	@publication_name	NVARCHAR(250)
	DECLARE	@JObProcName		NVARCHAR(200)	=	N''


	DECLARE @StoppedReplOnCLSQL76		BIT = NULL
	DECLARE @StoppedReplOnLACORPDIST02	BIT = NULL

	IF OBJECT_ID('tempdb..#TmpDatabases') IS NOT NULL
		DROP TABLE #TmpDatabases
	CREATE TABLE #TmpDatabases
	(
		DBName	sysname NOT NULL
	)

	SET XACT_ABORT ON 

	SET	@Publisher					=	ISNULL(@Publisher, '')
	SET	@Databases					=	ISNULL(@Databases, N'ALL' )
	SET	@StopOrStart				=	ISNULL(@StopOrStart, N'NONE' )
	SET	@PrintCommandsAndDoNotApply	=	ISNULL(@PrintCommandsAndDoNotApply, 1)
	SET	@Recipients					=	ISNULL(@Recipients, N'db@spark.net' )

	SET @subject					= @Publisher + ' Replication Stop/Start ' + @publisher_db
	SET @subject1					= @Publisher + ' Replication Stop/Start Process Failure for ' + @publisher_db
	SET @i_recipients				= @Recipients

	IF @StopOrStart = 'STOP'
		SET @JObProcName = N'msdb.dbo.sp_stop_job @job_name = '
	ELSE IF @StopOrStart = 'START'
		SET @JObProcName = N'msdb.dbo.sp_start_job @job_name = '

	IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'distribution')
	BEGIN
		PRINT 'This proc can be run only on a distribution database'
		RETURN
	END
	---------------STOPPING OR STARTING REPLICATION---------------------
	SET @StoppedReplOnCLSQL76		= NULL
	SET @StoppedReplOnLACORPDIST02	= NULL


	IF @Databases = @AllDB
	BEGIN
		INSERT	INTO #TmpDatabases(DBName)
		SELECT DISTINCT
				DBName	= Pub.publisher_db
		FROM	CLSQL76.distribution.dbo.MSpublications		Pub
		JOIN	CLSQL76.master.dbo.sysservers				Publisher	ON Publisher.srvid			= Pub.publisher_id
		WHERE	Publisher.srvname = @Publisher
	END
	ELSE IF LEN(ISNULL(@Databases, '')) > 0
	BEGIN
		-- Split string into comma separated values
		DECLARE @String    VARCHAR(max)

		WHILE LEN(@Databases) > 0
		BEGIN
			SET @String      = LEFT(@Databases, 
									ISNULL(NULLIF(CHARINDEX(',', @Databases) - 1, -1),
									LEN(@Databases)))
			SET @Databases = SUBSTRING(@Databases,
											ISNULL(NULLIF(CHARINDEX(',', @Databases), 0),
											LEN(@Databases)) + 1, LEN(@Databases))

			INSERT INTO #TmpDatabases(DBName)
			SELECT DISTINCT
					DBName	= Pub.publisher_db
			FROM	distribution.dbo.MSpublications		Pub
			JOIN	master.dbo.sysservers				Publisher	ON Publisher.srvid			= Pub.publisher_id
			WHERE	Publisher.srvname = @Publisher
			AND		Pub.publisher_db  = @String
			AND		NOT EXISTS (SELECT * FROM #TmpDatabases T1 WHERE T1.DBName = Pub.publisher_db)
		END
	END

	IF @PrintCommandsAndDoNotApply = 1
		SELECT sComments = '#TmpDatabases', * FROM #TmpDatabases

	IF EXISTS ( SELECT	1 FROM	#TmpDatabases T)
	BEGIN

		SET @SqlCmd = N'' + @CRLF

		;WITH CTEPublications
		AS
		(
		SELECT DISTINCT
				 publication_server	= Publisher.srvname
				,publisher_db		= Pub.publisher_db
				,publication_name	= Pub.publication  
				,LogReaderAgent		= jobs.name
		FROM	distribution.dbo.MSpublications		Pub
		JOIN	distribution.dbo.MSsubscriptions	Sub			ON Pub.publication_id		= Sub.publication_id
		JOIN	master.dbo.sysservers				Subscriber	ON Sub.subscriber_id		= Subscriber.srvid
		JOIN	master.dbo.sysservers				Publisher	ON Publisher.srvid			= Pub.publisher_id
		JOIN	distribution.dbo.MSlogreader_agents LogReader	ON	LogReader.publisher_id	= Pub.publisher_id
																AND	LogReader.publisher_db	= Pub.publisher_db
		JOIN	msdb.dbo.sysjobs					jobs		ON	jobs.job_id				= LogReader.job_id
		WHERE	Publisher.srvname = @Publisher
		AND		EXISTS (SELECT * FROM #TmpDatabases T WHERE T.DBName = Pub.publisher_db)
		)
		SELECT	@SqlCmd = @SqlCmd +  N'EXEC ' + @JObProcName + N'N''' + CONVERT(NVARCHAR(1000), CTEPublications.LogReaderAgent) + N'''' + @CRLF
		FROM	CTEPublications
				
		PRINT '-- T-SQL Script to Disable Log Reader agents for publisher : ' + @Publisher + ' on distributor ' + CONVERT(VARCHAR, @@SERVERNAME)
		PRINT '/*' + ISNULL(@SqlCmd, '--NO SCRIPT') + '*/'
		PRINT '-- T-SQL Script to Disable Log Reader  --'

		IF @PrintCommandsAndDoNotApply = 0
		BEGIN

			EXEC (@SqlCmd)
			SET @StoppedReplOnCLSQL76		= 1
		
			SELECT	@body = '***STOPPED/STARTED All Log reader agents from ' + @Publisher + ' in ' + @@SERVERNAME + ' ***' 

			EXEC msdb..sp_send_dbmail
				 @recipients	= @i_recipients
				,@profile_name	= 'ADMIN'
				,@subject		= @subject
				,@body			= @body
		END
	END
END
GO
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'distribution')
BEGIN
	IF OBJECT_ID('dbo.usp_StopOrStartLogReaderAgents') IS NOT NULL
		DROP PROCEDURE dbo.usp_StopOrStartLogReaderAgents
	PRINT 'Log Readers can be disabled only on distribution servers'
END
GO

/*

	--Testing Code
	EXEC dbo.usp_StopOrStartLogReaderAgents @publisher = 'LASQL02', @Databases = 'All' , @StopOrStart = 'Stop' , @PrintCommandsAndDoNotApply = 1, @Recipients = 'nmuthukumar@spark.net'
	GO
	EXEC dbo.usp_StopOrStartLogReaderAgents @publisher = 'LASQL02', @Databases = 'mnIMail1' , @StopOrStart = 'Stop' , @PrintCommandsAndDoNotApply = 1, @Recipients = 'nmuthukumar@spark.net'
	GO
	EXEC dbo.usp_StopOrStartLogReaderAgents @publisher = 'LASQL02', @Databases = 'NONE' , @StopOrStart = 'Stop' , @PrintCommandsAndDoNotApply = 1, @Recipients = 'nmuthukumar@spark.net'
	GO
	EXEC dbo.usp_StopOrStartLogReaderAgents @publisher = 'LASQL02', @PrintCommandsAndDoNotApply = 1, @Recipients = 'nmuthukumar@spark.net'
	GO

	EXEC dbo.usp_StopOrStartLogReaderAgents @publisher = 'LASQL02', @Databases = 'All' , @StopOrStart = 'START' , @PrintCommandsAndDoNotApply = 1, @Recipients = 'nmuthukumar@spark.net'
	GO
*/


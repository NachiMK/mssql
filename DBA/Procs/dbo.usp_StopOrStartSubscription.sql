USE mnDBA
GO
IF OBJECT_ID('dbo.usp_StopOrStartSubscription') IS NOT NULL
	DROP PROCEDURE dbo.usp_StopOrStartSubscription
GO
CREATE PROCEDURE dbo.usp_StopOrStartSubscription
	 @Subscriber					SYSNAME			-- Any DB server or just NULL for current server where this query is running on.
	,@Databases						SYSNAME			=	NULL	-- COULD BE 'ALL' (All will stop/start replication on list of replicated DBs on the server)  or Comma separated list of DB
	,@StopOrStart					VARCHAR(5)		=	NULL	-- STOP/START/NONE
	,@PrintCommandsAndDoNotApply	BIT				=	NULL	-- 1 or 0
	,@Recipients					NVARCHAR(250)	=	NULL	-- Any email address
AS EXECUTE AS CALLER
BEGIN

	SET NOCOUNT ON;

	DECLARE	@CRLF				NVARCHAR(4)	= CHAR(13) + CHAR(10)
	DECLARE @AllDB				NVARCHAR(5)	= N'ALL'
	
	DECLARE @ServerName			SYSNAME
	DECLARE	@query				NVARCHAR(MAX)
	DECLARE	@SqlCmd				VARCHAR(MAX)
	DECLARE	@body				VARCHAR(4000)
	DECLARE	@subject			NVARCHAR(250)
	DECLARE	@i_recipients		NVARCHAR(1000)
	DECLARE	@publication_server NVARCHAR(250)
	DECLARE	@publisher_db		NVARCHAR(250)
	DECLARE	@publication_name	NVARCHAR(250)
	DECLARE	@ReplProcName		NVARCHAR(200)	=	N''


	DECLARE @StoppedReplOnCLSQL76		BIT = NULL
	DECLARE @StoppedReplOnLACORPDIST02	BIT = NULL

	IF OBJECT_ID('tempdb..#TmpDatabases') IS NOT NULL
		DROP TABLE #TmpDatabases
	CREATE TABLE #TmpDatabases
	(
		DBName	sysname NOT NULL
	)

	SET XACT_ABORT ON 

	SET	@ServerName					=	ISNULL(@Subscriber, N'')
	SET	@Databases					=	ISNULL(@Databases, N'ALL' )
	SET	@StopOrStart				=	ISNULL(@StopOrStart, N'NONE' )
	SET	@PrintCommandsAndDoNotApply	=	ISNULL(@PrintCommandsAndDoNotApply, 1)
	SET	@Recipients					=	ISNULL(@Recipients, N'db@spark.net' )

	SET @subject					= @ServerName + ' Replication Stop/Start ' + @publisher_db
	SET @i_recipients				= @Recipients

	IF @StopOrStart = 'STOP'
		SET @ReplProcName = 'sp_MSstopdistribution_agent'
	ELSE IF @StopOrStart = 'START'
		SET @ReplProcName = 'sp_MSstartdistribution_agent'

	---------------STOPPING OR STARTING REPLICATION---------------------
	SET @StoppedReplOnCLSQL76		= NULL
	SET @StoppedReplOnLACORPDIST02	= NULL

	IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'distribution')
	BEGIN
		PRINT 'This proc can be run only on a distribution database'
		RETURN
	END

	IF @Databases = @AllDB
	BEGIN
		INSERT	INTO #TmpDatabases(DBName)
		SELECT DISTINCT
				DBName	= Sub.subscriber_db
		FROM	CLSQL76.distribution.dbo.MSsubscriptions	Sub
		JOIN	CLSQL76.master.dbo.sysservers				Subscriber	ON Subscriber.srvid			= Sub.subscriber_id
		WHERE	Subscriber.srvname = @ServerName
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
					DBName	= Sub.subscriber_db
			FROM	CLSQL76.distribution.dbo.MSsubscriptions	Sub
			JOIN	CLSQL76.master.dbo.sysservers				Subscriber	ON Subscriber.srvid			= Sub.subscriber_id
			WHERE	Subscriber.srvname = @ServerName
			AND		Sub.subscriber_db = @String
			AND		NOT EXISTS (SELECT * FROM #TmpDatabases T1 WHERE T1.DBName = Sub.subscriber_db)
		END
	END

	IF @PrintCommandsAndDoNotApply = 1
		SELECT sComments = '#TmpDatabases', * FROM #TmpDatabases

	IF EXISTS ( SELECT	1 FROM #TmpDatabases T)
	BEGIN

		SET @SqlCmd = '' + @CRLF

		;WITH CTEPublications
		AS
		(
		SELECT DISTINCT
				 publication_server	= Publisher.srvname
				,publisher_db		= p.publisher_db
				,publication_name	= p.publication  
				,subscriber_db		= Sub.subscriber_db
		FROM	CLSQL76.distribution.dbo.MSpublications p
		JOIN	CLSQL76.distribution.dbo.MSsubscriptions Sub ON p.publication_id = Sub.publication_id
		JOIN	CLSQL76.master.dbo.sysservers Subscriber ON Sub.subscriber_id = Subscriber.srvid
		JOIN	CLSQL76.master.dbo.sysservers Publisher ON Publisher.srvid = p.publisher_id
		WHERE	Subscriber.srvname = @ServerName
		AND		EXISTS (SELECT * FROM #TmpDatabases T WHERE T.DBName = Sub.subscriber_db)
		)
		SELECT	@SqlCmd = @SqlCmd +  N'EXEC CLSQL76.distribution.dbo.' + @ReplProcName + ' @publisher			= ''' + publication_server + ''''
						+ N',@publisher_db		= ''' + publisher_db		+ ''''
						+ N',@publication		= ''' + publication_name	+ ''''
						+ N',@subscriber		= ''' + @ServerName			+ ''''
						+ N',@subscriber_db		= ''' + subscriber_db		+ ''''
						+ @CRLF

		FROM	CTEPublications
				
		PRINT '-- T-SQL Script to Disable Subscription to Server: ' + @ServerName
		PRINT '/*' + ISNULL(@SqlCmd, '--NO SCRIPT') + '*/'
		PRINT '-- T-SQL Script to Disable Subscription  --'

		IF @PrintCommandsAndDoNotApply = 0
		BEGIN

			EXEC (@SqlCmd)
			SET @StoppedReplOnCLSQL76		= 1
		
			SELECT	@body = '***STOPPED/STARTED All Subscriptions To ' + @ServerName + ' in CLSQL76 ***' 

			EXEC msdb..sp_send_dbmail
				 @recipients	= @i_recipients
				,@profile_name	= 'ADMIN'
				,@subject		= @subject
				,@body			= @body
		END

		IF EXISTS (SELECT * FROM sys.servers WHERE name = 'LACORPDIST02')
		BEGIN
			SET @SqlCmd = '' + @CRLF

			;WITH CTEPublications
			AS
			(
				SELECT DISTINCT
						 publication_server	= Publisher.srvname
						,publisher_db		= p.publisher_db
						,publication_name	= p.publication  
						,subscriber_db		= Sub.subscriber_db
				FROM	LACORPDIST02.distribution.dbo.MSpublications p
				JOIN	LACORPDIST02.distribution.dbo.MSsubscriptions Sub ON p.publication_id = Sub.publication_id
				JOIN	LACORPDIST02.master.dbo.sysservers Subscriber ON Sub.subscriber_id = Subscriber.srvid
				JOIN	LACORPDIST02.master.dbo.sysservers Publisher ON Publisher.srvid = p.publisher_id
				WHERE	Subscriber.srvname = @ServerName
				AND		EXISTS (SELECT * FROM #TmpDatabases T WHERE T.DBName = Sub.subscriber_db)
			)
			SELECT	@SqlCmd = @SqlCmd +  N'EXEC LACORPDIST02.distribution.dbo.' + @ReplProcName + ' @publisher			= ''' + publication_server + ''''
							+ N',@publisher_db		= ''' + publisher_db		+ ''''
							+ N',@publication		= ''' + publication_name	+ ''''
							+ N',@subscriber		= ''' + @ServerName			+ ''''
							+ N',@subscriber_db		= ''' + subscriber_db		+ ''''
							+ @CRLF

			FROM	CTEPublications
				
			PRINT '-- T-SQL Script to Disable Subscription to Server: ' + @ServerName
			PRINT '/*' + ISNULL(@SqlCmd, '--NO SCRIPT') + '*/'
			PRINT '-- T-SQL Script to Disable Subscription  --'

			IF @PrintCommandsAndDoNotApply = 0
			BEGIN

				EXEC (@SqlCmd)
				SET @StoppedReplOnLACORPDIST02		= 1
		
				SELECT	@body = '***STOPPED/STARTED All Subscriptions To ' + @ServerName + ' in LACORPDIST02 ***' 

				EXEC msdb..sp_send_dbmail
					 @recipients	= @i_recipients
					,@profile_name	= 'ADMIN'
					,@subject		= @subject
					,@body			= @body
			END

		END

	END
END
GO
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'distribution')
BEGIN
	IF OBJECT_ID('dbo.usp_StopOrStartLogReaderAgents') IS NOT NULL
		DROP PROCEDURE dbo.usp_StopOrStartLogReaderAgents
	PRINT 'Stopping Subscriptions can be done only on distribution servers'
END
GO

/*

	--Testing Code
	EXEC dbo.usp_StopOrStartSubscription @Subscriber = N'LASQL02', @Databases = 'All' , @StopOrStart = 'Stop' , @PrintCommandsAndDoNotApply = 1, @Recipients = 'nmuthukumar@spark.net'
	GO
	EXEC dbo.usp_StopOrStartSubscription @Subscriber = N'LASQL02', @Databases = 'mnMember_ProdFlat' , @StopOrStart = 'Stop' , @PrintCommandsAndDoNotApply = 1, @Recipients = 'nmuthukumar@spark.net'
	GO
	EXEC dbo.usp_StopOrStartSubscription @Subscriber = N'LASQL02', @Databases = 'NONE' , @StopOrStart = 'Stop' , @PrintCommandsAndDoNotApply = 1, @Recipients = 'nmuthukumar@spark.net'
	GO
	EXEC dbo.usp_StopOrStartSubscription @Subscriber = N'LASQL02', @PrintCommandsAndDoNotApply = 1, @Recipients = 'nmuthukumar@spark.net'
	GO

	EXEC dbo.usp_StopOrStartSubscription @Subscriber = N'LASQL02', @Databases = 'All' , @StopOrStart = 'Start' , @PrintCommandsAndDoNotApply = 1, @Recipients = 'nmuthukumar@spark.net'
	GO
*/


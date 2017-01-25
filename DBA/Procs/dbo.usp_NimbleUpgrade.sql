USE [mnDBA]
GO

IF OBJECT_ID('dbo.usp_NimbleUpgrade') IS NOT NULL
	DROP PROCEDURE dbo.usp_NimbleUpgrade
GO

/****** Object:  StoredProcedure [dbo].[usp_NimbleUpgrade]    Script Date: 9/29/2016 9:01:08 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_NimbleUpgrade](
	 @DBName						NVARCHAR(250)
	,@ServerName					NVARCHAR(250)
	,@PrintCommandsDoNotApply		BIT
	,@OfflineWithRollback			BIT				=	0
	,@DataDrive						NVARCHAR(10)	=	N'H:'
	,@LogDrive						NVARCHAR(10)	=	N'L:'
	,@DataDriveFolder				NVARCHAR(10)	=	N'SQL_DATA'
	,@LogDriveFolder				NVARCHAR(10)	=	N'SQL_LOG'
	,@Recipients					NVARCHAR(250)	=	N'db@spark.net'

) WITH EXEC AS CALLER
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE	@CRLF				NVARCHAR(4)	=	CHAR(13) + CHAR(10)

	DECLARE	@query				NVARCHAR(MAX)
	DECLARE	@SqlCmd				VARCHAR(MAX)
	DECLARE	@body				VARCHAR(MAX)
	DECLARE	@subject			NVARCHAR(250)	= @ServerName + ' Nimble Upgrade Process For ' + @DBName
	DECLARE	@subject1			NVARCHAR(250)	= @ServerName + ' Nimble Upgrade Process Failure for ' + @DBName
	DECLARE	@i_recipients		NVARCHAR(MAX)	= ISNULL(@Recipients, N'db@spark.net')
	DECLARE	@publication_server NVARCHAR(250)
	DECLARE	@publisher_db		NVARCHAR(250)
	DECLARE	@publication_name	NVARCHAR(250)


	DECLARE @StoppedReplOnCLSQL76		BIT = NULL
	DECLARE @StoppedReplOnLACORPDIST02	BIT = NULL


	DECLARE  @SourceFolder		NVARCHAR(250) = N''	
			,@DestinationFolder	NVARCHAR(250) = N''
			,@FileName			NVARCHAR(250) = N''

	DECLARE  @TargetDataDrive	NVARCHAR(250)	=	N'H:'
			,@TargetLogDrive	NVARCHAR(250)	=	N'L:'
			,@TargetDataFolder	NVARCHAR(250)	=	N'SQL_DATA'
			,@TargetLogFolder	NVARCHAR(250)	=	N'SQL_LOG'
			,@DBFile			NVARCHAR(250)


	DECLARE  @TargetDataFullPath	NVARCHAR(250)	=	''
			,@TargetLogFullPath		NVARCHAR(250)	=	''

	IF OBJECT_ID('tempdb..#DBFiles') IS NOT NULL
		DROP TABLE #DBFiles

	IF @DataDrive IS NOT NULL AND (LEN(ISNULL(@DataDrive, '')) > 0)
		SET @TargetDataDrive = @DataDrive

	IF @LogDrive IS NOT NULL AND (LEN(ISNULL(@LogDrive, '')) > 0)
		SET @TargetLogDrive = @LogDrive

	IF @DataDriveFolder IS NOT NULL AND (LEN(ISNULL(@DataDriveFolder, '')) > 0)
		SET @TargetDataFolder = @DataDriveFolder

	IF @LogDriveFolder IS NOT NULL AND (LEN(ISNULL(@LogDriveFolder, '')) > 0)
		SET @TargetLogFolder = @LogDriveFolder


	SET @TargetDataFullPath = @TargetDataDrive + N'\' + @TargetDataFolder
	SET @TargetLogFullPath	= @TargetLogDrive  + N'\' + @TargetLogFolder

	SET @PrintCommandsDoNotApply = ISNULL(@PrintCommandsDoNotApply, 1)
	SET @OfflineWithRollback	= ISNULL(@OfflineWithRollback, 0)

	SET XACT_ABORT ON 

	SELECT	 ExistingPhysical_name	= physical_name
			,DBName					= D.name
			,SourceFolder			= LEFT(MF.physical_name, CHARINDEX('\', MF.physical_name, 4)- 1)
			,FileName				= SUBSTRING(MF.physical_name, LEN(LEFT(MF.physical_name, CHARINDEX('\', MF.physical_name, 4) + 1)), (LEN(MF.physical_name) - LEN(LEFT(MF.physical_name, CHARINDEX('\', MF.physical_name, 4)- 1))) )
			,DestinationFolder		= CASE WHEN physical_name LIKE  '%.ldf' THEN @TargetLogFullPath ELSE @TargetDataFullPath END
			,LogicalName			= MF.name 
	INTO	#DBFiles
	FROM	sys.master_files MF
	INNER
	JOIN	sys.databases D ON D.database_id	= MF.database_id
	WHERE	MF.database_id = DB_ID(@DBName)

	IF EXISTS (
				SELECT	*
				FROM	#DBFiles
				WHERE	DBName		= @DBName
				AND		ExistingPhysical_name LIKE @TargetDataDrive + '%'
				)
	BEGIN
			SELECT	@body = '***DATA FILE ALREADY IN TARGET LOCATION ' + @DBName + ' ***'

			EXEC msdb..sp_send_dbmail
				 @recipients = @i_recipients
				,@profile_name = 'ADMIN'
				,@subject = @subject
				,@body = @body

			RETURN
	END

	IF (@DBName IS NOT NULL AND @ServerName IS NOT NULL)
	BEGIN

		------------------DISABLE LPD-----------------------
		IF EXISTS ( SELECT	1
					FROM	CLSQL76.mnSystem.dbo.PhysicalDatabase
					WHERE	ServerName = @ServerName
					AND		PhysicalDatabaseName = @DBName )
		BEGIN 

			SET @SqlCmd	=	''
			SET @SqlCmd	=	@SqlCmd + N'UPDATE	CLSQL76.mnSystem.dbo.PhysicalDatabase ' + @CRLF
									+ N'SET		ActiveFlag = 0 ' + @CRLF
									+ N'WHERE	ServerName				= ''' + @ServerName + ''''	+ @CRLF
									+ N'AND		PhysicalDatabaseName	= ''' + @DBName		+ ''''	+ @CRLF

			SET @SqlCmd	=	@SqlCmd + N'UPDATE	CLSQL76.mnSystem.dbo.Property ' + @CRLF
									+ N'SET		PropertyValue = NEWID() ' + @CRLF
									+ N'WHERE	Owner = ''mnSystem''  ' + @CRLF
									+ N'AND		PropertyName = ''LogicalDatabaseVersion''  ' + @CRLF

			PRINT '-- T-SQL TO DISABLE LPD --'
			PRINT @SqlCmd
			PRINT '-- T-SQL TO DISABLE LPD --'
			
			IF @PrintCommandsDoNotApply = 0
			BEGIN					
				EXEC(@SqlCmd)

				SELECT	@body = '***DISABLED LPD FOR ' + @DBName + ' ***' 

				EXEC msdb..sp_send_dbmail
					 @recipients = @i_recipients
					,@profile_name = 'ADMIN'
					,@subject = @subject
					,@body = @body
			END

		END
		ELSE
		BEGIN
	
			PRINT '-- NO LPD Entry to Disable --'

			SELECT	@body = '***NO LPD ENTRY TO DISABLE FOR ' + @DBName + ' ***' 

			EXEC msdb..sp_send_dbmail
				 @recipients = @i_recipients
				,@profile_name = 'ADMIN'
				,@subject = @subject1
				,@body = @body

		END

		---------------STOPPING REPLICATION---------------------
		SET @StoppedReplOnCLSQL76		= NULL
		SET @StoppedReplOnLACORPDIST02	= NULL

		IF EXISTS ( SELECT	1
					FROM	sys.databases
					WHERE	OBJECT_ID(name + '.dbo.MSreplication_objects') IS NOT NULL
					AND		name = @DBName )
		BEGIN

			SELECT	 @publication_server = NULL
					,@publisher_db = NULL
					,@publication_name = NULL

	 
			SELECT DISTINCT
					 @publication_server = srv.srvname
					,@publisher_db = p.publisher_db
					,@publication_name = p.publication  
			FROM	CLSQL76.distribution.dbo.MSpublications p
			JOIN	CLSQL76.distribution.dbo.MSsubscriptions s ON p.publication_id = s.publication_id
			JOIN	CLSQL76.master.dbo.sysservers ss ON s.subscriber_id = ss.srvid
			JOIN	CLSQL76.master.dbo.sysservers srv ON srv.srvid = p.publisher_id
			WHERE	ss.srvname = @ServerName
			AND		s.subscriber_db = @DBName	

			IF (@publication_server IS NOT NULL) AND (@publisher_db IS NOT NULL) AND (@publication_name IS NOT NULL)
			BEGIN
				
				SET @SqlCmd = ''
				SET @SqlCmd	=	  N'EXEC CLSQL76.distribution.dbo.sp_MSstopdistribution_agent @publisher			= ''' + @publication_server + ''''
								+ N',@publisher_db		= ''' + @publisher_db		+ ''''
								+ N',@publication		= ''' + @publication_name	+ ''''
								+ N',@subscriber		= ''' + @ServerName			+ ''''
								+ N',@subscriber_db		= ''' + @DBName				+ ''''


				PRINT '-- T-SQL Script to Disable Subscription Pub Name: ' + @publication_name
				PRINT @SqlCmd
				PRINT '-- T-SQL Script to Disable Subscription  --'
				
				IF @PrintCommandsDoNotApply = 0
				BEGIN

					EXEC (@SqlCmd)
					SET @StoppedReplOnCLSQL76		= 1
		
					SELECT	@body = '***STOPPED FOR THE PUBLISHER ' + @publication_name + ' in CLSQL76 ***' 

					EXEC msdb..sp_send_dbmail
						 @recipients = @i_recipients
						,@profile_name = 'ADMIN'
						,@subject = @subject
						,@body = @body
				END
			END
			ELSE
			BEGIN
				PRINT '-- NO PUBLICATION FROM CLSQL76 TO BE STOPPED'
				SELECT	@body = '***NO PUBLICATION FROM CLSQL76 TO BE STOPPED***' 
				EXEC msdb..sp_send_dbmail
					 @recipients = @i_recipients
					,@profile_name = 'ADMIN'
					,@subject = @subject
					,@body = @body
			END

			SELECT	 @publication_server = NULL
					,@publisher_db = NULL
					,@publication_name = NULL

			SELECT DISTINCT
					 @publication_server = srv.srvname
					,@publisher_db = p.publisher_db
					,@publication_name = p.publication  
			FROM	LACORPDIST02.distribution.dbo.MSpublications p
			JOIN	LACORPDIST02.distribution.dbo.MSsubscriptions s ON p.publication_id = s.publication_id
			JOIN	LACORPDIST02.master.dbo.sysservers ss ON s.subscriber_id = ss.srvid
			JOIN	LACORPDIST02.master.dbo.sysservers srv ON srv.srvid = p.publisher_id
			WHERE	ss.srvname = @ServerName
			AND		s.subscriber_db = @DBName	

			IF (@publication_server IS NOT NULL) AND (@publisher_db IS NOT NULL) AND (@publication_name IS NOT NULL)
			BEGIN

				SET @SqlCmd = ''
				SET @SqlCmd	=	  N'EXEC LACORPDIST02.distribution.dbo.sp_MSstopdistribution_agent @publisher			= ''' + @publication_server + ''''
								+ N',@publisher_db		= ''' + @publisher_db		+ ''''
								+ N',@publication		= ''' + @publication_name	+ ''''
								+ N',@subscriber		= ''' + @ServerName			+ ''''
								+ N',@subscriber_db		= ''' + @DBName				+ ''''


				PRINT '-- T-SQL Script to Disable Subscription Pub Name: ' + @publication_name
				PRINT @SqlCmd
				PRINT '-- T-SQL Script to Disable Subscription  --'

				IF @PrintCommandsDoNotApply = 0
				BEGIN
					EXEC(@SqlCmd)
					SET @StoppedReplOnLACORPDIST02 = 1
					SELECT	@body = '***STOPPED FOR THE PUBLISHER ' + @publication_name + ' on LACORPDIST02 ***' 
				END

			END
			ELSE
			BEGIN
				PRINT '-- NO PUBLICATION on LACORPDIST02'
				SELECT	@body = '***NO PUBLICATION on LACORPDIST02 ***' 
			END

				EXEC msdb..sp_send_dbmail
					 @recipients = @i_recipients
					,@profile_name = 'ADMIN'
					,@subject = @subject
					,@body = @body

		END
  
		------------------KILL CONNECTIONS-----------------------
		WAITFOR DELAY '00:05';

		IF EXISTS ( SELECT	1
					FROM	CLSQL76.mnSystem.dbo.PhysicalDatabase
					WHERE	ServerName = @ServerName
					AND		PhysicalDatabaseName = @DBName
					AND		ActiveFlag = 0 )
			OR NOT EXISTS (SELECT * FROM CLSQL76.mnSystem.dbo.PhysicalDatabase WHERE	ServerName = @ServerName AND PhysicalDatabaseName = @DBName)
		BEGIN
			IF OBJECT_ID('tempdb..#temp') IS NOT NULL
				DROP TABLE #temp	
			
			SELECT	'Kill ' + CAST(p.spid AS VARCHAR) KillCommand
			INTO	#temp
			FROM	master.dbo.sysprocesses p (NOLOCK)
			JOIN	master..sysdatabases d (NOLOCK) ON p.dbid = d.dbid
			WHERE	p.dbid = DB_ID(@DBName) 

			SELECT	@query = STUFF((SELECT '  ' + KillCommand FROM #temp FOR XML PATH('') ), 1, 1, '') 

			PRINT '--Kill query'
			PRINT @query
			PRINT '--Kill query'

			IF @PrintCommandsDoNotApply = 0
				EXECUTE sp_executesql @query 

			------------------OFFLINE DB-----------------------
			SET @SqlCmd = ''
			SET @SqlCmd = @SqlCmd + 'EXEC(''ALTER DATABASE ' + @DBName + ' SET OFFLINE' + CASE WHEN @OfflineWithRollback = 1 THEN ' WITH ROLLBACK IMMEDIATE' ELSE '' END + ' '')'

			PRINT '--T-SQL Script to Offline DB --'
			PRINT @SqlCmd
			PRINT '--T-SQL Script to Offline DB --'

			IF @PrintCommandsDoNotApply = 0
			BEGIN
				EXEC  (@SqlCmd)

				SELECT	@body = @DBName + '*** SET TO OFFLINE ***' 

				EXEC msdb..sp_send_dbmail
					 @recipients = @i_recipients
					,@profile_name = 'ADMIN'
					,@subject = @subject
					,@body = @body
			END

		END
		ELSE
		BEGIN
			PRINT '-- No Queries to Kill or DB is not in LPE or DB is not SET to OFFLINE'	
			SELECT	@body = @DBName + '*** SET TO OFFLINE FAILED ***' 

			EXEC msdb..sp_send_dbmail
				 @recipients = @i_recipients
				,@profile_name = 'ADMIN'
				,@subject = @subject1
				,@body = @body


		END

		------------------COPY LDF AND MDF FILES-----------------------
		IF EXISTS ( SELECT	1
					FROM	sys.databases
					WHERE	name = @DBName
					AND		((state_desc = 'OFFLINE') OR (@PrintCommandsDoNotApply = 1))
				  )
		BEGIN

			DECLARE	@SourceFile AS VARCHAR(500);  
			DECLARE	@DestinationFile AS VARCHAR(500);  
			DECLARE	@Cmd AS VARCHAR(500);  

			DECLARE OBJECT_CURSOR CURSOR FAST_FORWARD READ_ONLY LOCAL
			FOR

			SELECT	 SourceFolder
					,DestinationFolder
					,FileName
			FROM	#DBFiles

			OPEN OBJECT_CURSOR

			FETCH NEXT FROM OBJECT_CURSOR
			INTO @SourceFolder, @DestinationFolder, @FileName

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
	
	
				PRINT '--Copying..DB ' + @DBName

				/* build copy command */  
				SET @Cmd = 'EXEC xp_cmdshell ' + '''' + 'ROBOCOPY "' + @SourceFolder + '" "' + @DestinationFolder + '" "' + @FileName + '" ' + ''''
 
				PRINT '--Script to Move Files. --'
				PRINT @Cmd
				PRINT '--Script to Move Files. --'

				IF @PrintCommandsDoNotApply = 0
					/* execute copy command */  
					EXEC (@Cmd); 


				FETCH NEXT FROM OBJECT_CURSOR
				INTO @SourceFolder, @DestinationFolder, @FileName

			END

			CLOSE OBJECT_CURSOR
			DEALLOCATE OBJECT_CURSOR


			IF @PrintCommandsDoNotApply = 0
			BEGIN
				SELECT	@body = @DBName + '*** MDF & LDF FILES MOVED TO NEW DRIVE ***' 

				EXEC msdb..sp_send_dbmail
					 @recipients = @i_recipients
					,@profile_name = 'ADMIN'
					,@subject = @subject
					,@body = @body
			END
		END
		ELSE
		BEGIN
			PRINT 'CANNOT COPY FILES DB IS STILL ONLINE'
		END

		------------------ALTER LDF AND MDF PATHS-----------------------
		IF EXISTS ( SELECT	1
					FROM	sys.databases
					WHERE	name = @DBName
					AND		(state_desc = 'OFFLINE' OR	(@PrintCommandsDoNotApply = 1)))
		BEGIN

			DECLARE	 @LogicalName		VARCHAR(250)
					,@CurrentLocation	VARCHAR(250)

			DECLARE	@SqlCmd1 VARCHAR(MAX)
			DECLARE	@SqlCmd2 VARCHAR(MAX)

			DECLARE OBJECT_CURSOR CURSOR FAST_FORWARD READ_ONLY LOCAL
			FOR
			SELECT	 LogicalName
					,DBName
					,''''''
					+ CASE WHEN ExistingPhysical_name LIKE '%.ldf'
							THEN @TargetLogFullPath + N'\' + FileName
							ELSE @TargetDataFullPath + N'\' + FileName
						END + '''''' AS CurrentLocation
			FROM	#DBFiles

			OPEN OBJECT_CURSOR

			FETCH NEXT FROM OBJECT_CURSOR
			INTO @LogicalName, @DBName, @CurrentLocation

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
	
				PRINT '--ALTERING ' + @DBName + 'for ' + @LogicalName + ' file' 

				SET @SqlCmd1 = ''
				SET @SqlCmd1 = @SqlCmd1 + 'EXEC(''ALTER DATABASE ' + @DBName + ' MODIFY FILE( NAME = ' + @LogicalName + ', FILENAME = ' + @CurrentLocation + ')'')' + @CRLF

				PRINT '-- T-SQL to move Files --'
				PRINT @SqlCmd1
				PRINT '-- T-SQL to move Files --'

				IF @PrintCommandsDoNotApply = 0
					EXEC  (@SqlCmd1)

				PRINT '--ALTERING ' + @DBName + 'for ' + @LogicalName + ' file completed at :' + CONVERT(VARCHAR, GETDATE(), 114)

				FETCH NEXT FROM OBJECT_CURSOR
				INTO @LogicalName, @DBName, @CurrentLocation

			END

			CLOSE OBJECT_CURSOR
			DEALLOCATE OBJECT_CURSOR


			IF @PrintCommandsDoNotApply = 0
			BEGIN
				SELECT	@body = @DBName + '*** LDF & MDF PATHS ALTERED ***' 

				EXEC msdb..sp_send_dbmail
					 @recipients = @i_recipients
					,@profile_name = 'ADMIN'
					,@subject = @subject
					,@body = @body
			END
		END
		ELSE
		BEGIN
			PRINT '--CANNOT ALTER PATH DB IS STILL ONLINE'
		END

		-------------------------SET ONLINE----------------------------------
		IF EXISTS ( SELECT	 MF.name AS LogicalName
							,physical_name AS CurrentLocation
							,MF.state_desc
							,DB_NAME(MF.database_id) AS DBName
					FROM	sys.master_files MF
					INNER
					JOIN	sys.databases D ON D.database_id = MF.database_id
					WHERE	D.database_id > 4 -- SKIP SYSTEM DATABASES
					AND		DB_NAME(MF.database_id) = @DBName
					AND		(
								(physical_name LIKE '%.ldf' AND physical_name LIKE @TargetLogDrive + '%')
							OR	(physical_name NOT LIKE '%.ldf' AND physical_name LIKE @TargetDataDrive + '%')
							OR	(@PrintCommandsDoNotApply = 1)
							) 
					)
		BEGIN
			PRINT '--Ready for Online....'

			SET @SqlCmd2 = ''
			SET @SqlCmd2 = @SqlCmd2 + 'EXEC(''ALTER DATABASE ' + @DBName + ' SET ONLINE '')'

			PRINT '--T-SQL Script to bring DB ONLINE--'
			PRINT @SqlCmd2
			PRINT '--T-SQL Script to bring DB ONLINE--'
			
			IF @PrintCommandsDoNotApply = 0
			BEGIN
				EXEC  (@SqlCmd2)

				SELECT	@body = @DBName + '*** SET TO ONLINE ***' 

				EXEC msdb..sp_send_dbmail
						 @recipients = @i_recipients
						,@profile_name = 'ADMIN'
						,@subject = @subject
						,@body = @body
			END
		END

		------------------ENABLE LPD-----------------------
		IF EXISTS ( SELECT	1
					FROM	sys.databases
					WHERE	name = @DBName
					AND		((state_desc = 'ONLINE' ) OR (@PrintCommandsDoNotApply = 1))
				  )
		BEGIN

			SELECT	 @publication_server = NULL
					,@publisher_db = NULL
					,@publication_name = NULL

	 
			SELECT DISTINCT
					 @publication_server = srv.srvname
					,@publisher_db = p.publisher_db
					,@publication_name = p.publication  
			FROM	CLSQL76.distribution.dbo.MSpublications p
			JOIN	CLSQL76.distribution.dbo.MSsubscriptions s ON p.publication_id = s.publication_id
			JOIN	CLSQL76.master.dbo.sysservers ss ON s.subscriber_id = ss.srvid
			JOIN	CLSQL76.master.dbo.sysservers srv ON srv.srvid = p.publisher_id
			WHERE	ss.srvname = @ServerName
			AND		s.subscriber_db = @DBName

			IF ((@StoppedReplOnCLSQL76 = 1) OR (@PrintCommandsDoNotApply = 1))
			BEGIN
				SET @SqlCmd	=	  N'EXEC CLSQL76.distribution.dbo.sp_MSstartdistribution_agent @publisher = ''' + @publication_server + ''''
								+ N',@publisher_db	= ''' + @publisher_db		+ ''''
								+ N',@publication	= ''' + @publication_name	+ ''''
								+ N',@subscriber	= ''' + @ServerName			+ ''''
								+ N',@subscriber_db	= ''' + @DBName				+ ''''

				PRINT '-- T-SQL Script to Enable Subscription Pub Name: ' + @publication_name
				PRINT @SqlCmd
				PRINT '-- T-SQL Script to Enable Subscription  --'
				
				IF @PrintCommandsDoNotApply = 0
				BEGIN
					EXEC (@SqlCmd)
				END
			END


			SELECT	 @publication_server = NULL
					,@publisher_db = NULL
					,@publication_name = NULL

			SELECT DISTINCT
					 @publication_server = srv.srvname
					,@publisher_db = p.publisher_db
					,@publication_name = p.publication  
			FROM	LACORPDIST02.distribution.dbo.MSpublications p
			JOIN	LACORPDIST02.distribution.dbo.MSsubscriptions s ON p.publication_id = s.publication_id
			JOIN	LACORPDIST02.master.dbo.sysservers ss ON s.subscriber_id = ss.srvid
			JOIN	LACORPDIST02.master.dbo.sysservers srv ON srv.srvid = p.publisher_id
			WHERE	ss.srvname = @ServerName
			AND		s.subscriber_db = @DBName

			IF ((@StoppedReplOnLACORPDIST02 = 1) OR (@PrintCommandsDoNotApply = 1))
			BEGIN
				SET @SqlCmd	=	  N'EXEC LACORPDIST02.distribution.dbo.sp_MSstartdistribution_agent @publisher = ''' + @publication_server + ''''
								+ N',@publisher_db	= ''' + @publisher_db		+ ''''
								+ N',@publication	= ''' + @publication_name	+ ''''
								+ N',@subscriber	= ''' + @ServerName			+ ''''
								+ N',@subscriber_db	= ''' + @DBName				+ ''''

				PRINT '-- T-SQL Script to Enable Subscription Pub Name: ' + @publication_name
				PRINT @SqlCmd
				PRINT '-- T-SQL Script to Enable Subscription  --'
				
				IF @PrintCommandsDoNotApply = 0
				BEGIN
					EXEC (@SqlCmd)
				END
			END

			IF EXISTS ( SELECT	1
						FROM	CLSQL76.mnSystem.dbo.PhysicalDatabase
						WHERE	ServerName = @ServerName
						AND		PhysicalDatabaseName = @DBName
						AND		((ActiveFlag = 0) OR (@PrintCommandsDoNotApply = 1))
					  )
			BEGIN

				SET @SqlCmd	=	''
				SET @SqlCmd	=	@SqlCmd + N'UPDATE	CLSQL76.mnSystem.dbo.PhysicalDatabase ' + @CRLF
										+ N'SET		ActiveFlag = 1 ' + @CRLF
										+ N'WHERE	ServerName				= ''' + @ServerName + ''''	+ @CRLF
										+ N'AND		PhysicalDatabaseName	= ''' + @DBName		+ ''''	+ @CRLF + ';'

				SET @SqlCmd	=	@SqlCmd + N'UPDATE	CLSQL76.mnSystem.dbo.Property ' + @CRLF
										+ N'SET		PropertyValue = NEWID() ' + @CRLF
										+ N'WHERE	Owner = ''mnSystem''  ' + @CRLF
										+ N'AND		PropertyName = ''LogicalDatabaseVersion''  ' + @CRLF

				PRINT '-- T-SQL to Enable in LPD--'
				PRINT @SqlCmd
				PRINT '-- T-SQL to Enable in LPD--'
				
				IF @PrintCommandsDoNotApply = 0
				BEGIN
					EXEC(@SqlCmd)
					
					SELECT	@body = '***ENABLED LPD FOR ' + @DBName + ' ***' 

					EXEC msdb..sp_send_dbmail
						 @recipients = @i_recipients
						,@profile_name = 'ADMIN'
						,@subject = @subject
						,@body = @body
				END
			END

		END
		ELSE
		BEGIN
			PRINT 'PLEASE ENTER DBNAME and SERVERNAME'
		END
	END
END
GO
/*

-- Testing code
EXEC mnDBA.dbo.usp_NimbleUpgrade @DBName = 'mnIMail10', @ServerName = 'LADBREPORT', @PrintCommandsDoNotApply = 0, @OfflineWithRollback = 0, @Recipients = 'nmuthukumar@spark.net'
GO
*/
GO

/*
	This script is to put a SQL server in downtime

	This primarily applies for
	LASQL01 - 10, CLSQ43. For LASQLPRODFLAT01, 02, and LASEARCHDB01 you can do this but in addition you have to disable jobs that run on
	other servers that might do a cross server query.
*/

USE mnSystem 
GO

-- PARAMETERS
DECLARE @TargetServer			SYSNAME			= ''
DECLARE @Debug					BIT				= 1 -- setting to 0 will not print any debug information.
DECLARE @Recipients				NVARCHAR(1000)	= N'nmuthukumar@spark.net' --could be any email address just to receive simple notifications
DECLARE @ReasonToDisableJobs	NVARCHAR(100)	= 'PATCH RESTART'
DECLARE @ServerDesiredState		NVARCHAR(10)	= 'DOWN' -- DOWN/UP

/*********************************************/
--- DO NOT UPDATE "ANY" CODE BELOW
/*********************************************/
DECLARE @ActiveFlag				BIT				= NULL -- 0 for disable in LPD or 1 for enable
DECLARE @StartOrStopRepl		VARCHAR(5)		= '' -- STOP/START
DECLARE @EnableOrDisableJobs	VARCHAR(10)		= '' -- ENABLE/DISABLE

IF @ServerDesiredState = 'DOWN'
BEGIN
	SET @ActiveFlag				= 0
	SET @StartOrStopRepl		= 'STOP'
	SET @EnableOrDisableJobs	= 'DISABLE'
END
ELSE IF @ServerDesiredState = 'UP'
BEGIN
	SET @ActiveFlag				= 1
	SET @StartOrStopRepl		= 'START'
	SET @EnableOrDisableJobs	= 'ENABLE'
END

/*
	Disable LPD - Stop data coming into source server
	This is applied only on CLSQL76
*/
-- Proceed if server is in LPD
IF EXISTS (SELECT * FROM mnSystem.dbo.PhysicalDatabase WHERE	ServerName	= @TargetServer) AND (@@SERVERNAME = 'CLSQL76')
BEGIN
	PRINT 'Server in LPD...'
	IF @Debug = 1
	BEGIN
		SELECT sComments = 'Before LPD Changes', * FROM mnSystem.dbo.PhysicalDatabase WITH (NOLOCK)
		WHERE ServerName = @TargetServer
		ORDER BY 3

		SELECT * FROM mnSystem.dbo.Property WHERE PropertyName = 'LogicalDatabaseVersion' AND Owner = 'mnSystem'
	END

	DECLARE @TranCount INT = @@TRANCOUNT

	BEGIN TRAN

	SELECT TranCountInBatch = @TranCount

	IF @@SERVERNAME = 'CLSQL76'
	BEGIN
		UPDATE	mnSystem.dbo.PhysicalDatabase
		SET		ActiveFlag	= @ActiveFlag
		WHERE	ServerName	= @TargetServer
		AND		ActiveFlag	!= @ActiveFlag

		SELECT NEWID() --grab new rowguid value to be updated below
 
		UPDATE	mnSystem.dbo.Property
		SET		PropertyValue	= NEWID()
		WHERE	Owner			= 'mnSystem'
		AND		PropertyName	= 'LogicalDatabaseVersion'
	END

	IF @Debug = 1
	BEGIN

		SELECT * FROM mnSystem.dbo.Property WHERE PropertyName = 'LogicalDatabaseVersion' AND Owner = 'mnSystem'

		SELECT * FROM mnSystem.dbo.PhysicalDatabase WITH (NOLOCK)
		WHERE ServerName = @TargetServer
		ORDER BY 3
	END

	IF (((@@TRANCOUNT >= 1) AND (@@TRANCOUNT > @TranCount)) AND (@@SERVERNAME = 'CLSQL76'))
	BEGIN
		PRINT 'LPD Changes were committed'
		COMMIT
	END
	ELSE
	BEGIN
		PRINT 'LPD Changes are being rolled back'
		ROLLBACK
	END

	SELECT TRANCOUNT = @@TRANCOUNT, TranCountBeforeOurupdates = @TranCount
END
ELSE
BEGIN
	PRINT 'Server not in LPD...'
END

/*
	Disable Subscritption on Target server
	You have to wait for the above LPD changes to propagate to taget server before you apply this step

	THIS IS TO BE APPLIED ONLY ON CLSQL76/LACORPDIST02
*/
IF EXISTS (SELECT * FROM mnSystem.dbo.PhysicalDatabase WHERE	ServerName	= @TargetServer AND	ActiveFlag = @ActiveFlag)
	OR NOT EXISTS (SELECT * FROM mnSystem.dbo.PhysicalDatabase WHERE	ServerName	= @TargetServer)
BEGIN
	IF @ActiveFlag = 0
		WAITFOR DELAY '00:00:30' -- Waiting so that the LPD update is replicated to target server.
	EXEC mnDBA.dbo.usp_StopOrStartSubscription @Subscriber = @TargetServer, @Databases = 'All' , @StopOrStart = @StartOrStopRepl , @PrintCommandsAndDoNotApply = 0, @Recipients = @Recipients
END


/*
	Disable Log Reader agents (or publicatios) from Target server

	THIS IS TO BE APPLIED ONLY ON CLSQL76/LACORPDIST02
*/
IF EXISTS (SELECT * FROM mnSystem.dbo.PhysicalDatabase WHERE	ServerName	= @TargetServer AND	ActiveFlag = @ActiveFlag)
	OR NOT EXISTS (SELECT * FROM mnSystem.dbo.PhysicalDatabase WHERE	ServerName	= @TargetServer)
BEGIN
	EXEC mnDBA.dbo.usp_StopOrStartLogReaderAgents @Publisher = @TargetServer, @Databases = 'All' , @StopOrStart = @StartOrStopRepl , @PrintCommandsAndDoNotApply = 0, @Recipients = @Recipients
END

/*
	Disable jobs
*/
IF EXISTS (SELECT * FROM mnSystem.dbo.PhysicalDatabase WHERE	ServerName	= @TargetServer AND	ActiveFlag = @ActiveFlag)
	OR NOT EXISTS (SELECT * FROM mnSystem.dbo.PhysicalDatabase WHERE	ServerName	= @TargetServer)
BEGIN
	DECLARE @SqlCmd NVARCHAR(MAX)
	SET @SqlCmd = 'EXEC ' + @TargetServer + '.mnDBA.dbo.usp_DisableOrEnableJobs ' + '@Reason = ''' + @ReasonToDisableJobs + ''', @OnlyReplicationJobs = 0, @EnableOrDisableJobs = ''' + @EnableOrDisableJobs + ''', @Debug = 0'
	PRINT @SqlCmd
	EXEC (@SqlCmd)
END

USE [DBATools]
GO

IF OBJECT_ID('dbo.sp_RestoreFromAllFilesInDirectory') IS NOT NULL
	DROP PROCEDURE [dbo].[sp_RestoreFromAllFilesInDirectory]
GO

CREATE PROCEDURE [dbo].[sp_RestoreFromAllFilesInDirectory]
(
	 @SourceDirBackupFiles	NVARCHAR(200)
	,@DestDirDbFiles		NVARCHAR(200)
	,@DestDirLogFiles		NVARCHAR(200) 
	,@OnlyPrintCommands		BIT				=	NULL
)
AS
BEGIN

	--Originally written by Tibor Karaszi 2004. Use at own risk. 

	--Restores from all files in a certain directory. Assumes that: 
	--  There's only one backup on each backup device. 
	--  Each database uses only two database files and the mdf file is returned first from the RESTORE FILELISTONLY command. 

	--Sample execution: 
	-- EXEC sp_RestoreFromAllFilesInDirectory 'C:\Mybakfiles\', 'D:\Mydatabasesdirectory\' ,’C:\MylogDirectory\’ 

	SET NOCOUNT ON

	SET @OnlyPrintCommands = ISNULL(@OnlyPrintCommands, 1)

	--Table to hold each backup file name in
	IF OBJECT_ID('tempdb..#files') IS NOT NULL
		DROP TABLE #files
	CREATE TABLE #files
	(
		 fname varchar(200)
		,depth int
		,file_ int
	)
	
	INSERT #files
	EXECUTE master.dbo.xp_dirtree @SourceDirBackupFiles, 1, 1

	DELETE	#files
	WHERE	fname not like '%.bak'
	OR		file_ = 0

	--Table to hold the result from RESTORE HEADERONLY. Needed to get the database name out from
	IF OBJECT_ID('tempdb..#bdev') IS NOT NULL
		DROP TABLE #bdev
	CREATE TABLE #bdev
	(
	 BackupName				NVARCHAR(128) 
	,BackupDescription		NVARCHAR(255) 
	,BackupType				SMALLINT
	,ExpirationDate			DATETIME
	,Compressed				TINYINT
	,Position				SMALLINT
	,DeviceType				TINYINT
	,UserName				NVARCHAR(128) 
	,ServerName				NVARCHAR(128) 
	,DatabaseName			NVARCHAR(128) 
	,DatabaseVersion		BIGINT
	,DatabaseCreationDate	DATETIME
	,BackupSize				NUMERIC(20,0)
	,FirstLSN				NUMERIC(25,0)
	,LastLSN				NUMERIC(25,0)
	,CheckpointLSN			NUMERIC(25,0)
	,DatabaseBackupLSN		NUMERIC(25,0)
	,BackupStartDate		DATETIME
	,BackupFinishDate		DATETIME
	,SortOrder				SMALLINT
	,[CodePage]				SMALLINT
	,UnicodeLocaleId		BIGINT
	,UnicodeComparisonStyle	BIGINT
	,CompatibilityLevel		TINYINT
	,SoftwareVendorId		BIGINT
	,SoftwareVersionMajor	BIGINT
	,SoftwareVersionMinor	BIGINT
	,SoftwareVersionBuild	BIGINT
	,MachineName			NVARCHAR(128) 
	,Flags					BIGINT
	,BindingID				UNIQUEIDENTIFIER
	,RecoveryForkID			UNIQUEIDENTIFIER
	,Collation				NVARCHAR(128) 
	,FamilyGUID				UNIQUEIDENTIFIER
	,HasBulkLoggedData		BIGINT
	,IsSnapshot				BIGINT
	,IsReadOnly				BIGINT
	,IsSingleUser			BIGINT
	,HasBackupChecksums		BIGINT
	,IsDamaged				BIGINT
	,BegibsLogChain			BIGINT
	,HasIncompleteMetaData	BIGINT
	,IsForceOffline			BIGINT
	,IsCopyOnly				BIGINT
	,FirstRecoveryForkID	UNIQUEIDENTIFIER
	,ForkPointLSN			NUMERIC(25,0)
	,RecoveryModel			NVARCHAR(128) 
	,DifferentialBaseLSN	NUMERIC(25,0)
	,DifferentialBaseGUID	UNIQUEIDENTIFIER
	,BackupTypeDescription	NVARCHAR(128) 
	,BackupSetGUID			UNIQUEIDENTIFIER
	,CompressedBackupSize	BIGINT
	,Containment			BIGINT
	, KeyAlgorithm			NVARCHAR(32)
	, EncryptorThumbprint	VARBINARY(20)
	, EncryptorType			NVARCHAR(23)
	)

	--Table to hold result from RESTORE FILELISTONLY. Need to generate the MOVE options to the RESTORE command
	IF OBJECT_ID('tempdb..#dbfiles') IS NOT NULL
		DROP TABLE #dbfiles
	CREATE TABLE #dbfiles
	(
	 LogicalName			NVARCHAR(128) 
	,PhysicalName			NVARCHAR(260) 
	,[Type]					CHAR(1) 
	,FileGroupName			NVARCHAR(128) 
	,Size					NUMERIC(20,0)
	,MaxSize				NUMERIC(20,0)
	,FileId					BIGINT
	,CreateLSN				NUMERIC(25,0)
	,DropLSN				NUMERIC(25,0)
	,UniqueId				UNIQUEIDENTIFIER
	,ReadOnlyLSN			NUMERIC(25,0)
	,ReadWriteLSN			NUMERIC(25,0)
	,BackupSizeInBytes		BIGINT
	,SourceBlockSize		BIGINT
	,FilegroupId			BIGINT
	,LogGroupGUID			UNIQUEIDENTIFIER
	,DifferentialBaseLSN	NUMERIC(25)
	,DifferentialBaseGUID	UNIQUEIDENTIFIER
	,IsReadOnly				BIGINT
	,IsPresent				INT 
	,TDEThumbprint			UNIQUEIDENTIFIER
	)

	DECLARE @fname			VARCHAR(200) 
	DECLARE @dirfile		VARCHAR(300) 
	DECLARE @LogicalName	NVARCHAR(128) 
	DECLARE @PhysicalName	NVARCHAR(260) 
	DECLARE @type			CHAR(1) 
	DECLARE @DbName			SYSNAME 
	DECLARE @sql			NVARCHAR(1000) 

	
	IF LEN(@SourceDirBackupFiles) > 0 AND (RIGHT(@SourceDirBackupFiles, 1) != '\')
		SET @SourceDirBackupFiles = @SourceDirBackupFiles + N'\'

	IF LEN(@DestDirDbFiles) > 0 AND (RIGHT(@DestDirDbFiles, 1) != '\')
		SET @DestDirDbFiles = @DestDirDbFiles + N'\'

	IF LEN(@DestDirLogFiles) > 0 AND (RIGHT(@DestDirLogFiles, 1) != '\')
		SET @DestDirLogFiles = @DestDirLogFiles + N'\'

	IF @OnlyPrintCommands = 1
	BEGIN
		PRINT '----- PARAMS -----'
		PRINT 'Backup Dir:' + @SourceDirBackupFiles
		PRINT 'Data Dir  :' + @DestDirDbFiles
		PRINT 'Log Dir   :' + @DestDirLogFiles
		PRINT '----- PARAMS -----'
	END

	DECLARE files CURSOR LOCAL READ_ONLY FAST_FORWARD FOR

	SELECT fname FROM #files

	DECLARE dbfiles CURSOR FOR
	SELECT LogicalName, PhysicalName, Type FROM #dbfiles

	OPEN files

	FETCH NEXT FROM files INTO @fname
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @dirfile = @SourceDirBackupFiles + @fname

		--Get database name from RESTORE HEADERONLY, assumes there's only one backup on each backup file.
		TRUNCATE TABLE #bdev
		INSERT #bdev
		EXEC('RESTORE HEADERONLY FROM DISK = ''' + @dirfile + '''') 
		SET @DbName = (SELECT DatabaseName FROM #bdev)

		--Construct the beginning for the RESTORE DATABASE command
		SET @sql = 'RESTORE DATABASE [' + @DbName + '] FROM DISK = ''' + @dirfile + ''' WITH REPLACE, MOVE '

		--Get information about database files from backup device into temp table
		TRUNCATE TABLE #dbfiles
		INSERT #dbfiles
		EXEC('RESTORE FILELISTONLY FROM DISK = ''' + @dirfile + '''')

		OPEN dbfiles
		FETCH NEXT FROM dbfiles INTO @LogicalName, @PhysicalName, @type
		
		--For each database file that the database uses
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @type = 'D'
				SET @sql = @sql + '''' + @LogicalName + ''' TO ''' + @DestDirDbFiles + @DbName + '.mdf'', MOVE '
			ELSE IF @type = 'L'
				SET @sql = @sql + '''' + @LogicalName + ''' TO ''' + @DestDirLogFiles + @DbName + '_log.ldf'''
		
		
			FETCH NEXT FROM dbfiles INTO @LogicalName, @PhysicalName, @type
		END

		--Here's the actual RESTORE command 
		PRINT @sql 

		--Remove the comment below if you want the procedure to actually execute the restore command. 
		IF @OnlyPrintCommands = 0
			EXEC(@sql) 

		CLOSE dbfiles 
		FETCH NEXT FROM files INTO @fname 
	END 

	CLOSE files 
	DEALLOCATE dbfiles 
	DEALLOCATE files 

END

GO

/*
	-- Testing Code
	EXEC [dbo].[sp_RestoreFromAllFilesInDirectory]
	 @SourceDirBackupFiles	= 'C:\SQL\SQL_BACKUP\Products'
	,@DestDirDbFiles		= 'C:\SQL\SQL_DATA'
	,@DestDirLogFiles		= 'C:\SQL\SQL_LOG'
	,@OnlyPrintCommands		=	1

	EXEC [dbo].[sp_RestoreFromAllFilesInDirectory]
	 @SourceDirBackupFiles	= 'D:\SQL_BACKUP'
	,@DestDirDbFiles		= 'D:\SQL_DATA'
	,@DestDirLogFiles		= 'D:\SQL_LOG'
	,@OnlyPrintCommands		=	1

*/
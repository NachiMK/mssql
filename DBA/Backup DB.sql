DECLARE @dbname sysname
,@ServerName varchar(20)
,@path varchar(100)
,@dbtype VARCHAR(max)
,@bkpType VARCHAR(100)
,@liteSpeed VARCHAR (100)
,@retention int
,@filenamecount smallint
 
SET @dbType = 'mnMember_ProdFlat_scd'
SET @bkpType = 'FULL'
SET @liteSpeed = 'N'
SET @retention = 5
SET @filenamecount  = 1
--> Path Where Backup will be created
SET @path = 'T:\SQL_BACKUP\full\'

EXEC mnDBA.dbo.usp_Backup_call @path = @path , @backup_databases = @dbType
,@bkpType = @bkpType, @retention = @retention
, @liteSpeed = @liteSpeed,@filenamecount =@filenamecount



RESTORE FILELISTONLY FROM DISK ='\\PATH ACCESIBLE FROM TARGET SERVER\full\mnIPBlocker.BAK'
 
RESTORE DATABASE MyDatabase from disk ='\\PATH ACCESIBLE FROM TARGET SERVER\full\mnIPBlocker.BAK'
WITH  FILE = 1,  
-- BASED ON ABOVE HEADER RESULTS CREATE PROPER NUMBER OF FULES
MOVE N'mnIPBlocker_PROD' TO N'G:\SQL_DATA\mnIPBlocker_PROD.mdf',   
MOVE N'mnIPBlocker_PROD_log' TO N'G:\SQL_LOG\mnIPBlocker_PROD_log.ldf',  NOUNLOAD,  STATS = 10


exec DatabaseBackup @Databases = 'mnIMail1', @Directory = 'G:\SQL_BACKUP\FULL\', @BackupType = 'FULL', @Verify = 'Y', @Compress = 'N'

GO

exec DatabaseBackup @Databases = 'mnIMail1', @Directory = 'G:\SQL_BACKUP\DIFF\', @BackupType = 'DIFF', @Verify = 'Y', @Compress = 'N'


GO

USE [master]
RESTORE DATABASE [mnIMail1] FROM  DISK = N'G:\SQL_BACKUP\FULL\LACUBEDATA01_mnIMail1_FULL_20160916_140413.bak' 
WITH  FILE = 1,  MOVE N'mnIMail1_Log' TO N'L:\SQL_LOG\mnIMail1_Log.ldf',  NORECOVERY,  NOUNLOAD,  REPLACE,  STATS = 5

GO

RESTORE DATABASE [mnIMail1] FROM  DISK = N'G:\SQL_BACKUP\DIFF\LACUBEDATA01_mnIMail1_DIFF_20160916_151726.bak' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 10
GO

RESTORE DATABASE [mnIMail1] FROM  DISK = N'G:\SQL_BACKUP\DIFF\LACUBEDATA01_mnIMail1_DIFF_20160919_070608.bak' WITH  FILE = 1,  RECOVERY,  NOUNLOAD,  STATS = 10
GO

RESTORE DATABASE [mnIMail1] FROM  DISK = N'G:\SQL_BACKUP\DIFF\LACUBEDATA01_mnIMail1_DIFF_20160919_104249.bak' WITH  FILE = 1,  RECOVERY,  NOUNLOAD,  STATS = 10
GO


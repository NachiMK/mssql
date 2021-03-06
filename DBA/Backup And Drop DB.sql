BACKUP DATABASE [Roundys] TO  DISK = N'D:\Backup\Roundys_backup_D5.bak' WITH NOFORMAT, NOINIT,  NAME = N'Roundys-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

BACKUP DATABASE [TD] TO  DISK = N'D:\Backup\TD_backup_D5.bak' WITH NOFORMAT, NOINIT,  NAME = N'TD-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

BACKUP DATABASE [ASMCRMProd_MSCRM] TO  DISK = N'D:\Backup\ASMCRMProd_MSCRM_backup_D5.bak' WITH NOFORMAT, NOINIT,  NAME = N'ASMCRMProd_MSCRM-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

/*
DROP DATABASE ROUNDYS
GO
*/

/*

RESTORE DATABASE [TD] FROM  DISK = N'D:\Backup\TD_backup_D5.bak' WITH  FILE = 1,  
MOVE N'TD_log' TO N'E:\Log\TD_Log.ldf',  NOUNLOAD,  STATS = 10
GO

*/

/*
	SHRINK
-- Truncate the log by changing the database recovery model to SIMPLE.
ALTER DATABASE TD
SET RECOVERY SIMPLE;
GO

*/
-- Shrink the truncated log file to 1 MB.
DBCC SHRINKFILE (TD_Log, TRUNCATEONLY);
GO

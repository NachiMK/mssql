USE Maropost
/*
	Script to Shrink Log file
*/
-- Check space available
SELECT name , CurrentSize = size/128.0, SpaceUsed = CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 ,size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS AvailableSpaceInMB
FROM sys.database_files;

-- Truncate the log by changing the database recovery model to SIMPLE.
ALTER DATABASE Maropost
SET RECOVERY SIMPLE;
GO
-- Shrink the truncated log file to 1 MB.
--DBCC SHRINKFILE (Maropost_log);
--DBCC SHRINKFILE (Maropost);
GO

	
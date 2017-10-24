-- USE DBATools
SELECT
     DB.name
    ,DataFileSizeGB = CONVERT(NUMERIC(20, 2), SUM(CASE WHEN type = 0 THEN MF.size * 8 / 1024.0 /1024.0 ELSE 0 END) )
    ,LogFileSizeGB  = CONVERT(NUMERIC(20, 2), SUM(CASE WHEN type = 1 THEN MF.size * 8 / 1024.0 /1024.0 ELSE 0 END) )
	,TotalSize = CONVERT(NUMERIC(20, 2), SUM(MF.size * 8 / 1024.0 /1024.0) )
FROM
    sys.master_files MF
    JOIN sys.databases DB ON DB.database_id = MF.database_id
WHERE DB.source_database_id is null -- exclude snapshots
AND DB.database_id > 4
AND	DB.name not in ('DBA', 'DBATools')
GROUP BY DB.name
ORDER BY DB.name

IF OBJECT_ID('tempdb..#DBFileSize') IS NOT NULL
	DROP TABLE #DBFileSize
CREATE TABLE #DBFileSize
(
	 DBName				SYSNAME
	,FileName			NVARCHAR(500)
	,CurrentSizeMB		NUMERIC(22, 4)
	,FreeSpaceMB		NUMERIC(22, 4)
)
DECLARE @FileSizeQuery NVARCHAR(MAX)
SET		@FileSizeQuery =
N'
USE ?

INSERT INTO
		#DBFileSize
SELECT	 DbName			= DB_NAME()
		,FileName		= name 
		,CurrentSizeMB	= size/128.0
		,FreeSpaceMB		= size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0
FROM	sys.database_files; 
'
EXEC dbo.sp_foreachdb @Command = @FileSizeQuery, @User_only = 1


SELECT	*
FROM	#DBFileSize

SELECT	 DBName
		,CurrentSizeMB  = SUM(CurrentSizeMB)
		,FreeSpaceMB    = SUM(FreeSpaceMB)
		,CurrentSizeGB  = SUM(CurrentSizeMB / 1024.0)
		,FreeSpaceGB    = SUM(FreeSpaceMB / 1024.0)
		,[CurrentSize(MF)] = MIN(TotalSize)
FROM	#DBFileSize DB
CROSS APPLY
	(
		SELECT	 SDB.name
				,DataFileSizeGB = CONVERT(NUMERIC(20, 2), SUM(CASE WHEN type = 0 THEN MF.size * 8 / 1024.0 /1024.0 ELSE 0 END) )
				,LogFileSizeGB  = CONVERT(NUMERIC(20, 2), SUM(CASE WHEN type = 1 THEN MF.size * 8 / 1024.0 /1024.0 ELSE 0 END) )
				,TotalSize = CONVERT(NUMERIC(20, 2), SUM(MF.size * 8 / 1024.0 /1024.0) )
		FROM	sys.master_files MF
		JOIN	sys.databases SDB ON SDB.database_id = MF.database_id
		WHERE	SDB.source_database_id is null -- exclude snapshots
		AND		SDB.database_id > 4
		AND		SDB.name not in ('DBA', 'DBATools')
		AND		SDB.Name = DB.DBName
		GROUP BY SDB.name
	)	S
GROUP BY
	DBName
ORDER BY
	DBName

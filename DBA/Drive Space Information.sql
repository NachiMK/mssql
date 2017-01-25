/*
	Find Drive Space Total Occupied and Total Available
*/

IF OBJECT_ID('tempdb..#VolumeStats') IS NOT NULL
	DROP TABLE #VolumeStats
CREATE TABLE #VolumeStats
(
	 ServerName		SYSNAME
	,[Drive]		NVARCHAR(256)
	,[AvailableMBs]	DECIMAL(20, 2)
	,[AvailableGBs]	DECIMAL(20, 2)
	,[TotalMBs]		DECIMAL(20, 2)
	,[TotalGBs]		DECIMAL(20, 2)
	,InsertDtTm		DATETIME		CONSTRAINT DF_TMP_VolStats DEFAULT GETDATE()
)

DECLARE @ServerName SYSNAME
DECLARE	@SQLCommand	NVARCHAR(MAX)

DECLARE OBJECT_CURSOR CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

SELECT		name
FROM		SYS.servers
WHERE		1 = 1
AND		name = @@SERVERNAME
--AND		name	IN (@@SERVERNAME, 'LACORPDIST02','LARESEARCHDB01.matchnet.com','LASEARCHDB01','LASQL01','LASQL02','LASQL03','LASQL04','LASQL05','LASQL06','LASQL07','LASQL08','LASQL09','LASQL10','LASQLPRODFLAT02', 'OCSQLFINANCE01')
--WHERE		name	NOT IN ('CLSQL41', 'CLSQL44', 'LASEARCHDB01', 'TEMPSQL4STAGE', 'CLSQL75', 'LADBREPORT', 'LASQLPRODFLAT02', 'LASQLPRODFLAT01', 'LACUBEDATA01', 'repl_distributor', 'SQLAF01', '')
ORDER BY	server_id

OPEN OBJECT_CURSOR

FETCH NEXT FROM OBJECT_CURSOR
INTO @ServerName

WHILE (@@FETCH_STATUS = 0)
BEGIN

	PRINT	'--------------------'
	PRINT	'Server: ' + @ServerName

	SET @SQLCommand = '
	EXECUTE(
	''
	;WITH VolumeStats AS 
	( 
		SELECT DISTINCT
			 ServerName		= @@SERVERNAME
			,[Drive]		= s.volume_mount_point
			,[AvailableMBs]	= CAST(s.available_bytes / 1048576.0 as decimal(20,2))
			,[AvailableGBs]	= (CAST(s.available_bytes / 1048576.0 as decimal(20,2)))/1024.00
			,[TotalMBs]		= CAST(s.total_bytes / 1048576.0 as decimal(20,2))
			,[TotalGBs]		= (CAST(s.total_bytes / 1048576.0 as decimal(20,2)))/1024.00
		FROM 
			master.sys.master_files f
			CROSS APPLY master.sys.dm_os_volume_stats(f.database_id, f.[file_id]) s
	)
	SELECT
			 V.ServerName
			,V.Drive
			,V.AvailableMBs
			,V.AvailableGBs
			,V.TotalMBs
			,V.TotalGBs
			,GETDATE()
	FROM	VolumeStats V
	WHERE	1 = 1
	AND		V.Drive NOT LIKE ''''C:%'''' '') AT ' + @ServerName

	IF @ServerName = @@SERVERNAME
	BEGIN
		SET @SQLCommand = REPLACE(@SQLCommand, ' AT ', '')
		SET @SQLCommand = REPLACE(@SQLCommand, @@SERVERNAME, '')
	END

	PRINT  @SQLCommand
	
	INSERT INTO #VolumeStats
	EXEC(@SQLCommand)

	PRINT	'--------------------'
	    
	FETCH NEXT FROM OBJECT_CURSOR
	INTO @ServerName
END

CLOSE OBJECT_CURSOR
DEALLOCATE OBJECT_CURSOR


-- RESULTS
SELECT * 
FROM	#VolumeStats V
WHERE	1 = 1
--AND		V.Drive LIKE 'H:%'
--AND		V.AvailableGBs < 61
ORDER BY
		V.ServerName, V.Drive, V.AvailableGBs DESC



-- Volume Stats by File/DB
;WITH VolumeStats AS 
( 
	SELECT DISTINCT
		 ServerName			= @@SERVERNAME
		,DBName				= DB_NAME(S.database_id)
		--,PhysicalLocation	= f.physical_name
		,LogicalName		= s.logical_volume_name
		,[Drive]		= s.volume_mount_point
		,[AvailableMBs]	= CAST(s.available_bytes / 1048576.0 as decimal(20,2))
		,[AvailableGBs]	= (CAST(s.available_bytes / 1048576.0 as decimal(20,2)))/1024.00
		,[TotalMBs]		= CAST(s.total_bytes / 1048576.0 as decimal(20,2))
		,[TotalGBs]		= (CAST(s.total_bytes / 1048576.0 as decimal(20,2)))/1024.00
		,UsedSpaceInGBs		= CONVERT(DECIMAL(10,2),((size * 8.00) / 1024.00 / 1024.00))
	FROM 
		sys.master_files f
		CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) s
)

SELECT
		V.*
FROM	VolumeStats V
WHERE	1 = 1
--AND		V.Drive LIKE 'H:%'
--AND		V.AvailableGBs < 60
ORDER BY
		V.ServerName, DBName, V.Drive, V.AvailableGBs DESC

-- Backup Dates
SELECT 
		a.Name
		,Last_Backup_Date = CASE WHEN MAX(backup_finish_date) IS NULL THEN NULL ELSE max(backup_finish_date) END 
FROM	sys.sysdatabases a 
LEFT JOIN	msdb.dbo.backupset b ON a.name = b.database_name 
GROUP BY	a.NAME
ORDER BY	LAst_Backup_date DESC

-- Last Restores
;WITH LastRestores AS
(
SELECT
    DatabaseName = [d].[name] ,
    [d].[create_date] ,
    [d].[compatibility_level] ,
    [d].[collation_name] ,
    r.*,
    RowNum = ROW_NUMBER() OVER (PARTITION BY d.Name ORDER BY r.[restore_date] DESC)
FROM master.sys.databases d
LEFT OUTER JOIN msdb.dbo.[restorehistory] r ON r.[destination_database_name] = d.Name
)
SELECT *
FROM [LastRestores]
WHERE [RowNum] = 1
ORDER BY restore_date DESC

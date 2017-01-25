SELECT
    DB.name,
    SUM(CASE WHEN type = 0 THEN MF.size * 8 / 1024.0 /1024.0 ELSE 0 END) AS DataFileSizeGB,
    SUM(CASE WHEN type = 1 THEN MF.size * 8 / 1024.0 /1024.0 ELSE 0 END) AS LogFileSizeGB
FROM
    sys.master_files MF
    JOIN sys.databases DB ON DB.database_id = MF.database_id
WHERE DB.source_database_id is null -- exclude snapshots
AND DB.database_id > 4
GROUP BY DB.name
ORDER BY DB.name DESC
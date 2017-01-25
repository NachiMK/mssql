SELECT  DatabaseName = DB_NAME(database_id)
        --,physical_name
        ,SizeInGB = SUM(( ( size * 8 ) / 1024.00 ) / 1024.00)
FROM    sys.master_files
WHERE   database_id > 4
AND		type = 0
GROUP BY
		DB_NAME(database_id)
ORDER BY
		DB_NAME(database_id)


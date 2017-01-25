DECLARE @startup DATETIME,
        @tbb DECIMAL(38, 0),
        @total_reads DECIMAL(38, 0),
        @total_data_size DECIMAL(38, 0),
        @mb DECIMAL(38, 0) ,
        @gb DECIMAL(38, 0) ;

SET @mb = 1024.0 * 1024.0 ;
SET @gb = @mb * 1024.0 ;

SELECT  @startup = create_date
FROM    sys.databases
WHERE   name='tempdb' ;

SELECT  @tbb = SUM(CAST(COALESCE(backup_size, 0) AS DECIMAL(38,0)))
FROM    sys.databases d
        LEFT JOIN msdb.dbo.backupset b ON d.name = b.database_name
WHERE   b.backup_start_date >= @startup
        AND b.type <> 'L'
        AND d.database_id > 4 ;

SELECT  @total_reads = SUM(num_of_bytes_read)
FROM    sys.dm_io_virtual_file_stats(NULL, NULL) vfs
WHERE   vfs.database_id > 4 ;

SELECT  @total_data_size = SUM(CAST(size * 8 AS DECIMAL(38,0))) / @mb
FROM    sys.master_files
WHERE   [type] <> 1
        AND database_id > 4 ;

SELECT  (@total_reads - COALESCE(@tbb, 0)) / @gb AS [Non-backup reads (GB)] ,
        ((@total_reads - COALESCE(@tbb, 0)) / @gb) /
            DATEDIFF(DAY, @startup, CURRENT_TIMESTAMP) AS [Non-backup reads / day (GB)] ,
        @total_data_size  AS [Total Data Size (GB)] ;


SELECT  object_name,
        counter_name,
        instance_name AS [NUMA Node] ,
        cntr_value AS [value]
FROM    sys.dm_os_performance_counters
WHERE   LTRIM(RTRIM(object_name)) = 'SQLServer:Buffer Node'
        AND LTRIM(RTRIM(counter_name)) = 'Page life expectancy' ;

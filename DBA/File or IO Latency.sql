	SELECT 
			 CaptureID			=	1
			,RecordCreatedDtTm	=	GETDATE()
			,[ReadLatency]		=	CASE WHEN [num_of_reads] = 0 THEN 0 ELSE ([io_stall_read_ms] / [num_of_reads]) END
			,[WriteLatency]		=	CASE WHEN [io_stall_write_ms] = 0 THEN 0 ELSE ([io_stall_write_ms] / [num_of_writes]) END
			,[Latency]			=	CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
											THEN 0
										ELSE ([io_stall] / ([num_of_reads] + [num_of_writes]))
									END
			,[AvgBPerRead]		=	CASE WHEN [num_of_reads] = 0
											THEN 0
											ELSE ([num_of_bytes_read] / [num_of_reads])
									END
			,[AvgBPerWrite]		=	CASE WHEN [io_stall_write_ms] = 0
										THEN 0
										ELSE ([num_of_bytes_written] / [num_of_writes])
									END
			,[AvgBPerTransfer]	=	CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
											THEN 0
											ELSE (([num_of_bytes_read] + [num_of_bytes_written]) / ([num_of_reads] + [num_of_writes]))
									END
			,[Drive]			=	LEFT([mf].[physical_name], 2)
			,[DBName]			=	DB_NAME([vfs].[database_id])
			,[vfs].[database_id]
			,[vfs].[file_id]
			,[vfs].[sample_ms]
			,[vfs].[num_of_reads]
			,[vfs].[num_of_bytes_read]
			,[vfs].[io_stall_read_ms]
			,[vfs].[num_of_writes]
			,[vfs].[num_of_bytes_written]
			,[vfs].[io_stall_write_ms]
			,[vfs].[io_stall]
			,[size_on_disk_MB]	=	[vfs].[size_on_disk_bytes] / 1024 / 1024.
			,[vfs].[file_handle]
			,[mf].[physical_name]
	FROM	[sys].[dm_io_virtual_file_stats](NULL, NULL) AS vfs
	JOIN	[sys].[master_files] [mf] ON [vfs].[database_id] = [mf].[database_id]
											AND [vfs].[file_id] = [mf].[file_id]
	ORDER BY [Latency] DESC;
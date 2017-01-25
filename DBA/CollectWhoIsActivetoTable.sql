USE master
GO

IF @@SERVERNAME = 'NVBIDBD5'
	EXEC sp_executesql N'CREATE SCHEMA [Perf]';
GO

IF @@SERVERNAME = 'NVBIDBD5'
BEGIN
	CREATE TABLE Perf.WhoIsActive 
	( 
	 [dd hh:mm:ss.mss]		VARCHAR(8000)	NULL
	,[session_id]			SMALLINT		NOT NULL
	,[sql_text]				XML				NULL
	,[login_name]			NVARCHAR(128)	NOT NULL
	,[wait_info]			NVARCHAR(4000)	NULL
	,[CPU]					VARCHAR(30)		NULL
	,[tempdb_allocations]	VARCHAR(30)		NULL
	,[tempdb_current]		VARCHAR(30)		NULL
	,[blocking_session_id]	SMALLINT		NULL
	,[reads]				VARCHAR(30)		NULL
	,[writes]				VARCHAR(30)		NULL
	,[physical_reads]		VARCHAR(30)		NULL
	,[query_plan]			XML				NULL
	,[used_memory]			VARCHAR(30)		NULL
	,[status]				VARCHAR(30)		NOT NULL
	,[open_tran_count]		VARCHAR(30)		NULL
	,[percent_complete]		VARCHAR(30)		NULL
	,[host_name]			NVARCHAR(128)	NULL
	,[database_name]		NVARCHAR(128)	NULL
	,[program_name]			NVARCHAR(128)	NULL
	,[start_time]			DATETIME		NOT NULL
	,[login_time]			DATETIME		NULL
	,[request_id]			INT				NULL
	,[collection_time]		DATETIME		NOT NULL
	);

	CREATE NONCLUSTERED INDEX [IDX_Perf_WhoIsactive_Dt] ON Perf.WhoIsActive(collection_time);

END

/*
	Usage of above table
*/
EXEC dbo.sp_WhoIsActive @get_plans = 1,	@destination_table = 'Perf.WhoIsActive'
GO
EXEC dbo.sp_CleanUpWhoIsActive @DaysToKeep = 10
GO

SELECT	*
FROM	Perf.WhoIsActive WITH (READUNCOMMITTED)



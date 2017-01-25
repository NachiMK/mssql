IF OBJECT_ID('tempdb..#IndexStats') IS NOT NULL
	DROP TABLE #IndexStats
GO

CREATE TABLE #IndexStats
(
	 DBName					SYSNAME
	,TableName				NVARCHAR(255)
	,FullQualitifiedName	SYSNAME
	,UserSeeks				DECIMAL
	,UserScans				DECIMAL
	,UserUpdates			DECIMAL
	,ReadsAndWrites			DECIMAL
	,Reads					DECIMAL
)
INSERT	INTO #IndexStats
EXEC	sp_MSforeachdb 'USE [?]; IF DB_ID(''?'') > 4
BEGIN
SELECT
		 DBName					=	DB_NAME()
		,TableName				=	object_name(b.object_id)
		,FullQualitifiedName	=	DB_NAME() + ''.'' + object_name(b.object_id)
		,a.user_seeks
		,a.user_scans
		,a.user_updates 
		,ReadsAndWrites			=	a.user_seeks + a.user_scans + a.user_updates
		,Reads					=	a.user_seeks + a.user_scans

FROM	sys.dm_db_index_usage_stats	a
RIGHT
OUTER	JOIN [?].sys.indexes		b	ON	a.object_id = b.object_id AND a.database_id = DB_ID()
WHERE	b.object_id > 100 
END'

-- Aggregate by Table Name
SELECT	 [Table Name]				=	TableName
		,[Total Accesses]			=	SUM(ReadsAndWrites)
		,[Total Writes]				=	SUM(UserUpdates)
		,[% Accesses are Writes]	=	CONVERT(DEC(25, 2), (SUM(UserUpdates) / SUM(ReadsAndWrites) * 100))
		,[Total Reads]				=	SUM(UserSeeks + UserScans)
		,[% Accesses are Reads]		=	CONVERT(DEC(25, 2), (SUM(Reads) / SUM(ReadsAndWrites) * 100))
		,[Read Seeks]				=	SUM(UserSeeks)
		,[% Reads are Index Seeks]	=	CONVERT(DEC(25, 2), (SUM(UserSeeks) / SUM(Reads) * 100))
		,[Read Scans]				=	SUM(UserScans)
		,[% Reads are Index Scans]	=	CONVERT(DEC(25, 2), (SUM(UserScans) / SUM(Reads) * 100))
FROM	#IndexStats
GROUP BY
		TableName
HAVING
		SUM(Reads) > 0
ORDER BY
		SUM(ReadsAndWrites) DESC


-- Aggregate by Database and Table Name
SELECT	 [Database Name]			=	DBName
		,[Table Name]				=	TableName
		,[Total Accesses]			=	SUM(ReadsAndWrites)
		,[Total Writes]				=	SUM(UserUpdates)
		,[% Accesses are Writes]	=	CONVERT(DEC(25, 2), (SUM(UserUpdates) / SUM(ReadsAndWrites) * 100))
		,[Total Reads]				=	SUM(UserSeeks + UserScans)
		,[% Accesses are Reads]		=	CONVERT(DEC(25, 2), (SUM(Reads) / SUM(ReadsAndWrites) * 100))
		,[Read Seeks]				=	SUM(UserSeeks)
		,[% Reads are Index Seeks]	=	CONVERT(DEC(25, 2), (SUM(UserSeeks) / SUM(Reads) * 100))
		,[Read Scans]				=	SUM(UserScans)
		,[% Reads are Index Scans]	=	CONVERT(DEC(25, 2), (SUM(UserScans) / SUM(Reads) * 100))
FROM	#IndexStats
GROUP BY
		DBName, TableName
HAVING
		SUM(Reads) > 0
ORDER BY
		DBName, SUM(ReadsAndWrites) DESC

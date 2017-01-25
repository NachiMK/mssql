/*

USE mnMember_ProdFlat
GO

EXEC dbo.sp_BlitzIndex @DatabaseName = 'mnMember_PRodFlat'

*/

IF OBJECT_ID('tempdb..#IndexStats') IS NOT NULL
	DROP TABLE #IndexStats
SELECT * INTO #IndexStats FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') T

;WITH CTE
AS
(
SELECT	SchemaName = S.Name
		,TableName = ST.name
		,IndexName = I.name
		,RN = ROW_NUMBER() OVER (PARTITION BY S.name, ST.name, I.index_id ORDER BY T.avg_fragmentation_in_percent DESC)
		,T.*
FROM	#IndexStats	T
JOIN	sys.tables ST	ON	ST.object_id	= T.object_id
JOIN	sys.schemas S	ON	S.schema_id		= ST.schema_id
JOIN	sys.indexes I	ON	I.object_id		= ST.object_id
						AND I.index_id		= T.index_id
)
SELECT	*
		,Script = 'ALTER INDEX [' + CTE.IndexName + '] ON [' + CTE.SchemaName + '].[' + CTE.TableName + '] REBUILD PARTITION = ALL '
FROM	CTE
WHERE	RN = 1
AND		CTE.avg_fragmentation_in_percent > 30
AND		CTE.record_count > 1000
ORDER BY
		CTE.SchemaName, CTE.TableName, CTE.IndexName


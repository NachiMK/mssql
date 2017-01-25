;WITH CTE_TableSize
AS
(
SELECT	 databasename
      	,tablename
      	,rows
      	,reserved
      	,data
      	,indexsize
      	,unused
      	,insertdate
		,rn = ROW_NUMBER() OVER (PARTITION BY databasename, tablename ORDER BY insertdate DESC)
		,DataAndIndexInGB = ((CONVERT(FLOAT, REPLACE(data, ' KB', '')) +  CONVERT(FLOAT, REPLACE(indexsize, ' KB', '')))/1024.00)/1024.00
FROM	mnDBA..TableSizeAudit WITH (READUNCOMMITTED)
--WHERE	databasename = 'mnMOnitoring' AND tablename = 'ApiWebLog'
WHERE	1= 1
AND		databasename = 'Maropost'
AND		insertdate > '11/1/2015'
--AND		tablename = 'APIWebLog'
AND		tablename	LIKE 'Maropost%Mail%'
--ORDER BY insertdate DESC
)
SELECT	Today.databasename
		,Today.tablename
		,[Today]					= Today.insertdate
		,[Yesterday]				= Yesterday.insertdate
		,[Rows - Today]				= Today.rows
		,[Rows - Yesterday]			= ISNULL(Yesterday.rows, 0)
		,[Rows - Today - Yesterday]	= Today.rows - ISNULL(Yesterday.rows, 0)

		,[Size - Today]				= Today.DataAndIndexInGB
		,[Size - Yesterday]			= ISNULL(Yesterday.DataAndIndexInGB, 0)
		,[Size - Today - Yesterday]	= Today.DataAndIndexInGB - ISNULL(Yesterday.DataAndIndexInGB, 0)

		,[Data Diff In MB]			=	(CONVERT(FLOAT, REPLACE(Today.data, ' KB', '')) - ISNULL(CONVERT(FLOAT, REPLACE(Yesterday.data, ' KB', '')), 0))/1024.00
		,[Index Diff In MB]			=	(CONVERT(FLOAT, REPLACE(Today.indexsize, ' KB', '')) - ISNULL(CONVERT(FLOAT, REPLACE(Yesterday.indexsize, ' KB', '')), 0))/1024.00
		,[Reserved Diff In MB]		=	(CONVERT(FLOAT, REPLACE(Today.reserved, ' KB', '')) - ISNULL(CONVERT(FLOAT, REPLACE(Yesterday.reserved, ' KB', '')), 0))/1024.00
		,[NetSize Diff In MB]		=	(CONVERT(FLOAT, REPLACE(Today.data, ' KB', '')) - ISNULL(CONVERT(FLOAT, REPLACE(Yesterday.data, ' KB', '')), 0)
									+ CONVERT(FLOAT, REPLACE(Today.indexsize, ' KB', '')) - ISNULL(CONVERT(FLOAT, REPLACE(Yesterday.indexsize, ' KB', '')), 0)
									+ CONVERT(FLOAT, REPLACE(Today.reserved, ' KB', '')) - ISNULL(CONVERT(FLOAT, REPLACE(Yesterday.reserved, ' KB', '')), 0))/1024.00

FROM	CTE_TableSize Today
LEFT
JOIN	CTE_TableSize Yesterday	ON	Yesterday.tablename = Today.tablename
								AND Yesterday.databasename = Today.databasename
								AND Yesterday.rn = (Today.rn + 1)
WHERE	1 = 1
AND		ABS(Today.rows - ISNULL(Yesterday.rows, 0)) > 0
--AND		Today.databasename = 'Mingle_scd_new'
--AND		Today.tablename = 'MingleUser'
ORDER BY Today.insertdate DESC


-- DETAILS
SELECT	 * 
		,Totalsize = CONVERT(FLOAT, REPLACE(DATA, ' KB', '')) + CONVERT(FLOAT, REPLACE(indexsize, ' KB', '')) + CONVERT(FLOAT, REPLACE(unused, ' KB', ''))
FROM	mnDBA..TableSizeAudit
WHERE	1 = 1
AND		tablename = 'MingleUser'
AND		databasename = 'Mingle_scd_new'
AND		insertdate > '10/1/2015'
ORDER BY insertdate DESC

-- MONTHLY TOTAL By DB, Table
SELECT 
		databasename
		,tablename
		,YearID = YEAR(insertdate)
		,MonthId = MONTH(insertdate)
		,AvgRows = AVG(CONVERT(BIGINT, rows))
		,Cnt = COUNT(*)
		,AvgDataIdxUnused = AVG(CONVERT(FLOAT, REPLACE(DATA, ' KB', '')) + CONVERT(FLOAT, REPLACE(indexsize, ' KB', '')) + CONVERT(FLOAT, REPLACE(unused, ' KB', '')))
		,AvgDataIdxUnusedInGB = ((AVG(CONVERT(FLOAT, REPLACE(DATA, ' KB', '')) + CONVERT(FLOAT, REPLACE(indexsize, ' KB', '')) + CONVERT(FLOAT, REPLACE(unused, ' KB', ''))))/1024.00)/1024.00
FROM	mnDBA..TableSizeAudit 
WHERE	1 = 1
--AND		tablename = 'MingleUser'
AND		databasename = 'mnMonitoring'
AND		tablename LIKE '%APIWebLog%'
AND		insertdate > DATEADD(dd, -120, GETDATE())
GROUP BY	
		 databasename
		,tablename
		,YEAR(insertdate)
		,MONTH(insertdate)
ORDER BY
		 databasename
		,tablename
		,YEAR(insertdate)
		,MONTH(insertdate)


-- MONTHLY TOTAL
SELECT 
		YEAR(insertdate)
		,MONTH(insertdate)
		,AVG(CONVERT(BIGINT, rows))
		,COUNT(*)
		,AVG(CONVERT(FLOAT, REPLACE(DATA, ' KB', '')) + CONVERT(FLOAT, REPLACE(indexsize, ' KB', '')) + CONVERT(FLOAT, REPLACE(unused, ' KB', '')))
		,((AVG(CONVERT(FLOAT, REPLACE(DATA, ' KB', '')) + CONVERT(FLOAT, REPLACE(indexsize, ' KB', '')) + CONVERT(FLOAT, REPLACE(unused, ' KB', ''))))/1024.00)/1024.00
FROM	mnDBA..TableSizeAudit 
WHERE	1 = 1
--AND		tablename = 'MingleUser'
--AND		databasename = 'Mingle_scd_new'
AND		insertdate > DATEADD(dd, -90, GETDATE())
GROUP BY	
		YEAR(insertdate)
		,MONTH(insertdate)

-- OVERALL AVERAGE
SELECT
		 AVG(CONVERT(BIGINT, rows))
		,COUNT(*)
		,AVG(CONVERT(FLOAT, REPLACE(DATA, ' KB', '')) + CONVERT(FLOAT, REPLACE(indexsize, ' KB', '')) + CONVERT(FLOAT, REPLACE(unused, ' KB', '')))
FROM	mnDBA..TableSizeAudit
WHERE	1 = 1
--AND		tablename = 'MingleUser'
--AND		databasename = 'Mingle_scd_new'
AND		insertdate > DATEADD(dd, -90, GETDATE())

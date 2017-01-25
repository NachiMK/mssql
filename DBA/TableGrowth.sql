SELECT *
FROM	mnDBA.dbo.DBGrowthRate
WHERE	MetricDate > '10/1/2015'
AND DBName = 'mnMOnitoring'
ORDER BY DBName, MetricDate DESC


SELECT	DBName, YEAR(MetricDate), MONTH(MetricDate), AVG(CONVERT(DECIMAL, REPLACE(GrowthAmt, ' MB', ''))), AVG(CONVERT(DECIMAL, REPLACE(GrowthAmt, ' MB', '')))/1024.00  InGB, COUNT(MetricDate)
FROM	mnDBA.dbo.DBGrowthRate
WHERE	CONVERT(DECIMAL, REPLACE(GrowthAmt, ' MB', '')) > 50 AND MetricDate > '1/1/2015'
AND DBName = 'mnMOnitoring'
GROUP BY DBName, YEAR(MetricDate), MONTH(MetricDate)
ORDER BY DBName

SELECT * FROM mnDBA..DBGrowthRate WHERE DBName = 'mnMOnitoring'

SELECT	 * 
		,Totalsize = CONVERT(DECIMAL, REPLACE(DATA, ' KB', '')) + CONVERT(DECIMAL, REPLACE(indexsize, ' KB', '')) + CONVERT(DECIMAL, REPLACE(unused, ' KB', ''))
FROM	mnDBA..TableSizeAudit
WHERE	tablename = 'ApiWebLog'
AND		insertdate > '10/1/2015'
ORDER BY insertdate DESC

SELECT	AVG(rows)
		,COUNT(*)
FROM	mnDBA..TableSizeAudit
WHERE	tablename = 'ApiWebLog'
AND		insertdate > '10/1/2015'

SELECT 
		YEAR(insertdate)
		,MONTH(insertdate)
		,AVG(rows)
		,COUNT(*)
		,AVG(CONVERT(DECIMAL, REPLACE(DATA, ' KB', '')) + CONVERT(DECIMAL, REPLACE(indexsize, ' KB', '')) + CONVERT(DECIMAL, REPLACE(unused, ' KB', '')))
		,((AVG(CONVERT(DECIMAL, REPLACE(DATA, ' KB', '')) + CONVERT(DECIMAL, REPLACE(indexsize, ' KB', '')) + CONVERT(DECIMAL, REPLACE(unused, ' KB', ''))))/1024.00)/1024.00
FROM	mnDBA..TableSizeAudit WHERE tablename = 'ApiWebLog'
AND		insertdate > '1/1/2015'
GROUP BY	
		YEAR(insertdate)
		,MONTH(insertdate)

SELECT
		AVG(rows)
		,COUNT(*)
		,AVG(CONVERT(DECIMAL, REPLACE(DATA, ' KB', '')) + CONVERT(DECIMAL, REPLACE(indexsize, ' KB', '')) + CONVERT(DECIMAL, REPLACE(unused, ' KB', '')))
FROM	mnDBA..TableSizeAudit WHERE tablename = 'ApiWebLog'
AND		insertdate BETWEEN '9/1/2015' and '10/1/2015'

SELECT 17006920.695652/1024.00 AS InMB, (17006920.695652/1024.00)/1024.00 AS INGB
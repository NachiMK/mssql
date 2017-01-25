SELECT * FROM mnDBA..DBGrowthRate WHERE DBName = 'mnMonitoring' ORDER BY MetricDate DESC

IF OBJECT_ID('tempdb..#TMP') IS NOT NULL
	DROP TABLE #TMP
;WITH CTEDBSize
AS
(
SELECT	*
		,RowNumber = ROW_NUMBER() OVER	(PARTITION BY DBID ORDER BY MetricDate DESC) 
FROM	mnDBA..DBGrowthRate WHERE DBName = 'mnMonitoring' 
)
SELECT Curr.DBGrowthID ,
       Curr.DBName ,
       Curr.DBID ,
       Curr.NumPages ,
       Curr.OrigSize ,
       Curr.CurSize ,
       Curr.GrowthAmt ,
       Curr.MetricDate ,
       Curr.DataSize ,
       Curr.LogSize ,
       Curr.RowNumber,
	   Grwoth = Curr.CurSize - Prev.CurSize 
INTO	#TMP
FROM	CTEDBSize AS Curr
JOIN	CTEDBSize AS Prev	ON	Prev.DBID = Curr.DBID
							AND	Curr.RowNumber = Prev.RowNumber + 1


SELECT * FROM #TMP WHERE Grwoth != 0
ORDER BY MetricDate desc

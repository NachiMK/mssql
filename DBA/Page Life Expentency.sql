IF OBJECT_ID('tempdb..#PLE') IS NOT NULL
	DROP TABLE #PLE
SELECT  ServerName
		,NumaNode	= Numa_Node
		,PLE		= Value
		,Date		= CONVERT(DATE, RecordCreatedDateTime)
		,Day		= DATEPART(dd, RecordCreatedDateTime)
		,Hour		= DATEPART(hh, RecordCreatedDateTime)
		,RecordCreatedDateTime
		,RN			= ROW_NUMBER() OVER (PARTITION BY ServerName, Numa_Node ORDER BY RecordCreatedDateTime, DATEPART(hh, RecordCreatedDateTime))
INTO	#PLE
FROM	mnDBA.Perf.PerformanceCounters
WHERE	((DATEPART(hh, RecordCreatedDateTime) < 10) AND (DATEPART(dd, RecordCreatedDateTime) = 2)
		 OR
		 (DATEPART(dd, RecordCreatedDateTime) != 2)
		 )
ORDER BY
	Servername, Numa_Node, RN

SELECT	ServerName, NumaNode, PLE = AVG(PLE), Hour
FROM	#PLE
GROUP BY
		ServerName, NumaNode, Hour
ORDER BY
		ServerName, Hour, NumaNode


IF OBJECT_ID('tempdb..#Compared') IS NOT NULL
	DROP TABLE #Compared
;WITH Cmp
AS
(
SELECT	 ServerName
		,Hour
		,AvgPLE = AVG(PLE)
FROM	#PLE
GROUP BY
	ServerName, Hour
)
SELECT	 Nxt.ServerName
      	,Nxt.Hour
      	,Nxt.AvgPLE
		,PrevHour						=	ISNULL(P.Hour, Z.Hour)
		,PrevHourAvgPLE					=	ISNULL(P.AvgPLE, Z.AvgPLE)
		,DiffComparedToPrevHour			=	ISNULL(P.AvgPLE, Z.AvgPLE) - Nxt.AvgPLE
		,PctDiffComparedToPrevHour		=	(Nxt.AvgPLE * 1.00) / (ISNULL(P.AvgPLE, Z.AvgPLE) * 1.00)
INTO	#Compared
FROM	Cmp Nxt
JOIN	Cmp	Z	ON	Z.ServerName = Nxt.ServerName AND Z.Hour = 23
LEFT
JOIN	Cmp P	ON	Nxt.ServerName = P.ServerName AND Nxt.Hour - 1 = P.Hour
ORDER BY
	Nxt.ServerName, Nxt.Hour

;WITH CTE
AS
(
	SELECT	*
			,RN = ROW_NUMBER() OVER (ORDER BY C.PctDiffComparedToPrevHour DESC)
	FROM	#Compared  C
)
SELECT * FROM CTE ORDER BY RN 


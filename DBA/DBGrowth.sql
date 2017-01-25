SELECT * FROM mnDBA.dbo.DBGrowthRate WHERE CONVERT(DECIMAL, REPLACE(GrowthAmt, ' MB', '')) > 50 AND MetricDate > '10/1/2015'
ORDER BY DBName, MetricDate DESC


SELECT	DBName, AvgGrowthAmount = AVG(CONVERT(DECIMAL, REPLACE(GrowthAmt, ' MB', ''))), NoOfDays = COUNT(MetricDate)
FROM	mnDBA.dbo.DBGrowthRate
WHERE	CONVERT(DECIMAL, REPLACE(GrowthAmt, ' MB', '')) > 50 AND MetricDate > '10/1/2015'
GROUP BY DBName
ORDER BY DBName

-- GB Growth per day
SELECT (632 + 10567) / 1024.00

SELECT *
FROM	mnDBA.dbo.DBGrowthRate
WHERE	1 = 1
--AND		DBName LIKE 'mnIMail%'
AND		MetricDate > '1/1/2016'
AND		CONVERT(DECIMAL, REPLACE(GrowthAmt, ' MB', '')) > 0
ORDER BY DBName, MetricDate DESC


SELECT	 DBName
		,TotalGrowthAmountInGB = SUM(CONVERT(DECIMAL, REPLACE(GrowthAmt, ' MB', '')))/1024.00
		,NoOfDays		= DATEDIFF(dd, MIN(MetricDate), MAX(MetricDate))
		,NoOfLogEntries = COUNT(MetricDate)
		,AvgGrowthAmountInGB = (SUM(CONVERT(DECIMAL, REPLACE(GrowthAmt, ' MB', '')))/1024.00) / DATEDIFF(dd, MIN(MetricDate), MAX(MetricDate))
FROM	mnDBA.dbo.DBGrowthRate
WHERE	1 = 1
--AND		DBName LIKE 'mnMember_ProdFlat_scd%'
AND		MetricDate > '1/1/2016'
--AND		CONVERT(DECIMAL, REPLACE(GrowthAmt, ' MB', '')) > 10
GROUP BY
		DBName
ORDER BY
		AvgGrowthAmountInGB DESC, DBName


IF OBJECT_ID('tempdb..#Resources') IS NOT NULL
	DROP TABLE #Resources
SELECT  * 
INTO	#Resources
FROM	mnDBA.perf.ResourceCounters_Central
WHERE	RecordDateTime > '8/18/2016'
AND		RecordDatetime < '8/25/2016'
AND		Servername IN (
 'LASQL01'
,'LASQL02'
,'LASQL03'
,'LASQL04'
,'LASQL05'
,'LASQL06'
,'LASQL07'
,'LASQL08'
,'LASQL09'
,'LASQL10'
)

SELECT * FROM #Resources

;WITH CTELatestPerDay
AS
(
	SELECT	Servername ,
	      	ResourceID ,
	      	RecordDatetime ,
	      	EventTime ,
	      	SQLProcessUtilization ,
	      	SystemIdle ,
	      	OtherProcessUtilization ,
	      	CPUBusyPCT ,
	      	IOBusyPCT ,
	      	StartingUserConnections ,
	      	ConnectionOpened ,
	      	EndingUserConnections ,
	      	TransactionsPerSec ,
	      	BatchReqPerSec ,
			rn = ROW_NUMBER() OVER (PARTITION BY Servername ORDER BY RecordDatetime DESC)
	FROM	#Resources
)
SELECT * FROM CTELatestPerDay
WHERE rn = 1


SELECT	 R.Servername
		,EventDay			= CONVERT(DATE, R.RecordDatetime)
		,NetTransPerDay		= SUM(R.TransactionsPerSec)
		,AvgPerSecond		= SUM(R.TransactionsPerSec)/(24.0 * 60.0 * 60.0)
		,NoOfRecords		= COUNT(*)
--		,AvgTransPer5Min	= AVG(R.TransactionsPerSec)
FROM	#Resources R
--WHERE	(CONVERT(NUMERIC(10,2), REPLACE(R.Servername, 'LASQL', ''))%2) != 0
GROUP BY
		R.Servername
		,CONVERT(DATE, R.RecordDatetime)
ORDER BY
		R.Servername
		,CONVERT(DATE, R.RecordDatetime)


SELECT	 EventDay			= CONVERT(DATE, R.RecordDatetime)
		,NetTransPerDay		= SUM(R.TransactionsPerSec)
		,AvgPerSecond		= SUM(R.TransactionsPerSec)/(24.0 * 60.0 * 60.0)
		,NoOfRecords		= COUNT(*)
		--,AvgTransPer5Min	= AVG(R.TransactionsPerSec)
FROM	#Resources R
--WHERE	(CONVERT(NUMERIC(10,2), REPLACE(R.Servername, 'LASQL', ''))%2) != 0
GROUP BY
		CONVERT(DATE, R.RecordDatetime)
ORDER BY
		CONVERT(DATE, R.RecordDatetime)

--SELECT TOP 10 * FROM mnDBA.perf.ExecutionCapture_Central WITH (READUNCOMMITTED) WHERE ResourceID IN (SELECT TOP 1 ResourceID FROM #Resources)

SELECT TOP 10 * FROM mnDBA.perf.ExecutionCapture_Central WITH (READUNCOMMITTED) WHERE ResourceID = 51915 AND RecordDateTime > '8/18/2016'

--SELECT TOP 10 * FROM mnDBA.perf.ExecutionCapture_Central WITH (READUNCOMMITTED) WHERE ResourceID IN (SELECT TOP 10 ResourceID FROM #Resources)

DECLARE @transactionsbegin DECIMAL
DECLARE @transactionsend DECIMAL

DECLARE @AtStart BIGINT
DECLARE @AtEnd BIGINT

SET @transactionsbegin= (select cntr_value  FROM sys.dm_os_performance_counters
where counter_name ='transactions/sec' and instance_name ='_Total')

--PRINT 'START DATE TIME:'
--SELECT GETDATE()

SELECT @AtStart = ms_ticks FROM sys.dm_os_sys_info

--Print @timetowait
WAITFOR delay '00:00:05'

SELECT @AtEnd = ms_ticks FROM sys.dm_os_sys_info

--PRINT 'END DATE TIME:'
--SELECT GETDATE()

set @transactionsend= (select cntr_value  FROM sys.dm_os_performance_counters where counter_name ='transactions/sec' and instance_name ='_Total')

--SELECT transactionbegin = @transactionsbegin, transactionend = @transactionsend, AtStart = @AtStart, AtEnd = @AtEnd

SELECT TransPerSec   = (@transactionsend - @transactionsbegin) / ((@AtEnd - @AtStart) / 1000.0)
	   ,TransPer5Sec  = (@transactionsend - @transactionsbegin) / 5.0
	   ,TimeElapsed  = ((@AtEnd - @AtStart) / 1000.0)
	   ,StartDate	= (SELECT sqlserver_start_time FROM sys.dm_os_sys_info)

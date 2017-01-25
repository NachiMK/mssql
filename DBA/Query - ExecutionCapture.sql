SELECT  *
FROM    mnDBA.perf.ExecutionCapture WITH (READUNCOMMITTED)
WHERE   
	LastExecutionTime > '2016-06-21'
AND dbname = 'mnMember_ProdFlat'
AND objectName = 'usp_MemberFlat_Process_Partition_PC'
ORDER BY LastExecutionTime



SELECT * FROM mnDBA.perf.ResourceCounters WHERE RecordDatetime > '6/21/2016' ORDER BY RecordDatetime

SELECT	 EventDate = CONVERT(DATE, EventTime)
		,HourOfEvent = DATEPART(hh, EventTime) 
		,AveIOPct = AVG(IOBusyPCT)
FROM	mnDBA.perf.ResourceCounters 
WHERE	RecordDatetime > '6/20/2016'
GROUP BY
	CONVERT(DATE, EventTime)
	,DATEPART(hh, EventTime) 
ORDER BY 
	EventDate
	,HourOfEvent


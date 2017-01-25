SELECT * FROM mnDBA.Perf.ServerStats WHERE FindingsGroup = 'Server Performance' AND ServerName = @@SERVERNAME
ORDER BY Finding, CheckDate

SELECT * FROM mnDBA.Perf.PerfmonStats WHERE Counter_Name LIKE '%Page life%' AND ServerName = 'LASQLPRODFLAT01'

SELECT	 ServerName
		,Counter_Name
		,AvgCounterValue = AVG(cntr_value)
FROM	mnDBA.Perf.PerfmonStats 
WHERE 1 = 1
AND	(
		(Counter_Name LIKE '%Page life%')
		OR
		(Counter_Name LIKE '%Page%Reads%')
		OR
		(Counter_Name LIKE '%Disk%reads%')
	)
--AND ServerName IN ( 'LASQLPRODFLAT01')
GROUP BY ServerName, Counter_Name
ORDER BY ServerName, Counter_Name


-- Look at waits
SELECT  ServerName
		,wait_type
		,sum_wait_time_ms	=	SUM(os.wait_time_ms) 
		,sum_waiting_tasks	=	SUM(os.waiting_tasks_count) 
		,avg_wait_time_ms	=	CAST((SUM(os.wait_time_ms) / (1. * SUM(os.waiting_tasks_count) )) AS NUMERIC(12,1))
FROM	mnDBA.Perf.WaitStats os
WHERE	1= 1
AND		(
			(wait_type LIKE '%PageIOlatch_SH%')
		)
--AND ServerName IN ( 'LASQLPRODFLAT01')
GROUP BY ServerName, wait_type
ORDER BY ServerName, wait_type

SELECT	 ServerName
		,Counter_Name
		,CheckDate			=	CONVERT(DATE, CheckDate)
		,AvgCountervalue	=	AVG(cntr_value)
FROM	mnDBA.Perf.PerfmonStats 
WHERE	1= 1
AND		(
			(Counter_Name LIKE '%Page life%')
			OR
			(Counter_Name LIKE '%Page%reads%')
			OR
			(Counter_Name LIKE '%Page%input%')
		)
--AND ServerName = 'LASQLPRODFLAT01'
--AND		CONVERT(DATE, CheckDate) > '9/22/2016'
GROUP BY 
		 ServerName
		,Counter_Name
		,CONVERT(DATE, CheckDate)
ORDER BY ServerName, Counter_Name, CONVERT(DATE, CheckDate)


SELECT	 ServerName
		,Counter_Name
		,CheckDate			=	CONVERT(DATE, CheckDate)
		,CheckedHour		=	DATEPART(HH, CheckDate)
		,AvgCountervalue	=	AVG(cntr_value)
FROM	mnDBA.Perf.PerfmonStats 
WHERE	1= 1
AND		(
			(Counter_Name LIKE '%Page life%')
			OR
			(Counter_Name LIKE '%Page%reads%')
			OR
			(Counter_Name LIKE '%Page%input%')
		)
--AND ServerName = 'LASQLPRODFLAT01'
GROUP BY 
		 ServerName
		,Counter_Name
		,CONVERT(DATE, CheckDate)
		,DATEPART(HH, CheckDate)
ORDER BY ServerName, Counter_Name, CONVERT(DATE, CheckDate) ,DATEPART(HH, CheckDate)


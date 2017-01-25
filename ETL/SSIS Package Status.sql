USE SSISDB
GO

DECLARE @ProjectName VARCHAR(100) =  'ETL_Maropost_MatchMailExport'

SELECT TOP 1 * FROM internal.executions 
WHERE	1 = 1
AND		project_name = @ProjectName
ORDER BY execution_id DESC

DECLARE @execution_id INT

SET @execution_id = 
(
SELECT TOP 1 execution_id FROM internal.executions 
WHERE	1 = 1
AND		project_name = @ProjectName
ORDER BY execution_id DESC
)
-- SELECT @execution_id = MAX(execution_id) FROM SSISDB.catalog.executions
SELECT @execution_id

SELECT  *
FROM    [DataFeed].[dbo].[ProcessErrorLog](NOLOCK)
WHERE   execution_id = @execution_id
ORDER BY 1 DESC

SELECT  *
FROM    [DataFeed].[dbo].[ProcessLog](NOLOCK)
WHERE   execution_id = @execution_id
ORDER BY 1 DESC

-- if want to see it in ssis catalog
SELECT  DurationInMins = DATEDIFF(mi, CONVERT(DATETIME, message_time), GETDATE()), *
FROM    SSISDB.[catalog].[event_messages] (NOLOCK)
WHERE   1 = 1
--AND event_name = 'OnError'
AND operation_id = @execution_id
--AND message LIKE '%usp_ETL_Maropost_UpdateChangeControl%'
ORDER BY 2 DESC

/*
-- Process Attribute values
SELECT	P.ProcessID, P.ProcessName, C.ProcessID, C.ProcessName, PA.IntValue, PA.TextValue, PA.DateValue
		,PPA.IntValue, PPA.TextValue, PPA.DateValue
FROM	DataFeed.dbo.Process	P
LEFT
JOIN	DataFeed.dbo.Process	C	ON	C.ParentProcessID = P.ProcessID
LEFT
JOIN	DataFeed.dbo.ProcessAttribute	PA	ON	PA.ProcessID = C.ProcessID
LEFT
JOIN	DataFeed.dbo.ProcessAttribute	PPA	ON	PPA.ProcessID = P.ProcessID
WHERE	P.ProcessName = 'Maropost SubscriberInfo'

--SELECT * FROM catalog.executions ORDER BY created_time desc
*/
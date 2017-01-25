DECLARE 
    @RequiredStartTime DATETIME, 
    @RequiredEndTime DATETIME

SELECT @RequiredStartTime = '20110101', @RequiredEndTime = '20110401'

;WITH xmlnamespaces (
DEFAULT
'http://schemas.microsoft.com/sqlserver/reporting/2008/01/reportdefinition',
'http://schemas.microsoft.com/SQLServer/reporting/reportdesigner' AS rd
)
SELECT
    a.Name AS [Report Name],
    x.value('CommandText[1]','VARCHAR(max)') AS [Stored Procedure]
    --CONVERT(CHAR(8),DATEADD(ss, (EL.TimeDataRetrieval
    --	  + EL.TimeProcessing
    --	  + EL.TimeRendering)/1000,0),108 )AS Duration,
    --'@'+REPLACE(CAST(el.[parameters] AS NVARCHAR(MAX)),'&',', @') AS [Parameters]
INTO #ReportSP
FROM
(
    SELECT 
    	NAME,
    	ItemID,
    	CAST(CAST(CONTENT AS VARBINARY(MAX)) AS XML) AS reportxml
    FROM reportserver.dbo.catalog
    WHERE [TYPE] = 2
) a
--INNER JOIN ExecutionLog EL ON EL.ReportID = a.ItemID
CROSS APPLY a.reportxml.nodes('/Report/DataSets/DataSet/Query')r(x)
WHERE 
    NOT PATINDEX('%.%', name) > 0
    AND x.value('CommandType[1]', 'VARCHAR(max)') ='StoredProcedure'
	--AND x.value('CommandText[1]','VARCHAR(max)') LIKE '%Rpt.SCH005_LILOCheckReport%'
	
SELECT * FROM #ReportSP AS RS WHERE [Stored Procedure] LIKE	'%SCH005_LILOCheckReport%'
SELECT * FROM #ReportSP AS RS WHERE [Stored Procedure] LIKE	'%SCH007_MultipleSJAReport%'
SELECT * FROM #ReportSP AS RS WHERE [Stored Procedure] LIKE	'%HC001_SKUStatus%'
SELECT * FROM #ReportSP AS RS WHERE [Stored Procedure] LIKE	'%RW5008_StoreSchedule%'
SELECT * FROM #ReportSP AS RS WHERE [Stored Procedure] LIKE	'%RW5011_EmployeesWithScheduledPurchase%'

SELECT * FROM #ReportSP AS RS WHERE [Stored Procedure] LIKE	'%sp_InData_GetExecutionData%'
SELECT * FROM #ReportSP AS RS WHERE [Stored Procedure] LIKE	'%sp_InData_GetExecutionDataByJob%'
SELECT * FROM #ReportSP AS RS WHERE [Stored Procedure] LIKE	'%sp_InData_GetExecutionDataByProject%'


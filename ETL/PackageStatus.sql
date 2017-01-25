/*
	Script to Find Package Status
	or Task Status.
*/
USE InData_Log
GO

/*
	Package Time
*/
IF 1 = 0
SELECT  P.PackageGUID, P.PackageName, PL.MachineName, PL.PackageLogID, PL.StartDateTime, PL.EndDateTime
		,DurationInMinutes = DATEDIFF(mi, PL.StartDateTime, ISNULL(PL.EndDateTime, GETDATE()))
		,PL.Status
FROM    SSIS.PackageLog AS PL WITH (READUNCOMMITTED)
join	SSIS.Package AS P WITH (READUNCOMMITTED) ON P.PackageGUID = PL.PackageGUID
WHERE	P.EnteredDateTime > '6/17/2014'
AND		PL.MachineName = 'NVBIDBD5'
AND		PL.StartDateTime >= '2014-06-17 15:03:11.000'

/*
	Task Time
*/
IF 1 = 0
SELECT  P.PackageGUID
		,P.PackageName
		,PL.MachineName
		,PackageStartTime	= PL.StartDateTime
		,PackageEndTime		= PL.EndDateTime
		,PackageStatus		= PL.Status
		,DurationInMinutes	= DATEDIFF(mi, PL.StartDateTime, ISNULL(PL.EndDateTime, GETDATE()))
		,TaskName			= PTL.SourceName
		,TaskStartTime		= PTL.StartDateTime
		,TaskEndTime		= PTL.EndDateTime
		,TaskDurInMin		= DATEDIFF(mi, PTL.StartDateTime, ISNULL(PTL.EndDateTime, GETDATE()))
FROM    SSIS.PackageLog AS PL WITH (READUNCOMMITTED)
JOIN	SSIS.Package AS P WITH (READUNCOMMITTED) ON P.PackageGUID = PL.PackageGUID
JOIN	SSIS.PackageTaskLog AS PTL WITH (READUNCOMMITTED) ON PTL.PackageLogID = PL.PackageLogID
WHERE	P.EnteredDateTime > '12/10/2014'
AND		PL.MachineName = 'NVBIDBD5'
AND		PL.StartDateTime >= '2014-12-10 13:03:11.000'
AND		PTL.SourceName IN ('DFT Stg Photo', 'SQL DS Photo')
ORDER BY PL.PackageLogID, TaskName

IF 1 = 0
SELECT  P.PackageGUID
		,P.PackageName
		,PL.MachineName
		,PackageStartTime	= PL.StartDateTime
		,PackageEndTime		= PL.EndDateTime
		,PackageStatus		= PL.Status
		,DurationInMinutes	= DATEDIFF(mi, PL.StartDateTime, ISNULL(PL.EndDateTime, GETDATE()))
		,TaskName			= PTL.SourceName
		,TaskStartTime		= PTL.StartDateTime
		,TaskEndTime		= PTL.EndDateTime
		,TaskDurInMin		= DATEDIFF(mi, PTL.StartDateTime, ISNULL(PTL.EndDateTime, GETDATE()))
		,EL.ErrorCode
		,EL.ErrorDescription
		,EL.PackageErrorLogID
		,EL.SourceName
FROM    InData_Log.SSIS.PackageLog AS PL WITH (READUNCOMMITTED)
JOIN	InData_Log.SSIS.Package AS P WITH (READUNCOMMITTED) ON P.PackageGUID = PL.PackageGUID
JOIN	InData_Log.SSIS.PackageTaskLog AS PTL WITH (READUNCOMMITTED) ON PTL.PackageLogID = PL.PackageLogID
LEFT	JOIN	InData_Log.SSIS.PackageErrorLog AS EL WITH (READUNCOMMITTED) ON EL.PackageLogID = PTL.PackageLogID
WHERE	PL.StartDateTime >= '2014-10-29 05:00:00.000'
--AND		P.PackageName LIKE 'Roundy%' --'PTS003 - ETL PTS'
--AND		P.PackageName LIKE 'Jet%' --'PTS003 - ETL PTS'
AND		P.PackageName LIKE '%QnA%' --'PTS003 - ETL PTS'
--AND		P.PackageName IN ('PTS003 - ETL PTS') --'PTS003 - ETL PTS'
--AND		PTL.SourceName IN ('SQL DS Answer')
--AND		PL.Status in ('R', 'E')
--AND		PTL.EndDateTime is null
ORDER BY PL.PackageLogID, P.PackageGUID, PL.StartDateTime, TaskName

/* All Running Packages */
IF 1 = 0
SELECT  P.PackageGUID
		,P.PackageName
		,PL.MachineName
		,PackageStartTime	= PL.StartDateTime
		,PackageEndTime		= PL.EndDateTime
		,PackageStatus		= PL.Status
		,DurationInMinutes	= DATEDIFF(mi, PL.StartDateTime, ISNULL(PL.EndDateTime, GETDATE()))
		--,EL.ErrorCode
		--,EL.ErrorDescription
		--,EL.PackageErrorLogID
		--,EL.SourceName
FROM    InData_Log.SSIS.PackageLog AS PL WITH (READUNCOMMITTED)
JOIN	InData_Log.SSIS.Package AS P WITH (READUNCOMMITTED) ON P.PackageGUID = PL.PackageGUID
--LEFT	JOIN	InData_Log.SSIS.PackageErrorLog AS EL WITH (READUNCOMMITTED) ON EL.PackageLogID = PTL.PackageLogID
WHERE	1 = 1
--AND		PL.StartDateTime >= '2014-09-29 00:00:00.000'
AND		PL.StartDateTime >= CONVERT(DATE, GETDATE())
--AND		PL.Status in ('R', 'E')
AND		PL.EndDateTime is null
ORDER BY PL.PackageLogID, P.PackageGUID, PL.StartDateTime

/*
	All Tasks
*/
IF 1 = 0
SELECT  P.PackageGUID
		,P.PackageName
		,PL.MachineName
		,PackageStartTime	= PL.StartDateTime
		,PackageEndTime		= PL.EndDateTime
		,PackageStatus		= PL.Status
		,DurationInMinutes	= DATEDIFF(mi, PL.StartDateTime, ISNULL(PL.EndDateTime, GETDATE()))
		,TaskName			= PTL.SourceName
		,TaskStartTime		= PTL.StartDateTime
		,TaskEndTime		= PTL.EndDateTime
		,TaskDurInMin		= DATEDIFF(mi, PTL.StartDateTime, ISNULL(PTL.EndDateTime, GETDATE()))
FROM    SSIS.PackageLog AS PL WITH (READUNCOMMITTED)
JOIN	SSIS.Package AS P WITH (READUNCOMMITTED) ON P.PackageGUID = PL.PackageGUID
JOIN	SSIS.PackageTaskLog AS PTL WITH (READUNCOMMITTED) ON PTL.PackageLogID = PL.PackageLogID
WHERE	P.EnteredDateTime > '6/17/2014'
AND		PL.MachineName = 'NVBIDBD5'
AND		PL.StartDateTime >= '2014-06-17 15:03:11.000'
ORDER BY PackageStatus, PL.PackageLogID, TaskName

/*
	a specific running package
*/
--SELECT  *
--FROM    master.Perf.WhoIsActive WITH (READUNCOMMITTED)
--WHERE	collection_time > '11/21/2014 00:45'
--AND	1 = 0
--ORDER BY collection_time DESC


SELECT  P.PackageGUID
		,P.PackageName
		,PL.MachineName
		,PackageStartTime	= PL.StartDateTime
		,PackageEndTime		= PL.EndDateTime
		,PackageStatus		= PL.Status
		,DurationInMinutes	= DATEDIFF(mi, PL.StartDateTime, ISNULL(PL.EndDateTime, GETDATE()))
		,TaskName			= PTL.SourceName
		,TaskStartTime		= PTL.StartDateTime
		,TaskEndTime		= PTL.EndDateTime
		,TaskDurInMin		= DATEDIFF(mi, PTL.StartDateTime, ISNULL(PTL.EndDateTime, GETDATE()))
		,EL.ErrorCode
		,EL.ErrorDescription
		,EL.PackageErrorLogID
		,EL.SourceName
FROM    InData_Log.SSIS.PackageLog AS PL WITH (READUNCOMMITTED)
JOIN	InData_Log.SSIS.Package AS P WITH (READUNCOMMITTED) ON P.PackageGUID = PL.PackageGUID
JOIN	InData_Log.SSIS.PackageTaskLog AS PTL WITH (READUNCOMMITTED) ON PTL.PackageLogID = PL.PackageLogID
LEFT	JOIN	InData_Log.SSIS.PackageErrorLog AS EL WITH (READUNCOMMITTED) ON EL.PackageLogID = PTL.PackageLogID
WHERE	PL.StartDateTime >= '2015-02-01 11:05:00.000'
--AND		P.PackageName IN ('PTS003 - ETL PTS') --'QnA01_DM'
--AND		P.PackageName IN ('QnA01_DM')
--AND		PL.Status in ('R', 'E')
--AND		PTL.EndDateTime is null
AND			((P.PackageName LIKE '%PTS003%') OR (P.PackageName LIKE '%PTS002%'))
-- PACKAGE TASKS THAT ARE STILL RUNNING
--AND			PTL.EndDateTime IS NULL
AND			((PTL.SourceName IN ('SEQ Stg Data', 'SEQ Stg Integrate', 'SEQ Screens')))
ORDER BY P.PackageName, PL.PackageLogID, P.PackageGUID, PTL.StartDateTime, TaskName


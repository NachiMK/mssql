/*==========================================================================
Author:		Rick Paniagua
Name:		A3 Convention - ETL SSIS Log Analysis - Single Package.sql
============================================================================
GET LAST BATCH RUN FOR GIVEN SSIS PACKAGE
===========================================================================*/

DECLARE @PackageName	VARCHAR(80) = 'kenexa'
DECLARE	@LastBatchLogID INT 

--GET LAST BatchLogID FOR PACKAGE
SELECT		TOP 1 @LastBatchLogID = PL.BatchLogID
FROM		InData_Log.SSIS.PackageLog PL
JOIN		InData_Log.SSIS.Package P ON PL.PackageGUID = P.PackageGUID 
WHERE		P.PackageName LIKE @PackageName + '%'
ORDER BY	PL.StartDateTime DESC 

--GET PACKAGE RESULTS
SELECT		 P.PackageID															PackageID
			,P.PackageName															PackageName
			,PL.BatchLogID															BatchLogID
			,PL.[Status]															[Status]
			,PL.StartDateTime														StartDateTime
			,ISNULL(DATEDIFF(SECOND, PL.StartDateTime, PL.EndDateTime	) / 60.00
				  , DATEDIFF(SECOND, PL.StartDateTime, GETDATE()) / 60.00)			RunningDuration_Minutes			
			,PTL.SourceName															SourceName
			,PTL.StartDateTime														StartDateTime
			,PTL.EndDateTime														EndDateTime
			,PEL.ErrorCode															ErrorCode
			,PEL.ErrorDescription													ErrorDescription
			,DATEDIFF(SECOND, PTL.StartDateTime, PTL.EndDateTime)					TaskDuration_Seconds
			,DATEDIFF(SECOND, PTL.StartDateTime, PTL.EndDateTime) / 60.00			TaskDuration_Minutes
			,PL.EndDateTime															EndDateTime		
			,DATEDIFF(SECOND, PL.StartDateTime, PL.EndDateTime	)					PackageDuration_Seconds
			,DATEDIFF(SECOND, PL.StartDateTime, PL.EndDateTime	) / 60.00			PackageDuration_Minutes
FROM		InData_Log.SSIS.Package P
JOIN		InData_Log.SSIS.PackageLog PL		ON P.PackageGUID = PL.PackageGUID
LEFT JOIN	InData_Log.SSIS.PackageTaskLog PTL	ON PL.PackageLogID = PTL.PackageLogID
LEFT JOIN	InData_Log.SSIS.PackageErrorLog PEL ON PTL.PackageLogID = PEL.PackageLogID
												   AND PTL.SourceID = PEL.SourceID
WHERE		 PL.BatchLogID = @LastBatchLogID
ORDER BY	 PL.BatchLogID
			,PTL.PackageTaskLogID
			,PTL.SourceName

--SELECT		PVL.*
--FROM		InData_Log.SSIS.PackageLog PL 
--JOIN		InData_Log.SSIS.PackageVariableLog PVL ON PL.PackageLogID = PVL.PackageLogID
--WHERE		PL.BatchLogID = @LastBatchLogID


/*

	Run this script in servers LASQL01-10, PRODFLAT01, 02, CLSQL41, and CLSQL44 to get server backup details.

	This script will get only the duration it took to take the BACKUP. IT DOESNT SHOW how long it took to copy the file over to the shared folders.

*/
USE mnDBA
GO

IF OBJECT_ID('tempdb..#LogDates') IS NOT NULL
       DROP TABLE #LogDates
SELECT backup_id,@@SERVERNAME AS ServerName,db_name AS DBName,MIN(backup_step_date) AS StartDate,MAX(backup_step_date) AS EndDate,
              DATEDIFF(SECOND,MIN(backup_step_date),MAX(backup_step_date)) AS RunTimeInSec,
              COUNT(*) AS TotalRecords
INTO #LogDates
FROM dbo.Backup_Log (READUNCOMMITTED)
WHERE (backup_step LIKE 'STEP2| START%' OR backup_step LIKE 'STEP2| END%') 
--AND backup_id IN  (1164647,1165045)
GROUP BY backup_id,db_name
ORDER BY 1 


IF OBJECT_ID('tempdb..#BackupType') IS NOT NULL
       DROP TABLE #BackupType
SELECT LD.backup_id ,
       LD.ServerName ,
       LD.DBName ,
       LD.StartDate ,
       LD.EndDate ,
       LD.RunTimeInSec,
          BC.bkpType,
          LD.TotalRecords,
          DATEDIFF(DAY,BC.backup_date,GETDATE()) DaysofBackup
INTO #BackupType
FROM #LogDates AS LD 
JOIN dbo.Backup_Control AS BC ON BC.backup_id = LD.backup_id


SELECT   SERVERNAME
		,DBNAME

		,AvgDurInSec_TLog		=	SUM(CASE WHEN BKPTYPE = 'TLog' THEN RunTimeInSec ELSE NULL END)/COUNT(CASE WHEN BKPTYPE = 'TLog' THEN TotalRecords ELSE NULL END)
		,AvgDurInMin_TLog		=	CONVERT(NUMERIC(10, 2), (SUM(CASE WHEN BKPTYPE = 'TLog' THEN RunTimeInSec ELSE NULL END)/60.00)/COUNT(CASE WHEN BKPTYPE = 'TLog' THEN TotalRecords ELSE NULL END))

		,AvgDurInSec_Diff		=	SUM(CASE WHEN BKPTYPE = 'diff' THEN RunTimeInSec ELSE NULL END)/COUNT(CASE WHEN BKPTYPE = 'diff' THEN TotalRecords ELSE NULL END)
		,AvgDurInMin_Diff		=	CONVERT(NUMERIC(10, 2), (SUM(CASE WHEN BKPTYPE = 'diff' THEN RunTimeInSec ELSE NULL END)/60.00)/COUNT(CASE WHEN BKPTYPE = 'diff' THEN TotalRecords ELSE NULL END))

		,AvgDurInSec_Full		=	SUM(CASE WHEN BKPTYPE = 'full' THEN RunTimeInSec ELSE NULL END)/COUNT(CASE WHEN BKPTYPE = 'full' THEN TotalRecords ELSE NULL END)
		,AvgDurInMin_Full		=	CONVERT(NUMERIC(10, 2), (SUM(CASE WHEN BKPTYPE = 'full' THEN RunTimeInSec ELSE NULL END)/60.00)/COUNT(CASE WHEN BKPTYPE = 'full' THEN TotalRecords ELSE NULL END))

		,AvgDurInSec_sys		=	SUM(CASE WHEN BKPTYPE = 'system' THEN RunTimeInSec ELSE NULL END)/COUNT(CASE WHEN BKPTYPE = 'system' THEN TotalRecords ELSE NULL END)
		,AvgDurInMin_sys		=	CONVERT(NUMERIC(10, 2), (SUM(CASE WHEN BKPTYPE = 'system' THEN RunTimeInSec ELSE NULL END)/60.00)/COUNT(CASE WHEN BKPTYPE = 'system' THEN TotalRecords ELSE NULL END))

		,SUM(RunTimeInSec)/COUNT(TotalRecords) AS AvgDurationInSeconds
		,CONVERT(NUMERIC(10, 2), (SUM(RunTimeInSec)/60.00)/COUNT(TotalRecords)) AS AvgDurationInMins

        ,MIN(RUNTIMEINSEC) Shortest
        ,MAX(RUNTIMEINSEC) Longest
        ,MAX(DAYSOFBACKUP) AS TotalNumberofDays

		,Pair = CASE @@SERVERNAME
					WHEN 'LASQL01' THEN 'LASQL01/02'
					WHEN 'LASQL02' THEN 'LASQL01/02'
					WHEN 'LASQL03' THEN 'LASQL03/04'
					WHEN 'LASQL04' THEN 'LASQL03/04'
					WHEN 'LASQL05' THEN 'LASQL05/06'
					WHEN 'LASQL06' THEN 'LASQL05/06'
					WHEN 'LASQL07' THEN 'LASQL07/07'
					WHEN 'LASQL08' THEN 'LASQL07/08'
					WHEN 'LASQL09' THEN 'LASQL09/10'
					WHEN 'LASQL10' THEN 'LASQL09/10'

					ELSE @@SERVERNAME
				END
FROM #BACKUPTYPE
GROUP BY SERVERNAME,DBNAME,TotalRecords
ORDER BY ServerName, DBName

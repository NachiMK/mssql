/*
	Script to easily look through Member Databases
*/
IF OBJECT_ID('tempdb..#MemberDBs') IS NOT NULL
	DROP TABLE #MemberDBs
SELECT	PD.ServerName
		,PD.PhysicalDatabaseName
		,MemberDBPartitionID = CONVERT(INT, REPLACE(PD.PhysicalDatabaseName, LD.LogicalDatabaseName, ''))
INTO	#MemberDBs
FROM	mnSystem.dbo.LogicalDatabase			AS LD	WITH (READUNCOMMITTED)
JOIN	mnSystem.dbo.HydraMode					AS HM	WITH (READUNCOMMITTED)	ON	HM.HydraModeID = LD.HydraModeID
JOIN	mnSystem.dbo.LogicalPhysicalDatabase	AS LPD	WITH (READUNCOMMITTED)	ON	LPD.LogicalDatabaseID = LD.LogicalDatabaseID
JOIN	mnSystem.dbo.PhysicalDatabase			AS PD	WITH (READUNCOMMITTED)	ON	PD.PhysicalDatabaseID = LPD.PhysicalDatabaseID
WHERE	1 = 1
AND		LD.LogicalDatabaseName LIKE 'mnMember'
AND		CONVERT(INT, REPLACE(PD.ServerName, 'LASQL', '')) % 2 = 0
ORDER BY	PD.ServerName, MemberDBPartitionID

-- SELECT * FROM #MemberDBs

IF OBJECT_ID('tempdb..#Result') IS NOT NULL
	DROP TABLE #Result
CREATE TABLE #Result
(
	MemberId	INT	NOT NULL
	,ServerName	VARCHAR(100)
	,DBName		VARCHAR(100)
)

DECLARE  @ServerName	VARCHAR(100)
		,@DBName		VARCHAR(100)

DECLARE @SqlCmd VARCHAR(MAX)
DECLARE @CRLF	NCHAR(2)		= CHAR(13) + CHAR(10)

DECLARE OBJECT_CURSOR CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

SELECT		 ServerName
      		,PhysicalDatabaseName
FROM		#MemberDBs
ORDER BY	MemberDBPartitionID

OPEN OBJECT_CURSOR

FETCH NEXT FROM OBJECT_CURSOR
INTO @ServerName, @DBName

WHILE (@@FETCH_STATUS = 0)
BEGIN

	PRINT 'Querying Member Partition DB: ' + @DBName

	SET @SqlCmd = ''
	SET @SqlCmd = @SqlCmd	+	'INSERT INTO #Result' + @CRLF
	SET @SqlCmd = @SqlCmd	+	'EXEC(''SELECT MemberId, ServerName = ''''' + @ServerName + ''''', DBName = ''''' + @DBName + ''''''
							+	' FROM ' + @DBName + '.dbo.SearchPreference	T	WITH (READUNCOMMITTED) WHERE SearchTypeID = 2'')'	+	@CRLF
							+	 CASE WHEN @ServerName = @@SERVERNAME THEN N'' ELSE N' AT ' + @ServerName END

	PRINT  @SqlCmd
	EXEC  (@SqlCmd)

	PRINT 'Querying Member Partition DB: ' + @DBName + ' completed at :' + CONVERT(VARCHAR, GETDATE(), 114)

	FETCH NEXT FROM OBJECT_CURSOR
	INTO @ServerName, @DBName
END

CLOSE OBJECT_CURSOR
DEALLOCATE OBJECT_CURSOR


SELECT * FROM #Result
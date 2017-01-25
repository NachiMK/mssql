/*
	Update Member Information Template

	Loop through Member DBs and update tables in those DBs

	Server: Connect to CLSQL76 or one of the LASQL01 through 10 and run the template (make sure to modify it to your needs)
*/
-- Member IDs to be updated: 
-- Either use a list of find the members
IF OBJECT_ID('tempdb..#MembersToUpdate') IS NOT NULL
	DROP TABLE #MembersToUpdate
CREATE TABLE #MembersToUpdate
(
	 MemberID		INT	NOT NULL
	 ,PartitionID	INT
)
INSERT INTO #MembersToUpdate (MemberID)
SELECT	32661499		UNION
SELECT	120086324		UNION
SELECT	51291489		UNION
SELECT	8682096

-- UPDATE PARTITION ID
UPDATE #MembersToUpdate SET PartitionID = (MemberID % 24) + 1 WHERE PartitionID IS NULL

SELECT * FROM #MembersToUpdate

-- Get Member Databases
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
ORDER BY	PD.ServerName, MemberDBPartitionID

-- SELECT * FROM #MemberDBs ORDER BY MemberDBPartitionID

-- SANITY CHECK, DOES ALL OUR MEMBERS HAVE DBs to UPDATE
SELECT * FROM #MembersToUpdate	MU
LEFT
JOIN	#MemberDBs				MDB	ON	MDB.MemberDBPartitionID = MU.PartitionID
WHERE	MDB.MemberDBPartitionID IS NULL

DECLARE  @ServerName	VARCHAR(100)
		,@DBName		VARCHAR(100)
		,@PartitionID	INT
DECLARE @SqlCmd VARCHAR(MAX)
DECLARE @CRLF	NCHAR(2)		= CHAR(13) + CHAR(10)
DECLARE @MemberID	INT

DECLARE OBJECT_CURSOR CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

SELECT		 ServerName
      		,PhysicalDatabaseName
			,MemberDBPartitionID
FROM		#MemberDBs
WHERE		EXISTS (SELECT * FROM #MembersToUpdate WHERE PartitionID = MemberDBPartitionID)
ORDER BY	MemberDBPartitionID, ServerName

OPEN OBJECT_CURSOR

FETCH NEXT FROM OBJECT_CURSOR
INTO @ServerName, @DBName, @PartitionID

WHILE (@@FETCH_STATUS = 0)
BEGIN

	PRINT 'Updating Member Partition DB: ' + @DBName + ' in Server:' + @ServerName

	-- LOOP THROUGH MEMBERS IN THAT PARTITION AND UPDATE
	DECLARE MemberCursor CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

	SELECT	MemberID
	FROM	#MembersToUpdate
	WHERE	PartitionID	= @PartitionID

	OPEN	MemberCursor

	FETCH NEXT FROM MemberCursor
	INTO	@MemberID

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		PRINT 'Updating Member :' + CONVERT(VARCHAR, @MemberID)

		SET @SqlCmd = ''

		/*************************************************************************************/
		/*MAKE SURE THE BELOW QUERY IS SET TO UPDATE RIGHT MEMBER AND RIGHT NUMBER OF ROWS.*/
		/*************************************************************************************/

		SET @SqlCmd = @SqlCmd	+	'EXEC(''UPDATE T SET SearchTypeID = 4, UpdateDate = GETDATE()'
								+	' FROM ' + @DBName + '.dbo.SearchPreference	T	WHERE SearchTypeID = 2 AND MemberID = ' + CONVERT(VARCHAR, @MemberID) + ''')'	+	@CRLF
								+	 CASE WHEN @ServerName = @@SERVERNAME THEN N'' ELSE N' AT ' + @ServerName END

		/*************************************************************************************/
		/*MAKE SURE THE BELOW QUERY IS SET TO UPDATE RIGHT MEMBER AND RIGHT NUMBER OF ROWS.*/
		/*************************************************************************************/

		PRINT  @SqlCmd
		--EXEC  (@SqlCmd)

		PRINT 'Done updating Member :' + CONVERT(VARCHAR, @MemberID)

		FETCH NEXT FROM MemberCursor
		INTO		@MemberID
	END

	CLOSE MemberCursor
	DEALLOCATE MemberCursor

	PRINT 'Updating Member Partition DB: ' + @DBName + ' completed at :' + CONVERT(VARCHAR, GETDATE(), 114)

	FETCH NEXT FROM OBJECT_CURSOR
	INTO @ServerName, @DBName, @PartitionID
END

CLOSE OBJECT_CURSOR
DEALLOCATE OBJECT_CURSOR


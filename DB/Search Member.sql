/*
	Purpose: Search for a given Member across all DBs
	DATA-259


*/
-- 'dlw@mac.com'
-- beaconhill -- screen name
-- David Wagnor

DECLARE @SearchType VARCHAR(100) = 'INT'

IF OBJECT_ID('tempdb..#Members') IS NOT NULL
	DROP TABLE #Members
CREATE TABLE #Members
(
	MemberID INT NOT NULL 
)
INSERT INTO #Members SELECT MemberID = 152282410
INSERT INTO #Members SELECT MemberID = 152282746
INSERT INTO #Members SELECT MemberID = 146262911
INSERT INTO #Members SELECT MemberID = 152282761
INSERT INTO #Members SELECT MemberID = 146262917
INSERT INTO #Members SELECT MemberID = 145468944
INSERT INTO #Members SELECT MemberID = 152282845
INSERT INTO #Members SELECT MemberID = 152282506
INSERT INTO #Members SELECT MemberID = 146262968
INSERT INTO #Members SELECT MemberID = 146263085
INSERT INTO #Members SELECT MemberID = 152282623
INSERT INTO #Members SELECT MemberID = 152282686
INSERT INTO #Members SELECT MemberID = 152282704
INSERT INTO #Members SELECT MemberID = 152282707
INSERT INTO #Members SELECT MemberID = 146262539
INSERT INTO #Members SELECT MemberID = 152282953
INSERT INTO #Members SELECT MemberID = 145469202
INSERT INTO #Members SELECT MemberID = 146262581
INSERT INTO #Members SELECT MemberID = 146262626
INSERT INTO #Members SELECT MemberID = 146262635
INSERT INTO #Members SELECT MemberID = 152282392
INSERT INTO #Members SELECT MemberID = 145468926
INSERT INTO #Members SELECT MemberID = 145468932
INSERT INTO #Members SELECT MemberID = 146262662
INSERT INTO #Members SELECT MemberID = 145468965
INSERT INTO #Members SELECT MemberID = 146263040
INSERT INTO #Members SELECT MemberID = 146262749
INSERT INTO #Members SELECT MemberID = 146262764
INSERT INTO #Members SELECT MemberID = 145469088
INSERT INTO #Members SELECT MemberID = 145469325
INSERT INTO #Members SELECT MemberID = 145469118
INSERT INTO #Members SELECT MemberID = 146262620
INSERT INTO #Members SELECT MemberID = 145469226
INSERT INTO #Members SELECT MemberID = 146263028
INSERT INTO #Members SELECT MemberID = 145468995
INSERT INTO #Members SELECT MemberID = 146262980
INSERT INTO #Members SELECT MemberID = 152282455
INSERT INTO #Members SELECT MemberID = 145469028
INSERT INTO #Members SELECT MemberID = 152282551
INSERT INTO #Members SELECT MemberID = 145469067
INSERT INTO #Members SELECT MemberID = 145469343
INSERT INTO #Members SELECT MemberID = 146262800
INSERT INTO #Members SELECT MemberID = 146262818
INSERT INTO #Members SELECT MemberID = 145469145
INSERT INTO #Members SELECT MemberID = 145469148
INSERT INTO #Members SELECT MemberID = 145469157
INSERT INTO #Members SELECT MemberID = 145469178
INSERT INTO #Members SELECT MemberID = 152282710
INSERT INTO #Members SELECT MemberID = 152282662
INSERT INTO #Members SELECT MemberID = 145469022
INSERT INTO #Members SELECT MemberID = 145468881
INSERT INTO #Members SELECT MemberID = 145468887
INSERT INTO #Members SELECT MemberID = 146262542
INSERT INTO #Members SELECT MemberID = 145469292
INSERT INTO #Members SELECT MemberID = 145468896
INSERT INTO #Members SELECT MemberID = 152282440
INSERT INTO #Members SELECT MemberID = 146263025
INSERT INTO #Members SELECT MemberID = 152282851
INSERT INTO #Members SELECT MemberID = 152282857
INSERT INTO #Members SELECT MemberID = 146262731
INSERT INTO #Members SELECT MemberID = 145469091
INSERT INTO #Members SELECT MemberID = 146262779
INSERT INTO #Members SELECT MemberID = 146262857
INSERT INTO #Members SELECT MemberID = 152282491
INSERT INTO #Members SELECT MemberID = 152282926
INSERT INTO #Members SELECT MemberID = 152282737
INSERT INTO #Members SELECT MemberID = 152282878
INSERT INTO #Members SELECT MemberID = 152282632
INSERT INTO #Members SELECT MemberID = 145468866
INSERT INTO #Members SELECT MemberID = 146262926
INSERT INTO #Members SELECT MemberID = 146262956
INSERT INTO #Members SELECT MemberID = 146263088
INSERT INTO #Members SELECT MemberID = 152282665
INSERT INTO #Members SELECT MemberID = 152282950

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

IF OBJECT_ID('tempdb..#AttributeGroup') IS NOT NULL
	DROP TABLE #AttributeGroup
SELECT	A.AttributeID, A.AttributeName, AG.AttributeGroupID, A.ScopeID, CommunityID = GroupID
INTO	#AttributeGroup
FROM	mnSystem..Attribute  A
JOIN	mnSystem..AttributeGroup AG ON AG.AttributeID = A.AttributeID
WHERE	AttributeName LIKE '%RegistrationScenarioID%'
AND		A.ScopeID = 10

IF OBJECT_ID('tempdb..#MemberSearch') IS NOT NULL
	DROP TABLE #MemberSearch
CREATE TABLE #MemberSearch
(
	 MemberID				INT NOT NULL
	,rowid					INT
	,Value					NVARCHAR(500)
)

-- SELECT * FROM #MemberDBs

DECLARE @AttributeValue	 VARCHAR(100) = '1042'
DECLARE @AttributeValueINt	 INT = 1042
DECLARE  @ServerName	VARCHAR(100)
		,@DBName		VARCHAR(100)

DECLARE @SqlCmd VARCHAR(MAX)

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

	-- TEXT VALUE
	IF @SearchType = 'TEXT'
	BEGIN
		SET @SqlCmd = ''
		SET @SqlCmd = @SqlCmd	+	'INSERT INTO '	+	CHAR(13)
		SET @SqlCmd = @SqlCmd	+	'		#MemberSearch'	+	CHAR(13)
		SET @SqlCmd = @SqlCmd	+	'SELECT	MAT.MemberID, MAT.rowid, MAT.Value'	+	CHAR(13)
		SET @SqlCmd = @SqlCmd	+	'FROM	' + @ServerName + '.' + @DBName + '.dbo.MemberAttributeText	MAT	WITH (READUNCOMMITTED)'	+	CHAR(13)
		SET @SqlCmd = @SqlCmd	+	'WHERE	MAT.Value IS NOT NULL'	+	CHAR(13)
		SET @SqlCmd = @SqlCmd	+	'AND	Value = ''' + @AttributeValue + ''''
		SET @SqlCmd = @SqlCmd	+	'AND	EXISTS (SELECT 1 FROM #AttributeGroup AG	WITH (READUNCOMMITTED)	WHERE AG.AttributeGroupID = MAT.AttributeGroupID )'	+	CHAR(13)
	END
	ELSE IF @SearchType = 'INT'
	BEGIN
		SET @SqlCmd = ''
		SET @SqlCmd = @SqlCmd	+	'INSERT INTO '	+	CHAR(13)
		SET @SqlCmd = @SqlCmd	+	'		#MemberSearch'	+	CHAR(13)
		SET @SqlCmd = @SqlCmd	+	'SELECT	MAT.MemberID, MAT.rowid, MAT.Value'	+	CHAR(13)
		SET @SqlCmd = @SqlCmd	+	'FROM	' + @ServerName + '.' + @DBName + '.dbo.MemberAttributeInt	MAT	WITH (READUNCOMMITTED)'	+	CHAR(13)
		SET @SqlCmd = @SqlCmd	+	'WHERE	MAT.Value IS NOT NULL'	+	CHAR(13)
		--SET @SqlCmd = @SqlCmd	+	'AND	Value = ' + CONVERT(VARCHAR, @AttributeValueINt)
		SET @SqlCmd = @SqlCmd	+	'AND	EXISTS (SELECT 1 FROM #AttributeGroup AG	WITH (READUNCOMMITTED)	WHERE AG.AttributeGroupID = MAT.AttributeGroupID )'	+	CHAR(13)
		SET @SqlCmd = @SqlCmd	+	'AND	EXISTS (SELECT 1 FROM #Members	M1 WITH (READUNCOMMITTED)	WHERE M1.MemberId = MAT.MemberId )'	+	CHAR(13)
	END

	PRINT  @SqlCmd
	EXEC  (@SqlCmd)
    
	FETCH NEXT FROM OBJECT_CURSOR
	INTO @ServerName, @DBName
END

CLOSE OBJECT_CURSOR
DEALLOCATE OBJECT_CURSOR


SELECT  MemberID
		,rowid
		,Value
		,(MemberID % 24) + 1
FROM	#MemberSearch

SELECT  MemberID
		,rowid
		,Value
		,(MemberID % 24) + 1
FROM	#MemberSearch
WHERE	Value = 1042

SELECT * FROM mnMember8.dbo.MemberAttributeText WHERE MemberID = 113333695 AND AttributeGroupID = 530
SELECT * FROM mnMember9.dbo.MemberAttributeText WHERE MemberID = 124457432 AND AttributeGroupID = 530
SELECT * FROM LASQL08.mnMember23.dbo.MemberAttributeText WHERE MemberID = 136859398 AND AttributeGroupID = 530


-- SEARCH  in Logon
SELECT	TOP 10 * FROM	mnLogon.dbo.logonmembercommunity WHERE EmailAddress = 'dlw@mac.com'
SELECT	TOP 10 * FROM	mnLogon.dbo.EmailMemberHistory WITH (READUNCOMMITTED) WHERE Email = 'dlw@mac.com'

-- SEARCH IN Admin tool search backend (Which is prod flat 2)
SELECT * FROM dbo.vw_memberflat_community_pivot_Communityid WHERE EmailAddress = 'dlw@mac.com'


--SELECT * FROM dbo.vw_memberflat_community_pivot_Communityid WHERE SiteFirstName = 'David' AND SiteLastName = 'Wagner'

SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_1	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_2	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_3	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_8	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_9	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_10	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_12	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_17	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_20	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_21	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_22	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_23	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_24	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_25	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_27	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_28	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_29	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_30	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_31	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_32	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_33	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_34	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_35	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_36	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_37	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_38	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_39	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_40	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_41	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_42	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_43	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_44	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_45	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_46	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_47	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_48	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_49	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_50	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_51	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_52	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_53	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_54	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_55	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_56	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
SELECT communityID, memberid, siteid, SiteFirstName, SiteLastName, BrandInsertDate, BrandLastLogonDate FROM dbo.memberflat_community_57	WITH (READUNCOMMITTED) WHERE SiteFirstName= 'David' AND SiteLastName = 'Wagner'
DECLARE @MemberID		INT	=	106624536
DECLARE @TargetMemberID	INT	=	108597144
DECLARE	@PartitiionID	INT

DECLARE @CommunityID INT = 3
DECLARE @AffinityID INT
DECLARE @PartitionCount INT
DECLARE @Owner VARCHAR(20)
DECLARE @ParamDefinition NVARCHAR(500)
DECLARE	@SQLCmd	NVARCHAR(MAX)
DECLARE	@TableName	VARCHAR(100)
DECLARE @TargetTableName	VARCHAR(100)

SELECT	@PartitiionID	=	(@MemberID % 24) + 1

DECLARE  @ServerName	VARCHAR(100)
		,@DBName		VARCHAR(100)


SELECT	@ServerName	=	ServerName
		,@DBName	=	PhysicalDatabaseName
FROM	mnSystem.dbo.PhysicalDatabase WHERE PhysicalDatabaseName LIKE 'mnList' + CONVERT(VARCHAR, @PartitiionID) 
AND		CONVERT(INT, REPLACE(ServerName, 'LASQL', '')) % 2 = 0


SET @Owner = 'YNMDomainID' + CAST(@CommunityID AS VARCHAR(2))
SELECT  @PartitionCount = PropertyValue
FROM    mnSystem.dbo.Property WITH ( NOLOCK )
WHERE   Owner = @Owner
AND     PropertyName = 'AffinityID'

-- FIRST FIND Affinity ID
SELECT	@AffinityID = @MemberID % @PartitionCount
SET		@TableName	=	'D' + CONVERT(VARCHAR, @CommunityID) + 'YNMList' + CONVERT(VARCHAR, @AffinityID)

SET @SQLCmd	=	''
SET @SQLCmd	=	@SQLCmd + N'SELECT  MemberID ,' + CHAR(13)
SET @SQLCmd	=	@SQLCmd + N'        TargetMemberID ,' + CHAR(13)
SET @SQLCmd	=	@SQLCmd + N'        PrivateLabelID ,' + CHAR(13)
SET @SQLCmd	=	@SQLCmd + N'        CAST(DirectionFlag AS INT) AS DirectionFlag ,' + CHAR(13)
SET @SQLCmd	=	@SQLCmd + N'        CAST(YNMTypeID AS INT) AS YNMTypeID ,' + CHAR(13)
SET @SQLCmd	=	@SQLCmd + N'        UpdateDate AS DateTime ,' + CHAR(13)
SET @SQLCmd	=	@SQLCmd + N'        ListTypeID' + CHAR(13)
SET @SQLCmd	=	@SQLCmd + N'FROM    ' + @ServerName + '.' + @DBName + '.dbo.' + @TableName + ' WITH ( NOLOCK )'  + CHAR(13)
SET @SQLCmd	=	@SQLCmd + N'WHERE   MemberID = ' + CONVERT(NVARCHAR, @MemberID) + CHAR(13)

IF @TargetMemberID IS NOT NULL
	SET @SQLCmd	=	@SQLCmd + N'AND    TargetMemberID = ' + CONVERT(NVARCHAR, @TargetMemberID) + CHAR(13)

SET @SQLCmd	=	@SQLCmd + N'AND    DirectionFlag = 1' + CHAR(13)
SET @SQLCmd	=	@SQLCmd + N'AND    ListTypeID = 1' + CHAR(13)

PRINT @SQLCmd
EXEC(@SQLCmd)

IF @TargetMemberID IS NOT NULL
BEGIN
	SELECT  @AffinityID = @TargetMemberID % @PartitionCount
	SET		@TargetTableName	=	'D' + CONVERT(VARCHAR, @CommunityID) + 'YNMList' + CONVERT(VARCHAR, @AffinityID)

	SET @SQLCmd = REPLACE(REPLACE(REPLACE(REPLACE(@SQLCmd, CONVERT(VARCHAR, @MemberID), '-99999'), CONVERT(VARCHAR, @TargetMemberID), CONVERT(VARCHAR, @MemberID)), '-99999', CONVERT(VARCHAR, @TargetMemberID)), @TableName, @TargetTableName)

	PRINT @SQLCmd
	EXEC(@SQLCmd)
END

SELECT	 MemberID = @MemberID, TargetMemberID = @TargetMemberID, PartitiionID = @PartitiionID, ServerName = @ServerName, DBName = @DBName
		,CommunityID = @CommunityID, PartitionCount = @PartitionCount, TableName = @TableName
		,@TargetTableName, TargetAFfinity = @AffinityID

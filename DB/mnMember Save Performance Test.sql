IF OBJECT_ID('tempdb..#MAD') IS NOT NULL
	DROP TABLE #MAD
SELECT TOP 100 MemberID, Value, MAD.AttributeGroupID
INTO #MAD
FROM dbo.MemberAttributeDate MAD

IF OBJECT_ID('tempdb..#MAI') IS NOT NULL
	DROP TABLE #MAI
SELECT TOP 100 MemberID, Value, MAI.AttributeGroupID
INTO #MAI
FROM dbo.MemberAttributeInt MAI 
WHERE EXISTS (SELECT * FROM #MAD M WHERE M.MemberID = MAI.MemberID)


IF OBJECT_ID('tempdb..#MAT') IS NOT NULL
	DROP TABLE #MAT
SELECT TOP 100 MemberID, Value, MAT.AttributeGroupID, MAT.LanguageID, MAT.StatusMask
INTO #MAT
FROM dbo.MemberAttributeText MAT
WHERE EXISTS (SELECT * FROM #MAI M WHERE M.MemberID = MAT.MemberID)

DECLARE @MemberID int
DECLARE @Attribute1AttributeGroupID int
DECLARE @Attribute1DataType varchar(50)
DECLARE @Attribute1ValueInt int

DECLARE @Attribute2AttributeGroupID int
DECLARE @Attribute2DataType varchar(50)
DECLARE @Attribute2ValueDate DATETIME

DECLARE @Attribute3AttributeGroupID int
DECLARE @Attribute3DataType varchar(50)
DECLARE @Attribute3ValueText NVARCHAR(max)
DECLARE @Attribute3LanguageID int
DECLARE @Attribute3StatusMask int

DECLARE @InsertDate datetime

DECLARE OBJECT_CURSOR CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

SELECT  MemberID
       ,Value
       ,AttributeGroupID
FROM	#MAI

OPEN OBJECT_CURSOR

FETCH NEXT FROM OBJECT_CURSOR
INTO @MemberID, @Attribute1ValueInt, @Attribute1AttributeGroupID

WHILE (@@FETCH_STATUS = 0)
BEGIN

	SELECT   @Attribute2DataType = 'DATE'
			,@Attribute2ValueDate = Value
			,@Attribute2AttributeGroupID =  AttributeGroupID
	FROM	 #MAD
	WHERE	MemberID = @MemberID


	SELECT	 @Attribute3DataType = 'TEXT'
			,@Attribute3ValueText = Value
			,@Attribute3AttributeGroupID = AttributeGroupID
			,@Attribute3LanguageID = LanguageID
			,@Attribute3StatusMask = StatusMask 
	FROM	#MAT
	WHERE	MemberID = @MemberID

	EXEC dbo.up_MemberAttribute_Save_Multiple
		 @MemberID						= @MemberId
		,@Attribute1AttributeGroupID	= @Attribute1AttributeGroupID
		,@Attribute1DataType			= 'NUMBER'
		,@Attribute1ValueInt			= @Attribute1ValueInt

		,@Attribute2AttributeGroupID	= @Attribute2AttributeGroupID
		,@Attribute2DataType			= @Attribute2DataType
		,@Attribute2ValueDate			= @Attribute2ValueDate

		,@Attribute3AttributeGroupID	= @Attribute3AttributeGroupID
		,@Attribute3DataType			= @Attribute3DataType
		,@Attribute3LanguageID			= @Attribute3LanguageID
		,@Attribute3ValueText			= @Attribute3ValueText
		,@Attribute3StatusMask			= @Attribute3StatusMask
		
		,@InsertDate = '2015-10-26 18:51:42' -- datetime
	    
		PRINT '--------------------'
		PRINT 'Member :' + CONVERT(VARCHAR, @MemberId)
		PRINT '@Attribute1AttributeGroupID	:' + CONVERT(VARCHAR, @Attribute1AttributeGroupID)
		PRINT '@Attribute1DataType			:' + CONVERT(VARCHAR, 'NUMBER')
		PRINT '@Attribute1ValueInt			:' + CONVERT(VARCHAR, @Attribute1ValueInt)

		PRINT '@Attribute2AttributeGroupID	:' + CONVERT(VARCHAR, @Attribute2AttributeGroupID)
		PRINT '@Attribute2DataType			:' + CONVERT(VARCHAR, @Attribute2DataType)
		PRINT '@Attribute2ValueDate			:' + CONVERT(VARCHAR, @Attribute2ValueDate)

		PRINT '@Attribute3AttributeGroupID	:' + CONVERT(VARCHAR, @Attribute3AttributeGroupID)
		PRINT '@Attribute3DataType			:' + CONVERT(VARCHAR, @Attribute3DataType)
		PRINT '@Attribute3LanguageID		:' + CONVERT(VARCHAR, @Attribute3LanguageID)
		PRINT '@Attribute3ValueText			:' + @Attribute3ValueText
		PRINT '@Attribute3StatusMask		:' + CONVERT(VARCHAR, @Attribute3StatusMask)
		
		PRINT '@InsertDate = ' + '2015-10-26 18:51:42' 

		PRINT '--------------------'


	FETCH NEXT FROM OBJECT_CURSOR
	INTO @MemberID, @Attribute1ValueInt, @Attribute1AttributeGroupID
END

CLOSE OBJECT_CURSOR
DEALLOCATE OBJECT_CURSOR

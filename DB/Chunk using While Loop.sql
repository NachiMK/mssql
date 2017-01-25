-- WHILE LOOK USING SINGLE PK
DECLARE @WL_StartKey	INT	= 1
DECLARE @WL_MaxKey		INT
DECLARE @WL_BatchSize	INT = 100000

SET @WL_MaxKey = (SELECT COUNT(*) FROM RW5.dbo.Answer WITH (READUNCOMMITTED))

WHILE (@WL_StartKey <= @WL_MaxKey)
BEGIN
	
	--SELECT TOP (@WL_BatchSize) * FROM RW5.dbo.Answer AS A WITH (READUNCOMMITTED)
	-- NEED TO USE OFFSET/NEXT
	
	SET @WL_StartKey = @WL_StartKey + @WL_BatchSize
END

GO


-- WHILE  LOOP USING RANGE
DECLARE @WL_StartKey	INT	= 1
DECLARE @WL_EndKey		INT
DECLARE @WL_MaxKey		INT
DECLARE @WL_BatchSize	INT = 100000

SET @WL_MaxKey = (SELECT COUNT(*) FROM RW5.dbo.Answer WITH (READUNCOMMITTED))

WHILE (@WL_StartKey <= @WL_MaxKey)
BEGIN
	
	--SELECT TOP (@WL_BatchSize) * FROM RW5.dbo.Answer AS A WITH (READUNCOMMITTED) WHERE A BETWEEN @WL_StartKey AND @WL_EndKey
	
	SET	@WL_StartKey	= @WL_StartKey + @WL_EndKey
	SET @WL_EndKey		= @WL_EndKey + @WL_BatchSize
END

GO

	IF OBJECT_ID('tempdb..#Outer') IS NOT NULL
		DROP TABLE #Outer
	CREATE TABLE #Outer
	(
		ID INT NOT NULL
	)

	IF OBJECT_ID('tempdb..#T') IS NOT NULL
		DROP TABLE #T
	CREATE TABLE #T
	(
		ID INT NOT NULL IDENTITY(1, 1) PRIMARY KEY CLUSTERED
	)

	DECLARE	@MaxID				INT
			,@StartRange		INT = 1
			,@EndRange			INT
			,@Batch				INT	= 1000

	SELECT @MaxID = MAX(ID) FROM #Outer
	
	SET @EndRange = @Batch
	IF @MaxID < @Batch
		SET @EndRange = @MaxID

	WHILE (@StartRange <= @MaxID)
	BEGIN

		PRINT 'Processing Rows between Range:' + CONVERT(VARCHAR, @StartRange) + ' and end Range:' + CONVERT(VARCHAR, @EndRange) + ' remaining rows:' + CONVERT(VARCHAR, (@MaxID - @EndRange))

		SELECT	1
		FROM	#Outer O
		WHERE	EXISTS (
							SELECT	* 
							FROM	#T T
							WHERE	T.ID		= O.ID
							AND		T.ID BETWEEN @StartRange AND @EndRange
						)

		SET	@StartRange	= @EndRange + 1
		SET @EndRange	= @EndRange + @Batch

		IF @EndRange > @MaxID
			SET @EndRange = @MaxID
	END

/*
	Date Issue
*/

-- DROP ASSEMBLY HelloWorld
--CREATE ASSEMBLY [ASM.Framework.Transformation]
--FROM 'C:\A3 Database Resources\ASM.Framework.Transformation.dll'
--WITH PERMISSION_SET = SAFE;

-- DROP FUNCTION DS.ConvertNumericToDate
--CREATE FUNCTION DS.ConvertNumericToDate
--(
--	 @DateString NVARCHAR(200)
--	,@DefaultValue DATETIME
--)
--RETURNS DATETIME
--EXTERNAL NAME [ASM.Framework.Transformation].[ASM.Framework.Transformation.TransformationMgr].ConvertStringToDate

DECLARE @StartDtId INT	= 1
DECLARE @EndDtId INT	= 2958465
DECLARE @EndHoursID	INT = 99

IF OBJECT_ID('tempdb..#IntDate') IS NOT NULL 
	DROP TABLE #IntDate
;WITH 
   L0 AS (SELECT 1 AS C UNION ALL SELECT 1)       --2 rows
  ,L1 AS (SELECT 1 AS C FROM L0 AS A, L0 AS B)    --4 rows (2x2)
  ,L2 AS (SELECT 1 AS C FROM L1 AS A, L1 AS B)    --16 rows (4x4)
  ,L3 AS (SELECT 1 AS C FROM L2 AS A, L2 AS B)    --256 rows (16x16)
  ,L4 AS (SELECT 1 AS C FROM L3 AS A, L3 AS B)    --65536 rows (256x256)
  ,L5 AS (SELECT 1 AS C FROM L4 AS A, L4 AS B)    --4,294,967,296 rows (65536x65536)
  ,Nums AS (SELECT row_number() OVER (ORDER BY (SELECT 0)) AS N FROM L5)  
SELECT
	iDate = N
INTO
	#IntDate
FROM	Nums
WHERE	N <= @EndDtId


IF OBJECT_ID('tempdb..#HoursFraction') IS NOT NULL 
	DROP TABLE #HoursFraction
;WITH 
   L0 AS (SELECT 1 AS C UNION ALL SELECT 1)       --2 rows
  ,L1 AS (SELECT 1 AS C FROM L0 AS A, L0 AS B)    --4 rows (2x2)
  ,L2 AS (SELECT 1 AS C FROM L1 AS A, L1 AS B)    --16 rows (4x4)
  ,L3 AS (SELECT 1 AS C FROM L2 AS A, L2 AS B)    --256 rows (16x16)
--  ,L4 AS (SELECT 1 AS C FROM L3 AS A, L3 AS B)    --65536 rows (256x256)
--  ,L5 AS (SELECT 1 AS C FROM L4 AS A, L4 AS B)    --4,294,967,296 rows (65536x65536)
  ,Nums AS (SELECT row_number() OVER (ORDER BY (SELECT 0)) AS N FROM L3)  
SELECT
	iFractionHours = N
INTO
	#HoursFraction
FROM	Nums
WHERE	N <= @EndHoursID

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DblDate')
BEGIN
	CREATE TABLE DS.DblDate
	(
		 dblDate VARCHAR(30)
		,iDate INT
		,iFractionHours INT
		,pkID INT IDENTITY(1, 1)
	)
	CREATE NONCLUSTERED INDEX [Tmp_DblDate] ON DS.DblDate(iDate, iFractionHours)
END
ELSE
	TRUNCATE TABLE DS.DblDate

INSERT INTO	DS.DblDate
SELECT CONVERT(VARCHAR, iDate) + '.' + CONVERT(VARCHAR, iFractionHours) AS dblDate, iDate, iFractionHours
FROM		#IntDate AS ID
CROSS JOIN	#HoursFraction AS HF
ORDER BY iDate, iFractionHours

SELECT COUNT(*) FROM DS.DblDate AS DD

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DateValidation1')
BEGIN
	-- DROP TABLE DS.DateValidation1
	CREATE TABLE DS.DateValidation1
	(
		 DateString		VARCHAR(30)
		,DateInt		INT
		,DateFraction	INT
		,pkID			INT
		,SqlDate		DATETIME
		,CSharpDate		DATETIME
	)
	CREATE NONCLUSTERED INDEX [Tmp_DtValld] ON DS.DateValidation1(pkID)
END
ELSE
BEGIN
	TRUNCATE TABLE DS.DateValidation1
END

-- PROCSES IN BATCHES
DECLARE @MaxRows INT
SELECT @MaxRows = COUNT(*) FROM DS.DblDate

DECLARE @StartId INT
DECLARE @EndId INT
DECLARE @BatchSize INT = 50000

SET @StartId = 1
SET @EndId = @BatchSize

WHILE (@EndId <= @MaxRows)
BEGIN
	PRINT '-------------------------------------------------------------------------'
	PRINT 'Starting Id:' + CONVERT(VARCHAR, @StartId) + 'End Id:' + CONVERT(VARCHAR, @EndId)

	INSERT INTO DS.DateValidation1(
			 DateString
			,DateInt
			,DateFraction
			,pkID)
	SELECT	 DateString = dblDate
			,DateInt = iDate
			,DateFraction = iFractionHours
			,pkID
	FROM	DS.DblDate AS DD
	WHERE	DD.pkId BETWEEN @StartId  AND @EndId

	BEGIN TRY		

		UPDATE	DS.DateValidation1
		SET		SqlDate = DS.ConvertToDateTime(DateString, NULL)
		FROM	DS.DateValidation1
		WHERE	pkId BETWEEN @StartId  AND @EndId
		
	END TRY
	BEGIN CATCH
		PRINT 'Error Finding SQL Date :' + 'Starting Id:' + CONVERT(VARCHAR, @StartId) + 'End Id:' + CONVERT(VARCHAR, @EndId)
		PRINT ERROR_NUMBER()
		PRINT ERROR_MESSAGE()
		PRINT ERROR_LINE()
	END CATCH

	BEGIN TRY		

		UPDATE	DS.DateValidation1
		SET		CSharpDate = DS.ConvertNumericToDate(DateString, NULL)
		FROM	DS.DateValidation1
		WHERE	pkId BETWEEN @StartId  AND @EndId
		
	END TRY
	BEGIN CATCH
		PRINT 'Error Finding C# Date :' + 'Starting Id:' + CONVERT(VARCHAR, @StartId) + 'End Id:' + CONVERT(VARCHAR, @EndId)
		PRINT ERROR_NUMBER()
		PRINT ERROR_MESSAGE()
		PRINT ERROR_LINE()
	END CATCH
	
	PRINT '-------------------------------------------------------------------------'
	
	SET @StartId = @EndId + 1
	SET @EndId = @EndId + @BatchSize
END


/*
SELECT DS.ConvertToDateTime('2.99999', NULL), DS.ConvertNumericToDate('2.99999', NULL)
,DS.ConvertToDateTime('2.99999', NULL), DS.ConvertNumericToDate('2.99999998', NULL)

SELECT 292888035/50000, 58750000/50000 -- Processed TIll 58750000
*/
USE MarsDrinks
GO
/*
	Program Overview
*/

DECLARE @DistributorList	VARCHAR(1000)
DECLARE @MarketList			VARCHAR(1000)

SET @DistributorList	= '-7683113954589538551,-5616406884406218638,6727040305548859214,6206664083362027440,3320305798522949317,1139177255650629103'
SET @MarketList			= '-154,2229'

DECLARE @StartProgramWeek	INT
DECLARE @EndProgramWeek		INT

DECLARE @sql AS NVARCHAR(4000);

DECLARE @KeyMetricText TABLE(
	 KeyMetricText	VARCHAR(100)	NOT NULL
	,DisplayText	VARCHAR(100)	NOT NULL
	,SortOrder		INT				NOT NULL)

--IF OBJECT_ID('tempdb..#Weeks') IS NOT NULL 
--	DROP TABLE #Weeks
--CREATE TABLE #Weeks
DECLARE @Weeks TABLE(
	ProgWeekNumber	INT			NOT NULL
,	ProgWeekName	VARCHAR(20)	NOT NULL
,	DateValue_SK	INT			NOT NULL
,	WeekRangeName	VARCHAR(20)	NOT NULL)

--IF OBJECT_ID('tempdb..#Markets') IS NOT NULL 
--	DROP TABLE #Markets
--CREATE TABLE #Markets
DECLARE @Markets TABLE(
	 Market			VARCHAR(80)		NOT NULL
	,Distributor	VARCHAR(100)	NOT NULL)

IF OBJECT_ID('tempdb..#KeyMetricByWeekAndMarket') IS NOT NULL 
	DROP TABLE #KeyMetricByWeekAndMarket
CREATE TABLE #KeyMetricByWeekAndMarket(
	 Market			VARCHAR(80)		NOT NULL
	,Distributor	VARCHAR(100)	NOT NULL
	,KeyMetricText	VARCHAR(100)	NOT NULL
	,ProgWeekNumber	INT				NOT NULL
	,ProgWeekName	VARCHAR(40)		NOT NULL
	,DateValue_SK	INT				NOT NULL)
CREATE NONCLUSTERED INDEX [TIX_DV_KeyMetricByWeek] ON #KeyMetricByWeekAndMarket(KeyMetricText,DateValue_SK) INCLUDE(ProgWeekNumber, ProgWeekName)

IF OBJECT_ID('tempdb..#Overview') IS NOT NULL 
	DROP TABLE #Overview
CREATE TABLE #Overview(
	 Market			VARCHAR(80)		NOT NULL
	,Distributor	VARCHAR(100)	NOT NULL
	,ProgWeekName	VARCHAR(40)		NOT NULL
	,Metric			VARCHAR(100)	NOT NULL
	,NoOfFacts		INT				NOT NULL
	,SortOrder		INT				NOT NULL)
CREATE NONCLUSTERED INDEX [TIX_Overview_ProgWeekNumber] ON #Overview(ProgWeekName) INCLUDE(NoOfFacts, Metric)

-- PARAMETERS
IF @StartProgramWeek IS NULL
	SELECT @StartProgramWeek = MIN(Prog_Week) FROM DM.DateValue DV WITH (READUNCOMMITTED) WHERE Prog_Week > 0

-- FIND THE LAST WEEK WE HAVE FOR GIVEN PROGRAM
IF @EndProgramWeek IS NULL
BEGIN
	SELECT @EndProgramWeek = MAX(Prog_Week) FROM DM.DateValue DV WITH (READUNCOMMITTED)
	WHERE DateValue_SK = (SELECT MAX(Assignment_DateValue_SK) FROM DM.Assignment AS A)
END

SELECT	 @StartProgramWeek StartProgramWeek
		,@EndProgramWeek EndProgramWeek

-- GET ALL WEEKS WE WANTED TO DISPLAY
INSERT INTO @Weeks(
		 ProgWeekNumber
		,ProgWeekName
		,DateValue_SK
		,WeekRangeName)
SELECT	 DV.Prog_Week			ProgWeekNumber
		,DV.Prog_WeekName		ProgWeekName
		,DV.DateValue_SK		DateValue_SK
		,REPLACE(WeekRangeName_StartMon, '/' + CAST(DV.[Year] AS VARCHAR(4)), '')	WeekRangeName
FROM	DM.DateValue AS DV WITH (READUNCOMMITTED)
WHERE	DV.Prog_Week BETWEEN @StartProgramWeek AND @EndProgramWeek

-- KEY METRICS WE WANTED TO SHOW IN REPORT
INSERT INTO @KeyMetricText
SELECT	 'Assignment Completed'		KeyMetricText
		,'Assignments Completed'	DisplayText
		,1							SortOrder
UNION
SELECT 'Brewer Serviced'			KeyMetricText
		,'Brewers Serviced'			DisplayText
		,2							SortOrder
UNION
SELECT 'Merchandiser Serviced'		KeyMetricText
		,'Merchandisers Serviced'	DisplayText
		,3							SortOrder
UNION
SELECT 'Product Added'				KeyMetricText
		,'Products Added'			DisplayText
		,4							SortOrder
UNION
SELECT  'Sample Left Behind'		KeyMetricText
		,'Samples Left Behind'		DisplayText
		,5							SortOrder

--SELECT * FROM @KeyMetricText K 

-- GET ALL MARKETS AND DISTRIBUTORS
INSERT INTO @Markets(
		 Market
		,Distributor)
SELECT	 DISTINCT 
		 Market
		,Distributor
FROM	DM.Location L	WITH (READUNCOMMITTED)
WHERE	LEN(L.Distributor) > 0
AND		LEN(L.Market) > 0
-- FILTER FOR ONLY GIVEN MARKET
AND		EXISTS (SELECT * FROM Rpt.StringToTable_INT(@MarketList, ',') D WHERE D.Value = L.Market_BK)
-- FILTER FOR ONLY GIVEN DISTRIBUTOR
AND		EXISTS (SELECT * FROM Rpt.StringToTable_BIGINT(@DistributorList, ',') D WHERE D.Value = L.Distributor_BK)

-- GET ALL COMBINATIONS OF MARKETS/DISTRIBUTORS/KEY METRIC/DATE THAT IS AVAILABLE IN SYSTEM
INSERT INTO #KeyMetricByWeekAndMarket(
		 Market
		,Distributor
		,KeyMetricText
		,ProgWeekNumber
		,ProgWeekName
		,DateValue_SK)
SELECT	 Market
		,Distributor    
		,KeyMetricText
		,ProgWeekNumber
		,ProgWeekName
		,DateValue_SK
FROM			@KeyMetricText AS KMT
CROSS	JOIN	@Weeks AS W
CROSS	JOIN	@Markets AS M

-- ADD WEEK RANGE TO WEEK NAME
UPDATE	K
SET		ProgWeekName = ProgWeekName + ' (' + ISNULL((SELECT TOP 1 W.WeekRangeName FROM @Weeks W WHERE W.ProgWeekName = K.ProgWeekName), '') + ')'
FROM	#KeyMetricByWeekAndMarket K

;WITH	RptKeyMetricFact
AS(
	-- GET KEY METRICS
	SELECT	 KMF.Assignment_DateValue_SK
			,KMF.KeyMetricMapping_SK
			,KMF.KeyMetricFact_SK
			,KMM.KeyMetric
			,KMM.KeyMetricID
			,L.Distributor
			,L.Market
	FROM	DM.KeyMetricFact KMF		WITH (READUNCOMMITTED)
	JOIN	DM.KeyMetricMapping KMM		WITH (READUNCOMMITTED)	ON	KMM.KeyMetricMapping_SK		= KMF.KeyMetricMapping_SK
	JOIN	DM.Location L				WITH (READUNCOMMITTED)	ON	L.Location_SK				= KMF.Location_SK
	WHERE	EXISTS (SELECT * FROM @KeyMetricText K WHERE K.KeyMetricText = KMM.KeyMetric)
	AND		KMM.KeyMetric != 'Assignment Completed'

	UNION

	-- GET ASSIGNMENT COMPLETED
	SELECT	 A.Assignment_DateValue_SK	Assignment_DateValue_SK
			,-9999						KeyMetricMapping_SK
			,-1 * A.Assignment_SK		KeyMetricFact_SK
			,'Assignment Completed'		KeyMetric
			,'A0001'					KeyMetricID
			,L.Distributor				Distributor
			,L.Market					Market
	FROM	DM.Assignment AS A	WITH (READUNCOMMITTED)
	JOIN	DM.Location L		WITH (READUNCOMMITTED)	ON	L.Location_SK	= A.Location_SK
	WHERE	A.AssignmentStatus = 'Completed')
-- FIND METRICS BY MARKET/DISTRIBUTOR/WEEK NAME/METRIC
INSERT INTO	#Overview (
			Market
			,Distributor
			,ProgWeekName
			,Metric
			,SortOrder
			,NoOfFacts
)
SELECT		 ISNULL(W.Market, '')			Market
			,ISNULL(W.Distributor, '')		Distributor
			,ISNULL(W.ProgWeekName, -1)		ProgWeekName
			,ISNULL(K.DisplayText,'')		Metric
			,K.SortOrder					SortOrder
			,COUNT(KMF.KeyMetricFact_SK)	NoOfFacts
FROM		#KeyMetricByWeekAndMarket W
INNER JOIN	@KeyMetricText K			ON	K.KeyMetricText				= W.KeyMetricText
LEFT JOIN	RptKeyMetricFact KMF		ON	KMF.Assignment_DateValue_SK	= W.DateValue_SK
										AND	KMF.KeyMetric				= W.KeyMetricText
										AND	KMF.Market					= W.Market
										AND	KMF.Distributor				= W.Distributor
GROUP BY
GROUPING	SETS
(
	(W.Market, W.Distributor, W.ProgWeekName, K.DisplayText, K.SortOrder),
	(W.Market, W.Distributor, K.DisplayText, K.SortOrder)
)

SET		@sql = 'SELECT P.* ' +
				N',(SELECT TOP 1 NoOfFacts FROM #Overview AS O1 WHERE O1.Metric = P.Metric AND O1.ProgWeekName = ''-1'' AND O1.Market = P.Market AND O1.Distributor = P.Distributor)	Total ' + 
				N'FROM	#Overview O ' + 
				N'PIVOT(SUM(NoOfFacts) FOR ProgWeekName IN (' + 
				-- PIVOT METRICS BY WEEK
				STUFF(
				(
				SELECT	N',' + QUOTENAME(ProgWeekName) as [text()]
				FROM	(SELECT DISTINCT ProgWeekName FROM #KeyMetricByWeekAndMarket AS K) AS ProgWeeks
				ORDER BY ProgWeekName
				FOR XML PATH('')
				)
				, 1, 1, '') + N')) AS P ORDER BY Market, Distributor, SortOrder';

PRINT @Sql

EXEC SP_EXECUTESQL @stmt = @sql

--SELECT	
--		*
--		,(SELECT TOP 1 NoOfFacts FROM #Overview AS O1 WHERE O1.Metric = P.Metric AND O1.ProgWeekName = '-1')	Total
--FROM	#Overview O
--PIVOT(SUM(NoOfFacts) FOR ProgWeekName IN ([Week 01], [Week 02], [Week 03], [Week 04], [Week 29])) AS P;

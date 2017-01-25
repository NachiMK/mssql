USE master
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_CleanUpWhoIsActive')
	EXEC ('CREATE PROC dbo.sp_CleanUpWhoIsActive AS SELECT ''stub version, to be replaced''')
GO

/*********************************************************************************************
This Procedure cleans the performance data that was collected
*********************************************************************************************/
ALTER PROC dbo.sp_CleanUpWhoIsActive
(
	@DaysToKeep INT = 10
)
AS
BEGIN
	SET @DaysToKeep = ISNULL(@DaysToKeep, 10)
	
	IF @DaysToKeep > 90
		SET @DaysToKeep = 90
	
	SET @DaysToKeep = -1 * @DaysToKeep
	DECLARE @TodayEOD		DATETIME = DATEADD(ss, -1, DATEADD(dd, 1, CONVERT(VARCHAR, CONVERT(DATE, GETDATE()), 101)))
	DECLARE @LastDateToKeep DATETIME = DATEADD(dd, @DaysToKeep, @TodayEOD)
	
	DELETE	Perf.WhoIsActive
	WHERE	collection_time	<= @LastDateToKeep 
	
END
GO

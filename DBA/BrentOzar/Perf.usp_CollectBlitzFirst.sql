USE mnDBA
GO

IF OBJECT_ID('Perf.usp_CollectBlitzFirst') IS NOT NULL
	DROP PROCEDURE Perf.usp_CollectBlitzFirst
GO

CREATE PROCEDURE Perf.usp_CollectBlitzFirst
AS
BEGIN

	DECLARE @CuttOffDate DATE
	SET @CuttOffDate = DATEADD(dd, -7, GETUTCDATE())

	IF OBJECT_ID('Perf.ServerStats') IS NOT NULL
	BEGIN
		DELETE Perf.ServerStats WHERE CheckDate < @CuttOffDate
	END

	IF OBJECT_ID('Perf.FileStats') IS NOT NULL
	BEGIN
		DELETE Perf.FileStats WHERE CheckDate < @CuttOffDate
	END

	IF OBJECT_ID('Perf.WaitStats') IS NOT NULL
	BEGIN
		DELETE Perf.WaitStats WHERE CheckDate < @CuttOffDate
	END

	IF OBJECT_ID('Perf.PerfmonStats') IS NOT NULL
	BEGIN
		DELETE Perf.PerfmonStats WHERE CheckDate < @CuttOffDate
	END

	EXEC sp_BlitzFirst @OutputDatabaseName = 'mnDBA', @OutputSchemaName = 'Perf', @OutputTableName = 'ServerStats', @OutputTableNameFileStats = 'FileStats', @OutputTableNamePerfmonStats = 'PerfmonStats', @OutputTableNameWaitStats = 'WaitStats'

END
GO

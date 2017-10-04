/*
For each Audit Enabled Database
BEGIN
	GetAuditSize()
	LimitReached = IsAuditLimitReached(90%)
	IF LimitReached
		PauseAudit()
		SaveAuditSummaryData()
		GetTablesToExcludeFromAudit()
		RemaininngPct = GetRemainingPercentageOfTablesToAudit()
		SQLCLR_MoveAuditFiles()
		GenerateAuditScript(TableList)
		ReCreateAudit(Script, Enable)

	IF RemaininngPct > 5%
		AddDatabaseToAudit = False
END

IF AddDatabaseToAudit
	GenerateAuditScript(TableList)
	ReCreateAudit(Script, Enable)

How to find if IsAuditLimitReached()?
  - NoOfFilesCreated = Find how many files we have created so far
  - LatestFileSize = Find the last files size
  - StatusOfAudit = Check the status of audit.
  - If StatusOfAudit == Failed or (LatestFileSize > Size of Audit and (NoOfFilesCreated >= MaxAllowedFiles))
	 -- We have reached the size limit
  - else
     -- We can keep growing

*/
--USE DBATools
--GO
--IF OBJECT_ID('dbo.usp_DataSeed_SQLAuditing_AllDatabases') IS NOT NULL
--	DROP PROCEDURE [dbo].[usp_DataSeed_SQLAuditing_AllDatabases]
--GO
CREATE PROCEDURE [dbo].[usp_DataSeed_SQLAuditing_AllDatabases]
(
	 @ArchivePath				NVARCHAR(MAX)	
	,@NewAuditPath				NVARCHAR(300)	
	,@MaxFileSizeInMB			INT				= NULL
	,@MaxFiles					INT				= NULL
	,@MinNumberOfDBAuditAllowed	TINYINT			= NULL
	,@Debug						BIT				= NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	/*
	DECLARE	@ArchivePath		NVARCHAR(MAX)	=	N'D:\SQL_AUDIT\Archive\'
	DECLARE @NewAuditPath		NVARCHAR(300)	=	N'D:\SQL_AUDIT\TableUsage\'
	DECLARE @MaxFileSizeInMB	INT				= 2
	DECLARE @MaxFiles			INT				= 2
	DECLARE @MinNumberOfDBAuditAllowed	TINYINT	= 3
	DECLARE @Debug				BIT = 1
	*/

	IF @@SERVERNAME = N'DBTest2'
	BEGIN
		SET @ArchivePath		= ISNULL(@ArchivePath, N'D:\SQL_AUDIT\Archive\')
		SET @NewAuditPath		= ISNULL(@NewAuditPath, 'D:\SQL_AUDIT\TableUsage\')
	END

	SET @MaxFileSizeInMB			= ISNULL(@MaxFileSizeInMB, 2)
	SET @MaxFiles					= ISNULL(@MaxFiles, 2)
	SET @MinNumberOfDBAuditAllowed	= ISNULL(@MinNumberOfDBAuditAllowed, 3)
	SET @Debug						= ISNULL(@Debug, 0)


	DECLARE @AuditFileSpaceCutOffPct_10	NUMERIC(10, 2)	= 10.00
	DECLARE @RemainingTableCuttOffPct_5	NUMERIC(10, 2)	= 5.00
	DECLARE @MinimumCutOff_Hours		NUMERIC(10,2)	= 2.0

	DECLARE @ServerAuditPreFix	NVARCHAR(100)	= 'ServerAudit_TableUsuage_'

	DECLARE @NoOfAuditAlmostCompleted INT = 0

	DECLARE @DatabaseName		SYSNAME
	DECLARE	@DBAuditName		NVARCHAR(300)
	DECLARE @ServerAuditName	NVARCHAR(300)
	DECLARE @AuditPath			NVARCHAR(300)
	DECLARE @AuditLimitReached	BIT		= 0
	DECLARE @IsAuditEnabled		INT
	DECLARE @OutputTableList	NVARCHAR(2000) = ''
	DECLARE @AddTableAuditScript NVARCHAR(MAX)
	DECLARE @RemainingTablePct	NUMERIC(22, 2)
	DECLARE @AuditCreatedTime	DATETIME

	DECLARE	@DirectoryPath		NVARCHAR(MAX)
	DECLARE	@SearchPattern		NVARCHAR(MAX)
	DECLARE	@Overwrite			BIT	=	1

	DECLARE @ErrorMessage	NVARCHAR(4000);  
	DECLARE @ErrorProc		NVARCHAR(4000);
	DECLARE @ErrorLine		BIGINT; 
	DECLARE @ErrorSeverity	INT;  
	DECLARE @ErrorState		INT;  


	IF OBJECT_ID('tempdb..#AuditStatusResults') IS NOT NULL
		DROP TABLE #AuditStatusResults
	CREATE TABLE #AuditStatusResults
	(
		 DatabaseName				SYSNAME			NOT NULL
		,DatabaseId					BIGINT			NOT NULL
		,AuditStatus				NVARCHAR(50)
		,AllowedMaxFileSizeInBytes	DECIMAL
		,LatestFileSize				DECIMAL
		,SpaceRemainingInLastFile	DECIMAL
		,NOofFilesAllowed			DECIMAL
		,NoOfLogFilesCreated		DECIMAL
		,MaxFileCountReached		NVARCHAR(5)
		,CanAuditGrow				NVARCHAR(5)
		,DBAuditName				NVARCHAR(300)
		,DBAuditCreateDate			DATETIME
		,DBAuditEnabled				BIT
		,ServerAuditName			SYSNAME
		,ServerAuditEnabled			TINYINT
		,LogFilePath				NVARCHAR(350)
		,LogFile					NVARCHAR(350)
		,LogFileFullPath			NVARCHAR(700)
		,AuditStatusTime			DATETIME2
		,LatestFileFullPath			NVARCHAR(350)
	)

	IF OBJECT_ID('tempdb..#AuditFiles') IS NOT NULL
		DROP TABLE #AuditFiles
	CREATE TABLE #AuditFiles
	(
		 DatabaseName	SYSNAME
		,AuditName		NVARCHAR(300)
		,DirectoryPath	NVARCHAR(400)
		,FilePattern	NVARCHAR(400)
		,FileName		NVARCHAR(400)
	)

	IF OBJECT_ID('tempdb..#CopyFilesResult') IS NOT NULL
		DROP TABLE #CopyFilesResult
	CREATE TABLE #CopyFilesResult
	(
		 KeyName	NVARCHAR(MAX)
		,KeyValue	NVARCHAR(MAX)
	)

	EXEC dbo.usp_GetAuditStatus @Databases = 'ALL', @ResultsOutputTable = '#AuditStatusResults', @Debug = 0

	DECLARE AuditStatus_Cursor CURSOR FAST_FORWARD READ_ONLY LOCAL FOR

	SELECT		DatabaseName
	FROM		#AuditStatusResults
	ORDER By	DatabaseName

	OPEN AuditStatus_Cursor

	FETCH NEXT FROM AuditStatus_Cursor
	INTO @DatabaseName

	WHILE (@@FETCH_STATUS = 0)
	BEGIN

		BEGIN TRY

			SET @AuditLimitReached = 0

			IF @Debug = 1
			BEGIN
				PRINT '------ Processing DB ---------'
				PRINT 'DB:' + @DatabaseName
			END

			SELECT	 @AuditLimitReached =	CASE WHEN (AuditStatus = 'STOPPED') OR
													  ((MaxFileCountReached = 'Yes') AND (((SpaceRemainingInLastFile / AllowedMaxFileSizeInBytes) * 100.00) < @AuditFileSpaceCutOffPct_10))
											THEN 1 ELSE 0 END
					,@DBAuditName		= DBAuditName
					,@AuditCreatedTime	= DBAuditCreateDate
					,@ServerAuditName	= ServerAuditName
					,@AuditPath			= LogFilePath
			FROM	#AuditStatusResults
			WHERE	DatabaseName = @DatabaseName

			IF @Debug = 1
				SELECT	 AuditLimitReached =	@AuditLimitReached
						,CanAuditGrow
						,MaxFileCountReached 
						,LatestFileSize
						,SpaceRemainingInLastFile
						,AllowedMaxFileSizeInBytes
						,PctRemaining = ((SpaceRemainingInLastFile / AllowedMaxFileSizeInBytes) * 100.00)
						,DatabaseName		= @DatabaseName
						,ServerAuditName	= @ServerAuditName
				FROM	#AuditStatusResults
				WHERE	DatabaseName = @DatabaseName

			IF @AuditLimitReached = 1
			BEGIN
				PRINT 'Audit Limit Reached. So Disabling.'
				EXEC dbo.usp_DisableEnableAudit @DatabaseName = @DatabaseName, @DBAuditName = @DBAuditName, @ServerAuditName = @ServerAuditName, @EnableAudit = 0, @Debug = @Debug

				EXEC @IsAuditEnabled = dbo.usp_IsAuditEnabled	 @DatabaseName	= @DatabaseName
																,@DBAuditName	= @DBAuditName
																,@Debug			= @Debug
				PRINT 'Audit Disabled Check results:' + CONVERT(VARCHAR, @IsAuditEnabled)

				IF @IsAuditEnabled = 0
				BEGIN
		
					PRINT 'Saving Audit Files '
					EXEC dbo.usp_SaveAuditSummary	 @DatabaseName	= @DatabaseName
													,@DBAuditName	= @DBAuditName
													,@Debug			= @Debug

					PRINT 'Retrieving tables to be Audited'
					EXEC dbo.usp_GetTablesToBeAudited @DatabaseName		= @DatabaseName
													,@DBAuditName		= @DBAuditName
													,@OutputTableList	= @OutputTableList OUTPUT
													,@RemainingTablePct	= @RemainingTablePct OUTPUT
													,@AddTableAuditScript = @AddTableAuditScript OUTPUT
													,@Debug = @Debug
			
					PRINT 'Retrieving Audit files.'
					EXEC dbo.usp_GetAuditFiles	 @DatabaseName		= @DatabaseName
												,@DBAuditName		= @DBAuditName
												,@ResultsOutputTable= '#AuditFiles'
												,@Debug				= @Debug
					SET @DirectoryPath = (SELECT TOP 1 DirectoryPath FROM #AuditFiles)
					SET @SearchPattern = (SELECT TOP 1 FilePattern FROM #AuditFiles)

					PRINT 'Copying Files from: ' + ISNULL(@DirectoryPath, 'Null DirectoryPath') + ' for pattern:' + ISNULL(@SearchPattern, 'NULL @SearchParttern')
					INSERT INTO
							#CopyFilesResult
					SELECT	*
					FROM	[dbo].[udf_MoveMatchedFiles](@DirectoryPath
														,@SearchPattern
														,@ArchivePath) T
				
					IF @RemainingTablePct > @RemainingTableCuttOffPct_5
					BEGIN

						PRINT 'Creating Audit for: @DatabaseName = ' + @DatabaseName + ' , @DBAuditName = ' + @DBAuditName + ', @TablesToAudit = ' + @OutputTableList
						EXEC dbo.usp_CreateAudit 
							 @DatabaseName			= @DatabaseName
							,@DBAuditName			= @DBAuditName
							,@ServerAuditName		= @ServerAuditName
							,@AuditPath				= @AuditPath
							,@MaxFileSizeInMB		= @MaxFileSizeInMB
							,@MaxFiles				= @MaxFiles
							,@AddTableAuditScript	= @AddTableAuditScript
							,@print_command_only	= 0
							,@Debug					= @Debug

					END
					ELSE
					BEGIN
						SET @NoOfAuditAlmostCompleted = @NoOfAuditAlmostCompleted + 1

						IF @Debug = 1
							SELECT	sComments = '@RemainingTablePct Is less than @RemainingTableCuttOffPct_5'
									, RemainingTablePct = @RemainingTablePct 
									, RemainingTableCuttOffPct_5 = @RemainingTableCuttOffPct_5
									, NoOfAuditAlmostCompletedAfterUpdate = @NoOfAuditAlmostCompleted
					END

					PRINT 'Enabling Audit. After recreating it.'
					EXEC dbo.usp_DisableEnableAudit  @DatabaseName = @DatabaseName
													,@DBAuditName = @DBAuditName
													,@ServerAuditName = @ServerAuditName
													,@EnableAudit = 1
													,@Debug = @Debug
				END -- @AuditEnabled
			END -- @AuditLimitReached
			ELSE
			BEGIN
				IF @Debug = 1
					SELECT TimeSinceAuditCreated = DATEDIFF(hh, @AuditCreatedTime, GETDATE())
						, DatabaseName = @DAtabaseName, MinimumCutOff_Hours = @MinimumCutOff_Hours
						, NoOfAuditAlmostCompletedBeforeUpdate = @NoOfAuditAlmostCompleted

				IF DATEDIFF(hh, @AuditCreatedTime, GETDATE()) > @MinimumCutOff_Hours
					SET @NoOfAuditAlmostCompleted = @NoOfAuditAlmostCompleted + 1

				IF @Debug = 1
					SELECT NoOfAuditAlmostCompletedAfterUpdate = @NoOfAuditAlmostCompleted
			END
	
		END TRY
		BEGIN CATCH

		SELECT   
			 @ErrorMessage	= ERROR_MESSAGE()
			,@ErrorSeverity	= ERROR_SEVERITY()
			,@ErrorState	= ERROR_STATE()
			,@ErrorProc		= ERROR_PROCEDURE()
			,@ErrorLine		= ERROR_LINE()

			IF @Debug = 1
			BEGIN
				RAISERROR (@ErrorMessage, @ErrorSeverity,@ErrorState, @ErrorProc, @ErrorLine); 
			END

		END CATCH

		FETCH NEXT FROM AuditStatus_Cursor
		INTO @DatabaseName
	END

	CLOSE AuditStatus_Cursor
	DEALLOCATE AuditStatus_Cursor

	IF @Debug = 1
		SELECT	 NoOfAuditAlmostCompleted	= @NoOfAuditAlmostCompleted
				,CntOfAudits				= (SELECT COUNT(*) FROM #AuditStatusResults WHERE AuditStatus = 'RUNNING')
				,MinNumberOfDBAuditAllowed	= @MinNumberOfDBAuditAllowed

	IF ((@NoOfAuditAlmostCompleted >= (SELECT COUNT(*) FROM #AuditStatusResults))
		OR ((SELECT COUNT(*) FROM #AuditStatusResults WHERE AuditStatus = 'RUNNING') < @MinNumberOfDBAuditAllowed))
	BEGIN
		SET @DatabaseName = (
			SELECT	TOP 1 DatabaseName
			FROM	dbo.udf_GetDatabasesForAuditing() T
			WHERE   NOT EXISTS (SELECT 1 FROM #AuditStatusResults A WHERE A.DatabaseName = T.DatabaseName)
		)
	
		SET @DBAuditName	 = N'DB_Audit_' + @DatabaseName + N'_TableUsuage'
		SET @AuditPath		 = @NewAuditPath
		SET @ServerAuditName = @ServerAuditPreFix	+ @DatabaseName

		PRINT 'Creating New Audit for: @DatabaseName = ' + @DatabaseName + ' , @DBAuditName = ' + @DBAuditName + ', @TablesToAudit = ' + @OutputTableList
		EXEC dbo.usp_CreateAudit 
			 @DatabaseName			= @DatabaseName
			,@DBAuditName			= @DBAuditName
			,@ServerAuditName		= @ServerAuditName
			,@AuditPath				= @AuditPath
			,@MaxFileSizeInMB		= @MaxFileSizeInMB
			,@MaxFiles				= @MaxFiles
			,@AddTableAuditScript	= N''
			,@print_command_only	= 0
			,@Debug					= @Debug
	END
END
GO
/*
	-- Testing Code
	DECLARE @Debug				BIT				= 1
	DECLARE	@ArchivePath		NVARCHAR(MAX)	= N'D:\SQL_AUDIT\Archive\'
	DECLARE @NewAuditPath		NVARCHAR(300)	= N'D:\SQL_AUDIT\TableUsage\'
	DECLARE @MaxFileSizeInMB	INT				= 2
	DECLARE @MaxFiles			INT				= 2
	DECLARE @MinNumberOfDBAuditAllowed	TINYINT	= 3

	EXEC [dbo].[usp_DataSeed_SQLAuditing_AllDatabases]
		 @ArchivePath				= @ArchivePath
		,@NewAuditPath				= @NewAuditPath
		,@MaxFileSizeInMB			= @MaxFileSizeInMB
		,@MaxFiles					= @MaxFiles
		,@MinNumberOfDBAuditAllowed	= @MinNumberOfDBAuditAllowed
		,@Debug						= @Debug

*/
/*
EXEC dbo.usp_DisableEnableAudit @DatabaseName = 'Assets'	, @DBAuditName = N'DB_Audit_Assets_TableUsuage'		, @EnableAudit = 1, @Debug = 1
EXEC dbo.usp_DisableEnableAudit @DatabaseName = 'Products'	, @DBAuditName = N'DB_Audit_Products_TableUsuage'	, @EnableAudit = 1, @Debug = 1

DELETE FROM DBA.[dbo].[DataSeedAuditFiles]
DELETE FROM DBA.[dbo].[DataSeedAuditSummary]

DECLARE @Databases NVARCHAR(1000)
DECLARE @AuditNamePattern nvarchar(300)
DECLARE @Debug INT = 1

EXEC dbo.usp_DeleteAudit @Databases	= @Databases
						,@AuditNamePattern = @AuditNamePattern
						,@Debug			= @Debug
*/
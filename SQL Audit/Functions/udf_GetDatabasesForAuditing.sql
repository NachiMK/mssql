--USE DBATools
--GO
--IF OBJECT_ID('dbo.udf_GetDatabasesForAuditing') IS NOT NULL
--	DROP FUNCTION dbo.udf_GetDatabasesForAuditing
--GO
CREATE FUNCTION dbo.udf_GetDatabasesForAuditing()
RETURNS @TblReturn TABLE
(
	DatabaseName SYSNAME
)
AS
BEGIN

	INSERT INTO
			@TblReturn
			(
				DatabaseName
			)
	SELECT	Distinct name 
	FROM	sys.databases
	WHERE	database_id > 4
	AND		state_desc = N'ONLINE'
	AND		NAME NOT IN 
			(
				 'DBATools'
				,'DBA'
				,'Private'
				,'ASPState-55DowningStreet'
				,'ASPState-EuroStyleLighting'
				,'TCS_LP_Info-Center_9'
				,'TCS_55DS_Decor-Ideas'
				,'TCS_ESL_Modern-Inspiration'
				,'Bamboo'
				,'BitBucket'
				,'Confluence'
				,'FeCru'
				,'JIRA'
				,'UserProfile_Qtee'
				,'ASPState-QTee'
				,'TCS_Qtee'
				,'eDIRECT_email'
				,'EasyAsk'
				,'ssCartEasy_dbss'
				,'ReportServer'
				,'ReportServerTempDB'
				,'SSISDB'
			)
	ORDER BY
			NAME

	RETURN
END
GO

/*
	-- Testing Code
	SELECT	*
	FROM	dbo.udf_GetDatabasesForAuditing() T
	ORDER BY
			1
*/
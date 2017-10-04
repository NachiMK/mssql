--IF OBJECT_ID('dbo.udf_MoveMatchedFiles') IS NOT NULL
--	DROP FUNCTION [dbo].udf_MoveMatchedFiles
--GO
CREATE FUNCTION [dbo].[udf_MoveMatchedFiles](
	 @DirectoryPath NVARCHAR(MAX)
	,@SearchPattern NVARCHAR(MAX)
	,@DestDirectoryPath NVARCHAR(MAX))
RETURNS TABLE
(
	KeyName NVARCHAR(MAX),
	KeyValue NVARCHAR(MAX)
)
EXTERNAL NAME [SQLCLR.DBATools.Library].[SQLCLR.DBATools.Library.IOHelper].MoveMatchedFiles
GO

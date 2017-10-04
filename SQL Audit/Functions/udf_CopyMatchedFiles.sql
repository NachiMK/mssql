--IF OBJECT_ID('dbo.udf_CopyMatchedFiles') IS NOT NULL
--	DROP FUNCTION [dbo].udf_CopyMatchedFiles
--GO
CREATE FUNCTION [dbo].[udf_CopyMatchedFiles](
	 @DirectoryPath NVARCHAR(MAX)
	,@SearchPattern NVARCHAR(MAX)
	,@DestDirectoryPath NVARCHAR(MAX)
	,@Overwrite BIT)
RETURNS TABLE
(
	KeyName NVARCHAR(MAX),
	KeyValue NVARCHAR(MAX)
)
EXTERNAL NAME [SQLCLR.DBATools.Library].[SQLCLR.DBATools.Library.IOHelper].CopyMatchedFiles
GO
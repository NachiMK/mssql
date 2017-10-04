--IF OBJECT_ID('dbo.udf_FileMove') IS NOT NULL
--	DROP FUNCTION [dbo].udf_FileMove
--GO
CREATE FUNCTION [dbo].[udf_FileMove](@SourceFileName [NVARCHAR](MAX), @DestFileName [NVARCHAR](MAX))
RETURNS NVARCHAR(MAX)
AS 
EXTERNAL NAME [SQLCLR.DBATools.Library].[SQLCLR.DBATools.Library.IOHelper].FileMove
GO

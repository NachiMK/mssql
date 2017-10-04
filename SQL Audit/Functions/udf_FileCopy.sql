--IF OBJECT_ID('dbo.udf_FileCopy') IS NOT NULL
--	DROP FUNCTION [dbo].udf_FileCopy
--GO
CREATE FUNCTION [dbo].udf_FileCopy(@SourceFileName [NVARCHAR](MAX), @DestFileName [NVARCHAR](MAX), @Overwrite [BIT])
RETURNS NVARCHAR(MAX) 
AS 
EXTERNAL NAME [SQLCLR.DBATools.Library].[SQLCLR.DBATools.Library.IOHelper].FileCopy
GO

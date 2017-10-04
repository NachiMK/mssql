--IF OBJECT_ID('dbo.udf_SplitString') IS NOT NULL
--	DROP FUNCTION [dbo].udf_SplitString
--GO
CREATE FUNCTION [dbo].udf_SplitString(@input [NVARCHAR](MAX), @separator NVARCHAR(1))
RETURNS TABLE 
(
	[StringCol] [nvarchar](max) NULL
) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [SQLCLR.DBATools.Library].[SQLCLR.DBATools.Library.StringHelper].SplitStringCLR
GO

--IF OBJECT_ID('dbo.udf_Delete') IS NOT NULL
--	DROP FUNCTION [dbo].udf_Delete
--GO
CREATE FUNCTION [dbo].[udf_Delete](@Path [NVARCHAR](MAX))
RETURNS NVARCHAR(MAX)
AS 
EXTERNAL NAME [SQLCLR.DBATools.Library].[SQLCLR.DBATools.Library.IOHelper].FileDelete
GO

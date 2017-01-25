/* Run in Subscriber */
-- Rename DB
USE master
GO
EXEC sys.sp_renamedb
	@dbname = 'TestRepl'
   , -- sysname
	@newname = 'TestRepl' -- sysname



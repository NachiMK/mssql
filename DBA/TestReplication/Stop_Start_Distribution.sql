/* Run in distributor */
/*
	-- STOP Replication agent job (only subscription job)
	-- Rename database
	-- Create new database with same name on different location
	-- Start subscription - will it work?
*/
USE distribution
GO
--STOP the Distribution Agent:
EXEC sp_MSstopdistribution_agent 'LACubeData01', 'TestRepl', 'TestRepl ProdFlat to LADataMart01', 'LADataMart01', 'TestRepl'
 
  --START the Distribution Agent:
EXEC sp_MSstartdistribution_agent 'LACubeData01', 'TestRepl', 'TestRepl ProdFlat to LADataMart01', 'LADataMart01', 'TestRepl'

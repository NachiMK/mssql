-- 0x0001F69600000164000100000000

/*
{CALL [sp_MSupd_dboAccessCustomerPrivilege] (,,,,,2015-10-15 05:45:50.007,2015-11-15 05:45:39.153,,,5953846,0x6000)}
{CALL [sp_MSins_dboAccessTransaction] (1147781754,136111712,103,6,1151867282,NULL,NULL,NULL,2,1,2015-10-15 05:45:49.983,2015-10-15 05:45:49.983)}
{CALL [sp_MSins_dboAccessTransactionDetail] (1147781754,1,2015-10-15 05:45:39.153,2015-11-15 05:45:39.153,1,5,NULL)}
{CALL [sp_MSupd_dboAccessCustomerPrivilege] (,,,,,2015-10-15 05:45:50.007,2015-11-15 05:45:39.153,,,5953846,0x6000)}
{CALL [sp_MSins_dboAccessTransaction] (1147781754,136111712,103,6,1151867282,NULL,NULL,NULL,2,1,2015-10-15 05:45:49.983,2015-10-15 05:45:49.983)}
{CALL [sp_MSins_dboAccessTransactionDetail] (1147781754,1,2015-10-15 05:45:39.153,2015-11-15 05:45:39.153,1,5,NULL)}
*/

SELECT * FROM dbo.AccessCustomerPrivilege WHERE AccessCustomerPrivilegeID = 5953846
SELECT * FROM dbo.AccessTransaction WHERE AccessTransactionID = 1147781754
BEGIN TRAN
IF NOT EXISTS (SELECT * FROM dbo.AccessCustomerPrivilege WHERE AccessCustomerPrivilegeID = 5953846)
BEGIN
	INSERT INTO dbo.AccessCustomerPrivilege
			(AccessCustomerPrivilegeID
			,CustomerID
			,CallingSystemID
			,UnifiedPrivilegeTypeID
			,InsertDate
			,UpdateDate
			,EndDate
			,RemainingCount
			,ArchiveFlag)
	SELECT AccessCustomerPrivilegeID
		   ,CustomerID
		   ,CallingSystemID
		   ,UnifiedPrivilegeTypeID
		   ,InsertDate
		   ,UpdateDate
		   ,EndDate
		   ,RemainingCount
		   ,ArchiveFlag
	FROM LADBREPORT.epAccess.dbo.AccessCustomerPrivilege WHERE AccessCustomerPrivilegeID = 5953846
END
COMMIT

USE epAccess
GO

GO
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL10' 
        ,  @publisher_db =  'epAccess' 
        ,  @publication =  'epAccess Replication to LACUBEDATA01' 
        ,  @xact_seqno =  0x0001F69600000164000100000000


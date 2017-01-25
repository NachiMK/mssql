USE epRenewal
GO
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL10' 
        ,  @publisher_db =  'epRenewal' 
        ,  @publication =  'epRenewal Replication to LACUBEDATA01' 
        ,  @xact_seqno =  0x0000F2E4000004F2000100000000
GO
-- 0x0000F2E4000004ED0001000000000000

-- 0x0000F2E4000004ED0001000000000000
/*
{CALL [sp_MSupd_dboRenewalSubscription] (,,,,2015-09-16 12:06:30.343,2016-03-16 12:05:41.887,,,,,2015-09-16 12:06:30.557,4005194,0x3004)}
{CALL [sp_MSupd_dboRenewalSubscriptionDetail] (,,,2015-09-16 12:06:30.347,,,4005194,20239,0x08)}
{CALL [sp_MSins_dboRenewalTransaction] (1147317117,120310272,9081,6,1151374841,NULL,NULL,2015-09-16 12:06:30.340,2015-09-16 12:06:30.340,2,4005194,2,NULL,0,NULL,2015-09-16 12:06:30.557,2015-09-16 12:05:41.887,2016-03-16 12:05:41.887)}
{CALL [sp_MSins_dboRenewalTransactionDetail] (1147317117,20239)}
{CALL [sp_MSupd_dboRenewalSubscription] (,,,,2015-09-16 12:06:30.343,2016-03-16 12:05:41.887,,,,,2015-09-16 12:06:30.557,4005194,0x3004)}
{CALL [sp_MSupd_dboRenewalSubscriptionDetail] (,,,2015-09-16 12:06:30.347,,,4005194,20239,0x08)}
{CALL [sp_MSins_dboRenewalTransaction] (1147317117,120310272,9081,6,1151374841,NULL,NULL,2015-09-16 12:06:30.340,2015-09-16 12:06:30.340,2,4005194,2,NULL,0,NULL,2015-09-16 12:06:30.557,2015-09-16 12:05:41.887,2016-03-16 12:05:41.887)}
{CALL [sp_MSins_dboRenewalTransactionDetail] (1147317117,20239)}
*/

--EXEC sp_helpsubscriptionerrors @publisher = 'LASQL10', @publisher_db = 'epRenewal', @publication = 'epRenewal Replication to LACUBEDATA01', @subscriber = 'LACUBEDATA01', @subscriber_db = 'epRenewal'

USE epAccess
GO
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL10' 
        ,  @publisher_db =  'epAccess' 
        ,  @publication =  'epAccess Replication to LACUBEDATA01' 
        ,  @xact_seqno =  0x0001F38C000006AC000100000000
GO


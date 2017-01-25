USE epRenewal
GO

-- 0x0000F17300000322000500000000
/*
{CALL [sp_MSupd_dboRenewalSubscriptionDetail] (,33041,,2015-08-27 14:01:17.997,,,14475177,33053,0x0a)}
{CALL [sp_MSupd_dboRenewalSubscriptionDetail] (,33041,,2015-08-27 14:01:17.997,,,14475177,33053,0x0a)}
*/
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL10' 
        ,  @publisher_db =  'epRenewal' 
        ,  @publication =  'epRenewal Replication' 
        ,  @xact_seqno =  0x0000F17300000322000500000000
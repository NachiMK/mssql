-- 0x001FF19B00020BAD000300000000
--{CALL [sp_MSupd_dboUPSGlobalLog] (,,,,,,,,,,,,,2,,2015-11-19 16:59:52.727,1164525901,0x00a0)}
--{CALL [sp_MSupd_dboUPSGlobalLog] (,,,,,,,,,,,,,2,,2015-11-19 16:59:52.727,1164525901,0x00a0)}

USE mnMonitoring
GO
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL02' 
        ,  @publisher_db =  'mnMonitoring' 
        ,  @publication =  'mnMonitoring Replication - Inserts And Updates Only' 
        ,  @xact_seqno =  0x001FF19B00021BCA000300000000


SELECT * FROM dbo.UPSGlobalLog WHERE GlobalLogID = 1164525901


USE mnIMail1
GO
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL02' 
        ,  @publisher_db =  'mnImail1' 
        ,  @publication =  'mnImail1 LASQLPRODFLAT01 Replication' 
        ,  @xact_seqno =  0x000052930001B850000100000000


USE epOrder
GO
EXEC sp_setsubscriptionxactseqno  @publisher =  'LADBREPORT' 
        ,  @publisher_db =  'epOrder' 
        ,  @publication =  'LADBREPORT PublishedDB Publication' 
        ,  @xact_seqno =  0x00054928000035110005000000000000


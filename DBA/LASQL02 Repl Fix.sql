USE DataWarehouse
GO
EXEC sp_setsubscriptionxactseqno  @publisher =  'LACUBEDATA01' 
        ,  @publisher_db =  'DataWArehouse' 
        ,  @publication =  'DataWarehouse Replication to BHFinance04' 
        ,  @xact_seqno =  0x000AD47100008853013900000000



USE mnImail1
-- {CALL [sp_MSdel_dboMessageList] (927281125)}
-- 0x0000529400029176000100000000
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL02' 
        ,  @publisher_db =  'mnImail1' 
        ,  @publication =  'mnImail1 LASQLPRODFLAT01 Replication' 
        ,  @xact_seqno =  0x0000529400029176000100000000


USE mnMember5
--{CALL [sp_MSdel_dboMemberAttributeInt] (4314827,8082772)}
--{CALL [sp_MSins_dboMemberAttributeInt] (4314827,8082772,122,0)}
--{CALL [sp_MSdel_dboMemberAttributeInt] (68933208,8082772)}

EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL02' 
        ,  @publisher_db =  'mnMember5' 
        ,  @publication =  'mnMember5 LASQLPRODFLAT01 Replication' 
        ,  @xact_seqno =  0x0000449700002EEB000100000000

UPDATE mnMember5.dbo.MemberAttributeInt SET Value = 0 WHERE MemberID = 8082772 AND AttributeGroupID = 122

SELECT * FROM mnMember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND AttributeGroupID = 122
SELECT * FROM LASQL01.mnMember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND AttributeGroupID = 122
SELECT * FROM LASQL02.mnMember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND AttributeGroupID = 122

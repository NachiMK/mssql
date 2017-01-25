/*
{CALL [sp_MSdel_dboMemberAttributeInt] (32675761,113178637)}
{CALL [sp_MSins_dboMemberAttributeInt] (32675761,113178637,122,0)}
{CALL [sp_MSdel_dboMemberAttributeInt] (66254345,113178637)}
*/
-- 0x000038E80000E2BC000100000000
USE mnmember14
GO
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL06' 
        ,  @publisher_db =  'mnMember14' 
        ,  @publication =  'mnMember14 LASQLPRODFLAT01 Replication' 
        ,  @xact_seqno =  0x000038E80000E2BC000100000000

SELECT * FROM mnmember14.dbo.MemberAttributeInt WHERE MemberID = 113178637 AND rowid IN (32675761, 66254345)
SELECT * FROM LASQL06.mnmember14.dbo.MemberAttributeInt WHERE MemberID = 113178637 AND rowid IN (32675761, 66254345)
SELECT * FROM LASQL06.mnmember14.dbo.MemberAttributeInt WHERE MemberID = 113178637 AND rowid IN (32675761, 66254345)

SELECT * FROM mnmember14.dbo.MemberAttributeInt WHERE MemberID = 113178637 AND AttributeGroupID = 122
SELECT * FROM LASQL05.mnmember14.dbo.MemberAttributeInt WHERE MemberID = 113178637 AND AttributeGroupID = 122
SELECT * FROM LASQL06.mnmember14.dbo.MemberAttributeInt WHERE MemberID = 113178637 AND AttributeGroupID = 122

--0x000043880001A8BC000100000000



-- 0x00003BCE0000FC83000100000000
/*
{CALL [sp_MSdel_dboMemberAttributeInt] (41441576,140702172)}
{CALL [sp_MSins_dboMemberAttributeInt] (41441576,140702172,122,0)}
{CALL [sp_MSdel_dboMemberAttributeInt] (68197446,140702172)}

{CALL [sp_MSdel_dboMemberAttributeInt] (41441576,140702172)}
{CALL [sp_MSins_dboMemberAttributeInt] (41441576,140702172,122,0)}
{CALL [sp_MSdel_dboMemberAttributeInt] (69283501,140702172)}
*/
-- 0x00003BD1000076D1000100000000
USE mnmember13
GO
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL06' 
        ,  @publisher_db =  'mnMember13' 
        ,  @publication =  'mnMember13 LASQLPRODFLAT01 Replication' 
        ,  @xact_seqno =  0x00003BEC00020FD4000100000000

SELECT * FROM mnmember13.dbo.MemberAttributeInt WHERE MemberID = 140702172 AND rowid IN (41441576, 68197446)
SELECT * FROM LASQL06.mnmember13.dbo.MemberAttributeInt WHERE MemberID = 140702172 AND rowid IN (41441576, 68197446)
SELECT * FROM LASQL06.mnmember13.dbo.MemberAttributeInt WHERE MemberID = 140702172 AND rowid IN (41441576, 68197446)

SELECT * FROM mnmember13.dbo.MemberAttributeInt WHERE MemberID = 140702172 AND AttributeGroupID = 122
SELECT * FROM LASQL05.mnmember13.dbo.MemberAttributeInt WHERE MemberID = 140702172 AND AttributeGroupID = 122
SELECT * FROM LASQL06.mnmember13.dbo.MemberAttributeInt WHERE MemberID = 140702172 AND AttributeGroupID = 122

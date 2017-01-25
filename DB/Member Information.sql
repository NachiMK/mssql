/*
	Purpose: Find Member information
*/
SELECT (1002576 % 24) + 1 AS MemberDBPartition

-- LOGON DETAILS
SELECT * FROM LASQL03.mnLogon.dbo.logonmembercommunity WHERE MemberID = 1002576

-- Site/Brand/Community infor
SELECT * 
FROM	mnMember1.dbo.MemberGroup	MG	WITH (READUNCOMMITTED)
JOIN	mnSystem.dbo.[GROUP]		G	WITH (READUNCOMMITTED)	ON	G.GroupID = MG.GroupID
JOIN	mnSystem.dbo.Scope			S	WITH (READUNCOMMITTED)	ON	S.ScopeID = G.ScopeID
WHERE	MG.MemberID  = 1002576

-- ATtribute info
SELECT * 
FROM	mnMember1.dbo.MemberAttributeText	MAT	WITH (READUNCOMMITTED)
JOIN	mnSystem.dbo.AttributeGroup			AG	WITH (READUNCOMMITTED)	ON	AG.AttributeGroupID = MAT.AttributeGroupID
JOIN	mnSystem.dbo.Attribute				A	WITH (READUNCOMMITTED)	ON	A.AttributeID = AG.AttributeID
WHERE	MAT.MemberID  = 1002576


-- ATtribute info - INT
SELECT * 
FROM	mnMember1.dbo.MemberAttributeInt	MA	WITH (READUNCOMMITTED)
JOIN	mnSystem.dbo.AttributeGroup			AG	WITH (READUNCOMMITTED)	ON	AG.AttributeGroupID = MA.AttributeGroupID
JOIN	mnSystem.dbo.Attribute				A	WITH (READUNCOMMITTED)	ON	A.AttributeID = AG.AttributeID
LEFT
JOIN	mnSystem.dbo.AttributeOption		AO	WITH (READUNCOMMITTED)	ON	AO.AttributeID = A.AttributeID AND AO.AttributeValue = MA.Value
WHERE	MA.MemberID  = 1002576


-- ATtribute info - Date
SELECT * 
FROM	mnMember1.dbo.MemberAttributeDate	MAD	WITH (READUNCOMMITTED)
JOIN	mnSystem.dbo.AttributeGroup			AG	WITH (READUNCOMMITTED)	ON	AG.AttributeGroupID = MAD.AttributeGroupID
JOIN	mnSystem.dbo.Attribute				A	WITH (READUNCOMMITTED)	ON	A.AttributeID = AG.AttributeID
WHERE	MAD.MemberID  = 1002576

-- Membger Group Details
SELECT	*
FROM	mnMember1.dbo.MemberGroup			MG	WITH (READUNCOMMITTED)
WHERE	MG.MemberID		=	1002576

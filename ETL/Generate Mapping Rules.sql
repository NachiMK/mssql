/*
	Requirement: Create a Query that can map columns between two tables.

	Some exceptions for mapping: If a Column name ends with No_Pk it can be mapped to a column that is ending with _PK
*/
SELECT		 TargetSchema		=	RTS.name
			,TargetTableName	=	RT.name
			,TargetColumnName	=	RTC.name
			,TargetColType		=	RTT.name
			,TargetColLen		=	CASE WHEN ((RTT.name  LIKE '%char%') OR (RTT.name  LIKE '%VAR%')) THEN CONVERT(VARCHAR, RTC.max_length) ELSE '' END
			,TargetNullable		=	CASE WHEN RTC.is_nullable = 1 THEN 'Y' ELSE 'N' END
			,SourceSchema		=	RTD.SourceSchema
			,SourceTableName	=	RTD.SourceTableName
			,SourceColumnName	=	RTD.SourceColumnName
			,SourceColType		=	RTD.SourceColType
			,SourceColLen		=	RTD.SourceColLen	
			,SourceNullable		=	RTD.SourceNullable
FROM		sys.tables AS RT
JOIN		sys.schemas AS RTS		ON	RTS.schema_id		= RT.SCHEMA_ID
JOIN		sys.columns AS RTC		ON	RTC.object_id		= RT.object_id
JOIN		sys.types AS RTT		ON	RTT.user_type_id	= RTC.user_type_id
OUTER APPLY	(
			SELECT
			 SourceSchema		=	LTS.name
			,SourceTableName	=	LT.name
			,SourceColumnName	=	LTC.name
			,SourceColType		=	LTT.name + CASE WHEN ((LTT.name  LIKE '%char%') OR (LTT.name  LIKE '%VAR%')) THEN '(' + CONVERT(VARCHAR, LTC.max_length) + ')' ELSE '' END
			,SourceColLen		=	CASE WHEN LTT.name  LIKE '%char%' THEN CONVERT(VARCHAR, LTC.max_length) ELSE '' END
			,SourceNullable		=	CASE WHEN LTC.is_nullable = 1 THEN 'Y' ELSE 'N' END
			FROM		sys.tables AS LT
			JOIN		sys.schemas AS LTS		ON	LTS.schema_id		= LT.schema_id
			JOIN		sys.columns AS LTC		ON	LTC.object_id		= LT.object_id
			JOIN		sys.types AS LTT		ON	LTT.user_type_id	= LTC.user_type_id
			WHERE		LT.name		= 'zzAudit_DistrictEmployee'
			AND			LTS.name	= 'dbo'
			AND			LT.schema_id!= RT.schema_id
			AND			(
							(RTC.name	= LTC.name)
						OR	((REPLACE(LTC.name, 'No_PK', '_PK') = RTC.name) AND LTT.name = 'int')
						OR	((REPLACE(LTC.name, 'No_FK', '_FK') = RTC.name) AND LTT.name = 'int')
						OR	((REPLACE(RTC.name, 'Row', '') = LTC.name) AND LTT.name = 'timestamp')
						OR	((REPLACE(LTC.name, 'No_PK', '_FK') = RTC.name) AND LTT.name = 'int')
						)
			) AS RTD
WHERE		RTS.name	= 'DS'
AND			RT.name		= 'zzAudit_DistrictEmployee'
ORDER BY	RTC.column_id

--SELECT REPLACE('BranchNo_PK' , 'No_PK', '_PK')
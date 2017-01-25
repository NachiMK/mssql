SET NOCOUNT ON

DECLARE @MergeStmt VARCHAR(MAX)
DECLARE @SRCTable VARCHAR(40) = 'dbo.vw_StageMaropostCampaigns'
DECLARE @SRCAlias VARCHAR(4) = 'SRC.'

DECLARE @TgtTable VARCHAR(40) = 'dbo.MaropostCampaigns'
DECLARE @TgtAlias VARCHAR(4) = 'TGT.'

SET @MergeStmt = ''
SET @MergeStmt = @MergeStmt + 'MERGE ' + @TgtTable + ' TGT' + CHAR(13) 
SET @MergeStmt = @MergeStmt + 'USING (' + CHAR(13) 
SET @MergeStmt = @MergeStmt + '	SELECT	' + CHAR(13) 

SELECT	@MergeStmt = @MergeStmt + '		,' + C.name + CHAR(13) 
FROM	sys.columns AS C WHERE C.object_id = OBJECT_ID(@SRCTable)
AND		C.name NOT IN ('CreatedDate', 'UpdatedDate')
AND		C.is_identity = 0

SET @MergeStmt = @MergeStmt + CHAR(13) 
SET @MergeStmt = @MergeStmt + '	FROM	'+ @SRCTable + CHAR(13) 
SET @MergeStmt = @MergeStmt + '	)	SRC	('+ CHAR(13) 

SELECT	@MergeStmt = @MergeStmt + '		,' + C.name + CHAR(13) 
FROM	sys.columns AS C WHERE C.object_id = OBJECT_ID(@SRCTable)
AND		C.name NOT IN ('CreatedDate', 'UpdatedDate')
AND		C.is_identity = 0
SET @MergeStmt = @MergeStmt + '	)' + CHAR(13)
SET @MergeStmt = @MergeStmt + '	ON TGT.Column1 = SRC.Column1' + CHAR(13)
SET @MergeStmt = @MergeStmt + '	WHEN MATCHED AND (' + CHAR(13)

SELECT	 @MergeStmt = @MergeStmt + CASE WHEN C.is_nullable = 0 
			  THEN '	OR	(' + @SRCAlias + C.name + '<>' + @TgtAlias + C.name + ')' + CHAR(13)
			  ELSE '	OR	(' + @SRCAlias + C.name + '	IS	NOT NULL	AND	' + @TgtAlias + C.name + '	IS NULL)' + CHAR(13) +
			  '	OR	(' + @SRCAlias + C.name + '	IS	NULL		AND	' + @TgtAlias + C.name + '	IS NOT NULL)'  + CHAR(13) +
			  '	OR	(' + @SRCAlias + C.name + '	<>	' + @TgtAlias + C.name + ')'  + CHAR(13)
			  END
FROM	sys.columns AS C WHERE C.object_id = OBJECT_ID(@TgtTable)
AND		C.name NOT IN ('CreatedDate', 'UpdatedDate')
AND		C.is_identity = 0
AND		NOT EXISTS 
(
SELECT	* 
FROM	sys.indexes AS I 
JOIN	sys.index_columns AS IC ON IC.object_id = I.object_id
								AND IC.index_id = i.index_id
WHERE	I.object_id = C.object_id
AND		I.is_primary_key = 1
AND		IC.column_id = C.Column_id
)

SET @MergeStmt = @MergeStmt + '	) THEN' + CHAR(13) + CHAR(13)
SET @MergeStmt = @MergeStmt + '	UPDATE SET' + CHAR(13) 

SELECT	 @MergeStmt = @MergeStmt + '		,' + @TgtAlias + C.name + '	=	' + @SRCAlias + C.name + CHAR(13)
FROM	sys.columns AS C WHERE C.object_id = OBJECT_ID(@TgtTable)
AND		C.name NOT IN ('CreatedDate', 'UpdatedDate')
AND		C.is_identity = 0
AND		NOT EXISTS 
(
SELECT	* 
FROM	sys.indexes AS I 
JOIN	sys.index_columns AS IC ON IC.object_id = I.object_id
								AND IC.index_id = i.index_id
WHERE	I.object_id = C.object_id
AND		I.is_primary_key = 1
AND		IC.column_id = C.Column_id
)
	
SET @MergeStmt = @MergeStmt + CHAR(13) + '	WHEN NOT MATCHED BY TARGET THEN'  + CHAR(13)
SET @MergeStmt = @MergeStmt	+ CHAR(13) + '	INSERT ( '   + CHAR(13)
SELECT	 @MergeStmt = @MergeStmt + '		,' + C.name + CHAR(13)
FROM	sys.columns AS C WHERE C.object_id = OBJECT_ID(@TgtTable)
AND		C.name NOT IN ('CreatedDate', 'UpdatedDate')
AND		C.is_identity = 0
SET @MergeStmt = @MergeStmt + '	)'
SET @MergeStmt = @MergeStmt + '	VALUES ( '   + CHAR(13)
SELECT	 @MergeStmt = @MergeStmt + '		,' + @SRCAlias + C.name + CHAR(13)
FROM	sys.columns AS C WHERE C.object_id = OBJECT_ID(@TgtTable)
AND		C.name NOT IN ('CreatedDate', 'UpdatedDate')
AND		C.is_identity = 0
SET @MergeStmt = @MergeStmt + '	)'  + CHAR(13)

SET @MergeStmt = @MergeStmt + '	WHEN NOT MATCHED BY SOURCE THEN'  + CHAR(13)
SET @MergeStmt = @MergeStmt + '	DELETE'  + CHAR(13)
SET @MergeStmt = @MergeStmt + '	;' + CHAR(13)
	
-- FINAL PRINT
PRINT @MergeStmt



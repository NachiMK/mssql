SELECT	 Referencing_DatabaseId		= DB_ID()
		,Referencing_Object			= S.name
		,Referencing_Object_Id		= S.object_id
		,Referencing_Object_Type	= S.type_desc

		,Referenced_Database_Id		= COALESCE(PARSENAME(S.base_object_name,3),DB_NAME(DB_ID()))
		,Referenced_Schema_Id		= COALESCE(PARSENAME(S.base_object_name,2),SCHEMA_NAME(SCHEMA_ID()))
		,Referenced_TableId			= -1 * object_id(S.name)
		,Referenced_Object_Type		= OBJECTPROPERTYEX(OBJECT_ID(S.name), 'BaseType')
		,Referenced_Table_name		= PARSENAME(S.base_object_name,1)
FROM	SYS.SYNONYMS	S
JOIN	SYS.OBJECTS		O	ON S.object_id = O.object_id


SELECT	 Referencing_DatabaseId		= DB_ID()
		,Referencing_Object			= S.name
		,Referencing_Object_Id		= S.object_id
		,Referencing_Object_Type	= S.type_desc

		,Referenced_Database_Id		= COALESCE(DB_ID(PARSENAME(S.base_object_name,3)),DB_ID())
		,Referenced_Schema_Id		= COALESCE(SCHEMA_ID(PARSENAME(S.base_object_name,2)),SCHEMA_ID())
		,Referenced_TableId			= -1 * object_id(S.name)
		,Referenced_Object_Type		= CONVERT(NVARCHAR(256), OBJECTPROPERTYEX(OBJECT_ID(S.name), 'BaseType'))
		,Referenced_Table_name		= PARSENAME(S.base_object_name,1)
FROM	SYS.SYNONYMS	S
JOIN	SYS.OBJECTS		O	ON S.object_id = O.object_id

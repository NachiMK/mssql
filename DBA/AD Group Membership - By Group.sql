
/*================================================================
GET USERS/ACCOUNTS FOR AN AD GROUP
================================================================*/

DECLARE @cnSearchString NVARCHAR(200) = 'MATCHNET\Developers'

--RDG - CRM Production Servers

DECLARE @ADGroup TABLE ( ADGroupRow INT IDENTITY(1,1), ADGroup VARCHAR(100), GroupEmailAddress VARCHAR(100), GroupPath VARCHAR(400) )
DECLARE @ADGroupMember TABLE ( ADGroup VARCHAR(100), GroupEmailAddress VARCHAR(100), ADGroupMember VARCHAR(100), DisplayName VARCHAR(100), AccountType VARCHAR(100), EmailAddress VARCHAR(100) )
DECLARE @ADQueryString NVARCHAR(4000)	

SET @ADQueryString = '
	SELECT Name, mail, RIGHT(ADsPath, LEN(ADsPath) - LEN(''LDAP://'')) GroupPath
		FROM OPENQUERY(adsi,''  
						SELECT		name, ADsPath, mail
						FROM		''''LDAP://dc=asm,dc=lan''''  
						WHERE		objectClass = ''''group'''' 
						AND			name = ''''' + @cnSearchString + '''''
					'')'
	
--SELECT @ADQueryString
      
INSERT @ADGroup
EXEC sp_executesql @ADQueryString

--SELECT * FROM @ADGroup

DECLARE @g INT = 1

WHILE @g <= ( SELECT COUNT(1) FROM @ADGroup )
BEGIN

	SELECT @ADQueryString = '
		SELECT ''' + ADGroup + ''' ADGroup, ''' + ISNULL(GroupEmailAddress,'') + ''' GroupEmailAddress, sAMAccountName ADGroupMember, DisplayName, CASE sAMAccountType WHEN ''805306368'' THEN ''User'' WHEN ''268435456'' THEN ''Group'' END, mail 
		FROM OPENQUERY(adsi,''
							  SELECT	sAMAccountName, sAMAccountType, DisplayName, mail
							  FROM		''''LDAP://dc=asm,dc=lan''''  
							  WHERE		memberOf =''''' + GroupPath + '''''
								'')'
	FROM		@ADGroup
	WHERE		ADGroupRow = @g

	--SELECT @ADQueryString
	
	INSERT @ADGroupMember ( ADGroup, GroupEmailAddress, ADGroupMember, DisplayName, AccountType, EmailAddress )
	EXEC sp_executesql @ADQueryString

	SET @g = @g + 1

END

SELECT		DISTINCT  ADGroup, GroupEmailAddress
FROM		@ADGroupMember
ORDER BY	ADGroup

SELECT		 ADGroup
			,GroupEmailAddress
			,ADGroupMember
			,DisplayName
			,AccountType
			,EmailAddress
FROM		@ADGroupMember
ORDER BY	ADGroup, 
			ADGroupMember
 

 
/*================================================================
GET GROUPS FOR A AD USER/ACCOUNT
================================================================*/

DECLARE @LdapUsername NVARCHAR(256) = 'cabissrs.ds'
DECLARE @Query NVARCHAR(1024), @Path NVARCHAR(1024)

/*
rick.paniagua

*/

SET @Query = '
    SELECT @Path = distinguishedName
    FROM OPENQUERY(ADSI, ''
        SELECT distinguishedName
        FROM ''''LDAP://dc=asm,dc=lan''''
        WHERE 
            objectClass = ''''user'''' AND
            sAMAccountName = ''''' + @LdapUsername + '''''
    '')
'
 
--SELECT @Query
EXEC SP_EXECUTESQL @Query, N'@Path NVARCHAR(1024) OUTPUT', @Path = @Path OUTPUT 

   SET @Query = '
    SELECT name AS LdapGroup 
    FROM OPENQUERY(ADSI,''
        SELECT name 
        FROM ''''LDAP://dc=asm,dc=lan''''
        WHERE 
            objectClass=''''group'''' AND
            member=''''' + @Path + '''''
    '')
    ORDER BY name
'    

--SELECT @Query
EXEC SP_EXECUTESQL @Query
  

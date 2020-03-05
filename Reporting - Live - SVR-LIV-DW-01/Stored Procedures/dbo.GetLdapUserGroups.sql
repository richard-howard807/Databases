SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GetLdapUserGroups] -- 'sparke01'
(
    @LdapUsername NVARCHAR(256)
)
AS
BEGIN
    DECLARE @Query NVARCHAR(1024), @Path NVARCHAR(1024)

    SET @Query = '
        SELECT @Path = distinguishedName
        FROM OPENQUERY(ADSI, ''
            SELECT distinguishedName 
            FROM ''''LDAP://DC=SBC,DC=ROOT''''
            WHERE 
                objectClass = ''''user'''' AND
                sAMAccountName = ''''' + @LdapUsername + '''''
        '')
    '
    EXEC SP_EXECUTESQL @Query, N'@Path NVARCHAR(1024) OUTPUT', @Path = @Path OUTPUT 

    SET @Query = '
        SELECT name AS LdapGroup 
        FROM OPENQUERY(ADSI,''
            SELECT name 
            FROM ''''LDAP://DC=SBC,DC=ROOT''''
            WHERE 
                objectClass=''''group'''' AND
                member=''''' + @Path + '''''
        '')
        ORDER BY name
    --'
    EXEC SP_EXECUTESQL @Query

END
GO

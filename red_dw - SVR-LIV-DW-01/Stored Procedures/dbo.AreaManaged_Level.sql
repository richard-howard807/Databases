SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--EXEC [dbo].[AreaManaged_Level] 'jbonne'

CREATE proc [dbo].[AreaManaged_Level] @Username nvarchar(100) as
set nocount on 

--SET @Username = IIF (@Username = '7242', 'agill', @Username)
--SET @Username = IIF (@Username = '7242', 'nodono', @Username)


--DECLARE @Username AS NVARCHAR(100) = 'asteve'

DECLARE @Path NVARCHAR(1024)
DECLARE @Query NVARCHAR(MAX)
DECLARE @Query2 NVARCHAR(MAX)
DECLARE @Path2 NVARCHAR(1024)



SET @Query = '         
            SELECT @Path = distinguishedName         
            FROM OPENQUERY
                        (ADSI, ''             
                              SELECT distinguishedName              
                              FROM ''''LDAP://lb-ldaps:636''''             
                              WHERE                  
                              sAMAccountName = ''''' + @Username
    + '''''         
                        '')     '    
  
--PRINT @Query  

EXEC master.sys.SP_EXECUTESQL @Query, N'@Path NVARCHAR(1024) OUTPUT',
    @Path = @Path OUTPUT

 SET @Query = '         
      SELECT *          
      FROM OPENQUERY(ADSI,''             
            SELECT  name,  distinguishedName            
            FROM ''''LDAP://lb-ldaps:636''''             
            WHERE                  
                  objectClass=''''group'''' 
            AND member=''''' + @Path + '''''         
            '')         ORDER BY name     '     

 
 SET @Query2 = '         
      SELECT *          
      FROM OPENQUERY(ADSI,''             
            SELECT  name,  distinguishedName            
            FROM ''''LDAP://lb-ldaps:636''''             
            WHERE                  
                  objectClass=''''group'''' 
            AND member=''''' + REPLACE(@Path,'''','''''''''') + '''''         
            '')         ORDER BY name     '   

--PRINT @Query2

IF OBJECT_ID('tempdb..#ADGroups') IS NOT NULL 
DROP TABLE #ADGroups

  CREATE TABLE #ADGroups
    (
      distinguishedName VARCHAR(2000) ,
      Name VARCHAR(200)
    )
  INSERT  INTO [#ADGroups]
    ( distinguishedName, Name )
  VALUES  ( NULL, 'Everyone' )
  INSERT  INTO [#ADGroups]   
  (distinguishedName, Name ) 

EXEC master.sys.SP_EXECUTESQL @Query2, N'@Path2 NVARCHAR(1024) OUTPUT',
    @Path2 = @Path2 OUTPUT  


declare @FinalTbl table (Level varchar(100), mdx varchar(max), [sql] varchar(max), dax VARCHAR(max), [default] varchar(100))
insert into @FinalTbl values ('Individual', NULL, NULL, NULL, NULL)
insert into @FinalTbl (Level)

select 
CASE WHEN Name = 'People - Directors and Partners' THEN 'Firm'
WHEN Name = 'Head of Business Services' THEN 'Firm'
WHEN Name = 'People - All Consultants' THEN 'Firm'
WHEN Name = 'SSRS - Dev_ReportsAdmin' THEN 'Firm'
WHEN Name = 'Restricted - Operations - Finance' THEN 'Firm'
WHEN Name = 'Restricted - Operations - Risk & Compliance' THEN 'Firm'
WHEN Name = 'Restricted - Operations - Marketing' THEN 'Firm'
WHEN Name = 'Restricted - Operations - HR&D' THEN 'Firm'
WHEN Name = 'CascadeDepartment - Business Process' then 'Firm'
WHEN Name = 'People - All Legal Directors' THEN 'Firm'
WHEN Name = 'Reports_Testers' THEN 'Firm'
WHEN Name = 'People - All PAs' THEN 'Firm'
WHEN Name = 'People - Governance staff' THEN 'Firm'
WHEN Name = 'People - Business Services Management Department' then 'Firm'
WHEN Name = 'People - All Operations Managers' THEN 'Area Managed'
WHEN Name = 'People - Heads of Service Delivery' THEN 'Area Managed'
WHEN Name = 'People - Heads of Service Delivery and Directors' THEN 'Area Managed'
WHEN Name = 'People - Claims Management Department' THEN 'Area Managed'
WHEN Name = 'People - LTA Management' THEN 'Area Managed'
WHEN Name = 'People - Sector Leads' THEN 'Area Managed'
WHEN Name = 'People - Support Team Managers' THEN 'Area Managed'
WHEN Name = 'People - All BCMs' THEN 'Area Managed'
WHEN Name = 'People - Assistant Operations Managers' THEN 'Area Managed'
WHEN Name = 'People - Team Leaders' THEN 'Area Managed'
WHEN Name = 'People - Team Managers' THEN 'Area Managed'
WHEN Name = 'SSRS - Team Managers' THEN 'Area Managed'
WHEN Name = 'SSRSPARAMS - Team Level permission'  THEN 'Area Managed'
WHEN Name = 'SSRSPARAM - Firm Level permissions' THEN 'Firm'
WHEN Name = 'All Principal Associates' THEN 'Area Managed'

END
from #ADGroups


	/*** 
		INDIVIDUAL	
				***/

IF OBJECT_ID('tempdb..#Individual') IS NOT NULL  
DROP TABLE #Individual

create table #Individual (mdx varchar(max), [sql] varchar(max), dax VARCHAR(max))
insert into  #Individual (mdx, [sql], dax) 
exec [AreaManaged_Individual] @Username

update @FinalTbl 
set mdx = #Individual.mdx,
	[sql] = #Individual.[sql],
	[@FinalTbl].dax = #Individual.dax
from @FinalTbl
cross join #Individual 
where Level = 'Individual'

	/***
		AREA MANAGED
					***/

IF OBJECT_ID('tempdb..#AreaManaged') IS NOT NULL 
DROP TABLE #AreaManaged

create table #AreaManaged (mdx varchar(max), [sql] varchar(max), dax VARCHAR(MAX))
insert into  #AreaManaged (mdx, [sql], dax) 
exec [AreaManaged_AreaManaged] @Username

update @FinalTbl 
set mdx = #AreaManaged.mdx,
	[sql] = #AreaManaged.[sql],
	[@FinalTbl].dax = #AreaManaged.dax
from @FinalTbl
cross join #AreaManaged 
where Level = 'Area Managed'

	/***
		FIRM
			***/

update @FinalTbl 
set mdx = '[Dim Fed Hierarchy History].[Hierarchy].AllMembers',
    [sql] = '(select dim_fed_hierarchy_history_key from red_dw.dbo.dim_fed_hierarchy_history)',
	dax = 'Firm'
where Level = 'Firm'

update @FinalTbl set [default] = 'Individual'

/*** 
	SET DEFAULTS
				***/

if (
SELECT distinct TOP 1 Level
FROM @FinalTbl
WHERE Level = 'Area Managed'
) = 'Area Managed' update @FinalTbl set [default] = 'Area Managed'

if (
SELECT distinct TOP 1 Level
FROM @FinalTbl
WHERE Level = 'Firm'
) = 'Firm' update @FinalTbl set [default] = 'Firm'


select distinct 
CAST(Level as varchar(100)) 'Level',
CAST(mdx as nvarchar(max)) 'mdx',
CAST(sql as nvarchar(max)) 'sql',
CAST([@FinalTbl].dax AS NVARCHAR(MAX)) 'dax',
CAST([default] as nvarchar(max)) 'default'
from @FinalTbl where Level is not null

--exec AreaManaged_Level 'asteve'

--create table #user (
--Level nvarchar(100),
--mdx nvarchar(max),
--sql nvarchar(max),
--[default] nvarchar(100)
--)
--insert into #user
--exec AreaManaged_Level 'sparke01'


GO
GRANT EXECUTE ON  [dbo].[AreaManaged_Level] TO [db_ssrs_dynamicsecurity]
GO
GRANT EXECUTE ON  [dbo].[AreaManaged_Level] TO [SBC\SQL ROLE - DS_BI_TRAINEE]
GO

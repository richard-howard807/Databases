SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



--[dbo].[Dynamic_Hierarchy_Security] 'lwalsh01'

CREATE PROCEDURE [dbo].[Dynamic_Hierarchy_Security] --'screll'

@Username NVARCHAR(256) = NULL
AS

--DECLARE @Username NVARCHAR(256)
--SET @Username = 'lwalsh01'
  
DECLARE @Query NVARCHAR(MAX) ,
    @Path NVARCHAR(1024), 
    @Query2 NVARCHAR(MAX), 
    @Path2 NVARCHAR(1024)
		   
SET @Query = '         
            SELECT @Path = distinguishedName         
            FROM OPENQUERY
                        (ADSI, ''             
                              SELECT distinguishedName              
                              FROM ''''LDAP://DC=SBC,DC=ROOT''''             
                              WHERE                  
                              sAMAccountName = ''''' + @Username
    + '''''         
                        '')     '    
	
PRINT @Query	
					
						  
EXEC master.sys.SP_EXECUTESQL @Query, N'@Path NVARCHAR(1024) OUTPUT',
    @Path = @Path OUTPUT  
	
	SET @Query = '         
      SELECT *          
      FROM OPENQUERY(ADSI,''             
            SELECT  name,  distinguishedName            
            FROM ''''LDAP://DC=SBC,DC=ROOT''''             
            WHERE                  
                  objectClass=''''group'''' 
            AND member=''''' + @Path + '''''         
            '')         ORDER BY name     '     

 
 SET @Query2 = '         
      SELECT *          
      FROM OPENQUERY(ADSI,''             
            SELECT  name,  distinguishedName            
            FROM ''''LDAP://DC=SBC,DC=ROOT''''             
            WHERE                  
                  objectClass=''''group'''' 
            AND member=''''' + REPLACE(@Path,'''','''''''''') + '''''         
            '')         ORDER BY name     '   

PRINT @Query2

	IF OBJECT_ID('tempdb..#temp') IS NOT NULL 

    DROP TABLE #temp

	CREATE TABLE #temp
    (
      distinguishedName VARCHAR(2000) ,
      Name VARCHAR(200)
    )

	INSERT  INTO [#temp]
    ( distinguishedName, Name )
	VALUES  ( NULL, 'Everyone' )


	INSERT  INTO [#temp]   
	(distinguishedName, Name ) 


EXEC master.sys.SP_EXECUTESQL @Query2, N'@Path2 NVARCHAR(1024) OUTPUT',
    @Path2 = @Path2 OUTPUT  

--select * from #temp
--drop table #temp

DECLARE @Individual VARCHAR(MAX);

SELECT @Individual = CONVERT(VARCHAR(MAX), (
  SELECT '[Dim_Fed_Hierarchy_History].[Fed Hierarchy Business Key].['+RTRIM(CAST(fed_hierarchy_business_key AS VARCHAR(150)))+']'+ ','  
  FROM 
  (
  SELECT hier.fed_hierarchy_business_key,ROW_NUMBER() OVER (PARTITION BY emp.windowsusername ORDER BY hier.activeud desc) onerowfilter
  FROM 
red_dw.dbo.ds_sh_employee emp
left join
red_dw.dbo.dim_fed_hierarchy_history hier
on emp.employeeid = hier.employeeid
where emp.dss_current_flag ='Y'
and hier.dss_current_flag ='Y'
and emp.windowsusername = @Username) AS onerow
WHERE onerowfilter =1
  FOR XML PATH('')
))
SELECT @Individual = LEFT(@Individual, LEN(@Individual) - 1)

--select @Individual
DECLARE @BCMAreaManaged VarChar(MAX);

SELECT @BCMAreaManaged = CONVERT(VarChar(MAX), (
SELECT '[Fed Hierarchy Business Key].['+RTRIM(CAST(fed_hierarchy_business_key as varchar(150)))+']'+ ','  
 from 
red_dw.dbo.dim_fed_hierarchy_history hierarchy
where hierarchy.dss_current_flag = 'Y'
--and hierarchy.activeud = 1
and hierarchy.hierarchylevel2hist 
IN(
select distinct hier.hierarchylevel2hist
from red_dw.dbo.ds_sh_employee emp
left join
red_dw.dbo.dim_fed_hierarchy_history hier
on ((UPPER(emp.employeeid) = UPPER(hier.reportingbcmidud)
or UPPER(emp.employeeid) = UPPER(hier.worksforemployeeid))
or UPPER(emp.employeeid) = UPPER(hier.employeeid))
and hier.dss_current_flag ='Y'
and hier.activeud = 1
where emp.dss_current_flag ='Y'
and emp.windowsusername = @Username
)
and hierarchy.hierarchylevel3hist 
IN(
select distinct hier.hierarchylevel3hist
from red_dw.dbo.ds_sh_employee emp
left join
red_dw.dbo.dim_fed_hierarchy_history hier
on ((UPPER(emp.employeeid) = UPPER(hier.reportingbcmidud)
or UPPER(emp.employeeid) = UPPER(hier.worksforemployeeid))
or UPPER(emp.employeeid) = UPPER(hier.employeeid))
and hier.dss_current_flag ='Y'
and hier.activeud = 1
where emp.dss_current_flag ='Y'
and emp.windowsusername = @Username
)

and hierarchy.hierarchylevel4hist 
IN
(
select distinct hier.hierarchylevel4hist
from red_dw.dbo.ds_sh_employee emp
left join
red_dw.dbo.dim_fed_hierarchy_history hier
on ((UPPER(emp.employeeid) = UPPER(hier.reportingbcmidud)
or UPPER(emp.employeeid) = UPPER(hier.worksforemployeeid))
or UPPER(emp.employeeid) = UPPER(hier.employeeid))
and hier.dss_current_flag ='Y'
and hier.activeud = 1
where emp.dss_current_flag ='Y'
and emp.windowsusername = @Username
)
  FOR XML PATH('')
))
SELECT @BCMAreaManaged = LEFT(@BCMAreaManaged, LEN(@BCMAreaManaged) - 1)

/*JC 05082015 - Added Support Team Manager level*/
IF OBJECT_ID('tempdb..#STMAreaManaged') IS NOT NULL 

DROP TABLE #STMAreaManaged


CREATE TABLE #STMAreaManaged
    (
      complexcode VARCHAR(MAX) ,
	  code VARCHAR(MAX) ,
	  team VARCHAR(MAX) ,
	  practicearea VARCHAR(MAX) ,
	  businessline VARCHAR(MAX) 
      
    )

	INSERT  INTO #STMAreaManaged
   
SELECT '[Fed Hierarchy Business Key].['+RTRIM(CAST(fed_hierarchy_business_key as varchar(150)))+']'+ ','  as complexcode,  rtrim(fed_code) + ',' as code , hierarchylevel4hist + ',' as team, hierarchylevel3hist + ',' as practicearea, hierarchylevel2hist +',' as businessline
 from 
red_dw.dbo.dim_fed_hierarchy_history hierarchy
where hierarchy.dss_current_flag = 'Y'
--and hierarchy.activeud = 1
and hierarchy.hierarchylevel2hist 
IN(
select distinct hier.hierarchylevel2hist
from red_dw.dbo.ds_sh_employee emp
left join
red_dw.dbo.dim_fed_hierarchy_history hier
on ((UPPER(emp.employeeid) = UPPER(hier.reportingbcmidud)
or UPPER(emp.employeeid) = UPPER(hier.worksforemployeeid))
or UPPER(emp.employeeid) = UPPER(hier.employeeid))
and hier.dss_current_flag ='Y'
and hier.activeud = 1
where emp.dss_current_flag ='Y'
and emp.windowsusername = @Username
)
and hierarchy.hierarchylevel3hist 
IN(
select distinct hier.hierarchylevel3hist
from red_dw.dbo.ds_sh_employee emp
left join
red_dw.dbo.dim_fed_hierarchy_history hier
on ((UPPER(emp.employeeid) = UPPER(hier.reportingbcmidud)
or UPPER(emp.employeeid) = UPPER(hier.worksforemployeeid))
or UPPER(emp.employeeid) = UPPER(hier.employeeid))
and hier.dss_current_flag ='Y'
and hier.activeud = 1
where emp.dss_current_flag ='Y'
and emp.windowsusername = @Username
)

and hierarchy.hierarchylevel4hist 
IN
(
select distinct hier.hierarchylevel4hist
from red_dw.dbo.ds_sh_employee emp
left join
red_dw.dbo.dim_fed_hierarchy_history hier
on ((UPPER(emp.employeeid) = UPPER(hier.reportingbcmidud)
or UPPER(emp.employeeid) = UPPER(hier.worksforemployeeid))
or UPPER(emp.employeeid) = UPPER(hier.employeeid))
and hier.dss_current_flag ='Y'
and hier.activeud = 1
where emp.dss_current_flag ='Y'
and emp.windowsusername = @Username
)


DECLARE @STMAreaManaged VarChar(MAX), @STMAreaManagedcode VarChar(MAX), @STMAreaManagedTeam varchar(max), @STMAreaManagedPracticeArea varchar(max), @STMAreaManagedBusinessLine varchar(max);



select @STMAreaManaged = CONVERT(VarChar(MAX), (
select  complexcode as [text()]
from #STMAreaManaged
FOR XML PATH('') )) 
 
	 

select @STMAreaManagedcode = CONVERT(VarChar(MAX), (
select  code  as [text()]
from #STMAreaManaged
where code not like '%Unknown%'
FOR XML PATH('') )) 

select @STMAreaManagedTeam = CONVERT(VarChar(MAX), (
select distinct team as [text()]
from #STMAreaManaged
where code not like '%Unknown%'
FOR XML PATH('') )) 

select @STMAreaManagedPracticeArea = CONVERT(VarChar(MAX), (
select distinct practicearea as [text()]
from #STMAreaManaged
where code not like '%Unknown%'
FOR XML PATH('') )) 

select @STMAreaManagedBusinessLine = CONVERT(VarChar(MAX), (
select distinct businessline as [text()]
from #STMAreaManaged
where code not like '%Unknown%'
FOR XML PATH('') )) 

SELECT @STMAreaManaged = LEFT(@STMAreaManaged, LEN(@STMAreaManaged) - 1),
 @STMAreaManagedcode = LEFT(@STMAreaManagedcode, LEN(@STMAreaManagedcode) - 1), 
 @STMAreaManagedTeam = LEFT(@STMAreaManagedTeam, LEN(@STMAreaManagedTeam) - 1),
 @STMAreaManagedPracticeArea = LEFT(@STMAreaManagedPracticeArea, LEN(@STMAreaManagedPracticeArea) - 1),
 @STMAreaManagedBusinessLine = LEFT(@STMAreaManagedBusinessLine, LEN(@STMAreaManagedBusinessLine) - 1)

DECLARE @HOPAAreaManaged VarChar(MAX);

SELECT @HOPAAreaManaged = CONVERT(VarChar(MAX), (
SELECT '[Fed Hierarchy Business Key].['+RTRIM(CAST(fed_hierarchy_business_key as varchar(150)))+']'+ ','  
 from 
red_dw.dbo.dim_fed_hierarchy_history hierarchy
where hierarchy.dss_current_flag = 'Y'
--and hierarchy.activeud = 1
and hierarchy.hierarchylevel3hist 
IN(
select distinct hier.hierarchylevel3hist
from red_dw.dbo.ds_sh_employee emp
left join
red_dw.dbo.dim_fed_hierarchy_history hier
on UPPER(emp.employeeid) = UPPER(hier.
--worksfor
employeeid)
and hier.dss_current_flag ='Y'
and hier.activeud = 1
where emp.dss_current_flag ='Y'
and hierarchy.dss_current_flag = 'Y'
and emp.windowsusername = @Username
)
  FOR XML PATH('')
))
SELECT @HOPAAreaManaged = LEFT(@HOPAAreaManaged, LEN(@HOPAAreaManaged) - 1)

DECLARE @OperationsManagersAreaManaged VarChar(MAX);

SELECT @OperationsManagersAreaManaged = CONVERT(VarChar(MAX), (

SELECT '[Fed Hierarchy Business Key].['+RTRIM(CAST(fed_hierarchy_business_key as varchar(150)))+']'+ ','  
 from 
red_dw.dbo.dim_fed_hierarchy_history hierarchy
where hierarchy.dss_current_flag = 'Y'
--and hierarchy.activeud = 1

--and hierarchy.hierarchylevel2hist 
--IN(
--select distinct hier.hierarchylevel2hist
--from red_dw.dbo.ds_sh_employee emp
--left join
--red_dw.dbo.dim_fed_hierarchy_history hier
--on UPPER(emp.employeeid) = UPPER(hier.employeeid)
--and hier.dss_current_flag ='Y'
--and hier.activeud = 1
--where emp.dss_current_flag ='Y'
--and emp.windowsusername = @Username
--)
and (hierarchy.hierarchylevel4hist 
IN
(
select distinct hierarchylevel4hist
from
(
select  hier.hierarchylevel4hist
from red_dw.dbo.ds_sh_employee emp
left join
red_dw.dbo.dim_fed_hierarchy_history hier
on UPPER(emp.employeeid) = UPPER(hier.worksforemployeeid)
and hier.dss_current_flag ='Y'
and hier.activeud = 1
where emp.dss_current_flag ='Y'
and emp.windowsusername = @Username
union all
select hist1.hierarchylevel4hist from red_dw.dbo.dim_fed_hierarchy_history hist1
where 
hist1.dss_current_flag = 'Y'
and hist1.activeud = 1
and
hist1.worksforemployeeid in (
select hist.employeeid from red_dw.dbo.dim_fed_hierarchy_history hist
inner join red_dw.dbo.ds_sh_employee emp on upper(hist.worksforemployeeid) = upper(emp.employeeid) and emp.windowsusername = @Username and emp.dss_current_flag ='Y'
where jobtitle = 'Assistant Operations Manager'
and hist.dss_current_flag ='Y'
and hist.activeud = 1)

) as subset) )



  FOR XML PATH('')
))
SELECT @OperationsManagersAreaManaged = LEFT(@OperationsManagersAreaManaged, LEN(@OperationsManagersAreaManaged) - 1)


--DECLARE @ReportsDirectly VarChar(MAX);

--SELECT @ReportsDirectly = CONVERT(VarChar(MAX), (
--  SELECT '[Dim_Fed_Hierarchy_History].[Fed Hierarchy Business Key].['+CAST(fed_hierarchy_business_key as varchar(150))+']'+ ','  
--  from 
--  red_dw.dbo.ds_sh_employee emp
--		left join
--		red_dw.dbo.dim_fed_hierarchy_history hier
--		on upper(emp.employeeid) = upper(hier.reportingbcmidud)
--		or upper(emp.employeeid) = upper(hier.worksforemployeeid)
--		where hier.dss_current_flag ='Y'
--		and hier.activeud = 1
--		and emp.dss_current_flag ='Y'
--		and emp.windowsusername =  @Username
--  FOR XML PATH('')
--))
--SELECT @ReportsDirectly = LEFT(@ReportsDirectly, LEN(@ReportsDirectly) - 1)

IF OBJECT_ID('tempdb..#temphierarchy') IS NOT NULL 
DROP TABLE #temphierarchy

	CREATE TABLE #temphierarchy
    (
      [LevelID] int,
      [Level] VARCHAR(100),
	  [SecurityLevel] VARCHAR(100),
	  [CubeMember] VARCHAR(MAX)
    )

	INSERT INTO #temphierarchy
	  (
      [LevelID],
      [Level],
	  [SecurityLevel],
	  [CubeMember]
	  )

select distinct
CASE WHEN
Name = 'People - Directors and Partners' THEN 1
WHEN
Name = 'People - All Consultants' THEN 1
WHEN
Name = 'SSRS - Dev_ReportsAdmin' THEN 1
WHEN
Name = 'Restricted - Operations - Finance' THEN 1
WHEN
Name = 'Restricted - Operations - Risk & Compliance' THEN 1
WHEN
Name = 'Restricted - Operations - Marketing' THEN 1
WHEN
Name = 'Restricted - Operations - HR&D' THEN 1
WHEN
Name = 'People - All PAs' THEN 1
WHEN
Name = 'Reports_Testers' THEN 1
WHEN
Name = 'People - Governance staff' THEN 1
WHEN
Name = 'People - All Operations Managers' THEN 2
WHEN
Name = 'People - All HOPAs' THEN 3
WHEN 
name = 'People - Support Team Managers' THEN 4
WHEN
Name = 'People - All BCMs' THEN 4
WHEN
Name = 'People - Assistant Operations Managers' THEN 4
WHEN
Name = 'People - Team Leaders' THEN 4
ELSE 6 END
as [LevelID],
CASE WHEN
Name = 'People - Directors and Partners' THEN 'Directors and Partners'
WHEN
Name = 'People - All Consultants' THEN 'Directors and Partners'
WHEN
Name = 'SSRS - Dev_ReportsAdmin' THEN 'Directors and Partners'
WHEN
Name = 'Restricted - Operations - Finance' THEN 'Directors and Partners'
WHEN
Name = 'Restricted - Operations - Risk & Compliance' THEN 'Directors and Partners'
WHEN
Name = 'Restricted - Operations - Marketing' THEN 'Directors and Partners'
WHEN
Name = 'Restricted - Operations - HR&D' THEN 'Directors and Partners'
WHEN
Name = 'Reports_Testers' THEN 'Directors and Partners'
WHEN
Name = 'People - All PAs' THEN 'Directors and Partners'
WHEN
Name = 'People - Governance staff' THEN 'Directors and Partners'
WHEN
Name = 'People - All Operations Managers' THEN 'Operations Managers'
WHEN
Name = 'People - All HOPAs' THEN 'HOPA'
WHEN 
name = 'People - Support Team Managers' THEN 'Support Team Mangers'
WHEN
Name = 'People - All BCMs' THEN 'BCM'
WHEN
Name = 'People - Assistant Operations Managers' THEN 'BCM'
WHEN
Name = 'People - Team Leaders' THEN 'BCM'
ELSE 'Everyone' END
as [Level],
CASE WHEN
Name = 'People - Directors and Partners' THEN 'Firm'
WHEN
Name = 'People - All Consultants' THEN 'Firm'
WHEN
Name = 'SSRS - Dev_ReportsAdmin' THEN 'Firm'
WHEN
Name = 'Restricted - Operations - Finance' THEN 'Firm'
WHEN
Name = 'Restricted - Operations - Risk & Compliance' THEN 'Firm'
WHEN
Name = 'Restricted - Operations - Marketing' THEN 'Firm'
WHEN
Name = 'Restricted - Operations - HR&D' THEN 'Firm'
WHEN
Name = 'Reports_Testers' THEN 'Firm'
WHEN
Name = 'People - All PAs' THEN 'Firm'
WHEN
Name = 'People - Governance staff' THEN 'Firm'
WHEN
Name = 'People - All Operations Managers' THEN 'Area Managed'
WHEN
Name = 'People - All HOPAs' THEN 'Area Managed'
WHEN 
name = 'People - Support Team Managers' THEN 'Area Managed'
WHEN
Name = 'People - All BCMs' THEN 'Area Managed'
WHEN
Name = 'People - Assistant Operations Managers' THEN 'Area Managed'
WHEN
Name = 'People - Team Leaders' THEN 'Area Managed'
ELSE 'Individual' END
as [SecurityLevel],
CASE WHEN
Name = 'People - Directors and Partners' THEN '[Dim_Fed_Hierarchy_History].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'People - All Consultants' THEN '[Dim_Fed_Hierarchy_History].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'SSRS - Dev_ReportsAdmin' THEN '[Dim_Fed_Hierarchy_History].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'Restricted - Operations - Finance' THEN '[Dim_Fed_Hierarchy_History].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'Restricted - Operations - Risk & Compliance' THEN '[Dim_Fed_Hierarchy_History].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'Restricted - Operations - Marketing' THEN '[Dim_Fed_Hierarchy_History].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'Restricted - Operations - HR&D' THEN '[Dim_Fed_Hierarchy_History].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'Reports_Testers' THEN '[Dim_Fed_Hierarchy_History].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'People - All PAs' THEN '[Dim_Fed_Hierarchy_History].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'People - Governance staff' THEN '[Dim_Fed_Hierarchy_History].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'People - All Operations Managers' THEN REPLACE(REPLACE(@OperationsManagersAreaManaged,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - All HOPAs' THEN REPLACE(REPLACE(@HOPAAreaManaged,'&gt;','>'),'&amp;','&')
WHEN 
name = 'People - Support Team Managers' THEN REPLACE(REPLACE(@STMAreaManaged,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - All BCMs' THEN REPLACE(REPLACE(@BCMAreaManaged,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Assistant Operations Managers' THEN REPLACE(REPLACE(@BCMAreaManaged,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Team Leaders' THEN REPLACE(REPLACE(@BCMAreaManaged,'&gt;','>'),'&amp;','&')
ELSE
@Individual
--0
END
as [CubeMember]
 from #temp

--if (
--    select count(*)
--	from 
--  red_dw.dbo.ds_sh_employee emp
--		left join
--		red_dw.dbo.dim_fed_hierarchy_history hier
--		on emp.employeeid = hier.reportingbcmidud
--		or emp.employeeid = hier.worksforemployeeid
--		where hier.dss_current_flag ='Y'
--		and hier.activeud = 1
--		and emp.dss_current_flag ='Y'
--		and emp.windowsusername =  @Username)>0
		
--	begin

--      INSERT INTO #temphierarchy
--	  (
--      [LevelID],
--      [Level],
--	  [SecurityLevel],
--	  [CubeMember]
--	  )
--	  VALUES
--	  (5,'Manager','Reports Directly To User',CONVERT(VarChar(MAX), (@ReportsDirectly)))
--	  end

select * 
from 
(
select 
RANK() OVER ( PARTITION BY a.SecurityLevel ORDER BY a.LevelID ASC ) [RNK] ,
*
from #temphierarchy a
) as a where RNK = 1
order by LevelID

--PRINT @ReportsDirectly

GO
GRANT EXECUTE ON  [dbo].[Dynamic_Hierarchy_Security] TO [db_ssrs_dynamicsecurity]
GO
GRANT EXECUTE ON  [dbo].[Dynamic_Hierarchy_Security] TO [lnksvrdatareader]
GO
GRANT EXECUTE ON  [dbo].[Dynamic_Hierarchy_Security] TO [SBC\SQL - DataReader on SVR-LIV-DWH-01_Limited]
GO

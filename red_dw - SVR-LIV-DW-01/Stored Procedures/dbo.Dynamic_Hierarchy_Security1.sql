SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--USE [red_dw]
--GO
--/****** Object:  StoredProcedure [dbo].[Dynamic_Hierarchy_Security1]    Script Date: 14/10/2015 12:12:27 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO



----[dbo].[Dynamic_Hierarchy_Security1] 'sgitto'

CREATE PROCEDURE [dbo].[Dynamic_Hierarchy_Security1] --'5755'

@Username NVARCHAR(256) = NULL--,
--@Date AS DATE = CAST(GETDATE() AS DATE))
--@BusinessLine NVARCHAR(Max) = null

AS



--DECLARE @Username NVARCHAR(256) = 'eburke'
DECLARE   @StartDate AS DATE
Declare   @EndDate AS Date

SELECT @StartDate = MIN(calendar_date), @EndDate = MAX(calendar_date)

FROM [red_dw].[dbo].dim_date

WHERE fin_year =
(
SELECT [fin_year]
FROM [red_dw].[dbo].dim_date
WHERE calendar_date = CAST(GETDATE() AS DATE))


DECLARE @Query NVARCHAR(MAX) ,
    @Path NVARCHAR(1024), 
    @Query2 NVARCHAR(MAX), 
    @Path2 NVARCHAR(1024)
       
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
  
PRINT @Query  
          
              
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

IF OBJECT_ID('tempdb..#Individual') IS NOT NULL 

DROP TABLE #Individual


CREATE TABLE #Individual
    (
      complexcode VARCHAR(MAX) ,
    code VARCHAR(MAX) ,
    team VARCHAR(MAX) ,
    practicearea VARCHAR(MAX) ,
    businessline VARCHAR(MAX) ,
	complexhierarchy VARCHAR(MAX)
      
    )

  INSERT  INTO #Individual
   


  SELECT '[Dim Fed Hierarchy History].[Fed Hierarchy Business Key].['+RTRIM(CAST(fed_hierarchy_business_key as varchar(150)))+']'+ ',' complexcode , 
  rtrim(fed_hierarchy_business_key) + ',' as code, 
  hierarchylevel4hist + ',' as team, 
  hierarchylevel3hist + ',' as practicearea, 
  hierarchylevel2hist + ',' as businessline,
  '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].&['+display_name+']&[]&['+ISNULL(hierarchylevel5hist,'') + ']&['+hierarchylevel4hist+']&['+hierarchylevel3hist+']&['+hierarchylevel2hist+']&['+hierarchylevel1hist+']' +',' AS complexhierarchy

  --hier.fed_hierarchy_business_key, hier.hierarchylevel4hist,hier.hierarchylevel3hist,hier.hierarchylevel2hist,ROW_NUMBER() OVER (PARTITION BY emp.windowsusername ORDER BY hier.activeud desc) onerowfilter
  FROM 
red_dw.dbo.ds_sh_employee emp
left join
red_dw.dbo.dim_fed_hierarchy_history hier
on emp.employeeid = hier.employeeid
where 
-----------Changed 20161208 - 1553 - commented out the first two clauses
--emp.dss_current_flag ='Y'
--and hier.dss_current_flag ='Y' and
emp.windowsusername = @Username


DECLARE @Individual VarChar(MAX), @Individualcode VarChar(MAX), @IndividualTeam varchar(max), @IndividualPracticeArea varchar(max), @IndividualBusinessLine varchar(max), @IndividualHierarchyCode varchar(MAX);


select @Individual = CONVERT(VarChar(MAX), (
select  complexcode as [text()]
from #Individual
FOR XML PATH('') )) 
 
   

select @Individualcode = CONVERT(VarChar(MAX), (
select  code  as [text()]
from #Individual
where code not like '%Unknown%'
FOR XML PATH('') )) 

select @IndividualTeam = CONVERT(VarChar(MAX), (
select distinct team as [text()]
from #Individual
where code not like '%Unknown%'
FOR XML PATH('') )) 

select @IndividualPracticeArea = CONVERT(VarChar(MAX), (
select distinct practicearea as [text()]
from #Individual
where code not like '%Unknown%'
FOR XML PATH('') )) 

select @IndividualBusinessLine = CONVERT(VarChar(MAX), (
select distinct businessline as [text()]
from #Individual
where code not like '%Unknown%'
FOR XML PATH('') )) 

select @IndividualHierarchyCode = CONVERT(VarChar(MAX), (
select distinct complexhierarchy as [text()]
from #Individual
where code not like '%Unknown%'
FOR XML PATH('') )) 




SELECT @Individual = LEFT(@Individual, LEN(@Individual) - 1),
 @Individualcode = LEFT(@Individualcode, LEN(@Individualcode) - 1), 
 @IndividualTeam = LEFT(@IndividualTeam, LEN(@IndividualTeam) - 1),
 @IndividualPracticeArea = LEFT(@IndividualPracticeArea, LEN(@IndividualPracticeArea) - 1),
 @IndividualBusinessLine = LEFT(@IndividualBusinessLine, LEN(@IndividualBusinessLine) - 1),
  @IndividualHierarchyCode = LEFT(@IndividualHierarchyCode, LEN(@IndividualHierarchyCode) - 1)




IF OBJECT_ID('tempdb..#BCMAreaManaged') IS NOT NULL 

DROP TABLE #BCMAreaManaged


CREATE TABLE #BCMAreaManaged
    (
      complexcode VARCHAR(MAX) ,
    code VARCHAR(MAX) ,
    team VARCHAR(MAX) ,
    practicearea VARCHAR(MAX) ,
    businessline VARCHAR(MAX)  ,
	complexhierarchy VARCHAR(MAX)
      
    )

  INSERT  INTO #BCMAreaManaged
   
SELECT DISTINCT '[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].['+RTRIM(CAST(fed_hierarchy_business_key as varchar(150)))+']'+ ','  as complexcode,  rtrim(fed_code) + ',' as code , hierarchylevel4hist + ',' as team, hierarchylevel3hist + ',' as practicearea, hierarchylevel2hist +',' as businessline,
  '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].&['+display_name+']&[]&['+ISNULL(hierarchylevel5hist,'') + ']&['+hierarchylevel4hist+']&['+hierarchylevel3hist+']&['+hierarchylevel2hist+']&['+hierarchylevel1hist+']' +',' AS complexhierarchy
 from 
red_dw.dbo.dim_fed_hierarchy_history hierarchy
where (hierarchy.dss_current_flag = 'Y')
--OR
--dss_start_date BETWEEN @StartDate AND @EndDate

--OR dss_end_date BETWEEN @StartDate AND @EndDate)
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


DECLARE @BCMAreaManaged VarChar(MAX), @BCMAreaManagedcode VarChar(MAX), @BCMAreaManagedTeam varchar(max), @BCMAreaManagedPracticeArea varchar(max), @BCMAreaManagedBusinessLine varchar(max)
, @BCMAreaManagedHierarchyCode varchar(MAX);



select @BCMAreaManaged = CONVERT(VarChar(MAX), (
select  complexcode as [text()]
from #BCMAreaManaged
FOR XML PATH('') )) 
 
   

select @BCMAreaManagedcode = CONVERT(VarChar(MAX), (
select  code  as [text()]
from #BCMAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 

select @BCMAreaManagedTeam = CONVERT(VarChar(MAX), (
select distinct team as [text()]
from #BCMAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 

select @BCMAreaManagedPracticeArea = CONVERT(VarChar(MAX), (
select distinct practicearea as [text()]
from #BCMAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 

select @BCMAreaManagedBusinessLine = CONVERT(VarChar(MAX), (
select distinct businessline as [text()]
from #BCMAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 

select @BCMAreaManagedHierarchyCode = CONVERT(VarChar(MAX), (
select distinct complexhierarchy as [text()]
from #BCMAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 




SELECT @BCMAreaManaged = LEFT(@BCMAreaManaged, LEN(@BCMAreaManaged) - 1),
 @BCMAreaManagedcode = LEFT(@BCMAreaManagedcode, LEN(@BCMAreaManagedcode) - 1), 
 @BCMAreaManagedTeam = LEFT(@BCMAreaManagedTeam, LEN(@BCMAreaManagedTeam) - 1),
 @BCMAreaManagedPracticeArea = LEFT(@BCMAreaManagedPracticeArea, LEN(@BCMAreaManagedPracticeArea) - 1),
 @BCMAreaManagedBusinessLine = LEFT(@BCMAreaManagedBusinessLine, LEN(@BCMAreaManagedBusinessLine) - 1),
 @BCMAreaManagedHierarchyCode = LEFT(@BCMAreaManagedHierarchyCode, LEN(@BCMAreaManagedHierarchyCode) - 1)



IF OBJECT_ID('tempdb..#HOPAAreaManaged') IS NOT NULL 

DROP TABLE #HOPAAreaManaged


CREATE TABLE #HOPAAreaManaged
    (
      complexcode VARCHAR(MAX) ,
    code VARCHAR(MAX) ,
    team VARCHAR(MAX) ,
    practicearea VARCHAR(MAX) ,
    businessline VARCHAR(MAX)  ,
	complexhierarchy VARCHAR(MAX)
      
    )

  INSERT  INTO #HOPAAreaManaged



SELECT  DISTINCT  '[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].['+RTRIM(CAST(fed_hierarchy_business_key as varchar(150)))+']'+ ','  as complexcode,  rtrim(fed_code) + ',' as code, hierarchylevel4hist + ',' as team, hierarchylevel3hist + ',' as practicearea, hierarchylevel2hist + ',' as businessline,
  '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].&['+display_name+']&[]&['+ISNULL(hierarchylevel5hist,'') + ']&['+hierarchylevel4hist+']&['+hierarchylevel3hist+']&['+hierarchylevel2hist+']&['+hierarchylevel1hist+']' +',' AS complexhierarchy
 from 
red_dw.dbo.dim_fed_hierarchy_history hierarchy
where (hierarchy.dss_current_flag = 'Y'
OR
dss_start_date BETWEEN @StartDate AND @EndDate

OR dss_end_date BETWEEN @StartDate AND @EndDate)
--and hierarchy.activeud = 1
and hierarchy.hierarchylevel3hist 
IN(
select distinct hier.hierarchylevel3 -- changed to the actual practice area the HOPA sits in as people without an active fed code would not work.
--hier.hierarchylevel3hist
from red_dw.dbo.ds_sh_employee emp
left join
red_dw.dbo.dim_fed_hierarchy_history hier
on UPPER(emp.employeeid) = UPPER(hier.
--worksfor
employeeid)
and hier.dss_current_flag ='Y'
--and hier.activeud = 1 --removed as causing problems with HOPAs who do not have an active fed code.
where emp.dss_current_flag ='Y'
--and hierarchy.dss_current_flag = 'Y'
and emp.windowsusername = @Username
)
  
DECLARE @HOPAAreaManaged VarChar(MAX), @HOPAAreaManagedcode VarChar(MAX), @HOPAAreaManagedTeam varchar(max), @HOPAAreaManagedPracticeArea varchar(max), @HOPAAreaManagedBusinessLine varchar(max),
@HOPAAreaManagedHierarchyCode  varchar(max);



select @HOPAAreaManaged = CONVERT(VarChar(MAX), (
select  complexcode as [text()]
from #HOPAAreaManaged
FOR XML PATH('') )) 
 
   

select @HOPAAreaManagedcode = CONVERT(VarChar(MAX), (
select  code  as [text()]
from #HOPAAreaManaged
--Inner Join #BusinessLineFilter on #HOPAAreaManaged.businessline = #BusinessLineFilter.businessline
--where code not like '%Unknown%'
FOR XML PATH('') )) 

select @HOPAAreaManagedTeam = CONVERT(VarChar(MAX), (
select distinct team as [text()]
from #HOPAAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 

select @HOPAAreaManagedPracticeArea = CONVERT(VarChar(MAX), (
select distinct practicearea as [text()]
from #HOPAAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 

select @HOPAAreaManagedBusinessLine = CONVERT(VarChar(MAX), (
select distinct businessline as [text()]
from #HOPAAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 

select @HOPAAreaManagedHierarchyCode = CONVERT(VarChar(MAX), (
select distinct complexhierarchy as [text()]
from #HOPAAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 





SELECT @HOPAAreaManaged = LEFT(@HOPAAreaManaged, LEN(@HOPAAreaManaged) - 1),
 @HOPAAreaManagedcode = LEFT(@HOPAAreaManagedcode, LEN(@HOPAAreaManagedcode) - 1), 
 @HOPAAreaManagedTeam = LEFT(@HOPAAreaManagedTeam, LEN(@HOPAAreaManagedTeam) - 1),
 @HOPAAreaManagedPracticeArea = LEFT(@HOPAAreaManagedPracticeArea, LEN(@HOPAAreaManagedPracticeArea) - 1),
 @HOPAAreaManagedBusinessLine = LEFT(@HOPAAreaManagedBusinessLine, LEN(@HOPAAreaManagedBusinessLine) - 1),
 @HOPAAreaManagedHierarchyCode = LEFT(@HOPAAreaManagedHierarchyCode, LEN(@HOPAAreaManagedHierarchyCode) - 1)
 


IF OBJECT_ID('tempdb..#OperationsManagerAreaManaged') IS NOT NULL 

DROP TABLE #OperationsManagerAreaManaged


CREATE TABLE #OperationsManagerAreaManaged
    (
      complexcode VARCHAR(MAX) ,
    code VARCHAR(MAX) ,
    team VARCHAR(MAX) ,
    practicearea VARCHAR(MAX) ,
    businessline VARCHAR(MAX)  ,
	complexhierarchy VARCHAR(MAX)
      
    )

  INSERT  INTO #OperationsManagerAreaManaged





SELECT DISTINCT  '[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].['+RTRIM(CAST(fed_hierarchy_business_key as varchar(150)))+']'+ ','  as complexcode,  rtrim(fed_code) + ','  as code, hierarchylevel4hist + ',' as team, hierarchylevel3hist + ',' as practicearea, hierarchylevel2hist + ',' as businessline,
  '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].&['+display_name+']&[]&['+ISNULL(hierarchylevel5hist,'') + ']&['+hierarchylevel4hist+']&['+hierarchylevel3hist+']&['+hierarchylevel2hist+']&['+hierarchylevel1hist+']' +',' AS complexhierarchy
 from 
red_dw.dbo.dim_fed_hierarchy_history hierarchy
where (hierarchy.dss_current_flag = 'Y'
OR
dss_start_date BETWEEN @StartDate AND @EndDate

OR dss_end_date BETWEEN @StartDate AND @EndDate)
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



DECLARE @OperationsManagerAreaManaged VarChar(MAX), @OperationsManagerAreaManagedcode VarChar(MAX), @OperationsManagerAreaManagedTeam varchar(max), @OperationsManagerAreaManagedPracticeArea varchar(max), @OperationsManagerAreaManagedBusinessLine varchar(max),
@OperationsManagerAreaManagedHierarchyCode varchar(MAX);

select @OperationsManagerAreaManaged = CONVERT(VarChar(MAX), (
select  complexcode as [text()]
from #OperationsManagerAreaManaged
FOR XML PATH('') )) 
 
   

select @OperationsManagerAreaManagedcode = CONVERT(VarChar(MAX), (
select  code  as [text()]
from #OperationsManagerAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 

select @OperationsManagerAreaManagedTeam = CONVERT(VarChar(MAX), (
select  distinct team as [text()]
from #OperationsManagerAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 

select @OperationsManagerAreaManagedPracticeArea = CONVERT(VarChar(MAX), (
select  distinct practicearea as [text()]
from #OperationsManagerAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 

select @OperationsManagerAreaManagedBusinessLine = CONVERT(VarChar(MAX), (
select  distinct businessline as [text()]
from #OperationsManagerAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 

select @OperationsManagerAreaManagedHierarchyCode = CONVERT(VarChar(MAX), (
select  distinct complexhierarchy as [text()]
from #OperationsManagerAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 





SELECT @OperationsManagerAreaManaged = LEFT(@OperationsManagerAreaManaged, LEN(@OperationsManagerAreaManaged) - 1),
 @OperationsManagerAreaManagedcode = LEFT(@OperationsManagerAreaManagedcode, LEN(@OperationsManagerAreaManagedcode) - 1), 
 @OperationsManagerAreaManagedTeam = LEFT(@OperationsManagerAreaManagedTeam, LEN(@OperationsManagerAreaManagedTeam) - 1),
 @OperationsManagerAreaManagedPracticeArea = LEFT(@OperationsManagerAreaManagedPracticeArea, LEN(@OperationsManagerAreaManagedPracticeArea) - 1),
 @OperationsManagerAreaManagedBusinessLine = LEFT(@OperationsManagerAreaManagedBusinessLine, LEN(@OperationsManagerAreaManagedBusinessLine) - 1),
 @OperationsManagerAreaManagedHierarchyCode = LEFT(@OperationsManagerAreaManagedHierarchyCode, LEN(@OperationsManagerAreaManagedHierarchyCode) - 1)
 


 /*JC 05/08/2015 - Added Support Team Manager Level*/
IF OBJECT_ID('tempdb..#STMAreaManaged') IS NOT NULL 

DROP TABLE #STMAreaManaged


CREATE TABLE #STMAreaManaged
    (
      complexcode VARCHAR(MAX) ,
    code VARCHAR(MAX) ,
    team VARCHAR(MAX) ,
    practicearea VARCHAR(MAX) ,
    businessline VARCHAR(MAX)  ,
	complexhierarchy VARCHAR(MAX)
      
    )

  INSERT  INTO #STMAreaManaged
   
SELECT  DISTINCT '[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].['+RTRIM(CAST(fed_hierarchy_business_key as varchar(150)))+']'+ ','  as complexcode,  rtrim(fed_code) + ',' as code , hierarchylevel4hist + ',' as team, hierarchylevel3hist + ',' as practicearea, hierarchylevel2hist +',' as businessline,
  '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].&['+display_name+']&[]&['+ISNULL(hierarchylevel5hist,'') + ']&['+hierarchylevel4hist+']&['+hierarchylevel3hist+']&['+hierarchylevel2hist+']&['+hierarchylevel1hist+']' +',' AS complexhierarchy
 from 
red_dw.dbo.dim_fed_hierarchy_history hierarchy
where (hierarchy.dss_current_flag = 'Y'
OR
dss_start_date BETWEEN @StartDate AND @EndDate

OR dss_end_date BETWEEN @StartDate AND @EndDate)
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


DECLARE @STMAreaManaged VarChar(MAX), @STMAreaManagedcode VarChar(MAX), @STMAreaManagedTeam varchar(max), @STMAreaManagedPracticeArea varchar(max), @STMAreaManagedBusinessLine varchar(max),
@STMAreaManagedHierarchyCode varchar(MAX);

select @STMAreaManaged = CONVERT(VarChar(MAX), (
select  complexcode as [text()]
from #STMAreaManaged
FOR XML PATH('') )) 
 
   

select @STMAreaManagedcode = CONVERT(VarChar(MAX), (
select  code  as [text()]
from #STMAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 

select @STMAreaManagedTeam = CONVERT(VarChar(MAX), (
select distinct team as [text()]
from #STMAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 

select @STMAreaManagedPracticeArea = CONVERT(VarChar(MAX), (
select distinct practicearea as [text()]
from #STMAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 

select @STMAreaManagedBusinessLine = CONVERT(VarChar(MAX), (
select distinct businessline as [text()]
from #STMAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 

select @STMAreaManagedHierarchyCode = CONVERT(VarChar(MAX), (
select distinct complexhierarchy as [text()]
from #STMAreaManaged
--where code not like '%Unknown%'
FOR XML PATH('') )) 




SELECT @STMAreaManaged = LEFT(@STMAreaManaged, LEN(@STMAreaManaged) - 1),
 @STMAreaManagedcode = LEFT(@STMAreaManagedcode, LEN(@STMAreaManagedcode) - 1), 
 @STMAreaManagedTeam = LEFT(@STMAreaManagedTeam, LEN(@STMAreaManagedTeam) - 1),
 @STMAreaManagedPracticeArea = LEFT(@STMAreaManagedPracticeArea, LEN(@STMAreaManagedPracticeArea) - 1),
 @STMAreaManagedBusinessLine = LEFT(@STMAreaManagedBusinessLine, LEN(@STMAreaManagedBusinessLine) - 1),
 @STMAreaManagedHierarchyCode = LEFT(@STMAreaManagedHierarchyCode, LEN(@STMAreaManagedHierarchyCode) - 1)

 
IF OBJECT_ID('tempdb..#Firm') IS NOT NULL 

DROP TABLE #Firm


CREATE TABLE #Firm
    (
      complexcode VARCHAR(MAX) ,
    code VARCHAR(MAX) ,
    team VARCHAR(MAX) ,
    practicearea VARCHAR(MAX) ,
    businessline VARCHAR(MAX)  ,
	complexhierarchy VARCHAR(MAX)
      
    )

  INSERT  INTO #Firm





SELECT  DISTINCT  '[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].['+RTRIM(CAST(fed_hierarchy_business_key as varchar(150)))+']'+ ','  as complexcode,  rtrim(fed_code) + ','  as code, hierarchylevel4hist + ',' as team, hierarchylevel3hist + ',' as practicearea, hierarchylevel2hist + ',' as businessline,
  '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].&['+display_name+']&[]&['+ISNULL(hierarchylevel5hist,'') + ']&['+hierarchylevel4hist+']&['+hierarchylevel3hist+']&['+hierarchylevel2hist+']&['+hierarchylevel1hist+']' +',' AS complexhierarchy
 from 
red_dw.dbo.dim_fed_hierarchy_history hierarchy
where hierarchy.dss_current_flag = 'Y'
--and hierarchy.activeud = 1




DECLARE @Firmcode VarChar(MAX), @FirmTeam varchar(max), @FirmPracticeArea varchar(max), @FirmBusinessLine varchar(max),
@FirmHierarchyCode varchar(MAX)
;


select @Firmcode = CONVERT(VarChar(MAX), (
select  code  as [text()]
from #Firm
where code not like '%Unknown%'
FOR XML PATH('') )) 

select @FirmTeam = CONVERT(VarChar(MAX), (
select distinct team as [text()]
from #Firm
where code not like '%Unknown%'
FOR XML PATH('') )) 

select @FirmPracticeArea = CONVERT(VarChar(MAX), (
select distinct practicearea as [text()]
from #Firm
where code not like '%Unknown%'
FOR XML PATH('') )) 

select @FirmBusinessLine = CONVERT(VarChar(MAX), (
select  distinct businessline as [text()]
from #Firm
where code not like '%Unknown%'
FOR XML PATH('') )) 

select @FirmHierarchyCode = CONVERT(VarChar(MAX), (
select  distinct complexhierarchy as [text()]
from #Firm
where code not like '%Unknown%'
FOR XML PATH('') )) 




SELECT
 @Firmcode = LEFT(@Firmcode, LEN(@Firmcode) - 1), 
 @FirmTeam = LEFT(@FirmTeam, LEN(@FirmTeam) - 1),
 @FirmPracticeArea = LEFT(@FirmPracticeArea, LEN(@FirmPracticeArea) - 1),
 @FirmBusinessLine = LEFT(@FirmBusinessLine, LEN(@FirmBusinessLine) - 1),
 @FirmHierarchyCode = LEFT(@FirmHierarchyCode, LEN(@FirmHierarchyCode) - 1)
 

 IF OBJECT_ID('tempdb..#temphierarchy') IS NOT NULL 
DROP TABLE #temphierarchy

  CREATE TABLE #temphierarchy
    (
      [LevelID] int,
      [Level] VARCHAR(100),
    [SecurityLevel] VARCHAR(100),
    [CubeMember] VARCHAR(MAX),
    [FedCodes] VARCHAR(MAX),
    [Teams] VARCHAR(MAX),
    [PracticeAreas] VARCHAR(MAX),
    [BusinessLines] VARCHAR(MAX),
	[HierarchyCode] VARCHAR(MAX)
    )

  INSERT INTO #temphierarchy
    (
      [LevelID],
      [Level],
    [SecurityLevel],
    [CubeMember],
    [FedCodes],
    [Teams],
    [PracticeAreas],
    [BusinessLines],
	[HierarchyCode]
    )

select distinct
CASE WHEN
Name = 'People - Directors and Partners' THEN 1
WHEN
Name = 'Head of Business Services' THEN 1
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
Name = 'CascadeDepartment - Business Process' then 1
WHEN
Name = 'People - All PAs' THEN 1
WHEN
Name = 'Reports_Testers' THEN 1
WHEN
Name = 'People - Governance staff' THEN 1
WHEN
Name = 'People - All Operations Managers' THEN 2
WHEN
Name = 'People - Heads of Service Delivery and Directors' THEN 4
WHEN
Name = 'People - Claims Management Department' THEN 4
WHEN
Name = 'People - LTA Management' THEN 4
WHEN
Name = 'People - Sector Leads' THEN 3
WHEN
name = 'People - Support Team Managers' THEN 4
WHEN
Name = 'People - All BCMs' THEN 4
WHEN
Name = 'People - Assistant Operations Managers' THEN 4
WHEN
Name = 'People - Team Leaders' THEN 4
WHEN
Name = 'People - Team Managers' THEN 4
ELSE 6 END
as [LevelID],
CASE WHEN
Name = 'People - Directors and Partners' THEN 'Directors and Partners'
WHEN
Name = 'Head of Business Services' THEN 'Directors and Partners'
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
Name = 'CascadeDepartment - Business Process' then 'Directors and Partners'
WHEN
Name = 'Reports_Testers' THEN 'Directors and Partners'
WHEN
Name = 'People - All PAs' THEN 'Directors and Partners'
WHEN
Name = 'People - Governance staff' THEN 'Directors and Partners'
WHEN
Name = 'People - All Operations Managers' THEN 'Operations Managers'
WHEN
Name = 'People - Heads of Service Delivery and Directors' THEN 'BCM'
WHEN
Name = 'People - Claims Management Department' THEN 'BCM'
WHEN
Name = 'People - LTA Management' THEN 'BCM'
WHEN
Name = 'People - Sector Leads' THEN 'HOPA'
WHEN
name = 'People - Support Team Managers' THEN 'Support Team Managers'
WHEN
Name = 'People - All BCMs' THEN 'BCM'
WHEN
Name = 'People - Assistant Operations Managers' THEN 'BCM'
WHEN
Name = 'People - Team Leaders' THEN 'BCM'
WHEN
Name = 'People - Team Managers' THEN 'BCM'
ELSE 'Everyone' END
as [Level],
CASE WHEN
Name = 'People - Directors and Partners' THEN 'Firm'
 WHEN
Name = 'Head of Business Services' THEN 'Firm'
WHEN
Name = 'People - All Consultants' THEN 'Firm'
--
WHEN
Name = 'SQL - MI Team' THEN 'Firm'
--
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
Name = 'CascadeDepartment - Business Process' then 'Firm'
WHEN
Name = 'Reports_Testers' THEN 'Firm'
WHEN
Name = 'People - All PAs' THEN 'Firm'
WHEN
Name = 'People - Governance staff' THEN 'Firm'
WHEN
Name = 'People - All Operations Managers' THEN 'Area Managed'
WHEN
Name = 'People - Heads of Service Delivery and Directors' THEN 'Area Managed'
WHEN
Name = 'People - Claims Management Department' THEN 'Area Managed'
WHEN
Name = 'People - LTA Management' THEN 'Area Managed'
WHEN
Name = 'People - Sector Leads' THEN 'Area Managed'
WHEN 
name = 'People - Support Team Managers' THEN 'Area Managed'
WHEN
Name = 'People - All BCMs' THEN 'Area Managed'
WHEN
Name = 'People - Assistant Operations Managers' THEN 'Area Managed'
WHEN
Name = 'People - Team Leaders' THEN 'Area Managed'
WHEN
Name = 'People - Team Managers' THEN 'Area Managed'
ELSE 'Individual' END
as [SecurityLevel],
CASE WHEN
Name = 'People - Directors and Partners' THEN '[Dim Fed Hierarchy History].[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'Head of Business Services' THEN '[Dim Fed Hierarchy History].[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'People - All Consultants' THEN '[Dim Fed Hierarchy History].[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'SSRS - Dev_ReportsAdmin' THEN '[Dim Fed Hierarchy History].[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].allmembers'

--
WHEN
Name = 'SQL - MI Team' THEN '[Dim Fed Hierarchy History].[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].allmembers'
--

WHEN
Name = 'Restricted - Operations - Finance' THEN '[Dim Fed Hierarchy History].[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'Restricted - Operations - Risk & Compliance' THEN '[Dim Fed Hierarchy History].[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'Restricted - Operations - Marketing' THEN '[Dim Fed Hierarchy History].[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'Restricted - Operations - HR&D' THEN '[Dim Fed Hierarchy History].[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'CascadeDepartment - Business Process' then '[Dim Fed Hierarchy History].[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].allmembers' 
WHEN
Name = 'Reports_Testers' THEN '[Dim Fed Hierarchy History].[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'People - All PAs' THEN '[Dim Fed Hierarchy History].[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'People - Governance staff' THEN '[Dim Fed Hierarchy History].[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].allmembers'
WHEN
Name = 'People - All Operations Managers' THEN REPLACE(REPLACE(@OperationsManagerAreaManaged,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Heads of Service Delivery and Directors' THEN REPLACE(REPLACE(@BCMAreaManaged,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Claims Management Department' THEN REPLACE(REPLACE(@BCMAreaManaged,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - LTA Management' THEN REPLACE(REPLACE(@BCMAreaManaged,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Sector Leads' THEN REPLACE(REPLACE(@HOPAAreaManaged,'&gt;','>'),'&amp;','&')
WHEN 
name = 'People - Support Team Managers' THEN REPLACE(REPLACE(@STMAreaManaged, '&gt;','>'), '&amp;','&')
WHEN
Name = 'People - All BCMs' THEN REPLACE(REPLACE(@BCMAreaManaged,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Assistant Operations Managers' THEN REPLACE(REPLACE(@BCMAreaManaged,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Team Leaders' THEN REPLACE(REPLACE(@BCMAreaManaged,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Team Managers' THEN REPLACE(REPLACE(@BCMAreaManaged,'&gt;','>'),'&amp;','&')
ELSE
@Individual
--0
END
as [CubeMember],
CASE WHEN
Name = 'People - Directors and Partners' THEN REPLACE(REPLACE(@Firmcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Head of Business Services' THEN REPLACE(REPLACE(@Firmcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - All Consultants' THEN REPLACE(REPLACE(@Firmcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'SSRS - Dev_ReportsAdmin' THEN REPLACE(REPLACE(@Firmcode,'&gt;','>'),'&amp;','&')

--
WHEN
Name = 'SQL - MI Team' THEN REPLACE(REPLACE(@Firmcode,'&gt;','>'),'&amp;','&')
--

WHEN
Name = 'Restricted - Operations - Finance' THEN REPLACE(REPLACE(@Firmcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Restricted - Operations - Risk & Compliance' THEN REPLACE(REPLACE(@Firmcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Restricted - Operations - Marketing' THEN REPLACE(REPLACE(@Firmcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Restricted - Operations - HR&D' THEN REPLACE(REPLACE(@Firmcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'CascadeDepartment - Business Process' then  REPLACE(REPLACE(@Firmcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Reports_Testers' THEN REPLACE(REPLACE(@Firmcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - All PAs' THEN REPLACE(REPLACE(@Firmcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Governance staff' THEN REPLACE(REPLACE(@Firmcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - All Operations Managers' THEN REPLACE(REPLACE(@OperationsManagerAreaManagedcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Heads of Service Delivery and Directors' THEN REPLACE(REPLACE(@BCMAreaManagedcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Claims Management Department' THEN REPLACE(REPLACE(@BCMAreaManagedcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - LTA Management' THEN REPLACE(REPLACE(@BCMAreaManagedcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Sector Leads' THEN REPLACE(REPLACE(@HOPAAreaManagedcode,'&gt;','>'),'&amp;','&')
WHEN 
name = 'People - Support Team Managers' THEN REPLACE(REPLACE(@STMAreaManagedcode, '&gt;','>'), '&amp;','&')
WHEN
Name = 'People - All BCMs' THEN REPLACE(REPLACE(@BCMAreaManagedcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Assistant Operations Managers' THEN REPLACE(REPLACE(@BCMAreaManagedcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Team Leaders' THEN REPLACE(REPLACE(@BCMAreaManagedcode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Team Managers' THEN REPLACE(REPLACE(@BCMAreaManagedcode,'&gt;','>'),'&amp;','&')
ELSE @Individualcode end as FedCodes,

CASE WHEN
Name = 'People - Directors and Partners' THEN REPLACE(REPLACE(@FirmTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Head of Business Services' THEN REPLACE(REPLACE(@FirmTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - All Consultants' THEN REPLACE(REPLACE(@FirmTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'SSRS - Dev_ReportsAdmin' THEN REPLACE(REPLACE(@FirmTeam,'&gt;','>'),'&amp;','&')

--
WHEN
Name = 'SQL - MI Team' THEN REPLACE(REPLACE(@FirmTeam,'&gt;','>'),'&amp;','&')
--
WHEN
Name = 'Restricted - Operations - Finance' THEN REPLACE(REPLACE(@FirmTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Restricted - Operations - Risk & Compliance' THEN REPLACE(REPLACE(@FirmTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Restricted - Operations - Marketing' THEN REPLACE(REPLACE(@FirmTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Restricted - Operations - HR&D' THEN REPLACE(REPLACE(@FirmTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'CascadeDepartment - Business Process' then REPLACE(REPLACE(@FirmTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Reports_Testers' THEN REPLACE(REPLACE(@FirmTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - All PAs' THEN REPLACE(REPLACE(@FirmTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Governance staff' THEN REPLACE(REPLACE(@FirmTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - All Operations Managers' THEN REPLACE(REPLACE(@OperationsManagerAreaManagedTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Heads of Service Delivery and Directors' THEN REPLACE(REPLACE(@BCMAreaManagedTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Claims Management Department' THEN REPLACE(REPLACE(@BCMAreaManagedTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - LTA Management' THEN REPLACE(REPLACE(@BCMAreaManagedTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Sector Leads' THEN REPLACE(REPLACE(@HOPAAreaManagedTeam,'&gt;','>'),'&amp;','&')
WHEN
name = 'People - Support Team Managers' THEN REPLACE(REPLACE(@STMAreaManagedTeam, '&gt;','>'),'&amp;','&')
WHEN
Name = 'People - All BCMs' THEN REPLACE(REPLACE(@BCMAreaManagedTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Assistant Operations Managers' THEN REPLACE(REPLACE(@BCMAreaManagedTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Team Leaders' THEN REPLACE(REPLACE(@BCMAreaManagedTeam,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Team Managers' THEN REPLACE(REPLACE(@BCMAreaManagedTeam,'&gt;','>'),'&amp;','&')
ELSE
@IndividualTeam end as Teams,
CASE WHEN
Name = 'People - Directors and Partners' THEN REPLACE(REPLACE(@FirmPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Head of Business Services' THEN REPLACE(REPLACE(@FirmPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - All Consultants' THEN REPLACE(REPLACE(@FirmPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'SSRS - Dev_ReportsAdmin' THEN REPLACE(REPLACE(@FirmPracticeArea,'&gt;','>'),'&amp;','&')

--
WHEN
Name = 'SQL - MI Team' THEN REPLACE(REPLACE(@FirmPracticeArea,'&gt;','>'),'&amp;','&')
--
WHEN
Name = 'Restricted - Operations - Finance' THEN REPLACE(REPLACE(@FirmPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Restricted - Operations - Risk & Compliance' THEN REPLACE(REPLACE(@FirmPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Restricted - Operations - Marketing' THEN REPLACE(REPLACE(@FirmPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Restricted - Operations - HR&D' THEN REPLACE(REPLACE(@FirmPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'CascadeDepartment - Business Process' then REPLACE(REPLACE(@FirmPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Reports_Testers' THEN REPLACE(REPLACE(@FirmPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - All PAs' THEN REPLACE(REPLACE(@FirmPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Governance staff'THEN REPLACE(REPLACE(@FirmPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - All Operations Managers' THEN REPLACE(REPLACE(@OperationsManagerAreaManagedPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name =  'People - Heads of Service Delivery and Directors' THEN REPLACE(REPLACE(@BCMAreaManagedPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Claims Management Department' THEN REPLACE(REPLACE(@BCMAreaManagedPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - LTA Management' THEN REPLACE(REPLACE(@BCMAreaManagedPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Sector Leads' THEN REPLACE(REPLACE(@HOPAAreaManagedPracticeArea,'&gt;','>'),'&amp;','&')
WHEN 
name = 'People - Support Team Managers' THEN REPLACE(REPLACE(@STMAreaManagedPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - All BCMs' THEN REPLACE(REPLACE(@BCMAreaManagedPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Assistant Operations Managers' THEN REPLACE(REPLACE(@BCMAreaManagedPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Team Leaders' THEN REPLACE(REPLACE(@BCMAreaManagedPracticeArea,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Team Managers' THEN REPLACE(REPLACE(@BCMAreaManagedPracticeArea,'&gt;','>'),'&amp;','&')
ELSE
@IndividualPracticeArea end as PracticeAreas,
CASE WHEN
Name = 'People - Directors and Partners' THEN REPLACE(REPLACE(@FirmBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Head of Business Services' THEN REPLACE(REPLACE(@FirmBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - All Consultants' THEN REPLACE(REPLACE(@FirmBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'SSRS - Dev_ReportsAdmin' THEN REPLACE(REPLACE(@FirmBusinessLine,'&gt;','>'),'&amp;','&')

--
WHEN
Name = 'SQL - MI Team' THEN  REPLACE(REPLACE(@FirmBusinessLine,'&gt;','>'),'&amp;','&')
--
WHEN
Name = 'Restricted - Operations - Finance' THEN REPLACE(REPLACE(@FirmBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Restricted - Operations - Risk & Compliance' THEN REPLACE(REPLACE(@FirmBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Restricted - Operations - Marketing' THEN REPLACE(REPLACE(@FirmBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'Restricted - Operations - HR&D' THEN REPLACE(REPLACE(@FirmBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'CascadeDepartment - Business Process' THEN REPLACE(REPLACE(@FirmBusinessLine,'&gt;','>'),'&amp;','&') 
WHEN
Name = 'Reports_Testers' THEN REPLACE(REPLACE(@FirmBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - All PAs' THEN REPLACE(REPLACE(@FirmBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Governance staff'THEN REPLACE(REPLACE(@FirmBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - All Operations Managers' THEN REPLACE(REPLACE(@OperationsManagerAreaManagedBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Heads of Service Delivery and Directors' THEN REPLACE(REPLACE(@BCMAreaManagedBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Claims Management Department' THEN REPLACE(REPLACE(@BCMAreaManagedBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - LTA Management' THEN REPLACE(REPLACE(@BCMAreaManagedBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Sector Leads' THEN REPLACE(REPLACE(@HOPAAreaManagedBusinessLine,'&gt;','>'),'&amp;','&')
WHEN 
name = 'People - Support Team Managers' THEN REPLACE(REPLACE(@STMAreaManagedBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - All BCMs' THEN REPLACE(REPLACE(@BCMAreaManagedBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Assistant Operations Managers' THEN REPLACE(REPLACE(@BCMAreaManagedBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Team Leaders' THEN REPLACE(REPLACE(@BCMAreaManagedBusinessLine,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Team Managers' THEN REPLACE(REPLACE(@BCMAreaManagedBusinessLine,'&gt;','>'),'&amp;','&')
ELSE
@IndividualBusinessLine end as BusinessLines,

CASE WHEN
Name = 'People - Directors and Partners' THEN '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].allmembers'
 WHEN
Name = 'Head of Business Services' THEN '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].allmembers'
WHEN
Name = 'People - All Consultants' THEN '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].allmembers'

--
WHEN
Name = 'SQL - MI Team' THEN  '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].allmembers'
--
WHEN
Name = 'SSRS - Dev_ReportsAdmin' THEN '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].allmembers'
WHEN
Name = 'Restricted - Operations - Finance' THEN '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].allmembers'
WHEN
Name = 'Restricted - Operations - Risk & Compliance' THEN '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].allmembers'
WHEN
Name = 'Restricted - Operations - Marketing' THEN '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].allmembers'
WHEN
Name = 'Restricted - Operations - HR&D' THEN '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].allmembers'
WHEN
Name = 'CascadeDepartment - Business Process' THEN '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].allmembers' 
WHEN
Name = 'Reports_Testers' THEN '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].allmembers'
WHEN
Name = 'People - All PAs' THEN '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].allmembers'
WHEN
Name = 'People - Governance staff' THEN '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].allmembers'
WHEN
Name = 'People - All Operations Managers' THEN REPLACE(REPLACE(@OperationsManagerAreaManagedHierarchyCode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Heads of Service Delivery and Directors' THEN REPLACE(REPLACE(@BCMAreaManagedHierarchyCode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Claims Management Department' THEN REPLACE(REPLACE(@BCMAreaManagedHierarchyCode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - LTA Management' THEN REPLACE(REPLACE(@BCMAreaManagedHierarchyCode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Sector Leads' THEN REPLACE(REPLACE(@HOPAAreaManagedHierarchyCode,'&gt;','>'),'&amp;','&')
WHEN 
name = 'People - Support Team Managers' THEN REPLACE(REPLACE(@STMAreaManagedHierarchyCode, '&gt;','>'), '&amp;','&')
WHEN
Name = 'People - All BCMs' THEN REPLACE(REPLACE(@BCMAreaManagedHierarchyCode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Assistant Operations Managers' THEN REPLACE(REPLACE(@BCMAreaManagedHierarchyCode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Team Leaders' THEN REPLACE(REPLACE(@BCMAreaManagedHierarchyCode,'&gt;','>'),'&amp;','&')
WHEN
Name = 'People - Team Managers' THEN REPLACE(REPLACE(@BCMAreaManagedHierarchyCode,'&gt;','>'),'&amp;','&')
ELSE
@IndividualHierarchyCode
--0
END
as [HierarchyCode]



 from #temp



-- SELECT * FROM #temphierarchy
--if (
--    select count(*)
--  from 
--  red_dw.dbo.ds_sh_employee emp
--    left join
--    red_dw.dbo.dim_fed_hierarchy_history hier
--    on emp.employeeid = hier.reportingbcmidud
--    or emp.employeeid = hier.worksforemployeeid
--    where hier.dss_current_flag ='Y'
--    and hier.activeud = 1
--    and emp.dss_current_flag ='Y'
--    and emp.windowsusername =  @Username)>0
    
--  begin

--      INSERT INTO #temphierarchy
--    (
--      [LevelID],
--      [Level],
--    [SecurityLevel],
--    [CubeMember]
--    )
--    VALUES
--    (5,'Manager','Reports Directly To User',CONVERT(VarChar(MAX), (@ReportsDirectly)))
--    end

-- ********************************************************************
-- RH 20210513 - Added in divergent hierarchy 
-- ********************************************************************

declare @SQL nvarchar(2000)

select top 1 @SQL = ds_mds_divergent_hierarchy.sql_string
from dbo.ds_mds_divergent_hierarchy
where ds_mds_divergent_hierarchy.windowslogin = @Username

drop table if exists #fedcodes

CREATE TABLE #fedcodes
(
   dim_fed_hierarchy_history_key INT
)

INSERT INTO #fedcodes

execute sp_executesql @SQL

-- ********************************************************************
-- RH 20210513 - Added in divergent hierarchy 
-- ********************************************************************


select 
RNK,
LevelID,
Level,
SecurityLevel,
CubeMember, 
replace(CubeMember, '_', ' ') as 'CubeMember2', 
replace(replace (CubeMember, '[Dim Fed Hierarchy History]', '[dim_fed_hierarchy_hist]'), '[Fed Hierarchy Business Key]','[fed hierarchy history business key]')  as 'CubeMemberBSC', 
FedCodes, 
replace(FedCodes, ',', '|') as 'DAXString', 
Teams, 
PracticeAreas,
BusinessLines,
replace([HierarchyCode], '&amp;', '&')  AS [HierarchyCode]
--, Replace(Replace(Replace(Replace(CubeMember,'[Fed Hierarchy Business Key].[',''),'[Dim_Fed_Hierarchy_History].',''),'[Fed Hierarchy Business Key].',''),']','') as FedCodes

--,substring(CubeMember, CHARINDEX('Weightmans', CubeMember), len(CubeMember)) test

from 
(
select 
RANK() OVER ( PARTITION BY a.SecurityLevel ORDER BY a.LevelID ASC ) [RNK] ,
*
from #temphierarchy a
) as a where RNK = 1



-- ********************************************************************
-- RH 20210513 - Added in divergent hierarchy 
-- ********************************************************************
union all

select distinct 1 RNK, 4 LevelID, 'Divergent Hierarchy' Level, 'Area Managed' SecurityLevel,
		string_agg('[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].[' + cast(dim_fed_hierarchy_history.fed_hierarchy_business_key collate Latin1_General_CI_AS as varchar(max)) + ']',',') CubeMember,
		string_agg('[Fed Hierarchy Business Key].[Fed Hierarchy Business Key].[' +  cast(dim_fed_hierarchy_history.fed_hierarchy_business_key collate Latin1_General_CI_AS as varchar(max)) + ']',',') CubeMember,
		string_agg('[fed hierarchy history business key].[fed hierarchy history business key].[' +  cast(dim_fed_hierarchy_history.fed_hierarchy_business_key collate Latin1_General_CI_AS as varchar(max)) + ']',',') CubeMemberBSC,
		string_agg( cast(dim_fed_hierarchy_history.fed_hierarchy_business_key collate Latin1_General_CI_AS as varchar(max)),',') FedCodes,
		replace(string_agg( cast(dim_fed_hierarchy_history.fed_hierarchy_business_key collate Latin1_General_CI_AS  as varchar(max)),'|'), ',','|') DAXString,
		Teams.Teams collate Latin1_General_CI_AS,
		PracticeAreas.PracticeAreas collate Latin1_General_CI_AS,
		BusinessLines.BusinessLines collate Latin1_General_CI_AS,
		string_agg('[Dim Fed Hierarchy History].[Hierarchy].[Display Name].&[' + cast(display_name collate Latin1_General_CI_AS as varchar(max)) 
		+ ']&[]&[]&[' + cast(hierarchylevel4hist collate Latin1_General_CI_AS as varchar(max)) + ']&[' + cast(hierarchylevel3hist collate Latin1_General_CI_AS as varchar(max)) + ']&[' 
		+ cast(hierarchylevel2hist collate Latin1_General_CI_AS as varchar(max)) + '&[Weightmans LLP]',',') HierarchyCode
from #fedcodes inner join dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = #fedcodes.dim_fed_hierarchy_history_key
cross apply (
select string_agg(hierarchylevel4hist,',') Teams
	from (
		select distinct hierarchylevel4hist from #fedcodes inner join dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = #fedcodes.dim_fed_hierarchy_history_key
		where dim_fed_hierarchy_history.dss_current_flag = 'Y'
	) Teams
	) Teams
cross apply (

select string_agg(hierarchylevel3hist,',') PracticeAreas
	from (
	select distinct hierarchylevel3hist from #fedcodes inner join dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = #fedcodes.dim_fed_hierarchy_history_key
	where dim_fed_hierarchy_history.dss_current_flag = 'Y'
	) PracticeAreas
	) PracticeAreas
cross apply (

select string_agg(hierarchylevel2hist,',') BusinessLines
	from (
	select distinct hierarchylevel2hist from #fedcodes inner join dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = #fedcodes.dim_fed_hierarchy_history_key
	where dim_fed_hierarchy_history.dss_current_flag = 'Y'
	) BusinessLines
	) BusinessLines
where dim_fed_hierarchy_history.dss_current_flag = 'Y'
group by Teams.Teams
       , PracticeAreas.PracticeAreas
       , BusinessLines.BusinessLines


 -- ********************************************************************
-- RH 20210513 - Added in divergent hierarchy 
-- ********************************************************************


order by LevelID

--PRINT @ReportsDirectly


--DROP TABLE #HOPAAreaManaged
GO
GRANT EXECUTE ON  [dbo].[Dynamic_Hierarchy_Security1] TO [db_ssrs_dynamicsecurity]
GO
GRANT EXECUTE ON  [dbo].[Dynamic_Hierarchy_Security1] TO [SBC\jnorto]
GO
GRANT ALTER ON  [dbo].[Dynamic_Hierarchy_Security1] TO [SBC\SQL - DataReader on SVR-LIV-DWH-01]
GO
GRANT EXECUTE ON  [dbo].[Dynamic_Hierarchy_Security1] TO [SBC\SQL - DataReader on SVR-LIV-DWH-01]
GO
GRANT ALTER ON  [dbo].[Dynamic_Hierarchy_Security1] TO [SBC\SQL - DataReader on SVR-LIV-DWH-01_Limited]
GO
GRANT EXECUTE ON  [dbo].[Dynamic_Hierarchy_Security1] TO [SBC\SQL - DataReader on SVR-LIV-DWH-01_Limited]
GO

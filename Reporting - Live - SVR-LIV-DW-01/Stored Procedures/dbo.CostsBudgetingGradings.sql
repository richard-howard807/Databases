SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--exec [dbo].[CostsBudgetingGradings] NULL, 'Yes'

CREATE PROCEDURE [dbo].[CostsBudgetingGradings]

@Surname varchar(50),
@Leavers char(3)

AS




select Forename, Surname,cast(employeeid as uniqueidentifier) as employeeid ,[HierarchyLevel4] as Team,AdmissionTypeUD,leftdate,Leaver, DATEDIFF(month,leftdate,getdate()) as MonthsLeft,AdmissionDateud,JobTitle,LevelIDUD,YearsSinceQualification,
 case when YearsSinceQualification >= 8  and AdmissionTypeUD ='SRA' then 'A'
 when (AdmissionTypeUD = 'SRA' and (YearsSinceQualification >=4 and YearsSinceQualification <8)) or (AdmissionTypeUD =  'FILEX' and YearsSinceQualification >=4) then  'B'
 when (AdmissionTypeUD in ('SRA','FILEX') and YearsSinceQualification <4) or  AdmissionTypeUD in ('Association of Costs Lawyers','ILEX') then 'C'
else 'D' end as Grade
	
from (
select Employee.employeeid,forename, surname, rtrim(ltrim(admissiondateud)) as AdmissionTypeUD,[HierarchyLevel4],leftdate,leaver, AdmissionDateud,PostID,JobTitle,LevelIDUD, 

DATEDIFF(yy,Admission.AdmissionDateud,case when leftdate >getdate()then getdate() else coalesce(leftdate ,GETDATE())end) - 
case when DATEADD(YY,DATEDIFF(YY,Admission.AdmissionDateud,case when leftdate >getdate()then getdate() else coalesce(leftdate ,GETDATE())end),Admission.AdmissionDateud) > case when leftdate >getdate()then getdate() else coalesce(leftdate ,GETDATE())end then 1
else 0 end as YearsSinceQualification

from red_dw.dbo.ds_sh_employee as Employee
left join (SELECT AdmissionDetails.employeeid,NULL AS AdmissionTypeud,admissiondateud
from red_dw.dbo.ds_sh_employee_admission_details as AdmissionDetails

Inner Join 

(
SELECT employeeid
      ,max(sys_effectivedate) MaxEffectiveDate
  FROM red_dw.dbo.ds_sh_employee_admission_details
  
    group by employeeid) as MaxEffect
    
    on MaxEffect.employeeid = AdmissionDetails.employeeid and MaxEffect.MaxEffectiveDate = AdmissionDetails.sys_effectivedate)
 as Admission on Employee.employeeid = Admission.employeeid


left join (SELECT MainJobs.employeeid ,postid,jobtitle,levelidud , hierarchylevel4, sys_activejob
FROM red_dw.dbo.ds_sh_employee_jobs as MainJobs

INNER JOIN (
SELECT employeeid
      ,max(effective_start_date) as MaxEffectiveDate
  FROM red_dw.dbo.ds_sh_employee_jobs
  group by employeeid) as MaxRecord on MainJobs.employeeid = MaxRecord.employeeid and MainJobs.effective_start_date = MaxRecord.MaxEffectiveDate 
LEFT JOIN red_dw.dbo.ds_sh_valid_hierarchy_x as Hierarchy on Hierarchy.hierarchynode = MainJobs.hierarchynode



  ) as MainJob on Employee.employeeid = MainJob.employeeid
  where sys_ActiveJob = 1
  
  ) as AllData
  --where (DATEDIFF(month,leftdate,getdate()) <6 or leftdate is null )
  
  --and 
	Where
	
	Case when leftdate is null then 1 
when @Leavers = 'Yes' and leftdate is not null or leftdate is null then 1
else 0 end = 1
	
	and 
	
  Case when @Surname is null then 1
  when 
  
  REPLACE(UPPER(Surname),' ', '') like UPPER('%' + REPLACE(@Surname, ' ','') + '%') then 1
  else 0 end = 1
  
  order by Surname, Forename
GO

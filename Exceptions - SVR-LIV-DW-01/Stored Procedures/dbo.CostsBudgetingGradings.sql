SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



--exec [dbo].[CostsBudgetingGradings] NULL, 'Yes'

CREATE PROCEDURE [dbo].[CostsBudgetingGradings]

@Surname VARCHAR(50),
@Leavers CHAR(3)

AS


SELECT  Forename, Surname,employeeid AS employeeid ,[HierarchyLevel4] AS Team,AdmissionTypeUD,leftdate,Leaver, DATEDIFF(MONTH,leftdate,GETDATE()) AS MonthsLeft,AdmissionDateud,JobTitle,LevelIDUD,YearsSinceQualification,
 CASE WHEN YearsSinceQualification >= 8  AND AdmissionTypeUD ='SRA' THEN 'A'
 WHEN (AdmissionTypeUD = 'SRA' AND (YearsSinceQualification >=4 AND YearsSinceQualification <8)) OR (AdmissionTypeUD =  'FILEX' AND YearsSinceQualification >=4) THEN  'B'
 WHEN (AdmissionTypeUD IN ('SRA','FILEX') AND YearsSinceQualification <4) OR  AdmissionTypeUD IN ('Association of Costs Lawyers','ILEX') THEN 'C'
ELSE 'D' END AS Grade
FROM 
(SELECT dim_employee.employeeid,forename, surname, RTRIM(LTRIM(admissiontypeud)) AS AdmissionTypeUD, hierarchylevel4hist AS [HierarchyLevel4],leftdate,leaver, admissiondateud,postid,dim_employee.jobtitle,levelidud, 

DATEDIFF(yy,admissiondateud,CASE WHEN leftdate >GETDATE()THEN GETDATE() ELSE COALESCE(leftdate ,GETDATE())END) - 
CASE WHEN DATEADD(YY,DATEDIFF(YY,admissiondateud,CASE WHEN leftdate >GETDATE()THEN GETDATE() ELSE COALESCE(leftdate ,GETDATE())END),admissiondateud) > CASE WHEN leftdate >GETDATE()THEN GETDATE() ELSE COALESCE(leftdate ,GETDATE())END THEN 1
ELSE 0 END AS YearsSinceQualification FROM red_dw.dbo.dim_employee
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON  dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key AND dss_current_flag='Y' AND activeud=1
	WHERE
	
	CASE WHEN leftdate IS NULL THEN 1 
WHEN @Leavers = 'Yes' AND leftdate IS NOT NULL OR leftdate IS NULL THEN 1
ELSE 0 END = 1
	
	AND 
	
  CASE WHEN @Surname IS NULL THEN 1
  WHEN 
  
  REPLACE(UPPER(surname),' ', '') LIKE UPPER('%' + REPLACE(@Surname, ' ','') + '%') THEN 1
  ELSE 0 END = 1
  ) AS AllData
  WHERE AllData.forename <>'Unknown'



--SELECT Forename, Surname,CAST(employeeid AS UNIQUEIDENTIFIER) AS employeeid ,[HierarchyLevel4] AS Team,AdmissionTypeUD,leftdate,Leaver, DATEDIFF(MONTH,leftdate,GETDATE()) AS MonthsLeft,AdmissionDateud,JobTitle,LevelIDUD,YearsSinceQualification,
-- CASE WHEN YearsSinceQualification >= 8  AND AdmissionTypeUD ='SRA' THEN 'A'
-- WHEN (AdmissionTypeUD = 'SRA' AND (YearsSinceQualification >=4 AND YearsSinceQualification <8)) OR (AdmissionTypeUD =  'FILEX' AND YearsSinceQualification >=4) THEN  'B'
-- WHEN (AdmissionTypeUD IN ('SRA','FILEX') AND YearsSinceQualification <4) OR  AdmissionTypeUD IN ('Association of Costs Lawyers','ILEX') THEN 'C'
--ELSE 'D' END AS Grade
	
--FROM (
--SELECT Employee.employeeid,forename, surname, RTRIM(LTRIM(admissiondateud)) AS AdmissionTypeUD,[HierarchyLevel4],leftdate,leaver, AdmissionDateud,PostID,JobTitle,LevelIDUD, 

--DATEDIFF(yy,Admission.AdmissionDateud,CASE WHEN leftdate >GETDATE()THEN GETDATE() ELSE COALESCE(leftdate ,GETDATE())END) - 
--CASE WHEN DATEADD(YY,DATEDIFF(YY,Admission.AdmissionDateud,CASE WHEN leftdate >GETDATE()THEN GETDATE() ELSE COALESCE(leftdate ,GETDATE())END),Admission.AdmissionDateud) > CASE WHEN leftdate >GETDATE()THEN GETDATE() ELSE COALESCE(leftdate ,GETDATE())END THEN 1
--ELSE 0 END AS YearsSinceQualification

--FROM red_dw.dbo.ds_sh_employee AS Employee
--LEFT JOIN (SELECT AdmissionDetails.employeeid,NULL AS AdmissionTypeud,admissiondateud
--FROM red_dw.dbo.ds_sh_employee_admission_details AS AdmissionDetails

--INNER JOIN 

--(
--SELECT employeeid
--      ,MAX(sys_effectivedate) MaxEffectiveDate
--  FROM red_dw.dbo.ds_sh_employee_admission_details
  
--    GROUP BY employeeid) AS MaxEffect
    
--    ON MaxEffect.employeeid = AdmissionDetails.employeeid AND MaxEffect.MaxEffectiveDate = AdmissionDetails.sys_effectivedate)
-- AS Admission ON Employee.employeeid = Admission.employeeid


--LEFT JOIN (SELECT MainJobs.employeeid ,postid,jobtitle,levelidud , hierarchylevel4, sys_activejob
--FROM red_dw.dbo.ds_sh_employee_jobs AS MainJobs

--INNER JOIN (
--SELECT employeeid
--      ,MAX(effective_start_date) AS MaxEffectiveDate
--  FROM red_dw.dbo.ds_sh_employee_jobs
--  GROUP BY employeeid) AS MaxRecord ON MainJobs.employeeid = MaxRecord.employeeid AND MainJobs.effective_start_date = MaxRecord.MaxEffectiveDate 
--LEFT JOIN red_dw.dbo.ds_sh_valid_hierarchy_x AS Hierarchy ON Hierarchy.hierarchynode = MainJobs.hierarchynode



--  ) AS MainJob ON Employee.employeeid = MainJob.employeeid
--  WHERE sys_ActiveJob = 1
  
--  ) AS AllData
--  --where (DATEDIFF(month,leftdate,getdate()) <6 or leftdate is null )
  
--  --and 
--	WHERE
	
--	CASE WHEN leftdate IS NULL THEN 1 
--WHEN @Leavers = 'Yes' AND leftdate IS NOT NULL OR leftdate IS NULL THEN 1
--ELSE 0 END = 1
	
--	AND 
	
--  CASE WHEN @Surname IS NULL THEN 1
--  WHEN 
  
--  REPLACE(UPPER(Surname),' ', '') LIKE UPPER('%' + REPLACE(@Surname, ' ','') + '%') THEN 1
--  ELSE 0 END = 1
  
--  ORDER BY Surname, Forename
--GO


GO

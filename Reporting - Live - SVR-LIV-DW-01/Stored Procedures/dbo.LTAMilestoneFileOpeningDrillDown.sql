SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO























CREATE PROCEDURE [dbo].[LTAMilestoneFileOpeningDrillDown] --EXEC dbo.ClaimsMilestoneFileOpening '2020-05-01','2020-11-25'
(
@StartDate  AS DATE
,@EndDate  AS DATE
,@DisplayName AS NVARCHAR(100)
,@Team AS NVARCHAR(100)
)
AS 
BEGIN

SELECT AlData.ms_fileid,
       AlData.Client,
       AlData.[Client Name],
       AlData.Matter,
       AlData.[File],
       AlData.[Fee Earner],
       AlData.[Business Line],
       AlData.[Practice Area],
       AlData.Team,
       AlData.matter_description,
       AlData.[Matter Category],
       AlData.[Work Type],
       AlData.[Work Type Code],
       AlData.Milestone,
       AlData.[Task Filter Code],
       AlData.[Task Flow Code],
       AlData.[Task Description],
       AlData.[Date Created],
       AlData.[File Open Date],
       AlData.[Month/Year Open],
       AlData.[Task Completed],
       AlData.[Date Completed],
       AlData.[Days Diff Between File Open and Data Completed],
       AlData.[Completed By],
       AlData.Deleted,
       AlData.[Role Completed By],
       AlData.[Number Live Matters],
       AlData.Display_Name,
       AlData.[Date Instructions Received],
       AlData.ElapsedInstructiontoOpen
	   ,AlData.OpenedBy
	   FROM 
(
SELECT ms_fileid
,master_client_code AS [Client]
,client_name AS [Client Name]
,master_matter_number AS [Matter]
,master_client_code + '-' + master_matter_number AS [File]
,name AS [Fee Earner]
,hierarchylevel2hist AS [Business Line]
,hierarchylevel3hist AS [Practice Area]
,hierarchylevel4hist AS [Team]
,matter_description
,matter_category AS [Matter Category]
,work_type_code AS [Work Type]
,work_type_name AS [Work Type Code]
,tskMSStage AS [Milestone]
,tskFilter AS [Task Filter Code]
,NULL AS [Task Flow Code]
,tskDesc AS [Task Description]
,red_dw.dbo.datetimelocal(dbtasks.Created) AS [Date Created]
,date_opened_case_management AS [File Open Date]
,DATENAME(MONTH,date_opened_case_management) + CAST(YEAR(date_opened_case_management) AS NVARCHAR(4)) AS [Month/Year Open]
,CASE WHEN tskComplete=1 THEN 'Yes' ELSE 'No' END  AS [Task Completed]
,red_dw.dbo.datetimelocal(tskCompleted)AS [Date Completed]
,DATEDIFF(DAY,date_opened_case_management,red_dw.dbo.datetimelocal(tskCompleted)) AS [Days Diff Between File Open and Data Completed]
,usrFullName AS [Completed By]
,CASE WHEN tskActive=0 THEN 'Yes' ELSE 'No' END  AS [Deleted]
,CASE WHEN tskComplete=0 THEN 'Incomplete'
ELSE RoleType END AS [Role Completed By]
,1 AS [Number Live Matters]
,CASE WHEN tskFilter='Tsk001' THEN 'REM Complete Conflict Check - Support'
WHEN tskFilter IN ('tsk006','tsk_01_2040_FileOpening') THEN 'REM File Opening Process - Support'
WHEN tskFilter IN ('tsk004','tsk_01_2020_AddAssociates') THEN 'REM Add associates to matter - Support'
WHEN tskFilter IN ('tsk011','tsk_01_2090_OpeningRisk') THEN 'REM Complete Opening Risk Assessment - Support'
WHEN tskFilter='tsk_01_090_ADMCompleteCDD' THEN 'ADM: Complete CDD form procedure - Case Handler'
WHEN tskFilter='tsk_02_050_REMReviewMatter' THEN 'ADM: Monthly review - Case Handler'
WHEN tskFilter='tsk_01_280_admcostsestimatereview' THEN 'ADM: Cost Estimate Review – Case Handler'
WHEN tskFilter IN ('tsk014','tsk_01_2110_FeeEarnerCheck') THEN 'REM: Fee earner check – Case Handler'
WHEN tskFilter='tsk_01_560_REMTMAuditRF' THEN 'REM: Team Manager File Audit Review - Team Mananger'
END AS [Display_Name]
,date_instructions_received AS [Date Instructions Received]
,DATEDIFF(DAY,date_instructions_received,date_opened_case_management) AS ElapsedInstructiontoOpen
,NULL AS [OpenedBy]
 FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
 AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype  WITH(NOLOCK)
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN MS_Prod.dbo.dbTasks  WITH(NOLOCK)
 ON ms_fileid=fileID
LEFT OUTER JOIN MS_Prod.dbo.dbUser  WITH(NOLOCK)
 ON tskCompletedBy=dbUser.usrID
LEFT OUTER JOIN (
SELECT DISTINCT fed_code AS usralias,levelidud,postid,dim_employee.jobtitle,CASE WHEN management_role_one='Team Manager' THEN 'Team Manager' ELSE [classification] END AS RoleType
FROM red_dw.dbo.dim_employee  WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  WITH(NOLOCK)
 ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key
WHERE dss_current_flag='Y'
AND activeud=1
UNION
SELECT DISTINCT payrollid AS usralias,levelidud,postid,dim_employee.jobtitle,CASE WHEN management_role_one='Team Manager' THEN 'Team Manager' ELSE [classification] END AS RoleType
FROM red_dw.dbo.dim_employee
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key
WHERE ISNUMERIC(fed_code)=0
AND dss_current_flag='Y'
AND dim_employee.jobtitle='Legal Secretary'
) AS Roles
ON Roles.usralias = dbUser.usrAlias COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
WHERE hierarchylevel2hist='Legal Ops - LTA'
AND CONVERT(DATE,date_opened_case_management,103) BETWEEN @StartDate AND @EndDate
AND tskMSStage=1
AND hierarchylevel4hist=@Team
AND tskFilter IN 
(
'Tsk001','tsk_01_2040_FileOpening','tsk_01_2020_AddAssociates','tsk_01_2090_OpeningRisk'
,'tsk_01_090_ADMCompleteCDD','tsk_02_050_REMReviewMatter','tsk_01_280_admcostsestimatereview','tsk_01_2110_FeeEarnerCheck','tsk_01_560_REMTMAuditRF'
,'tsk004','tsk014','tsk006','tsk_01_560_REMTMAuditRF'
)
--AND (CASE WHEN tskFilter='Tsk001' THEN 'REM Complete Conflict Check - Support'
--WHEN tskFilter IN ('tsk006','tsk_01_2040_FileOpening') THEN 'REM File Opening Process - Support'
--WHEN tskFilter IN ('tsk004','tsk_01_2020_AddAssociates') THEN 'REM Add associates to matter - Support'
--WHEN tskFilter IN ('tsk011','tsk_01_2090_OpeningRisk') THEN 'REM Complete Opening Risk Assessment - Support'
--WHEN tskFilter='tsk_01_090_ADMCompleteCDD' THEN 'ADM: Complete CDD form procedure - Case Handler'
--WHEN tskFilter='tsk_02_050_REMReviewMatter' THEN 'ADM: Monthly review - Case Handler'
--WHEN tskFilter='tsk_01_280_admcostsestimatereview' THEN 'ADM: Cost Estimate Review – Case Handler'
--WHEN tskFilter IN ('tsk014','tsk_01_2110_FeeEarnerCheck') THEN 'REM: Fee earner check – Case Handler'
--WHEN tskFilter='tsk_01_560_REMTMAuditRF' THEN 'REM: Team Manager File Audit Review - Team Mananger'
--END) =@DisplayName

UNION

SELECT ms_fileid
,master_client_code AS [Client]
,client_name AS [Client Name]
,master_matter_number AS [Matter]
,master_client_code + '-' + master_matter_number AS [File]
,name AS [Fee Earner]
,hierarchylevel2hist AS [Business Line]
,hierarchylevel3hist AS [Practice Area]
,hierarchylevel4hist AS [Team]
,matter_description
,matter_category AS [Matter Category]
,work_type_code AS [Work Type]
,work_type_name AS [Work Type Code]
,NULL AS [Milestone]
,NULL AS [Task Filter Code]
,NULL AS [Task Flow Code]
,NULL AS [Task Description]
,red_dw.dbo.datetimelocal(dbfile.Created) AS [Date Created]
,date_opened_case_management AS [File Open Date]
,DATENAME(MONTH,date_opened_case_management) + CAST(YEAR(date_opened_case_management) AS NVARCHAR(4)) AS [Month/Year Open]
,NULL  AS [Task Completed]
,NULL AS [Date Completed]
,NULL AS [Days Diff Between File Open and Data Completed]
,NULL AS [Completed By]
,NULL  AS [Deleted]
,RoleType AS [Role Completed By]
,1 AS [Number Live Matters]
,'Matter Creation – Support' AS [Display_Name]
,date_instructions_received AS [Date Instructions Received]
,DATEDIFF(DAY,date_instructions_received,date_opened_case_management) AS ElapsedInstructiontoOpen
,dbuser.usrFullName AS [OpenedBy]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN MS_Prod.config.dbFile  WITH(NOLOCK)
 ON ms_fileid=fileID
LEFT OUTER JOIN MS_Prod.dbo.dbUser  WITH(NOLOCK)
 ON dbFile.CreatedBy=dbUser.usrID
LEFT OUTER JOIN (SELECT fed_code AS usralias,levelidud,postid,dim_employee.jobtitle,CASE WHEN management_role_one='Team Manager' THEN 'Team Manager' ELSE [classification] END AS RoleType
FROM red_dw.dbo.dim_employee  WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  WITH(NOLOCK)
 ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key
WHERE dss_current_flag='Y'
AND activeud=1) AS Roles
ON Roles.usralias = dbUser.usrAlias COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
WHERE hierarchylevel2hist='Legal Ops - LTA'
AND 
CONVERT(DATE,date_opened_case_management,103) BETWEEN @StartDate AND @EndDate
AND hierarchylevel4hist=@Team

) AS AlData
WHERE AlData.Display_Name=@DisplayName
END


GO

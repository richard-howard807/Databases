SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











CREATE PROCEDURE [dbo].[ClaimsMilestoneFileOpeningDrillDown] --EXEC dbo.ClaimsMilestoneFileOpening '2020-05-01','2020-11-25'
(
@StartDate  AS DATE
,@EndDate  AS DATE
,@DisplayName AS NVARCHAR(50)
,@Team AS NVARCHAR(100)
)
AS 
BEGIN

SELECT * FROM (
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
,red_dw.dbo.datetimelocal(tskCompleted) AS [Date Completed]
,DATEDIFF(DAY,date_opened_case_management,red_dw.dbo.datetimelocal(tskCompleted)) AS [Days Diff Between File Open and Data Completed]
,usrFullName AS [Completed By]
,CASE WHEN tskActive=0 THEN 'Yes' ELSE 'No' END  AS [Deleted]
,CASE WHEN tskComplete=0 THEN 'Incomplete'
ELSE RoleType END AS [Role Completed By]
,1 AS [Number Live Matters]
,CASE WHEN tskFilter='tsk_01_010_ADMCommenceMIprocess' THEN 'MI Process - Team Manager'
WHEN tskFilter='tsk_031_01_010_ClientCare' THEN 'Client care process - Support Staff'
WHEN tskFilter='tsk_042_01_010_CCFA' THEN 'Commence CCFA process - Team Manager'
WHEN tskFilter IN ('tsk_065_01_010_FileOpen','tsk_024_01_010_FileOp2','tsk_01_020_ADMFileOpening','tsk_01_300_adm_file_open_proc_emp','tsk_065_01_010_FileOpen1','tsk_003_01_010_FileOpenCost') THEN 'File opening process - Support Staff'
WHEN tskFilter='tsk_065_01_020_ConflictSearch' THEN 'Conflict check - Case Handler'
WHEN tskFilter='tsk_065_01_960_AllocationNewMatter' THEN 'EML Allocation of New Matter - Team Manager'
WHEN tskFilter='tsk_065_01_961_NewMatterDataCollection' THEN 'New Matter data collection - Case Handler' 
WHEN tskFilter='tsk_072_01_010_ClientCare' THEN 'Client Care process - Support Staff' END AS [Display_Name]
,date_instructions_received AS [Date Instructions Received]
,DATEDIFF(DAY,date_instructions_received,date_opened_case_management) AS ElapsedInstructiontoOpen
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
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND CONVERT(DATE,date_opened_case_management,103) BETWEEN @StartDate AND @EndDate
AND ISNULL(red_dw.dbo.dim_matter_header_current.present_position,'') NOT IN ('Final bill sent - unpaid','To be closed/minor balances to be clear')
AND ISNULL(referral_reason,'')<>'Advice only'
AND ISNULL(referral_reason,'')<> 'In House'
AND tskMSStage=1
AND hierarchylevel4hist=@Team
AND tskFilter IN 
(
'tsk_01_010_ADMCommenceMIprocess','tsk_031_01_010_ClientCare','tsk_042_01_010_CCFA',
'tsk_065_01_010_FileOpen1','tsk_065_01_020_ConflictSearch',
'tsk_065_01_960_AllocationNewMatter','tsk_065_01_961_NewMatterDataCollection',
'tsk_072_01_010_ClientCare','tsk_065_01_010_FileOpen'
,'tsk_065_01_010_FileOpen','tsk_024_01_010_FileOp2','tsk_01_020_ADMFileOpening','tsk_01_300_adm_file_open_proc_emp','tsk_065_01_010_FileOpen1','tsk_003_01_010_FileOpenCost'

)

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
,NULL AS [Date Created]
,date_opened_case_management AS [File Open Date]
,DATENAME(MONTH,date_opened_case_management) + CAST(YEAR(date_opened_case_management) AS NVARCHAR(4)) AS [Month/Year Open]
,NULL  AS [Task Completed]
,NULL AS [Date Completed]
,NULL AS [Days Diff Between File Open and Data Completed]
,usrFullName AS [Completed By]
,NULL  AS [Deleted]
,RoleType  AS [Role Completed By]
,1 AS [Number Live Matters]
,'Matter Creation – Team Manager' AS  [Display_Name]
,date_instructions_received AS [Date Instructions Received]
,DATEDIFF(DAY,date_instructions_received,date_opened_case_management) AS ElapsedInstructiontoOpen
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
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND CONVERT(DATE,date_opened_case_management,103) BETWEEN @StartDate AND @EndDate
AND ISNULL(red_dw.dbo.dim_matter_header_current.present_position,'') NOT IN ('Final bill sent - unpaid','To be closed/minor balances to be clear')
AND ISNULL(referral_reason,'')<>'Advice only'
AND ISNULL(referral_reason,'')<> 'In House'
AND hierarchylevel4hist=@Team
) AS AllData
WHERE AllData.Display_Name =@DisplayName
END


GO

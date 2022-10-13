SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[ClaimsFileOpeningRoleActivityReport] --EXEC  [dbo].[ClaimsFileOpeningRoleActivityReport]  '2022-07-01','2022-07-29' 
(
@StartDate AS DATE
,@EndDate AS DATE
) 
AS

BEGIN

--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate='2021-07-01'
--SET @EndDate='2021-07-27'

SELECT AllData.Department,
       AllData.Role,
       AllData.NewTaskDesc,
       SUM(AllData.Number) AS Number,
	   CASE WHEN AllData.NewTaskDesc='Total Files Opened' THEN 1
	   WHEN AllData.NewTaskDesc='Client Care process' THEN 2
WHEN AllData.NewTaskDesc='Commence CCFA process' THEN 3
WHEN AllData.NewTaskDesc='Conflict check' THEN 4
WHEN AllData.NewTaskDesc='EML Allocation of New Matter' THEN 5
WHEN AllData.NewTaskDesc='File opening process' THEN 6
WHEN AllData.NewTaskDesc='Matter Creation' THEN 7
WHEN AllData.NewTaskDesc='MI Process' THEN 8
WHEN AllData.NewTaskDesc='New Matter data collection' THEN 9 END AS MatrixOrder

	   FROM 
(
SELECT hierarchylevel3hist AS Department	
,levelidud AS [Role]
,CASE WHEN tskFilter='tsk_01_010_ADMCommenceMIprocess' THEN 'MI Process'
WHEN tskFilter='tsk_031_01_010_ClientCare' THEN 'Client Care process'
WHEN tskFilter='tsk_042_01_010_CCFA' THEN 'Commence CCFA process'
WHEN tskFilter IN ('tsk_065_01_010_FileOpen','tsk_024_01_010_FileOp2','tsk_01_020_ADMFileOpening','tsk_01_300_adm_file_open_proc_emp','tsk_065_01_010_FileOpen1','tsk_003_01_010_FileOpenCost') THEN 'File opening process'
WHEN tskFilter='tsk_065_01_020_ConflictSearch' THEN 'Conflict check'
WHEN tskFilter='tsk_065_01_960_AllocationNewMatter' THEN 'EML Allocation of New Matter'
WHEN tskFilter='tsk_065_01_961_NewMatterDataCollection' THEN 'New Matter data collection' 
WHEN tskFilter='tsk_072_01_010_ClientCare' THEN 'Client Care process' END AS NewTaskDesc
,1 AS Number
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
) AS Roles
ON Roles.usralias = dbUser.usrAlias COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND CONVERT(DATE,date_opened_case_management,103) BETWEEN @StartDate AND @EndDate
--AND ISNULL(red_dw.dbo.dim_matter_header_current.present_position,'') NOT IN ('Final bill sent - unpaid','To be closed/minor balances to be clear')
--AND ISNULL(referral_reason,'')<>'Advice only'
--AND ISNULL(referral_reason,'')<> 'In House'
AND tskMSStage=1
AND tskFilter IN 
(
'tsk_01_010_ADMCommenceMIprocess','tsk_031_01_010_ClientCare','tsk_042_01_010_CCFA',
'tsk_065_01_010_FileOpen1','tsk_065_01_020_ConflictSearch',
'tsk_065_01_960_AllocationNewMatter','tsk_065_01_961_NewMatterDataCollection',
'tsk_072_01_010_ClientCare','tsk_065_01_010_FileOpen'
,'tsk_065_01_010_FileOpen','tsk_024_01_010_FileOp2','tsk_01_020_ADMFileOpening','tsk_01_300_adm_file_open_proc_emp','tsk_065_01_010_FileOpen1','tsk_003_01_010_FileOpenCost'

)
AND tskComplete=1 AND tskActive=1
UNION ALL

SELECT hierarchylevel3hist AS Department	
,levelidud AS [Role]
,'Matter Creation' AS NewTaskDesc
,1 AS Number
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
) AS Roles
ON Roles.usralias = dbUser.usrAlias COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
WHERE hierarchylevel2hist='Legal Ops - Claims'
--AND CONVERT(DATE,date_opened_case_management,103) BETWEEN @StartDate AND @EndDate
--AND ISNULL(red_dw.dbo.dim_matter_header_current.present_position,'') NOT IN ('Final bill sent - unpaid','To be closed/minor balances to be clear')
--AND ISNULL(referral_reason,'')<>'Advice only'
--AND ISNULL(referral_reason,'')<> 'In House'
UNION ALL


SELECT hierarchylevel3hist AS Department	
,levelidud AS [Role]
,'Total Files Opened' AS NewTaskDesc
,1 AS Number
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
) AS Roles
ON Roles.usralias = dbUser.usrAlias COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND CONVERT(DATE,date_opened_case_management,103) BETWEEN @StartDate AND @EndDate
--AND ISNULL(red_dw.dbo.dim_matter_header_current.present_position,'') NOT IN ('Final bill sent - unpaid','To be closed/minor balances to be clear')
--AND ISNULL(referral_reason,'')<>'Advice only'
--AND ISNULL(referral_reason,'')<> 'In House'
) AS AllData

GROUP BY CASE
         WHEN AllData.NewTaskDesc = 'Total Files Opened' THEN
         1
         WHEN AllData.NewTaskDesc = 'Client Care process' THEN
         2
         WHEN AllData.NewTaskDesc = 'Commence CCFA process' THEN
         3
         WHEN AllData.NewTaskDesc = 'Conflict check' THEN
         4
         WHEN AllData.NewTaskDesc = 'EML Allocation of New Matter' THEN
         5
         WHEN AllData.NewTaskDesc = 'File opening process' THEN
         6
         WHEN AllData.NewTaskDesc = 'Matter Creation' THEN
         7
         WHEN AllData.NewTaskDesc = 'MI Process' THEN
         8
         WHEN AllData.NewTaskDesc = 'New Matter data collection' THEN
         9
         END,
         AllData.Department,
         AllData.Role,
         AllData.NewTaskDesc
END 
GO

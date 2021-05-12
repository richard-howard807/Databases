SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ClaimsMilestoneFileOpeningCompletions]
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS 

BEGIN 

SELECT master_client_code + '-' + master_matter_number AS [File]
,client_name AS [Client Name]
,matter_description AS [Matter Description]
,matter_owner_full_name AS [Fee Earner]
,hierarchylevel4hist AS [Team]
,MS_Prod.dbo.dbUser.usrFullName AS [Completed By]
,red_dw.dbo.datetimelocal(tskCompleted) AS [Date Completed]
,CASE WHEN MS_Prod.dbo.dbUser.usrAlias IN
(
'5347','5893','4845','4618','4938','4937','2006','1803','3162','1392','1255','4384','3122'
,'593','3949','3233','4459','4664','3556','3600','3734','5699','1364','3484','4786','1804'
,'4158','4295','5674','3752','137','5862','1890','4957','4866','4188','1972','5425','5825'
,'1579','958','4781','1966','2078','3078','6485','5790','835','6169','1732','5152','3497'
,'2090','3393','5518','4234','4410','5508','6299','5798','6378','5527','551','4157','5405'
,'1067','3257','1500') THEN 'Yes' ELSE 'No' END AS CompletedByCorrectPerson
,CASE WHEN tskFilter='tsk_01_010_ADMCommenceMIprocess' THEN 'MI Process - Team Manager'
WHEN tskFilter='tsk_031_01_010_ClientCare' THEN 'Client care process - Support Staff'
WHEN tskFilter='tsk_042_01_010_CCFA' THEN 'Commence CCFA process - Team Manager'
WHEN tskFilter IN ('tsk_065_01_010_FileOpen','tsk_024_01_010_FileOp2','tsk_01_020_ADMFileOpening','tsk_01_300_adm_file_open_proc_emp','tsk_065_01_010_FileOpen1','tsk_003_01_010_FileOpenCost') THEN 'File opening process - Support Staff'
WHEN tskFilter='tsk_065_01_020_ConflictSearch' THEN 'Conflict check - Case Handler'
WHEN tskFilter='tsk_065_01_960_AllocationNewMatter' THEN 'EML Allocation of New Matter - Team Manager'
WHEN tskFilter='tsk_065_01_961_NewMatterDataCollection' THEN 'New Matter data collection - Case Handler' 
WHEN tskFilter='tsk_072_01_010_ClientCare' THEN 'Client Care process - Support Staff' END AS Area
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
AND red_dw.dbo.datetimelocal(tskCompleted) BETWEEN @StartDate AND @EndDate
AND ISNULL(red_dw.dbo.dim_matter_header_current.present_position,'') NOT IN ('Final bill sent - unpaid','To be closed/minor balances to be clear')
AND ISNULL(referral_reason,'')<>'Advice only'
AND ISNULL(referral_reason,'')<> 'In House'
AND tskMSStage=1
AND tskFilter IN 
(
'tsk_01_010_ADMCommenceMIprocess','tsk_031_01_010_ClientCare','tsk_042_01_010_CCFA',
'tsk_065_01_010_FileOpen1','tsk_065_01_020_ConflictSearch',
'tsk_065_01_960_AllocationNewMatter','tsk_065_01_961_NewMatterDataCollection',
'tsk_072_01_010_ClientCare','tsk_065_01_010_FileOpen'
,'tsk_065_01_010_FileOpen','tsk_024_01_010_FileOp2','tsk_01_020_ADMFileOpening','tsk_01_300_adm_file_open_proc_emp','tsk_065_01_010_FileOpen1','tsk_003_01_010_FileOpenCost'

)

UNION


SELECT master_client_code + '-' + master_matter_number AS [File]
,client_name AS [Client Name]
,matter_description AS [Matter Description]
,matter_owner_full_name AS [Fee Earner]
,hierarchylevel4hist AS [Team]
,MS_Prod.dbo.dbUser.usrFullName AS [Completed By]
,red_dw.dbo.datetimelocal(date_opened_case_management) AS [Date Completed]
,CASE WHEN MS_Prod.dbo.dbUser.usrAlias IN
(
'5347','5893','4845','4618','4938','4937','2006','1803','3162','1392','1255','4384','3122'
,'593','3949','3233','4459','4664','3556','3600','3734','5699','1364','3484','4786','1804'
,'4158','4295','5674','3752','137','5862','1890','4957','4866','4188','1972','5425','5825'
,'1579','958','4781','1966','2078','3078','6485','5790','835','6169','1732','5152','3497'
,'2090','3393','5518','4234','4410','5508','6299','5798','6378','5527','551','4157','5405'
,'1067','3257','1500') THEN 'Yes' ELSE 'No' END AS CompletedByCorrectPerson
,'Matter Creation' AS Area
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

END 
GO

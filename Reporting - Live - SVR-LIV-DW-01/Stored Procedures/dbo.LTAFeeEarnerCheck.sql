SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LTAFeeEarnerCheck]
(
@Filter AS NVARCHAR(MAX)
)
AS 


BEGIN 

IF @Filter='All'

BEGIN


SELECT RTRIM(master_client_code)+'-' + RTRIM(master_matter_number) AS [File]
,client_name AS [Client Name]
,matter_description AS [Matter Description]
,name AS [Fee Earner]
,'REM: Fee earner check – Case Handler' AS [Task Description]
,red_dw.dbo.datetimelocal(tskDue)  AS [Task Due]
,CASE WHEN tskComplete=1 THEN 'Yes' ELSE 'No' END AS [Task Completed]
,workemail AS [Email]

 FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
 AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
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
AND tskMSStage=1
AND tskFilter IN ('tsk014','tsk_01_2110_FeeEarnerCheck')
AND tskComplete=0
AND tskActive=1
AND red_dw.dbo.datetimelocal(tskDue)>='2021-05-25'

END 

ELSE 

BEGIN


SELECT RTRIM(master_client_code)+'-' + RTRIM(master_matter_number) AS [File]
,client_name AS [Client Name]
,matter_description AS [Matter Description]
,name AS [Fee Earner]
,'REM: Fee earner check – Case Handler' AS [Task Description]
,red_dw.dbo.datetimelocal(tskDue)  AS [Task Due]
,CASE WHEN tskComplete=1 THEN 'Yes' ELSE 'No' END AS [Task Completed]
,workemail AS [Email]

 FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
 AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
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
AND tskMSStage=1
AND tskFilter IN ('tsk014','tsk_01_2110_FeeEarnerCheck')
AND tskComplete=0
AND tskActive=1
AND workemail=@Filter
AND red_dw.dbo.datetimelocal(tskDue)>='2021-05-25'
END 

END 
GO

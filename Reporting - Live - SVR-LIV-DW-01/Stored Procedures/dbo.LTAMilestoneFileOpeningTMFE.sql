SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












CREATE PROCEDURE [dbo].[LTAMilestoneFileOpeningTMFE] -- EXEC [dbo].[LTAMilestoneFileOpeningTMFE] '2021-02-15','2021-02-21'
( 
@StartDate AS DATE
,@EndDate AS DATE
)
AS 

BEGIN 

SELECT Summary.ms_fileid,
       Summary.Client,
       Summary.[Client Name],
       Summary.Matter,
       Summary.[File],
       Summary.matter_description,
       Summary.Display_Name,
       Summary.[Fee Earner],
       Summary.[Business Line],
       Summary.[Practice Area],
       Summary.Team,
       Summary.[Matter Category],
       Summary.[Work Type],
       Summary.[Work Type Code],
       Summary.[Task Completed],
       Summary.[Task Due],
       Summary.ElapsedDueToCompleted,
       Summary.[Number Live Matters],
       Summary.TaskType,
       Summary.Within1Day,
       Summary.NotWithin1Day,
       Summary.NewTaskDesc,
       Summary.Overdue
	   ,1 AS NumberTasks
	   ,(CASE WHEN Summary.Deleted='Yes' THEN 1 ELSE 0 END) AS [Incomplete Deleted]
	   ,(CASE WHEN Summary.Deleted='No' AND Summary.[Task Completed]='Yes' THEN 1 ELSE 0 END) AS [Completed]
	   ,(CASE WHEN Summary.Deleted='No' AND Summary.[Task Completed]='No' AND Summary.Overdue=1 THEN 1 ELSE 0 END)AS [Incomplete Overdue]
	   ,(CASE WHEN Summary.Deleted='No' AND Summary.[Task Completed]='No' AND Summary.Overdue=0 THEN 1 ELSE 0 END) [Incomplete Not Yet Due]

	   
	   FROM 
(SELECT ms_fileid
,master_client_code AS [Client]
,client_name AS [Client Name]
,master_matter_number AS [Matter]
,master_client_code + '-' + master_matter_number AS [File]
,matter_description
,name AS [Display_Name]
,fed_code AS [Fee Earner]
,hierarchylevel2hist AS [Business Line]
,hierarchylevel3hist AS [Practice Area]
,hierarchylevel4hist AS [Team]

,matter_category AS [Matter Category]
,work_type_code AS [Work Type]
,work_type_name AS [Work Type Code]
,red_dw.dbo.datetimelocal(tskCompleted) AS [Task Completed Date]
,CASE WHEN tskComplete=1 THEN 'Yes' ELSE 'No' END  AS [Task Completed]
,red_dw.dbo.datetimelocal(tskDue) AS [Task Due]
,DATEDIFF(DAY,red_dw.dbo.datetimelocal(tskDue),red_dw.dbo.datetimelocal(tskCompleted)) AS ElapsedDueToCompleted
,1 AS [Number Live Matters]
,CASE WHEN tskFilter  IN ('tsk_01_2110_FeeEarnerCheck','tsk014' ) THEN 'Fee Earner'
WHEN tskFilter IN ('tsk_01_560_REMTMAuditRF') THEN 'Team Manager'
WHEN tskFilter IN ('tsk006','tsk_01_2040_FileOpening') THEN 'File Opening' END AS TaskType
,CASE WHEN tskDue IS NOT NULL AND tskCompleted IS NOT NULL AND DATEDIFF(DAY,red_dw.dbo.datetimelocal(tskDue),red_dw.dbo.datetimelocal(tskCompleted))<=1 THEN 1 ELSE 0 END  AS Within1Day
,CASE WHEN tskDue IS NULL THEN 1
WHEN DATEDIFF(DAY,red_dw.dbo.datetimelocal(tskDue),red_dw.dbo.datetimelocal(tskCompleted))>1 OR tskCompleted IS NULL THEN 1 ELSE 0 END AS NotWithin1Day
,CASE WHEN tskFilter='Tsk001' THEN 'REM Complete Conflict Check - Support'
WHEN tskFilter IN ('tsk006','tsk_01_2040_FileOpening') THEN 'REM File Opening Process - Support'
WHEN tskFilter IN ('tsk004','tsk_01_2020_AddAssociates') THEN 'REM Add associates to matter - Support'
WHEN tskFilter IN ('tsk011','tsk_01_2090_OpeningRisk') THEN 'REM Complete Opening Risk Assessment - Support'
WHEN tskFilter='tsk_01_090_ADMCompleteCDD' THEN 'ADM: Complete CDD form procedure - Case Handler'
WHEN tskFilter='tsk_02_050_REMReviewMatter' THEN 'ADM: Monthly review - Case Handler'
WHEN tskFilter='tsk_01_280_admcostsestimatereview' THEN 'ADM: Cost Estimate Review – Case Handler'
WHEN tskFilter IN ('tsk014','tsk_01_2110_FeeEarnerCheck') THEN 'REM: Fee earner check – Case Handler'
WHEN tskFilter='tsk_01_560_REMTMAuditRF' THEN 'REM: Team Manager File Audit Review - Team Mananger'
END AS NewTaskDesc
,CASE WHEN red_dw.dbo.datetimelocal(tskDue) <CONVERT(DATE,GETDATE(),103) THEN 1 ELSE 0 END Overdue
,CASE WHEN tskActive=0 THEN 'Yes' ELSE 'No' END  AS [Deleted]
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
AND 
CONVERT(DATE,date_opened_case_management,103) BETWEEN @StartDate AND @EndDate
AND master_client_code<>'30645'
AND date_closed_case_management IS NULL
AND tskMSStage=1
AND tskFilter IN (
'tsk_01_280_admcostsestimatereview'
,'tsk_01_560_REMTMAuditRF'
,'tsk_01_090_ADMCompleteCDD'
,'tsk_02_050_REMReviewMatter'
,'tsk_01_2110_FeeEarnerCheck' 
,'tsk_01_2040_FileOpening'
,'tsk014'
,'tsk006'
,'tsk004'
)
) AS Summary

END
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
















CREATE PROCEDURE [dbo].[LTAMilestoneFileOpening] --EXEC dbo.LTAMilestoneFileOpening '2021-02-01','2021-02-25'
(
@StartDate  AS DATE
,@EndDate  AS DATE
)
AS 
BEGIN

--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate='2020-05-01'
--SET @EndDate='2020-11-25'

SELECT 
       NewTaskDesc AS Display_Name,
	   [Task Filter Code],
       Summary.[Fee Earner],
       Summary.[Business Line],
       Summary.[Practice Area],
       Summary.Team,
       Summary.[Role Completed By],
	   CASE WHEN NewTaskDesc='REM Complete Conflict Check - Support' THEN 1 
	   WHEN NewTaskDesc='REM File Opening Process - Support' THEN 2
	   WHEN NewTaskDesc='REM Add associates to matter - Support' THEN 3
	   WHEN NewTaskDesc='REM Complete Opening Risk Assessment - Support' THEN 4
	   WHEN NewTaskDesc='ADM: Complete CDD form procedure - Case Handler' THEN 5
	   WHEN NewTaskDesc='REM: Fee earner check – Case Handler' THEN 6
	   WHEN NewTaskDesc='REM: Team Manager File Audit Review - Team Mananger' THEN 7  
	   WHEN NewTaskDesc='ADM: Monthly review - Case Handler' THEN 8  
	   WHEN NewTaskDesc='ADM: Cost Estimate Review – Case Handler' THEN 9  
	   END AS TaskOrder,
       SUM(Summary.[Number Live Matters]) AS [Number Live Matters],
	   SUM(Summary.[Days Diff Between File Open and Data Completed]) AS DateDiff,
	   SUM(ElapsedInstructiontoOpen) AS InstructiontoOpen
	   ,SUM(CASE WHEN Summary.Deleted='Yes' THEN 1 ELSE 0 END) AS [Incomplete Deleted]
	   ,SUM(CASE WHEN Summary.Deleted='No' AND Summary.[Task Completed]='Yes' THEN 1 ELSE 0 END) AS [Completed]
	   ,SUM(CASE WHEN Summary.Deleted='No' AND Summary.[Task Completed]='No' AND Summary.Overdue=1 THEN 1 ELSE 0 END)AS [Incomplete Overdue]
	   ,SUM(CASE WHEN Summary.Deleted='No' AND Summary.[Task Completed]='No' AND Summary.Overdue=0 THEN 1 ELSE 0 END) [Incomplete Not Yet Due]
FROM 
(
SELECT ms_fileid
,master_client_code AS [Client]
,client_name AS [Client Name]
,master_matter_number AS [Matter]
,master_client_code + '-' + master_matter_number AS [File]
,name AS [Display_Name]
,fed_code AS [Fee Earner]
,hierarchylevel2hist AS [Business Line]
,hierarchylevel3hist AS [Practice Area]
,hierarchylevel4hist AS [Team]

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
,red_dw.dbo.datetimelocal(tskDue) AS [Task Due Date]
,CASE WHEN tskComplete=1 THEN 'Yes' ELSE 'No' END  AS [Task Completed]
,red_dw.dbo.datetimelocal(tskCompleted) AS [Date Completed]
,DATEDIFF(DAY,date_opened_case_management,tskCompleted) AS [Days Diff Between File Open and Data Completed]
,usrFullName AS [Completed By]
,CASE WHEN tskActive=0 THEN 'Yes' ELSE 'No' END  AS [Deleted]
,CASE WHEN tskComplete=0 THEN 'Incomplete'
ELSE RoleType END AS [Role Completed By]
,1 AS [Number Live Matters]
,CASE WHEN red_dw.dbo.datetimelocal(tskDue) <CONVERT(DATE,GETDATE(),103) THEN 1 ELSE 0 END Overdue
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
WHERE hierarchylevel2hist='Legal Ops - LTA'
AND 
CONVERT(DATE,date_opened_case_management,103) BETWEEN @StartDate AND @EndDate
AND tskMSStage=1
AND tskFilter IN 
(
'Tsk001','tsk_01_2040_FileOpening','tsk_01_2020_AddAssociates','tsk_01_2090_OpeningRisk'
,'tsk_01_090_ADMCompleteCDD','tsk_02_050_REMReviewMatter','tsk_01_280_admcostsestimatereview','tsk_01_2110_FeeEarnerCheck','tsk_01_560_REMTMAuditRF'
,'tsk004','tsk014','tsk006'

)
) AS Summary

GROUP BY Summary.Display_Name,
       Summary.[Fee Earner],
       Summary.[Business Line],
       Summary.[Practice Area],
       Summary.Team,
       Summary.[Role Completed By],NewTaskDesc,[Task Filter Code]
END


GO

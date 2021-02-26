SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [dbo].[LTAMilestoneFileOpeningMatters] --EXEC dbo.LTAMilestoneFileOpeningMatters '2020-05-01','2020-11-25'
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


SELECT ms_fileid
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
,date_opened_case_management AS [File Open Date]
,date_instructions_received AS [Date Instructions Received]
,DATEDIFF(DAY,date_instructions_received,date_opened_case_management) AS ElapsedInstructiontoOpen
,1 AS [Number Live Matters]
,CASE WHEN date_instructions_received IS NOT NULL  AND DATEDIFF(DAY,date_instructions_received,date_opened_case_management)<=1 THEN 1 ELSE 0 END  AS Within1Day
,CASE WHEN date_instructions_received IS NULL THEN 1
WHEN DATEDIFF(DAY,date_instructions_received,date_opened_case_management)>1 THEN 1 ELSE 0 END AS NotWithin1Day

,CASE WHEN FeeEarner.FeeEarnerCompleted IS NULL THEN 0
WHEN date_instructions_received IS NOT NULL  AND DATEDIFF(DAY,date_instructions_received,FeeEarner.FeeEarnerCompleted)<=1 THEN 1 ELSE 0 END  AS FeeEarnerWithin1Day
,CASE WHEN FeeEarner.FeeEarnerCompleted IS NULL THEN 1
WHEN date_instructions_received IS NULL THEN 1
WHEN DATEDIFF(DAY,date_instructions_received,FeeEarner.FeeEarnerCompleted)>1 THEN 1 ELSE 0 END AS FeeEarnerNotWithin1Day


,CASE WHEN TM.TMCompleted IS NULL THEN 0
WHEN date_instructions_received IS NOT NULL  AND DATEDIFF(DAY,date_instructions_received,TM.TMCompleted)<=1 THEN 1 ELSE 0 END  AS TMWithin1Day
,CASE WHEN TM.TMCompleted IS NULL THEN 1
WHEN date_instructions_received IS NULL THEN 1
WHEN DATEDIFF(DAY,date_instructions_received,TM.TMCompleted)>1 THEN 1 ELSE 0 END AS TMNotWithin1Day


FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
 AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype  WITH(NOLOCK)
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN 
(
SELECT fileID,MIN(red_dw.dbo.datetimelocal(tskCompleted)) AS FeeEarnerCompleted
FROM ms_prod.dbo.dbTasks
WHERE tskFilter IN ('tsk_01_090_ADMCompleteCDD','tsk_02_050_REMReviewMatter')
AND tskComplete=1
AND tskActive=1
GROUP BY fileID
) AS FeeEarner
ON ms_fileid=FeeEarner.fileID
LEFT OUTER JOIN 
(
SELECT fileID,MIN(red_dw.dbo.datetimelocal(tskCompleted)) AS TMCompleted
FROM ms_prod.dbo.dbTasks
WHERE tskFilter IN ('tsk_01_280_admcostsestimatereview','tsk_01_560_REMTMAuditRF')
AND tskComplete=1
AND tskActive=1
GROUP BY fileID
) AS TM
ON ms_fileid=TM.fileID

WHERE hierarchylevel2hist='Legal Ops - LTA'
AND date_opened_case_management BETWEEN @StartDate AND @EndDate


END 
GO

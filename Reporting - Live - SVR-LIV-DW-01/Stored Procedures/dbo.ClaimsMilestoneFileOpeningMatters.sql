SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











CREATE PROCEDURE [dbo].[ClaimsMilestoneFileOpeningMatters] --EXEC dbo.ClaimsMilestoneFileOpeningMatters '2020-05-01','2020-11-25'
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

,CASE WHEN ClientCare.ClientCareCompleted IS NULL THEN 0
WHEN date_instructions_received IS NOT NULL  AND DATEDIFF(DAY,date_instructions_received,ClientCare.ClientCareCompleted)<=1 THEN 1 ELSE 0 END  AS ClientCareWithin1Day
,CASE WHEN ClientCare.ClientCareCompleted IS NULL THEN 1
WHEN date_instructions_received IS NULL THEN 1
WHEN DATEDIFF(DAY,date_instructions_received,ClientCare.ClientCareCompleted)>1 THEN 1 ELSE 0 END AS ClientCareNotWithin1Day

,CASE WHEN ConflictSearch.ConflictSearchCompleted IS NULL THEN 0
WHEN date_instructions_received IS NOT NULL  AND DATEDIFF(DAY,date_instructions_received,ConflictSearch.ConflictSearchCompleted)<=1 THEN 1 ELSE 0 END  AS ConflictSearchWithin1Day
,CASE WHEN ConflictSearch.ConflictSearchCompleted IS NULL THEN 1
WHEN date_instructions_received IS NULL THEN 1
WHEN DATEDIFF(DAY,date_instructions_received,ConflictSearch.ConflictSearchCompleted)>1 THEN 1 ELSE 0 END AS ConflictSearchNotWithin1Day

,ClientCare.ClientCareCompleted
,ConflictSearch.ConflictSearchCompleted


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
SELECT fileID,MIN(tskCompleted) AS ClientCareCompleted
FROM ms_prod.dbo.dbTasks
WHERE tskFilter='tsk_031_01_010_ClientCare'
AND tskComplete=1
AND tskActive=1
GROUP BY fileID
) AS ClientCare
ON ms_fileid=ClientCare.fileID
LEFT OUTER JOIN 
(
SELECT fileID,MIN(tskCompleted) AS ConflictSearchCompleted
FROM ms_prod.dbo.dbTasks
WHERE tskFilter='tsk_065_01_020_ConflictSearch'
AND tskComplete=1
AND tskActive=1
GROUP BY fileID
) AS ConflictSearch
ON ms_fileid=ConflictSearch.fileID
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND date_opened_case_management BETWEEN @StartDate AND @EndDate
AND ISNULL(red_dw.dbo.dim_matter_header_current.present_position,'') NOT IN ('Final bill sent - unpaid','To be closed/minor balances to be clear')
AND ISNULL(referral_reason,'')<>'Advice only'
AND ISNULL(referral_reason,'')<> 'In House'

END 
GO

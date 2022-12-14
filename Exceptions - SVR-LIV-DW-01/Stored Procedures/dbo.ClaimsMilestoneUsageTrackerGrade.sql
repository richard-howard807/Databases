SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [dbo].[ClaimsMilestoneUsageTrackerGrade]

AS 

BEGIN

SELECT hierarchylevel2hist AS Division
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,name AS [Fee Earner]
,fed_code AS [FedCode]
,master_client_code AS [Client]
,master_matter_number AS [Matter Number]
,matter_description AS [Matter Descripiton]
,date_opened_case_management AS [Date Opened]
,referral_reason AS [Referral Reason]
,dim_detail_core_details.present_position AS [Present Position]
,ISNULL(MilestoneTasks.[Processes Used],0) AS [Processes Used] 
,ISNULL(MilestoneTasks.Milestones,0) AS [Milestones Used]
,ISNULL([Precedents Used],0) AS [Precedents Used]
,Filtered.levelidud AS Grade
,CASE WHEN levelidud IN 
(
'Equity Partner','Fixed Share Partner','Paralegal','Associate','Principal Associate','Solicitor','Trainee'
) THEN 1 ELSE 0 END  AS ExtraFilter
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN (SELECT dim_matter_header_curr_key
,hierarchylevel2hist 
,hierarchylevel3hist
,hierarchylevel4hist
,name
,fed_code
,levelidud
,CASE WHEN levelidud IN 
(
'Equity Partner','Fixed Share Partner','Paralegal','Associate','Principal Associate','Solicitor','Trainee'
) THEN 1 ELSE 0 END  AS ExtraFilter
FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
 AND dss_current_flag='Y' AND hierarchylevel2hist='Legal Ops - Claims'
 AND activeud=1
LEFT OUTER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
 WHERE date_closed_case_management IS NULL) AS Filtered
  ON Filtered.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH(NOLOCK)
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT fileID,COUNT(1) AS [Processes Used]
,COUNT(DISTINCT tskMSStage) AS  Milestones
FROM MS_Prod.dbo.dbTasks WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON ms_fileid=fileID
WHERE tskMSStage IS NOT NULL
AND tskActive=1
AND date_closed_case_management IS NULL
AND tskComplete=1
GROUP BY fileID) AS MilestoneTasks
 ON ms_fileid=MilestoneTasks.fileID
LEFT OUTER JOIN
(
SELECT fileID,COUNT(1) AS [Precedents Used]--SELECT fileID,docDesc,PrecDesc,PrecTitle 
FROM MS_Prod.config.dbDocument WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON ms_fileid=fileID
INNER JOIN MS_Prod.dbo.dbPrecedents WITH(NOLOCK)
 ON PrecID=docprecID
WHERE PrecTitle NOT IN ('Default Shell File','DEFAULT')
AND date_closed_case_management IS NULL
GROUP BY fileID
) AS Prec
 ON ms_fileid=Prec.fileID
WHERE date_closed_case_management IS NULL
AND ISNULL(red_dw.dbo.dim_matter_header_current.present_position,'') NOT IN ('Final bill sent - unpaid','To be closed/minor balances to be clear')
AND ISNULL(referral_reason,'')<>'Advice only'
AND ISNULL(referral_reason,'')<> 'In House'
--AND Filtered.fed_code='4493'
END








GO

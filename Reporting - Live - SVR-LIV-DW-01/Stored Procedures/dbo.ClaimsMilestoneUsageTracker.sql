SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[ClaimsMilestoneUsageTracker]

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
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN (SELECT dim_matter_header_curr_key
,hierarchylevel2hist 
,hierarchylevel3hist
,hierarchylevel4hist
,name
,fed_code
FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
 AND dss_current_flag='Y' AND hierarchylevel2hist='Legal Ops - Claims'
 AND activeud=1
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
AND NOT ms_fileid NOT IN 
(5090820,5090832,5090835,5090842,5090848,5090853,5091073,5091288,5091677
,5096365,5097171,5097193,5097355,5097677,5097684,5097751,5098182,5098201
,5098209,5098213,5098214,5098218,5098222,5098226,5098228,5098515,5098518
,5098521,5098530,5098898,5099062,5099250) --Old Remedy Cases to exclude per request from Bob H
END








GO

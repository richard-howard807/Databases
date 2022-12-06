SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DefendantTrustDuplicateNameCheck]

AS 
BEGIN
SELECT
RTRIM(master_client_code)+'-'+RTRIM(master_matter_number)  AS [Matter ID]
,date_opened_case_management AS [Date opened]
,date_closed_case_management AS [Date closed]
,defendant_trust AS [Defendant Trust]
,nhs_second_defendant_trust AS [Second Defendant Trust]
,nhsr_defendant_trust_multi_def AS [Defendant trust (multi def)]	
FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_detail_health
 ON dim_detail_health.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
 ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN 
(
SELECT dim_matter_header_curr_key,nhsr_defendant_trust_multi_def FROM red_dw.dbo.dim_child_detail
INNER JOIN red_dw.dbo.dim_parent_detail
 ON dim_parent_detail.dim_parent_key = dim_child_detail.dim_parent_key
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = dim_parent_detail.client_code
 AND dim_matter_header_current.matter_number = dim_parent_detail.matter_number
WHERE nhsr_defendant_trust_multi_def IS NOT NULL
) AS nhsr_defendant_trust_multi_def
ON nhsr_defendant_trust_multi_def.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE defendant_trust IN
(
'Essex Partnership University NHS Foundation Trust'
,'North Essex Partnership NHS Foundation Trust'
,'Royal Wolverhampton NHS Trust (The)'
,'The Royal Wolverhampton NHS Trust'
,'Princess Alexandra Hospital NHS Trust'
,'The Princess Alexandra Hospital NHS Trust (The)'
,'Newcastle upon Tyne Hospitals NHS Foundation Trust (The)'
,'Newcastle-Upon-Tyne Hospitals NHS Foundation Trust'
) 
OR
nhs_second_defendant_trust IN
(
'Essex Partnership University NHS Foundation Trust'
,'North Essex Partnership NHS Foundation Trust'
,'Royal Wolverhampton NHS Trust (The)'
,'The Royal Wolverhampton NHS Trust'
,'Princess Alexandra Hospital NHS Trust'
,'The Princess Alexandra Hospital NHS Trust (The)'
,'Newcastle upon Tyne Hospitals NHS Foundation Trust (The)'
,'Newcastle-Upon-Tyne Hospitals NHS Foundation Trust'
)
OR
nhsr_defendant_trust_multi_def IN
(
'Essex Partnership University NHS Foundation Trust'
,'North Essex Partnership NHS Foundation Trust'
,'Royal Wolverhampton NHS Trust (The)'
,'The Royal Wolverhampton NHS Trust'
,'Princess Alexandra Hospital NHS Trust'
,'The Princess Alexandra Hospital NHS Trust (The)'
,'Newcastle upon Tyne Hospitals NHS Foundation Trust (The)'
,'Newcastle-Upon-Tyne Hospitals NHS Foundation Trust'
)
END
GO

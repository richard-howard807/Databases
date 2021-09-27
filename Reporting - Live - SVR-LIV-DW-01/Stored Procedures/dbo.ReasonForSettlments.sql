SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ReasonForSettlments]
AS 

BEGIN
SELECT 
RTRIM(master_client_code) + '-'+RTRIM(master_matter_number) AS [client and matter number]
,matter_description [matter description]
,client_name [client name]
,date_opened_case_management [date opened]
,date_closed_case_management [date closed]
,name [matter owner]
,hierarchylevel4hist [team]
,hierarchylevel3hist [department]
,dim_detail_core_details.[referral_reason] AS  [referral reason]
,dim_detail_core_details.[present_position] AS  [present position]
,dim_detail_core_details.[suspicion_of_fraud] AS  [suspicion of fraud]
,dim_detail_core_details.[injury_type] AS  [injury type]
,dim_detail_outcome.[outcome_of_case] AS  [outcome]
,ISNULL(dim_detail_health.[reason_for_settlement],dim_detail_outcome.reason_for_settlement) AS [reason for outcome]
,reasons_for_successful_outcome [reason for success]
,date_claim_concluded [date claim concluded]
,damages_paid [damages paid]
FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH(NOLOCK)
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome WITH(NOLOCK)
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary WITH(NOLOCK)
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_health WITH(NOLOCK)
 ON dim_detail_health.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE UPPER(referral_reason) LIKE '%DISP%'
AND 
(
dim_detail_health.[reason_for_settlement] IS NOT NULL OR 
dim_detail_outcome.[reason_for_settlement] IS NOT NULL OR 
dim_detail_outcome.reasons_for_successful_outcome IS NOT NULL
)
END 
GO

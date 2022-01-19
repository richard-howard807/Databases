SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GBListingReport]-- 'GB Associates'
(
@Filter AS NVARCHAR(20)
)
AS 

BEGIN

IF @Filter='All'

BEGIN

SELECT 
RTRIM(master_client_code) +'-'+RTRIM(master_matter_number) AS [Client/Matter Number]
,matter_description AS [Matter Description]
,dim_matter_header_current.date_opened_case_management AS [Date Opened]
,dim_matter_header_current.date_closed_case_management AS [Date Closed]
,name AS [Case Manager]
,work_type_name AS [Matter Type]
,insurerclient_name AS [Insurer Client]
,insurerclient_reference AS [Insurer Client Ref]
,insuredclient_name AS [Insured client name]
,insuredclient_reference AS [Insured Client Ref]
,dim_detail_core_details.[present_position] AS [Present position]
,dim_detail_core_details.[referral_reason] AS [Referral reason]
,dim_detail_core_details.[proceedings_issued] AS [Proceedings issued?]
,dim_detail_core_details.[track] AS [Track]
,dim_detail_core_details.[suspicion_of_fraud] AS [Suspicion of fraud?]
,dim_detail_finance.[output_wip_fee_arrangement] AS [Fee Arrangement]
,dim_detail_core_details.[incident_date] AS [Incident date]
,dim_detail_core_details.[injury_type] AS [Injury Type]
,dim_detail_claim.[dst_claimant_solicitor_firm] AS [Claimant Solicitor]
,fact_finance_summary.[damages_reserve] AS [Damages Reserve (gross)]
,fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [Claimant's Costs Reserve (gross)]
,fact_finance_summary.[defence_costs_reserve] AS [Defence Costs Reserve (gross)]
,fact_finance_summary.[other_defendants_costs_reserve] AS [Other Defendants Costs Reserve (Gross)]
,dim_detail_outcome.[outcome_of_case] AS [Outcome]
,dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded]
,fact_finance_summary.[damages_paid] AS [Damages Paid by Client]
,dim_detail_outcome.[date_costs_settled] AS [Date Costs Settled]
,fact_finance_summary.[claimants_costs_paid] AS [Claimant's Costs Paid by Client]
,fact_finance_summary.[detailed_assessment_costs_paid] AS [Detailed Assessment Costs Paid]
,fact_finance_summary.[other_defendants_costs_paid] AS [Costs Paid to Other Defendant]
,fact_finance_summary.[total_recovery] AS [Total Recovery]
,total_amount_billed AS [Total Billed]
,defence_costs_billed AS [Revenue]
,disbursements_billed AS [Disbursements Billed]
,vat_billed AS [VAT]
,NULL AS [Date of Last Bill]
,wip AS [WIP]
,fact_finance_summary.disbursement_balance AS [Unbilled Disbursements]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN (SELECT dim_matter_header_curr_key
FROM red_dw.dbo.dim_matter_header_current
WHERE master_client_code='G1001'
UNION
SELECT dim_matter_header_curr_key
FROM MS_Prod.config.dbAssociates WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON ms_fileid=fileID
INNER JOIN MS_Prod.config.dbContact  WITH(NOLOCK)
ON dbContact.contID = dbAssociates.contID
WHERE LOWER(contName) LIKE '%gallagher bassett%'
UNION
SELECT dim_matter_header_curr_key FROM axxia01.dbo.invol
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.case_id = invol.case_id
INNER JOIN axxia01.dbo.caclient  ON entity_code=cl_accode
WHERE LOWER(cl_clname) LIKE '%gallagher bassett%') AS Cases
 ON Cases.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current 
ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim 
 ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance 
 ON dim_detail_finance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE dim_matter_header_current.date_closed_case_management IS NULL OR dim_matter_header_current.date_closed_case_management>='2018-05-01' 


END

IF @Filter='GB Client'

BEGIN

SELECT 
RTRIM(master_client_code) +'-'+RTRIM(master_matter_number) AS [Client/Matter Number]
,matter_description AS [Matter Description]
,dim_matter_header_current.date_opened_case_management AS [Date Opened]
,dim_matter_header_current.date_closed_case_management AS [Date Closed]
,name AS [Case Manager]
,work_type_name AS [Matter Type]
,insurerclient_name AS [Insurer Client]
,insurerclient_reference AS [Insurer Client Ref]
,insuredclient_name AS [Insured client name]
,insuredclient_reference AS [Insured Client Ref]
,dim_detail_core_details.[present_position] AS [Present position]
,dim_detail_core_details.[referral_reason] AS [Referral reason]
,dim_detail_core_details.[proceedings_issued] AS [Proceedings issued?]
,dim_detail_core_details.[track] AS [Track]
,dim_detail_core_details.[suspicion_of_fraud] AS [Suspicion of fraud?]
,dim_detail_finance.[output_wip_fee_arrangement] AS [Fee Arrangement]
,dim_detail_core_details.[incident_date] AS [Incident date]
,dim_detail_core_details.[injury_type] AS [Injury Type]
,dim_detail_claim.[dst_claimant_solicitor_firm] AS [Claimant Solicitor]
,fact_finance_summary.[damages_reserve] AS [Damages Reserve (gross)]
,fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [Claimant's Costs Reserve (gross)]
,fact_finance_summary.[defence_costs_reserve] AS [Defence Costs Reserve (gross)]
,fact_finance_summary.[other_defendants_costs_reserve] AS [Other Defendants Costs Reserve (Gross)]
,dim_detail_outcome.[outcome_of_case] AS [Outcome]
,dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded]
,fact_finance_summary.[damages_paid] AS [Damages Paid by Client]
,dim_detail_outcome.[date_costs_settled] AS [Date Costs Settled]
,fact_finance_summary.[claimants_costs_paid] AS [Claimant's Costs Paid by Client]
,fact_finance_summary.[detailed_assessment_costs_paid] AS [Detailed Assessment Costs Paid]
,fact_finance_summary.[other_defendants_costs_paid] AS [Costs Paid to Other Defendant]
,fact_finance_summary.[total_recovery] AS [Total Recovery]
,total_amount_billed AS [Total Billed]
,defence_costs_billed AS [Revenue]
,disbursements_billed AS [Disbursements Billed]
,vat_billed AS [VAT]
,NULL AS [Date of Last Bill]
,wip AS [WIP]
,fact_finance_summary.disbursement_balance AS [Unbilled Disbursements]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN (SELECT dim_matter_header_curr_key
FROM red_dw.dbo.dim_matter_header_current
WHERE master_client_code='G1001'
UNION
SELECT dim_matter_header_curr_key
FROM MS_Prod.config.dbAssociates WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON ms_fileid=fileID
INNER JOIN MS_Prod.config.dbContact  WITH(NOLOCK)
ON dbContact.contID = dbAssociates.contID
WHERE LOWER(contName) LIKE '%gallagher bassett%'
UNION
SELECT dim_matter_header_curr_key FROM axxia01.dbo.invol
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.case_id = invol.case_id
INNER JOIN axxia01.dbo.caclient  ON entity_code=cl_accode
WHERE LOWER(cl_clname) LIKE '%gallagher bassett%') AS Cases
 ON Cases.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current 
ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim 
 ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance 
 ON dim_detail_finance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE dim_matter_header_current.date_closed_case_management IS NULL OR dim_matter_header_current.date_closed_case_management>='2018-05-01' 
AND master_client_code='G1001'
END



IF @Filter='GB Associates'

BEGIN

SELECT 
RTRIM(master_client_code) +'-'+RTRIM(master_matter_number) AS [Client/Matter Number]
,matter_description AS [Matter Description]
,dim_matter_header_current.date_opened_case_management AS [Date Opened]
,dim_matter_header_current.date_closed_case_management AS [Date Closed]
,name AS [Case Manager]
,work_type_name AS [Matter Type]
,insurerclient_name AS [Insurer Client]
,insurerclient_reference AS [Insurer Client Ref]
,insuredclient_name AS [Insured client name]
,insuredclient_reference AS [Insured Client Ref]
,dim_detail_core_details.[present_position] AS [Present position]
,dim_detail_core_details.[referral_reason] AS [Referral reason]
,dim_detail_core_details.[proceedings_issued] AS [Proceedings issued?]
,dim_detail_core_details.[track] AS [Track]
,dim_detail_core_details.[suspicion_of_fraud] AS [Suspicion of fraud?]
,dim_detail_finance.[output_wip_fee_arrangement] AS [Fee Arrangement]
,dim_detail_core_details.[incident_date] AS [Incident date]
,dim_detail_core_details.[injury_type] AS [Injury Type]
,dim_detail_claim.[dst_claimant_solicitor_firm] AS [Claimant Solicitor]
,fact_finance_summary.[damages_reserve] AS [Damages Reserve (gross)]
,fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [Claimant's Costs Reserve (gross)]
,fact_finance_summary.[defence_costs_reserve] AS [Defence Costs Reserve (gross)]
,fact_finance_summary.[other_defendants_costs_reserve] AS [Other Defendants Costs Reserve (Gross)]
,dim_detail_outcome.[outcome_of_case] AS [Outcome]
,dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded]
,fact_finance_summary.[damages_paid] AS [Damages Paid by Client]
,dim_detail_outcome.[date_costs_settled] AS [Date Costs Settled]
,fact_finance_summary.[claimants_costs_paid] AS [Claimant's Costs Paid by Client]
,fact_finance_summary.[detailed_assessment_costs_paid] AS [Detailed Assessment Costs Paid]
,fact_finance_summary.[other_defendants_costs_paid] AS [Costs Paid to Other Defendant]
,fact_finance_summary.[total_recovery] AS [Total Recovery]
,total_amount_billed AS [Total Billed]
,defence_costs_billed AS [Revenue]
,disbursements_billed AS [Disbursements Billed]
,vat_billed AS [VAT]
,NULL AS [Date of Last Bill]
,wip AS [WIP]
,fact_finance_summary.disbursement_balance AS [Unbilled Disbursements]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN (SELECT dim_matter_header_curr_key
FROM red_dw.dbo.dim_matter_header_current
WHERE master_client_code='G1001'
UNION
SELECT dim_matter_header_curr_key
FROM MS_Prod.config.dbAssociates WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON ms_fileid=fileID
INNER JOIN MS_Prod.config.dbContact  WITH(NOLOCK)
ON dbContact.contID = dbAssociates.contID
WHERE LOWER(contName) LIKE '%gallagher bassett%'
UNION
SELECT dim_matter_header_curr_key FROM axxia01.dbo.invol
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.case_id = invol.case_id
INNER JOIN axxia01.dbo.caclient  ON entity_code=cl_accode
WHERE LOWER(cl_clname) LIKE '%gallagher bassett%') AS Cases
 ON Cases.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current 
ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim 
 ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance 
 ON dim_detail_finance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE dim_matter_header_current.date_closed_case_management IS NULL OR dim_matter_header_current.date_closed_case_management>='2018-05-01' 
AND master_client_code<>'G1001'
END
END 
GO

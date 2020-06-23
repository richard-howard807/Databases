SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[TopMark]
AS
BEGIN
SELECT master_client_code +'.' + master_matter_number  AS [Client/Matter Number]
,dim_matter_header_current.client_name AS [Client Name]
,RTRIM(matter_description) AS [Matter Description]
,dim_matter_header_current.date_opened_case_management AS [Date Opened]
,dim_matter_header_current.date_closed_practice_management AS [Date Closed]
,name AS [Case Manager]
,work_type_name AS [Work Type]
,RTRIM(insurerclient_reference) AS [Insurer Client Ref]
,RTRIM(insuredclient_reference) AS [Insured Client Ref]
,dim_detail_core_details.[present_position] AS [Present position]
,dim_detail_core_details.[referral_reason] AS [Referral reason]
,dim_detail_core_details.[proceedings_issued] AS [Proceedings issued?]
,dim_detail_core_details.[track] AS [Track]
,dim_detail_core_details.[suspicion_of_fraud] AS [Suspicion of fraud?]
,dim_detail_finance.[output_wip_fee_arrangement] AS [Fee Arrangement]
,dim_detail_core_details.[incident_date] AS [Incident date]
,dim_detail_core_details.[injury_type] AS [Injury Type]
,dim_detail_claim.[dst_claimant_solicitor_firm ] AS [Claimant Solicitor]
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
,fact_finance_summary.total_amount_billed AS [Total Billed]
,fact_finance_summary.defence_costs_billed AS [Revenue]
,fact_finance_summary.disbursements_billed AS [Disbursements Billed]
,fact_finance_summary.vat_billed AS [VAT]
,last_bill_date AS [Date of Last Bill]
,wip AS [WIP]
,fact_finance_summary.disbursement_balance AS [Unbilled Disbursements]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
 ON dim_detail_claim.client_code = dim_matter_header_current.client_code
 AND dim_detail_claim.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
 LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
 ON dim_detail_finance.client_code = dim_matter_header_current.client_code
 AND dim_detail_finance.matter_number = dim_matter_header_current.matter_number
 LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
  LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
   LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
  ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
 AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
  ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
WHERE red_dw.dbo.dim_matter_header_current.client_code='W21295'--='W21259'
AND reporting_exclusions=0

END 
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[PWCDashboardData]

AS 

BEGIN 
SELECT 
master_client_code + '-' + master_matter_number AS [MatterSphere Client/Matter Ref]
,matter_description AS [Matter Description]
,dim_matter_header_current.date_opened_case_management AS [Date Opened]
,dim_matter_header_current.date_closed_case_management AS [Date Closed]
,name AS [Case Manager]
,dim_matter_header_current.client_name AS [Client Name]
,work_type_name AS [Matter Type]
,dim_detail_core_details.[capita_disease_type] AS [Disease Type]
,insurerclient_reference AS [Insurer Client Reference]
,client_reference AS [Client Reference]
,dim_detail_core_details.[capita_category_position_code] AS [Category Position Code]
,dim_detail_core_details.[present_position] AS [Present Position]
,dim_detail_core_details.[ll05_capita_likely_settlement_date] AS [Likely Settlement Date]
,dim_detail_core_details.[capita_fscs_protected_yes_enter_percent_no_leave_blank] AS [FSCS Protected?]
,dim_detail_core_details.[capita_dti_yes_enter_percent_no_leave_blank] AS [DTI?]
,dim_detail_core_details.[proceedings_issued] AS [Proceedings Issued]
,dim_detail_claim.[capita_claimant_medical_expert_name] AS [Claimant Medical Expert]
,dim_detail_claim.[capita_date_prelitigation_claimant_medical_report] AS [Date of Pre-Lit Medical Report]
,dim_detail_claim.[dst_claimant_solicitor_firm] AS [Claimant Solicitors]
,dim_detail_core_details.[incident_date] AS [Date of Loss]
,fact_finance_summary.[damages_reserve] AS [Damages Reserve (Client)]
,fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [Claimant's Costs Reserve (Client)]
,fact_finance_summary.[defence_costs_reserve] AS [Defence Costs Reserve (Client)]
,fact_detail_future_care.[disease_total_estimated_settlement_value] AS [Damages Reserve (100%)]
,fact_detail_claim.[disease_total_estimated_settlement] AS [Claimant's Costs Reserve (100%)]
,fact_detail_cost_budgeting.[total_estimated_profit_costs] AS [Profit Costs Reserve (100%)]
,dim_detail_outcome.[outcome_of_case] AS [Outcome of Case]
,dim_detail_claim.[capita_settlement_basis] AS [Settlement Basis ]
,dim_detail_claim.[capita_stage_of_settlement] AS [Stage of Settlement]
,dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded]
,fact_finance_summary.[damages_paid] AS [Damages Paid (Client)]
,fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] AS [Damages Paid (100%)]
,dim_detail_outcome.[date_costs_settled] AS [Date Costs Settled]
,dim_detail_outcome.[disease_are_we_dealing_with_the_costs] AS [Are we dealing with costs?]
,fact_finance_summary.[claimants_costs_paid] AS [Claimant's Costs Paid (Client)]
,fact_finance_summary.[claimants_total_costs_paid_by_all_parties] AS [Claimant's Costs Paid (100%)]
,dim_detail_outcome.[capita_date_final_fee_paid] AS [Date Final Fee Paid]
,total_amount_bill_non_comp AS [Total Billed]
,defence_costs_billed_composite AS [Revenue]
,disbursements_billed AS [Disbursements]
,vat_non_comp AS [VAT]
,wip AS [WIP]
,fact_finance_summary.disbursement_balance AS [Unpaid bill balance]
,last_bill_date AS [Date of Last Bill]
,last_time_transaction_date AS [Date of Last Posting]

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
 ON dim_detail_claim.client_code = dim_matter_header_current.client_code
 AND dim_detail_claim.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.fact_detail_claim
 ON fact_detail_claim.client_code = dim_matter_header_current.client_code
 AND fact_detail_claim.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting
 ON fact_detail_cost_budgeting.client_code = dim_matter_header_current.client_code
 AND fact_detail_cost_budgeting.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
 ON fact_detail_paid_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_paid_detail.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.fact_detail_future_care
 ON fact_detail_future_care.client_code = dim_matter_header_current.client_code
 AND fact_detail_future_care.matter_number = dim_matter_header_current.matter_number  
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number   
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
 AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number   
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key

WHERE client_group_name='pwc'
ORDER BY ms_fileid

END
GO

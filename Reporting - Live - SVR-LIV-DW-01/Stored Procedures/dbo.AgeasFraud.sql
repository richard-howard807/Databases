SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2021-08-10
-- Description:	Data from Ageas fraud report
-- =============================================
CREATE PROCEDURE [dbo].[AgeasFraud] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   SELECT 
	        dim_matter_header_current.[master_client_code]+'-'+dim_matter_header_current.[master_matter_number] AS [Client/Matter Reference],
	        dim_fed_hierarchy_history.[name] AS [Matter Owner],
			dim_matter_header_current.[matter_description] AS [Matter Description],
			dim_detail_core_details.[referral_reason] AS [Referral Reason],
			fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [Claimant Costs Reserve Current],
            dim_detail_claim.[ageas_office] AS [Office],
            dim_detail_finance.[output_wip_fee_arrangement] AS [Fee Arrangement],
            dim_detail_claim.[ageas_original_fee_handling_basis] AS [Ageas Original Fee Handling Basis],
            dim_detail_claim.[original_fee_handling_basis] AS [Original Fee Handling Basis],
            CASE WHEN dim_matter_header_current.[master_client_code]+'-'+dim_matter_header_current.[master_matter_number]='A3003-5113' THEN 'Trial Loss'
			WHEN dim_matter_header_current.[master_client_code]+'-'+dim_matter_header_current.[master_matter_number]='A3003-982' THEN 'Claim struck out'
			WHEN dim_matter_header_current.[master_client_code]+'-'+dim_matter_header_current.[master_matter_number]='A3003-8786' THEN 'Paid - Concerns resolved'
			WHEN dim_matter_header_current.[master_client_code]+'-'+dim_matter_header_current.[master_matter_number] IN ('A3003-9818','A3003-10073','A3003-10074','A3003-10294') THEN 'Concerns remain - economic decision to pay'
			ELSE dim_detail_claim.[manner_of_dispute_resolution] END AS [Manner of Dispute Resolution],
            dim_detail_claim.[name_of_instructing_insurer] AS [Name of Instructing Insurer],
            dim_client_involvement.[client_reference] AS [Client Reference],
            dim_client_involvement.[insurerclient_reference] AS [Insurer Client Reference],
            dim_client_involvement.[insuredclient_reference] AS [Insured Client Reference],
            dim_detail_core_details.[incident_date] AS [Incident Date],
            dim_matter_header_current.date_opened_case_management AS [Date Opened],
			dim_matter_header_current.date_closed_case_management AS [Date Closed],
            dim_detail_core_details.[fixed_fee] AS [Fixed Fee],
            dim_detail_core_details.[is_this_the_lead_file] AS [Is this the Lead file?],
            dim_detail_core_details.[suspicion_of_fraud] AS [Suspicion of Fraud],
            dim_detail_court.[court_check] AS [Court Check],
            dim_detail_critical_mi.[xl_reference] AS [Reference],
            dim_detail_fraud.[fraud_type_ageas] AS [Fraud Type],
            fact_finance_summary.[fixed_fee_amount] AS [Fixed Fee Amount],
            fact_finance_summary.[total_savings_percent] AS [Total Savings Percent],
            fact_finance_summary.[defence_costs_reserve] AS [Defence Costs Reserve],
            dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded],
            fact_finance_summary.[indemnity_spend] AS [Indemnity Spend],
            fact_finance_summary.[defence_costs_billed] AS [Revenue],
            fact_finance_summary.[wip] AS [WIP],
            fact_finance_summary.[total_recovery] AS [Total Recovery],
            dim_detail_core_details.[proceedings_issued] AS [Proeedings Issued],
            fact_detail_paid_detail.[tp_estimate] AS [Third Party Estimate],
			fact_finance_summary.[damages_reserve] AS [Damages Reserve],
			dim_detail_core_details.[is_this_a_linked_file] AS [Is this a Linked File?],
			fact_finance_summary.[total_billed_disbursements_vat] AS [Total Billed],
            fact_detail_elapsed_days.[turnaround_time] AS [Turnaround Time],
            fact_finance_summary.[paid_disbursements] AS [Paid Disbursements],
            fact_finance_summary.[disbursements_billed] AS [Disbursemnts Billed],
            fact_finance_summary.[disbursement_balance] AS [Disbursement Balance],
			dim_detail_client.[grp_ageas_claimant_number] AS [Claimant Number],
			dim_detail_core_details.[grpageas_case_handler] AS [Case Handler],
			dim_detail_outcome.[outcome_of_case] AS [Outcome],
			dim_detail_core_details.[present_position] AS [Present Position],
				CASE WHEN dim_detail_claim.name_of_instructing_insurer='Tesco Underwriting (TU)' OR dim_client.client_code='T3003' THEN 'Tesco Underwriting (TU)'
				ELSE 'Ageas Insurance Ltd (AIL)' END AS [Insurer],
				CASE WHEN dim_detail_outcome.date_claim_concluded IS NOT NULL AND dim_matter_header_current.date_opened_case_management<'2018-01-01' THEN 'Exclude'
				ELSE 'Include'END AS [Exclusions]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_client
ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud
ON dim_detail_fraud.dim_detail_fraud_key = fact_dimension_main.dim_detail_fraud_key
LEFT OUTER JOIN red_dw.dbo.dim_court_involvement
ON dim_court_involvement.dim_court_involvement_key = fact_dimension_main.dim_court_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client
ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days
ON fact_detail_elapsed_days.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi
ON dim_detail_critical_mi.dim_detail_critical_mi_key = fact_dimension_main.dim_detail_critical_mi_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND fact_dimension_main.matter_number <> 'ML'
AND dim_matter_header_current.client_group_name ='Ageas'
AND dim_detail_core_details.suspicion_of_fraud ='Yes'
AND CASE WHEN dim_detail_claim.name_of_instructing_insurer='Tesco Underwriting (TU)' OR dim_client.client_code='T3003' THEN 'Tesco Underwriting (TU)'
	ELSE 'Ageas Insurance Ltd (AIL)' END = 'Ageas Insurance Ltd (AIL)'
AND ISNULL(dim_detail_claim.referral_reason,'') <> 'Advice only'
AND ISNULL(dim_detail_outcome.outcome_of_case,'') NOT IN ('Exclude from reports','Returned to Client')
AND CASE WHEN dim_detail_outcome.date_claim_concluded IS NOT NULL AND dim_matter_header_current.date_opened_case_management<'2018-01-01' THEN 'Exclude'
	ELSE 'Include'END ='Include'
AND dim_matter_header_current.[master_client_code]+'-'+dim_matter_header_current.[master_matter_number] NOT IN ('A3003-12267','A3003-12305','A3003-12265','A3003-8241','A3003-8627','FW33900-50','A3003-10020','A3003-4993','A3003-5051','A3003-13081','A3003-13142')

END
GO

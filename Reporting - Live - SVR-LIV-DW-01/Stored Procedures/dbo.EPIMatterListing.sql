SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[EPIMatterListing]
AS
BEGIN

DROP TABLE IF EXISTS #epi_matters
DROP TABLE IF EXISTS #last_bill_date
DROP TABLE IF EXISTS #chargeable_hours


SELECT dim_matter_header_current.dim_matter_header_curr_key
INTO #epi_matters
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
WHERE 
	dim_matter_header_current.reporting_exclusions=0
	--AND dim_matter_header_current.department_code = '0012'
	AND RTRIM(dim_matter_worktype.work_type_group) = 'EPI'
	AND ISNULL(dim_matter_header_current.date_closed_practice_management, '9999-12-31') >= '2017-05-01'


SELECT 
	fact_bill_matter_detail_summary.dim_matter_header_curr_key
	, CAST(MAX(fact_bill_matter_detail_summary.bill_date) AS DATE)			AS last_bill_date
INTO #last_bill_date
FROM red_dw.dbo.fact_bill_matter_detail_summary
	INNER JOIN #epi_matters
		ON #epi_matters.dim_matter_header_curr_key = fact_bill_matter_detail_summary.dim_matter_header_curr_key
GROUP BY	
	fact_bill_matter_detail_summary.dim_matter_header_curr_key


SELECT 
	fact_billable_time_activity.dim_matter_header_curr_key
	, SUM(fact_billable_time_activity.minutes_recorded)			AS chargeable_hours
INTO #chargeable_hours
FROM red_dw.dbo.fact_billable_time_activity WITH(NOLOCK)
	INNER JOIN #epi_matters
		ON #epi_matters.dim_matter_header_curr_key = fact_billable_time_activity.dim_matter_header_curr_key
GROUP BY 
	fact_billable_time_activity.dim_matter_header_curr_key




SELECT 
	COALESCE(NULLIF(dim_matter_header_current.client_group_name, ''), dim_matter_header_current.client_name)		AS [Client Name/Client Group]
	, dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number			AS [Mattersphere Client/Matter Number]
	, dim_matter_header_current.matter_description				AS [Matter Description]
	, dim_fed_hierarchy_history.name			AS [Case Manager]
	, dim_fed_hierarchy_history.hierarchylevel4hist		AS [Team]
	, CAST(dim_matter_header_current.date_opened_case_management AS DATE)		AS [Date Opened (MS)]
	, CAST(dim_matter_header_current.date_closed_case_management AS DATE)		AS [Date Closed (MS)]
	, dim_matter_worktype.work_type_name				AS [Matter Type]
	, dim_detail_core_details.emp_litigatednonlitigated			AS [Litigated/Non-Litigated]
	, dim_instruction_type.instruction_type				AS [Instruction Type (RMG)]
	, COALESCE(dim_detail_practice_area.primary_case_classification, dim_detail_advice.emph_primary_issue, dim_detail_advice.lbs_issue, dim_detail_advice.issue)		AS [Primary Issue]
	, COALESCE(dim_detail_practice_area.secondary_case_classification, dim_detail_advice.emph_secondary_issue, dim_detail_advice.lbs_secondary_issue, dim_detail_advice.secondary_issue)	AS [Secondary Issue]
	, COALESCE(dim_detail_client.emp_case_classification, dim_detail_advice.case_classification, dim_detail_advice.tgif_classification)		AS [Case Classification]
	, dim_detail_client.emp_rmg_sensitive_case			AS [Sensitive Case?]
	, dim_detail_advice.policy_issue			AS [Policy Issue]
	, dim_detail_advice.diversity_issue			AS [Diversity Issue]
	, dim_detail_practice_area.emp_claimant_represented			AS [Claimant Represented]
	, dim_claimant_thirdparty_involvement.claimantsols_name		AS [Claimant Solicitor (From Associate)]
	, dim_detail_claim.dst_claimant_solicitor_firm			AS [Claimant Solicitor (Data Services)]
	, CAST(dim_detail_advice.employment_start_date AS DATE)			AS [Employment Start Date]
	, COALESCE(dim_detail_client.emp_claimants_place_of_work, dim_detail_advice.swissport_station, dim_detail_advice.site, dim_detail_advice.workplace_postcode)	AS [Claimant's Place of Work]
	, COALESCE(dim_detail_practice_area.emp_present_position, dim_detail_advice.status, dim_detail_advice.lbs_status)			AS [Present Position]
	, fact_detail_reserve_detail.potential_compensation				AS [Potential Compensation]
	, dim_detail_client.financial_risk					AS [Financial Risk]
	, COALESCE(dim_detail_practice_area.emp_prospects_of_success, dim_detail_client.case_prospects)		AS [Prospects of Success]
	, dim_detail_client.reputational_risk				AS [Reputational Risk]
	, dim_detail_advice.risk					AS [Risk]
	, CAST(dim_detail_court.emp_date_of_final_hearing AS DATE)		AS [Date of Hearing]
	, CAST(dim_detail_court.emp_date_of_preliminary_hearing_case_management AS DATE)			AS [Date of Preliminary Hearing]
	, dim_detail_court.location_of_hearing		AS [Location of Hearing]
	, dim_detail_court.length_of_hearing			AS [Length of Hearing]
	, COALESCE(dim_detail_practice_area.emp_outcome, dim_detail_advice.outcome, dim_detail_advice.lbs_outcome, dim_detail_advice.outcome_pe)		AS [Outcome]
	, fact_detail_paid_detail.actual_compensation		AS [Actual Compensation]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)			AS [Date Claim Concluded]
	, dim_detail_practice_area.emp_stage_of_outcome				AS [Stage of Outcome]
	, COALESCE(dim_detail_client.emp_what_were_the_learning_points, dim_detail_advice.knowledge_gap)			AS [Learning Points/Knowledge Gap]
	, dim_detail_finance.output_wip_fee_arrangement			AS [Fee Arrangement]
	, fact_finance_summary.fixed_fee_amount			AS [Fixed Fee Amount]
	, dim_detail_finance.output_wip_percentage_complete			AS [Percentage Completion]
	, fact_finance_summary.revenue_estimate_net_of_vat			AS [Revenue Estimate (Net of VAT)]
	, fact_detail_reserve_detail.disbursements_estimate_net_of_vat		AS [Disbursements Estimate (Net of VAT)]
	, fact_finance_summary.total_amount_bill_non_comp			AS [Total Billed (Incl. VAT)]
	, fact_finance_summary.defence_costs_billed_composite						AS [Revenue]
	, fact_finance_summary.disbursements_billed				AS [Disbursements]
	, fact_finance_summary.vat_non_comp				AS [VAT]
	, fact_finance_summary.wip				AS [WIP]
	, fact_finance_summary.disbursement_balance			AS [Unbilled Disbursements]
	, #last_bill_date.last_bill_date				AS [Date of Last Bill]
	, #chargeable_hours.chargeable_hours				AS [Chargeable Hours Posted]
	, CAST(fact_matter_summary_current.last_time_transaction_date AS DATE)			[Date of Last Time Posting]
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN #epi_matters
		ON #epi_matters.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
		 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
			AND dss_current_flag='Y'
	LEFT OUTER JOIN red_dw.dbo.dim_detail_practice_area
		 ON dim_detail_practice_area.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key 
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		 ON dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_advice
		ON dim_detail_advice.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_court
		ON dim_detail_court.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_instruction_type
		ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		 ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
		ON fact_detail_paid_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
		ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT JOIN red_dw.dbo.dim_detail_finance 
		ON dim_detail_finance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
		ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
			AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN #last_bill_date
		ON #last_bill_date.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN #chargeable_hours
		ON #chargeable_hours.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
--WHERE 
--	dim_matter_header_current.reporting_exclusions=0
--	--AND dim_matter_header_current.department_code='0012'
--	AND RTRIM(dim_matter_worktype.work_type_group) = 'EPI'
--	AND ISNULL(dim_matter_header_current.date_closed_practice_management, '9999-12-31') >= '2017-05-01'
--	--AND dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number = '808656/749'

END




GO

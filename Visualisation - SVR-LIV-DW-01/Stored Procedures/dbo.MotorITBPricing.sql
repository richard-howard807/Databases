SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2021-01-26
-- Description:	#85917, New one off dashboard for ITB pricing, requested by HF
---- =============================================
CREATE PROCEDURE [dbo].[MotorITBPricing]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--ITB pricing

SELECT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [MS Reference]
	, dim_matter_header_current.master_client_code AS [Client Code]
	, dim_matter_header_current.matter_description AS [Matter Description]
	, dim_detail_core_details.[credit_hire] AS [Credit Hire]
	, dim_detail_core_details.[suspicion_of_fraud] AS [Suspicion of Fraud]
	, dim_detail_outcome.[date_claim_concluded] AS [Date claim concluded]
	, YEAR(dim_detail_outcome.[date_claim_concluded]) AS [Year (calendar) claim concluded]
	, dim_detail_outcome.[outcome_of_case] AS [Outcome]
	, dim_detail_core_details.[does_claimant_have_personal_injury_claim] AS [Claim for PI?]
	, dim_detail_core_details.[track] AS [Track]
	, dim_detail_core_details.proceedings_issued AS [Proceedings Issued]
	, dim_detail_finance.output_wip_fee_arrangement AS [Fee Arrangement]
	, fact_detail_paid_detail.[hire_claimed] AS [Hire Claimed]
	, CASE WHEN fact_detail_paid_detail.[hire_claimed] BETWEEN 0 AND 10000 THEN '£0-£10k'
			WHEN fact_detail_paid_detail.[hire_claimed] BETWEEN 10000 AND 25000 THEN '£10k-£25k'
			WHEN fact_detail_paid_detail.[hire_claimed] BETWEEN 25000 AND 50000 THEN '£25k-£50k'
			WHEN fact_detail_paid_detail.[hire_claimed] BETWEEN 50000 AND 100000 THEN '£50k-£100k'
			WHEN fact_detail_paid_detail.[hire_claimed] > 100000 THEN '£100k+'
			END AS [Hire Claimed Banding]
	, fact_detail_paid_detail.[amount_hire_paid] AS [Hire Paid]
	, ISNULL(fact_detail_paid_detail.[hire_claimed],0)-ISNULL(fact_detail_paid_detail.[amount_hire_paid],0) AS [Hire Saved]
	, COALESCE(IIF(dim_detail_hire_details.[credit_hire_organisation_cho] = 'Other', NULL, dim_detail_hire_details.[credit_hire_organisation_cho]), dim_detail_hire_details.[other], dim_agents_involvement.cho_name)  AS [Credit Hire Organisation]
	, ISNULL(dim_detail_claim.[dst_claimant_solicitor_firm ],dim_claimant_thirdparty_involvement.[claimantsols_name]) AS [Claimant sol]
	, CASE WHEN COALESCE(IIF(dim_detail_hire_details.[credit_hire_organisation_cho] = 'Other', NULL, dim_detail_hire_details.[credit_hire_organisation_cho]), dim_detail_hire_details.[other], dim_agents_involvement.cho_name) IN ('McAms','Direct Accident Management (Dams)','Bond Turner','Bond Turner Ltd','Direct Accident Management')
	OR ISNULL(dim_detail_claim.[dst_claimant_solicitor_firm ],dim_claimant_thirdparty_involvement.[claimantsols_name]) IN ('McAms','Direct Accident Management (Dams)','Bond Turner','Bond Turner Ltd','Direct Accident Management') THEN 'Yes' ELSE 'No' END AS [Fraud CHO]
	, fact_finance_summary.[damages_reserve] AS [Total damages reserve current]
	, fact_detail_cost_budgeting.[personal_injury_reserve_current] AS [PI reserve]
	, fact_detail_reserve_detail.[general_damages_non_pi_misc_reserve_current] AS [SD Reserve]
	, fact_finance_summary.[damages_paid] AS [Total Damages Paid]
	, fact_detail_paid_detail.[personal_injury_paid] AS [PI paid]
	, fact_detail_paid_detail.[general_damages_misc_paid] AS [SD Paid]
	, fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [TP Costs reserve]
	, fact_finance_summary.[tp_total_costs_claimed] AS [Costs Claimed]
	, fact_finance_summary.[claimants_costs_paid] AS [Costs Paid]

	, fact_detail_reserve_detail.[indemnity_reserve] AS [Indemnity reserve]
	, CASE WHEN fact_detail_reserve_detail.[indemnity_reserve] BETWEEN 0 AND 10000 THEN '£0-£10k'
			WHEN fact_detail_reserve_detail.[indemnity_reserve] BETWEEN 10000 AND 25000 THEN '£10k-£25k'
			WHEN fact_detail_reserve_detail.[indemnity_reserve] BETWEEN 25000 AND 50000 THEN '£25k-£50k'
			WHEN fact_detail_reserve_detail.[indemnity_reserve] BETWEEN 50000 AND 100000 THEN '£50k-£100k'
			WHEN fact_detail_reserve_detail.[indemnity_reserve] > 100000 THEN '£100k+'
			END AS [Indemnity Reserve Banding]
	, ISNULL(fact_finance_summary.[damages_paid],0)+ISNULL(fact_finance_summary.[claimants_costs_paid],0) AS [Sum of Indemnity spend]
	, ISNULL(fact_detail_reserve_detail.[indemnity_reserve],0)-(ISNULL(fact_finance_summary.[damages_paid],0)+ISNULL(fact_finance_summary.[claimants_costs_paid],0) ) AS [Indemnity Savings]
	, fact_detail_elapsed_days.[elapsed_days_damages] AS [Elapsed days]
	, fact_finance_summary.defence_costs_billed AS [Revenue]
	, dim_detail_core_details.referral_reason

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting
ON fact_detail_cost_budgeting.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days
ON fact_detail_elapsed_days.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details
ON dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_agents_involvement
ON dim_agents_involvement.dim_agents_involvement_key = fact_dimension_main.dim_agents_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND NOT LOWER(ISNULL(dim_detail_outcome.outcome_of_case,'')) IN  ('exclude from reports','returned to client')
AND dim_detail_outcome.date_claim_concluded>='2018-01-01'
AND dim_fed_hierarchy_history.hierarchylevel3hist='Motor'
AND ISNULL(dim_detail_core_details.referral_reason,'') LIKE 'Dispute%'

END
GO

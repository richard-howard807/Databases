SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[markerstudy_savings_report]

AS 

BEGIN

SELECT 
	dim_client_involvement.insuredclient_name				AS [Insured]
	, YEAR(dim_detail_claim.date_of_accident)				AS [YOA]
	, dim_client_involvement.insurerclient_reference		AS [Claim No.]
	, CAST(dim_detail_claim.date_of_accident AS DATE)		AS [Date of Loss]
	, 'Weightmans'											AS [Panel Firm]
	, dim_matter_header_current.matter_owner_full_name		AS [Fee Earner]
	, dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number		AS [Panel Firm Ref.]
	, CAST(dim_detail_core_details.date_instructions_received AS DATE)			AS [Date Instructed]
	, fact_detail_paid_detail.interim_damages_paid_by_client_preinstruction		AS [Paid]
	, ''			AS [Outstanding]  --New field to be added
	, ''			AS [Recoveries Received]	--New field to be added
	, ''			AS [Recoveries Reserved]	--New field to be added
	--, (ISNULL(fact_detail_paid_detail.interim_damages_paid_by_client_preinstruction, 0) + ISNULL([Outstanding], 0)) 
	--		- (ISNULL([Recoveries Received], 0) + ISNULL([Recoveries Reserved], 0))			AS [Incurred (Net of Recoveries)]  --To be updated when new fields available
	, CASE	
		WHEN dim_detail_outcome.outcome_of_case IS NULL THEN 
			'No'
		ELSE
			'Yes'
	  END						AS [Damages Settled]
	, fact_finance_summary.damages_paid			AS [Damages Settlement Amount]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)					AS [Date Damages Settled]
	, ''						AS [Defendant Offer Made]   --New field to be added
	, ''						AS [Date Defendant Offer Made]		--New field to be added
	, ''						AS [Type of Defendant Offer]		--New field to be added
	, ''						AS [Claimant Offer Made]		--New field to be added
	, ''						AS [Date Claimant Offer Made]	--New field to be added
	, ''						AS [Type of Claimant Offer]		--New field to be added
	, CASE	
		WHEN dim_detail_outcome.date_costs_settled IS NULL THEN
			'No'
		ELSE
			'Yes'
	  END						AS [Costs Settled]
	, fact_finance_summary.claimants_total_costs_claimed		AS [Costs Claimed]
	, fact_finance_summary.claimants_costs_paid			AS [Costs Settlement Amount]
	, CAST(dim_detail_outcome.date_costs_settled AS DATE)		AS [Date Costs Agreed]
	, ''				AS [Offer Made by Defendant to Settle Claimant Costs]		--New field to be added
	, ''				AS [Date Costs Offer Made]	--New field to be added
	, dim_detail_core_details.proceedings_issued			AS [Proceedings Issued]
	, ''				AS [Reserve Recommendation Made]	--If there's a difference between out total reserve and (paid + outstanding columns) then Yes else No
	, CAST(dim_matter_header_current.date_closed_practice_management AS DATE)		AS [Date File Closed]
	, ''				AS [Relevant Comments (Optional)] 
	--======================================================================================================
	-- Internal report fields below
	--======================================================================================================
	, dim_detail_core_details.referral_reason			AS [Referral Reason]
	, dim_detail_core_details.delegated					AS [Delegated]
	, dim_detail_finance.output_wip_fee_arrangement		AS [Fee Arrangement]
	, fact_finance_summary.fixed_fee_amount			AS [Fixed Fee Amount]
	, dim_detail_core_details.track				AS [Track]
	, dim_client_involvement.insurerclient_name		AS [Insurer Associate]
	, dim_detail_core_details.present_position			AS [Present Position]
	, ''				AS [Claims Strategy]  --New field to be added
	, dim_detail_core_details.injury_type		AS [Injury Type]
	, fact_detail_paid_detail.damages_interims		AS [Interim Damages Post Instruction]
	, dim_detail_core_details.suspicion_of_fraud			AS [Suspicion of Fraud]
	, dim_detail_core_details.credit_hire		AS [Credit Hire]
	, dim_detail_core_details.has_the_claimant_got_a_cfa		AS [Has Claimant got a CFA]
	, fact_detail_reserve_detail.damages_reserve			AS [Damages Reserve]
	, fact_detail_reserve_detail.tp_costs_reserve			AS [Claimant Costs Reserve]
	, fact_detail_reserve_detail.defence_costs_reserve		AS [Defence Costs Reserve]
	, fact_detail_reserve_detail.total_reserve				AS [Total Reserve]
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
		ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
		ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
WHERE 1 = 1
	AND dim_matter_header_current.master_client_code = 'W24438'
	AND dim_matter_header_current.master_matter_number <> 0
	AND dim_matter_header_current.reporting_exclusions = 0
	AND LOWER(LTRIM(RTRIM(ISNULL(dim_detail_outcome.outcome_of_case, '')))) <> 'exclude from reports'
	--There will need to be a filter for the new instruction type field (cboInsTypeMSG) to filter to only Markerstudy Project. 
ORDER BY	
	dim_detail_core_details.date_instructions_received
	, dim_matter_header_current.master_matter_number


END	

GO

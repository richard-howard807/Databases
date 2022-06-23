SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[NHSRMonthlyCostReturn_v2] -- EXEC [dbo].[NHSRMonthlyCostReturn_v2] '2022-01-01','2022-02-28','Costs Settlement'
(
@StartDate AS DATE
,@EndDate  AS DATE
,@ReportType AS NVARCHAR(100)
)

AS
BEGIN


IF @ReportType='Costs Settlement'

BEGIN



SELECT 
	'Weightmans'			AS [Panel Firm]
	, LEFT(DATENAME(MONTH, dim_detail_outcome.date_costs_settled), 3) + '-' + CAST(YEAR(dim_detail_outcome.date_costs_settled) AS VARCHAR(4)) AS [Month of Work (mmm-yyyy)]
	, dim_client_involvement.insurerclient_reference		AS [NHS Resolution Reference]
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number		AS [Costs Panel Reference]
	, CASE
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNSGP', 'CNST', 'ELS', 'DH CL', 'ELSGP') THEN
			'Clinical'
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('DH Liab', 'LTPS', 'PES') THEN	
			'Non-Clinical'
		ELSE
			''
	 END					AS [Claim Type]
	, dim_detail_health.nhs_scheme			AS [Scheme]
	, ''			AS [Instruction Type]
	, ''			AS [Instruction Value (exc VAT)]
	, dim_detail_health.stage_of_settlement_nhsr		AS [Settlement Stage]
	, CAST(dim_detail_outcome.date_claimants_costs_received AS DATE)			AS [Date of Reciept of Instruction]
	, CAST(dim_detail_outcome.date_costs_settled AS DATE)			AS [Date of Settlement]
	, DATEDIFF(DAY, dim_detail_outcome.date_claimants_costs_received, dim_detail_outcome.date_costs_settled)		AS [Time to Resolution]
	, CAST(dim_detail_health.zurichnhs_date_final_bill_sent_to_client AS DATE)			AS [Date of File Closure]
	, fact_finance_summary.damages_paid				AS [Damages]
	, fact_detail_client.claimants_costs_claimed_provisional_bill			AS [Claimant Costs Claimed]
	, fact_finance_summary.tp_total_costs_claimed				AS [Claimant Costs Claimed - Certified Bill]
	, fact_finance_summary.claimants_costs_paid					AS [Overall Settlement Amount]
	, ISNULL(fact_detail_client.claimants_costs_claimed_provisional_bill, 0) - ISNULL(fact_finance_summary.claimants_costs_paid, 0)		AS [Gross Savings]
	, CAST(CASE 
		WHEN ISNULL(fact_detail_client.claimants_costs_claimed_provisional_bill, 0) = 0 THEN
			0
		WHEN ISNULL(fact_detail_client.claimants_costs_claimed_provisional_bill, 0) - ISNULL(fact_finance_summary.claimants_costs_paid, 0)	= 0 THEN
			0
		ELSE
			(ISNULL(fact_detail_client.claimants_costs_claimed_provisional_bill, 0) - ISNULL(fact_finance_summary.claimants_costs_paid, 0)) / ISNULL(fact_detail_client.claimants_costs_claimed_provisional_bill, 0)
	 END AS DECIMAL(4,4))				AS [Percentage Saving Against Costs Claimed]
	, fact_detail_claim.data_services_team_interest_paid
	, ''				AS [Court Level]
	, fact_detail_cost_budgeting.district_judge_other_side				AS [Court Location]
	, fact_detail_cost_budgeting.other_sides_costs_budget_1	
	, fact_detail_cost_budgeting.other_sides_costs_budget_2
	, fact_detail_cost_budgeting.other_sides_costs_budget_3
	, fact_detail_cost_budgeting.other_sides_costs_budget_4
	, fact_detail_cost_budgeting.other_sides_costs_budget_5
	, fact_detail_cost_budgeting.district_judge_other_side			AS [Name of Judge / Master]
	, dim_detail_health.nhs_da_success								AS [DA Success]
	--, ISNULL(#cb_time.cb_amount, 0)					AS [Own Costs Billed (Excl VAT)]
	, 'Manual completion'					AS [Disbursements Billed (Excl VAT]
	, 'Manual completion'					AS [Defence Costs (Excl VAT)]
	, 'Manual completion'					AS [Net Savings]
	, dim_detail_claim.dst_claimant_solicitor_firm			AS [Claimant Solicitors]
	, dim_claimant_thirdparty_involvement.claimantrep_name			AS [Claimant Agent]
	---------------------------------------------------------------------------------------------------------------------------------------------
	, ISNULL(fact_detail_cost_budgeting.estimated_disbursements_other_side, 0) 
		+ ISNULL(fact_detail_cost_budgeting.estimated_profit_costs_other_side, 0)		AS [Costs Budgeting Estimated Costs Claimed]
	---------------------------------------------------------------------------------------------------------------------------------------------
	, ISNULL(fact_detail_cost_budgeting.total_disbs_budget_agreedrecorded_other_side, 0) 
		+ ISNULL(fact_detail_cost_budgeting.total_profit_costs_budget_agreedrecorded_other_side, 0)		AS [Estimated Costs Agreed or Allowed]
	---------------------------------------------------------------------------------------------------------------------------------------------
	, ISNULL(fact_detail_cost_budgeting.estimated_disbursements_other_side, 0) 
		+ ISNULL(fact_detail_cost_budgeting.estimated_profit_costs_other_side, 0)
	  -
	  ISNULL(fact_detail_cost_budgeting.total_disbs_budget_agreedrecorded_other_side, 0) 
		+ ISNULL(fact_detail_cost_budgeting.total_profit_costs_budget_agreedrecorded_other_side, 0)			AS [Gross Saving on Estimated Costs as Claimed]
	---------------------------------------------------------------------------------------------------------------------------------------------
	--, CASE	
	--	WHEN  ISNULL(fact_detail_cost_budgeting.estimated_disbursements_other_side, 0) 
	--	+ ISNULL(fact_detail_cost_budgeting.estimated_profit_costs_other_side, 0) = 0 THEN
	--		0
	--	WHEN ISNULL(fact_detail_cost_budgeting.total_disbs_budget_agreedrecorded_other_side, 0) 
	--	+ ISNULL(fact_detail_cost_budgeting.total_profit_costs_budget_agreedrecorded_other_side, 0)	= 0 THEN
	--		0
	--	ELSE		
	--		ISNULL(fact_detail_cost_budgeting.estimated_disbursements_other_side, 0) 
	--			+ ISNULL(fact_detail_cost_budgeting.estimated_profit_costs_other_side, 0)
	--		  /
	--		  ISNULL(fact_detail_cost_budgeting.total_disbs_budget_agreedrecorded_other_side, 0) 
	--			+ ISNULL(fact_detail_cost_budgeting.total_profit_costs_budget_agreedrecorded_other_side, 0)		
	--  END AS [Percentage Saving on Estimated Costs as Claimed]

	  	, CAST(CASE	
		WHEN  ISNULL(fact_detail_cost_budgeting.estimated_disbursements_other_side, 0) 
		+ ISNULL(fact_detail_cost_budgeting.estimated_profit_costs_other_side, 0) = 0 THEN
			0
		WHEN ISNULL(fact_detail_cost_budgeting.total_disbs_budget_agreedrecorded_other_side, 0) 
		+ ISNULL(fact_detail_cost_budgeting.total_profit_costs_budget_agreedrecorded_other_side, 0)	= 0 THEN
			0
		ELSE		
			CAST(ISNULL(fact_detail_cost_budgeting.estimated_disbursements_other_side, 0) AS DECIMAL (22,8) )
				+ CAST(ISNULL(fact_detail_cost_budgeting.estimated_profit_costs_other_side, 0) AS DECIMAL (22,8))
			  /
			  CAST(ISNULL(fact_detail_cost_budgeting.total_disbs_budget_agreedrecorded_other_side, 0) AS DECIMAL(22,8)) 
				+ CAST(ISNULL(fact_detail_cost_budgeting.total_profit_costs_budget_agreedrecorded_other_side, 0) AS DECIMAL(22,8))		
	  END	AS DECIMAL(4,4))																	AS [Percentage Saving on Estimated Costs as Claimed]
	---------------------------------------------------------------------------------------------------------------------------------------------
	
	, 'Manual completion'									AS [Costs Budget Net Saving]
	, fact_detail_reserve_detail.claimant_costs_reserve_current		AS [Costs Reserve]
	, dim_detail_health.nhs_recommended_to_proceed_to_da			AS [Bills - Recommended to Proceed to DA]
	, dim_detail_health.nhs_stage_of_settlement						AS [Substantive Action Settlement Stage]
	,name AS [Matter Owner]
	,dim_detail_health.[nhs_who_dealt_with_costs],
     CBCodes.CBAllTimeBilled,
     CBCodes.CB10,
     CBCodes.CB11,
     CBCodes.CB12,
     CBCodes.CB13,
	 CASE WHEN ISNULL(CBCodes.CB10,0)+ISNULL(CBCodes.CB11,0)>0 THEN 'Costs Budgeting' 

	 WHEN ISNULL(CBCodes.CB12,0)>0 THEN 'Costs at Conclusion (paying party)' 
	 WHEN ISNULL(CBCodes.CB13,0)>0 THEN 'Costs at Conclusion (receiving party)' 
	 END AS NewInstructionType
	 	 ,DisbsAfterCosts.AllDisbs
	 ,DisbsAfterCosts.DisbsAfterCosts
	, dim_detail_core_details.present_position		AS [Present Position]

FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_health
		ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_court_involvement
		ON dim_court_involvement.dim_court_involvement_key = fact_dimension_main.dim_court_involvement_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_client
		ON fact_detail_client.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_claim
		ON fact_detail_claim.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting
		ON fact_detail_cost_budgeting.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
	LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
		ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
		inner JOIN 
		(
		SELECT  dim_matter_header_current.dim_matter_header_curr_key
		,SUM(time_charge_value) AS CBAllTimeBilled
		,SUM(CASE WHEN time_activity_code='CB10' THEN time_charge_value ELSE 0 END) AS CB10
		,SUM(CASE WHEN time_activity_code='CB11' THEN time_charge_value ELSE 0 END) AS CB11
		,SUM(CASE WHEN time_activity_code='CB12' THEN time_charge_value ELSE 0 END) AS CB12
		,SUM(CASE WHEN time_activity_code='CB13' THEN time_charge_value ELSE 0 END) AS CB13
		
		FROM red_dw.dbo.fact_bill_billed_time_activity
		INNER JOIN red_dw.dbo.dim_matter_header_current
		 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
		 INNER JOIN red_dw.dbo.dim_bill
		 ON dim_bill.dim_bill_key = fact_bill_billed_time_activity.dim_bill_key
		INNER JOIN red_dw.dbo.dim_bill_date
		 ON dim_bill_date.dim_bill_date_key = fact_bill_billed_time_activity.dim_bill_date_key
		WHERE master_client_code='N1001'
		AND time_activity_code IN ('CB10','CB11','CB12','CB13')
		AND bill_date BETWEEN @Startdate AND @Enddate
		--AND bill_date BETWEEN '2021-12-01' AND '2021-12-02'
		
		GROUP BY dim_matter_header_current.dim_matter_header_curr_key
		) AS CBCodes

ON CBCodes.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
		LEFT OUTER JOIN 
		(SELECT dim_matter_header_current.dim_matter_header_curr_key
		,CASE WHEN other_sides_cost_budget_5 IS NOT NULL THEN other_sides_cost_budget_5
		WHEN other_sides_cost_budget_4 IS NOT NULL THEN other_sides_cost_budget_4
		WHEN other_sides_cost_budget_3 IS NOT NULL THEN other_sides_cost_budget_3
		WHEN other_sides_cost_budget_2 IS NOT NULL THEN other_sides_cost_budget_2
		WHEN other_sides_cost_budget_1 IS NOT NULL THEN other_sides_cost_budget_1 END AS BudgetDate
		FROM red_dw.dbo.dim_detail_claim
		INNER JOIN red_dw.dbo.dim_matter_header_current
		 ON dim_matter_header_current.client_code = dim_detail_claim.client_code
		 AND dim_matter_header_current.matter_number = dim_detail_claim.matter_number

		WHERE master_client_code='N1001'
		AND (other_sides_cost_budget_1 IS NOT NULL OR
		other_sides_cost_budget_2 IS NOT NULL OR
		other_sides_cost_budget_3 IS NOT NULL OR
		other_sides_cost_budget_4 IS NOT NULL OR
		other_sides_cost_budget_5 IS NOT NULL)) AS BudgetDates
ON BudgetDates.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
		LEFT OUTER JOIN 
		(
		SELECT dim_matter_header_current.dim_matter_header_curr_key
		,SUM(total_disbursements) AS AllDisbs
		,SUM(CASE WHEN CONVERT(DATE,bill_date,103)>=CONVERT(DATE,date_claimants_costs_received,103) THEN total_disbursements ELSE 0 END) AS DisbsAfterCosts
		FROM red_dw.dbo.fact_disbursements_detail
		INNER JOIN red_dw.dbo.dim_matter_header_current
		 ON dim_matter_header_current.dim_matter_header_curr_key = fact_disbursements_detail.dim_matter_header_curr_key
		INNER JOIN red_dw.dbo.fact_bill
		 ON fact_bill.dim_bill_key = fact_disbursements_detail.dim_bill_key
		INNER JOIN red_dw.dbo.dim_bill
		 ON dim_bill.dim_bill_key = fact_disbursements_detail.dim_bill_key
		INNER JOIN red_dw.dbo.dim_bill_date
		 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
		LEFT OUTER JOIN  red_dw.dbo.dim_detail_outcome 
		ON dim_detail_outcome.client_code = fact_disbursements_detail.client_code
		AND dim_detail_outcome.matter_number = fact_disbursements_detail.matter_number
		WHERE master_client_code='N1001'
		AND bill_reversed=0
		GROUP BY dim_matter_header_current.dim_matter_header_curr_key
		) AS DisbsAfterCosts
		 ON DisbsAfterCosts.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE
	dim_matter_header_current.master_client_code = 'N1001'
	--AND dim_matter_header_current.master_matter_number = '00018093'
	AND dim_matter_header_current.reporting_exclusions = 0

	--AND dim_detail_outcome.date_costs_settled BETWEEN @Startdate AND @Enddate

END 


ELSE

BEGIN
SELECT 
	'Weightmans'			AS [Panel Firm]
	, LEFT(DATENAME(MONTH, dim_detail_outcome.date_costs_settled), 3) + '-' + CAST(YEAR(dim_detail_outcome.date_costs_settled) AS VARCHAR(4))			AS [Month of Work (mmm-yyyy)]
	, dim_client_involvement.insurerclient_reference		AS [NHS Resolution Reference]
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number		AS [Costs Panel Reference]
	, CASE
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNSGP', 'CNST', 'ELS', 'DH CL', 'ELSGP') THEN
			'Clinical'
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('DH Liab', 'LTPS', 'PES') THEN	
			'Non-Clinical'
		ELSE
			''
	 END					AS [Claim Type]
	, dim_detail_health.nhs_scheme			AS [Scheme]
	, ''			AS [Instruction Type]
	, ''			AS [Instruction Value (exc VAT)]
	, dim_detail_health.stage_of_settlement_nhsr		AS [Settlement Stage]
	, CAST(dim_detail_outcome.date_claimants_costs_received AS DATE)			AS [Date of Reciept of Instruction]
	, CAST(dim_detail_outcome.date_costs_settled AS DATE)			AS [Date of Settlement]
	, DATEDIFF(DAY, dim_detail_outcome.date_claimants_costs_received, dim_detail_outcome.date_costs_settled)		AS [Time to Resolution]
	, CAST(dim_detail_health.zurichnhs_date_final_bill_sent_to_client AS DATE)			AS [Date of File Closure]
	, fact_finance_summary.damages_paid				AS [Damages]
	, fact_detail_client.claimants_costs_claimed_provisional_bill			AS [Claimant Costs Claimed]
	, fact_finance_summary.tp_total_costs_claimed				AS [Claimant Costs Claimed - Certified Bill]
	, fact_finance_summary.claimants_costs_paid					AS [Overall Settlement Amount]
	, ISNULL(fact_detail_client.claimants_costs_claimed_provisional_bill, 0) - ISNULL(fact_finance_summary.claimants_costs_paid, 0)		AS [Gross Savings]
	, CAST(CASE 
		WHEN ISNULL(fact_detail_client.claimants_costs_claimed_provisional_bill, 0) = 0 THEN
			0
		WHEN ISNULL(fact_detail_client.claimants_costs_claimed_provisional_bill, 0) - ISNULL(fact_finance_summary.claimants_costs_paid, 0)	= 0 THEN
			0
		ELSE
			(ISNULL(fact_detail_client.claimants_costs_claimed_provisional_bill, 0) - ISNULL(fact_finance_summary.claimants_costs_paid, 0)) / ISNULL(fact_detail_client.claimants_costs_claimed_provisional_bill, 0)
	 END AS DECIMAL(4,4))				AS [Percentage Saving Against Costs Claimed]
	, fact_detail_claim.data_services_team_interest_paid
	, ''				AS [Court Level]
	, fact_detail_cost_budgeting.district_judge_other_side				AS [Court Location]
	, fact_detail_cost_budgeting.other_sides_costs_budget_1	
	, fact_detail_cost_budgeting.other_sides_costs_budget_2
	, fact_detail_cost_budgeting.other_sides_costs_budget_3
	, fact_detail_cost_budgeting.other_sides_costs_budget_4
	, fact_detail_cost_budgeting.other_sides_costs_budget_5
	, fact_detail_cost_budgeting.district_judge_other_side			AS [Name of Judge / Master]
	, dim_detail_health.nhs_da_success								AS [DA Success]
	--, ISNULL(#cb_time.cb_amount, 0)					AS [Own Costs Billed (Excl VAT)]
	, 'Manual completion'					AS [Disbursements Billed (Excl VAT]
	, 'Manual completion'					AS [Defence Costs (Excl VAT)]
	, 'Manual completion'					AS [Net Savings]
	, dim_detail_claim.dst_claimant_solicitor_firm			AS [Claimant Solicitors]
	, dim_claimant_thirdparty_involvement.claimantrep_name			AS [Claimant Agent]
	---------------------------------------------------------------------------------------------------------------------------------------------
	, ISNULL(fact_detail_cost_budgeting.estimated_disbursements_other_side, 0) 
		+ ISNULL(fact_detail_cost_budgeting.estimated_profit_costs_other_side, 0)		AS [Costs Budgeting Estimated Costs Claimed]
	---------------------------------------------------------------------------------------------------------------------------------------------
	, ISNULL(fact_detail_cost_budgeting.total_disbs_budget_agreedrecorded_other_side, 0) 
		+ ISNULL(fact_detail_cost_budgeting.total_profit_costs_budget_agreedrecorded_other_side, 0)		AS [Estimated Costs Agreed or Allowed]
	---------------------------------------------------------------------------------------------------------------------------------------------
	, ISNULL(fact_detail_cost_budgeting.estimated_disbursements_other_side, 0) 
		+ ISNULL(fact_detail_cost_budgeting.estimated_profit_costs_other_side, 0)
	  -
	  ISNULL(fact_detail_cost_budgeting.total_disbs_budget_agreedrecorded_other_side, 0) 
		+ ISNULL(fact_detail_cost_budgeting.total_profit_costs_budget_agreedrecorded_other_side, 0)			AS [Gross Saving on Estimated Costs as Claimed]
	---------------------------------------------------------------------------------------------------------------------------------------------
	,CAST( CASE	
		WHEN  ISNULL(fact_detail_cost_budgeting.estimated_disbursements_other_side, 0) 
		+ ISNULL(fact_detail_cost_budgeting.estimated_profit_costs_other_side, 0) = 0 THEN
			0
		WHEN ISNULL(fact_detail_cost_budgeting.total_disbs_budget_agreedrecorded_other_side, 0) 
		+ ISNULL(fact_detail_cost_budgeting.total_profit_costs_budget_agreedrecorded_other_side, 0)	= 0 THEN
			0
		ELSE		
			CAST(ISNULL(fact_detail_cost_budgeting.estimated_disbursements_other_side, 0) AS DECIMAL (22,8) )
				+ CAST(ISNULL(fact_detail_cost_budgeting.estimated_profit_costs_other_side, 0) AS DECIMAL (22,8))
			  /
			  CAST(ISNULL(fact_detail_cost_budgeting.total_disbs_budget_agreedrecorded_other_side, 0) AS DECIMAL(22,8)) 
				+ CAST(ISNULL(fact_detail_cost_budgeting.total_profit_costs_budget_agreedrecorded_other_side, 0) AS DECIMAL(22,8))		
	  END		AS DECIMAL(4,4))																AS [Percentage Saving on Estimated Costs as Claimed]
	---------------------------------------------------------------------------------------------------------------------------------------------
	
	, 'Manual completion'									AS [Costs Budget Net Saving]
	, fact_detail_reserve_detail.claimant_costs_reserve_current		AS [Costs Reserve]
	, dim_detail_health.nhs_recommended_to_proceed_to_da			AS [Bills - Recommended to Proceed to DA]
	, dim_detail_health.nhs_stage_of_settlement						AS [Substantive Action Settlement Stage]
	,name AS [Matter Owner]
	,dim_detail_health.[nhs_who_dealt_with_costs],
     CBCodes.CBAllTimeBilled,
     CBCodes.CB10,
     CBCodes.CB11,
     CBCodes.CB12,
     CBCodes.CB13,
	 CASE WHEN ISNULL(CBCodes.CB10,0)+ISNULL(CBCodes.CB11,0)>0 THEN 'Costs Budgeting' 

	 WHEN ISNULL(CBCodes.CB12,0)>0 THEN 'Costs at Conclusion (paying party)' 
	 WHEN ISNULL(CBCodes.CB13,0)>0 THEN 'Costs at Conclusion (receiving party)' 
	 END AS NewInstructionType
	 ,DisbsAfterCosts.AllDisbs
	 ,DisbsAfterCosts.DisbsAfterCosts
	 , dim_detail_core_details.present_position		AS [Present Position]
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_health
		ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_court_involvement
		ON dim_court_involvement.dim_court_involvement_key = fact_dimension_main.dim_court_involvement_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_client
		ON fact_detail_client.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_claim
		ON fact_detail_claim.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting
		ON fact_detail_cost_budgeting.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
	LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
		ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN 
(
SELECT  dim_matter_header_current.dim_matter_header_curr_key
,SUM(time_charge_value) AS CBAllTimeBilled
,SUM(CASE WHEN time_activity_code='CB10' THEN time_charge_value ELSE 0 END) AS CB10
,SUM(CASE WHEN time_activity_code='CB11' THEN time_charge_value ELSE 0 END) AS CB11
,SUM(CASE WHEN time_activity_code='CB12' THEN time_charge_value ELSE 0 END) AS CB12
,SUM(CASE WHEN time_activity_code='CB13' THEN time_charge_value ELSE 0 END) AS CB13
FROM red_dw.dbo.fact_bill_billed_time_activity
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
WHERE master_client_code='N1001'
AND time_activity_code IN ('CB10','CB11','CB12','CB13')
GROUP BY dim_matter_header_current.dim_matter_header_curr_key
) AS CBCodes
 ON CBCodes.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN (SELECT dim_matter_header_current.dim_matter_header_curr_key
,CASE WHEN other_sides_cost_budget_5 IS NOT NULL THEN other_sides_cost_budget_5
WHEN other_sides_cost_budget_4 IS NOT NULL THEN other_sides_cost_budget_4
WHEN other_sides_cost_budget_3 IS NOT NULL THEN other_sides_cost_budget_3
WHEN other_sides_cost_budget_2 IS NOT NULL THEN other_sides_cost_budget_2
WHEN other_sides_cost_budget_1 IS NOT NULL THEN other_sides_cost_budget_1 END AS BudgetDate
FROM red_dw.dbo.dim_detail_claim
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = dim_detail_claim.client_code
 AND dim_matter_header_current.matter_number = dim_detail_claim.matter_number
WHERE master_client_code='N1001'
AND (other_sides_cost_budget_1 IS NOT NULL OR
other_sides_cost_budget_2 IS NOT NULL OR
other_sides_cost_budget_3 IS NOT NULL OR
other_sides_cost_budget_4 IS NOT NULL OR
other_sides_cost_budget_5 IS NOT NULL)) AS BudgetDates
 ON BudgetDates.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN 
(
SELECT dim_matter_header_current.dim_matter_header_curr_key
,SUM(total_disbursements) AS AllDisbs
,SUM(CASE WHEN CONVERT(DATE,bill_date,103)>=CONVERT(DATE,date_claimants_costs_received,103) THEN total_disbursements ELSE 0 END) AS DisbsAfterCosts
FROM red_dw.dbo.fact_disbursements_detail
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_disbursements_detail.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.fact_bill
 ON fact_bill.dim_bill_key = fact_disbursements_detail.dim_bill_key
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_disbursements_detail.dim_bill_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
LEFT OUTER JOIN  red_dw.dbo.dim_detail_outcome 
ON dim_detail_outcome.client_code = fact_disbursements_detail.client_code
AND dim_detail_outcome.matter_number = fact_disbursements_detail.matter_number
WHERE master_client_code='N1001'
AND bill_reversed=0
GROUP BY dim_matter_header_current.dim_matter_header_curr_key
) AS DisbsAfterCosts
 ON DisbsAfterCosts.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE
	dim_matter_header_current.master_client_code = 'N1001'
	AND dim_matter_header_current.reporting_exclusions = 0

	AND BudgetDates.BudgetDate BETWEEN @Startdate AND @Enddate

END 


	END
GO

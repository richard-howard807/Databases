SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2020-11-19
-- Ticket:		#79133
-- Description:	New report to replace billing macro Motor currently use, shows when matters can be billed
-- =============================================

CREATE PROCEDURE [dbo].[client_billing_sla_report]
(
	@Team AS NVARCHAR(MAX)
	, @FeeEarner AS NVARCHAR(MAX)
)

AS

BEGIN

SET NOCOUNT ON;

-- For testing
--DECLARE @Team AS NVARCHAR(MAX) = 'Motor Mainstream'
--		, @FeeEarner AS NVARCHAR(MAX) = 'Charlie Maesschalck|Tracy Kielty'

DROP TABLE IF EXISTS #internal_counsel
DROP TABLE IF EXISTS #sla_billing
DROP TABLE IF EXISTS #Team
DROP TABLE IF EXISTS #FeeEarner

SELECT udt_TallySplit.ListValue  INTO #Team FROM 	dbo.udt_TallySplit('|', @Team)
SELECT udt_TallySplit.ListValue  INTO #FeeEarner FROM 	dbo.udt_TallySplit('|', @FeeEarner)



--========================================================================================================================================================================
-- Table locating matters with internal counsel WIP - removed table to replace with DAX query in report in attempt to speed up
--========================================================================================================================================================================
SELECT
	fact_dimension_main.client_code
	, dim_all_time_activity.matter_number
	, SUM(fact_all_time_activity.time_charge_value) AS [internal_counsel_time_value]
--SELECT [dim_all_time_activity].*, [fact_all_time_activity].*
INTO #internal_counsel
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
			AND dim_fed_hierarchy_history.hierarchylevel3hist = 'Motor'
	INNER  JOIN red_dw.[dbo].[dim_all_time_activity]
		ON dim_all_time_activity.client_code = fact_dimension_main.client_code
			AND dim_all_time_activity.matter_number = fact_dimension_main.matter_number
	INNER JOIN red_dw.[dbo].[fact_all_time_activity]
		ON fact_all_time_activity.dim_all_time_activity_key = dim_all_time_activity.dim_all_time_activity_key

WHERE 1 = 1
	--AND dim_fed_hierarchy_history.hierarchylevel3hist = 'Motor'
	--AND fact_dimension_main.client_code = 'W16098'
	--AND fact_dimension_main.matter_number = '00000002'
	AND dim_all_time_activity.unbilled_record = 1
	AND fact_all_time_activity.isactive = 1
	AND dim_all_time_activity.time_activity_code IN ('IC01', 'IC02', 'IC03', 'IC04', 'IC05', 'IC06')
GROUP BY
	fact_dimension_main.client_code
	, dim_all_time_activity.matter_number

--========================================================================================================================================================================


--========================================================================================================================================================================
-- Table setting out if each matter can be billed according to their SLA. Think this should be separate to the main query due to how much is going on
--========================================================================================================================================================================

SELECT 
	dim_matter_header_current.master_client_code 
	, dim_matter_header_current.master_matter_number						
	, dim_matter_header_current.master_client_code									AS [Client Code]
	, client_billing_sla.fixed_fee_rules
	, client_billing_sla.hourly_rate_rules
	, dim_detail_core_details.present_position										AS [Present Position]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)							AS [Date Claim Concluded]
	, dim_detail_finance.output_wip_fee_arrangement									AS [Fee Arrangement]
	, fact_finance_summary.fixed_fee_amount											AS [Fixed Fee Amount]
	, fact_finance_summary.wip														AS [WIP]
	, fact_finance_summary.disbursement_balance										AS [Disbs Balance]
	, CAST(fact_matter_summary_current.last_bill_date AS DATE)						AS [Date of Last Bill]
	, fact_matter_summary_current.disbursements_only_flag							AS [Was Last Bill Disbursement Only]
	, fact_finance_summary.defence_costs_billed										AS [Profit Costs]
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)		AS [Date Opened]
	, client_billing_sla.bill_rule_num	
	, bill_detail.interim_final
	, CASE 
		-- disb only bills. Min disb value of £30. Only checking on final bill status, clients have individual disb only rules for interims which haven't been built into this
		WHEN bill_detail.fixed_hourly = 'hourly' AND bill_detail.interim_final = 'final' 
		AND ISNULL(fact_finance_summary.wip, 0) < 50 AND ISNULL(fact_finance_summary.disbursement_balance, 0) >= 30 THEN 
			'disb only'
		-- disb only bills. have to check against profit costs to make sure the FF has already been billed
		WHEN bill_detail.fixed_hourly = 'fixed_fee' AND bill_detail.interim_final = 'final' AND ISNULL(fact_finance_summary.disbursement_balance, 0) >= 30 
		AND ISNULL(fact_finance_summary.defence_costs_billed, 0) >= ISNULL(fact_finance_summary.fixed_fee_amount, 0) THEN
			'disb only'
		-- fixed fee final bill. Checking if profit costs are below FF amount in case FF is already billed, can't check against 0 profit costs in case incorrect/part FF has been billed  
		WHEN bill_detail.fixed_hourly = 'fixed_fee' THEN 
			CASE -- MIB 40% interim bill if claim not settled after 3 months and FF amount is over £150	
				WHEN client_billing_sla.bill_rule_num = 'Rule 5' AND bill_detail.interim_final = 'interim' AND dim_detail_outcome.date_claim_concluded IS NULL
				AND ISNULL(fact_finance_summary.fixed_fee_amount, 0) > 150 AND ISNULL(fact_finance_summary.defence_costs_billed, 0) < 1
				AND GETDATE() > DATEADD(MONTH, 3, dim_matter_header_current.date_opened_practice_management)-DAY(dim_matter_header_current.date_opened_practice_management) THEN 
					'40% fixed fee'
				-- MIB final bill fixed fees
				WHEN client_billing_sla.bill_rule_num = 'Rule 5' AND bill_detail.interim_final = 'final' 
				AND ISNULL(fact_finance_summary.defence_costs_billed, 0) < ISNULL(fact_finance_summary.fixed_fee_amount, 0) THEN	
					'fixed fee'
				-- all other FF cases
				WHEN bill_detail.interim_final = 'final' AND ISNULL(fact_finance_summary.defence_costs_billed, 0) < ISNULL(fact_finance_summary.fixed_fee_amount, 0) THEN	
					'fixed fee'
				ELSE
					'no bill'
			END 
		WHEN client_billing_sla.bill_rule_num = 'Rule 25' THEN
			-- clients with this rule only bill hourly and only once the claim has concluded
			CASE 
				WHEN bill_detail.interim_final = 'final' THEN
					'hourly'
				ELSE
					'no bill'
			END
		-- hourly rate interim for clients with different rules for half year/full year to other dates
		WHEN client_billing_sla.bill_rule_num IN ('Rule 10', 'Rule 22') AND bill_detail.fixed_hourly = 'hourly' AND bill_detail.interim_final = 'interim'
		AND (DATEDIFF(MONTH, ISNULL(fact_matter_summary_current.last_bill_date, '1900-01-01'), GETDATE()) > 0 OR DATEDIFF(MONTH, dim_matter_header_current.date_opened_practice_management, GETDATE()) > 0)  THEN
			CASE 
				WHEN MONTH(GETDATE()) IN (10, 4) AND ISNULL(fact_finance_summary.wip, 0) >= 100 THEN
					'hourly'
				WHEN ISNULL(fact_finance_summary.wip, 0) >= client_billing_sla.wip_minimum 
				AND GETDATE() > DATEADD(MONTH, client_billing_sla.bill_frequency_months, dim_matter_header_current.date_opened_practice_management)-DAY(dim_matter_header_current.date_opened_practice_management)
				AND GETDATE() > DATEADD(MONTH, client_billing_sla.bill_frequency_months, ISNULL(fact_matter_summary_current.last_bill_date, '1900-01-01'))-DAY(ISNULL(fact_matter_summary_current.last_bill_date, '1900-01-01')) THEN 
					'hourly'
				ELSE 
					'no bill'
			END 
		-- hourly rate interim 
		WHEN bill_detail.fixed_hourly = 'hourly' AND bill_detail.interim_final = 'interim' AND ISNULL(fact_finance_summary.wip, 0) >= client_billing_sla.wip_minimum 
		-- datediff checks a bill hasn't already been raised or matter just opened in current month
		AND (DATEDIFF(MONTH, ISNULL(fact_matter_summary_current.last_bill_date, '1900-01-01'), GETDATE()) > 0 OR DATEDIFF(MONTH, dim_matter_header_current.date_opened_practice_management, GETDATE()) > 0)  THEN 
			CASE -- bill rule on Weightmans financial quarters	
				WHEN client_billing_sla.on_weightmans_quarter = 'Yes' AND MONTH(GETDATE()) IN (7, 10, 1, 4) THEN 
					'hourly'
				-- bill rule when not on Weightmans financial quarters
				WHEN client_billing_sla.on_weightmans_quarter = 'No' 
				-- check to make sure todays date is older than the date opened/last bill date plus sla bill frequency months
				AND GETDATE() > DATEADD(MONTH, client_billing_sla.bill_frequency_months, dim_matter_header_current.date_opened_practice_management)-DAY(dim_matter_header_current.date_opened_practice_management)
				AND GETDATE() > DATEADD(MONTH, client_billing_sla.bill_frequency_months, ISNULL(fact_matter_summary_current.last_bill_date, '1900-01-01'))-DAY(ISNULL(fact_matter_summary_current.last_bill_date, '1900-01-01')) THEN 
					'hourly'
				ELSE 
					'no bill'
			END
		-- hourly rate final. Minimum WIP value of £50 to avoid tiny bills being sent
		WHEN bill_detail.fixed_hourly = 'hourly' AND bill_detail.interim_final = 'final' AND ISNULL(fact_finance_summary.wip, 0) >= 50 THEN
			'hourly'
        ELSE
			'no bill'
	 END								AS [bill_type]
INTO #sla_billing
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
			AND dim_matter_header_current.date_closed_practice_management IS NULL
				AND dim_matter_header_current.client_code NOT IN ('00030645', '00453737', '00257251')
					AND dim_matter_header_current.reporting_exclusions = 0
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	INNER JOIN #Team
		ON #Team.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.hierarchylevel4hist
	INNER JOIN #FeeEarner
		ON #FeeEarner.ListValue COLLATE DATABASE_DEFAULT = dim_matter_header_current.matter_owner_full_name
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
		ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
	LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
		ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
			AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN dbo.client_billing_sla
		ON client_billing_sla.master_client_code COLLATE DATABASE_DEFAULT = dim_matter_header_current.master_client_code
	INNER JOIN (
					SELECT 
						dim_matter_header_current.master_client_code
						, dim_matter_header_current.master_matter_number
						, CASE 
							WHEN ISNULL(dim_detail_core_details.present_position, '') IN 
								('', 'Claim and costs concluded but recovery outstanding', 'Claim and costs outstanding', 'Claim concluded but costs outstanding') THEN
								'interim'
							ELSE
								'final'
							END																			AS [interim_final]
						, CASE 
							WHEN ISNULL(RTRIM(dim_detail_finance.output_wip_fee_arrangement), '') = 'Fixed Fee/Fee Quote/Capped Fee' THEN
								'fixed_fee'
							ELSE
								'hourly'
						  END				AS [fixed_hourly]
					FROM red_dw.dbo.fact_dimension_main
						INNER JOIN red_dw.dbo.dim_matter_header_current
							ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
								AND dim_matter_header_current.date_closed_practice_management IS NULL
									AND dim_matter_header_current.client_code NOT IN ('00030645', '00453737', '00257251')
										AND dim_matter_header_current.reporting_exclusions = 0
						INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
							ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
								AND dim_fed_hierarchy_history.hierarchylevel3hist = 'Motor'
						LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
							ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
						LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
							ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
				) AS bill_detail
		ON bill_detail.master_client_code = dim_matter_header_current.master_client_code
			AND bill_detail.master_matter_number = dim_matter_header_current.master_matter_number
WHERE 1 = 1
	--AND client_billing_sla.bill_rule_num IN ('Rule 10', 'Rule 22')
	--AND bill_detail.fixed_hourly = 'hourly'
	--AND dim_matter_header_current.master_client_code + 
	--	'-' + dim_matter_header_current.master_matter_number = 'A1001-11647'

--========================================================================================================================================================================


--========================================================================================================================================================================
-- Main query
--========================================================================================================================================================================
		
SELECT 
	all_data.*
	, CASE	
		WHEN all_data.[Interim or Final] = 'final' AND all_data.[Bill Type] = 'no bill' THEN
			'Close?'
		WHEN LOWER(all_data.[Outcome of Case]) = 'exclude from reports' THEN
			'Exclude from reports'
		WHEN all_data.bill_rule_num = 'Rule 20' THEN
			'No client SLA rules'
		-- these queries are preventing the report logic from correctly checking if we can bill
		WHEN COALESCE(all_data.query_1, all_data.query_2, all_data.query_3, all_data.query_4, all_data.query_8, all_data.query_10) IS NOT NULL THEN
			'Query'
		WHEN all_data.[Bill Type] = 'no bill' THEN
			'No bill'
		-- these queries should only prevent a bill if the case is capable of being billed according to logic
		WHEN COALESCE(all_data.query_5, all_data.query_6, all_data.query_7, all_data.query_9) IS NOT NULL THEN
			'Query'
		WHEN all_data.fixed_fee_success_fee = 'Yes' AND all_data.[Fee Arrangement] = 'Fixed Fee/Fee Quote/Capped Fee' AND 
		(LOWER(all_data.[Outcome of Case]) = 'struck out' OR LOWER(all_data.[Outcome of Case]) LIKE 'discontinued%' OR LOWER(all_data.[Outcome of Case]) LIKE 'won%') THEN
			'Success fee?'
		ELSE 
			'Bill'
	  END										AS [Can We Bill]
	-- row colour in report needs to be blue if clients are billed centrally
	, CASE
		WHEN all_data.[Client Code] IN ('C1001', '257248', '9008076', 'R1001', 'W15572') THEN
			'LightSkyBlue'
		ELSE
			'Transparent'
	  END										AS [centrally_billed_row_colour]
	-- The Can We Bill column cells need to be blue for centrally billed clients, green for bills, orange for query.
	, CASE	
		WHEN all_data.[Client Code] IN ('C1001', '257248', '9008076', 'R1001', 'W15572') THEN
			'LightSkyBlue'
		WHEN (
				 CASE	
					WHEN all_data.[Interim or Final] = 'final' AND all_data.[Bill Type] = 'no bill' THEN
						'Close?'
					WHEN LOWER(all_data.[Outcome of Case]) = 'exclude from reports' THEN
						'Exclude from reports'
					WHEN all_data.bill_rule_num = 'Rule 20' THEN
						'No client SLA rules'
					-- these queries are preventing the report logic from correctly checking if we can bill
					WHEN COALESCE(all_data.query_1, all_data.query_2, all_data.query_3, all_data.query_4, all_data.query_8, all_data.query_10) IS NOT NULL THEN
						'Query'
					WHEN all_data.[Bill Type] = 'no bill' THEN
						'No bill'
					-- these queries should only prevent a bill if the case is capable of being billed according to logic
					WHEN COALESCE(all_data.query_5, all_data.query_6, all_data.query_7, all_data.query_9) IS NOT NULL THEN
						'Query'
					WHEN all_data.fixed_fee_success_fee = 'Yes' AND all_data.[Fee Arrangement] = 'Fixed Fee/Fee Quote/Capped Fee' AND 
					(LOWER(all_data.[Outcome of Case]) = 'struck out' OR LOWER(all_data.[Outcome of Case]) LIKE 'discontinued%' OR LOWER(all_data.[Outcome of Case]) LIKE 'won%') THEN
						'Success fee?'
					ELSE 
						'Bill'
				  END	) = 'Bill' THEN
			'LimeGreen'
		WHEN (
				 CASE	
					WHEN all_data.[Interim or Final] = 'final' AND all_data.[Bill Type] = 'no bill' THEN
						'Close?'
					WHEN LOWER(all_data.[Outcome of Case]) = 'exclude from reports' THEN
						'Exclude from reports'
					WHEN all_data.bill_rule_num = 'Rule 20' THEN
						'No client SLA rules'
					-- these queries are preventing the report logic from correctly checking if we can bill
					WHEN COALESCE(all_data.query_1, all_data.query_2, all_data.query_3, all_data.query_4, all_data.query_8, all_data.query_10) IS NOT NULL THEN
						'Query'
					WHEN all_data.[Bill Type] = 'no bill' THEN
						'No bill'
					-- these queries should only prevent a bill if the case is capable of being billed according to logic
					WHEN COALESCE(all_data.query_5, all_data.query_6, all_data.query_7, all_data.query_9) IS NOT NULL THEN
						'Query'
					WHEN all_data.fixed_fee_success_fee = 'Yes' AND all_data.[Fee Arrangement] = 'Fixed Fee/Fee Quote/Capped Fee' AND 
					(LOWER(all_data.[Outcome of Case]) = 'struck out' OR LOWER(all_data.[Outcome of Case]) LIKE 'discontinued%' OR LOWER(all_data.[Outcome of Case]) LIKE 'won%') THEN
						'Success fee?'
					ELSE 
						'Bill'
				  END	) = 'Query' THEN
			'Orange'
		ELSE
			'Transparent'
	END								AS [can_we_bill_colour]		
FROM (
	SELECT 
		dim_matter_header_current.master_client_code + 
			'-' + dim_matter_header_current.master_matter_number						AS [MS Reference]
		, dim_matter_header_current.master_client_code									AS [Client Code]
		, dim_matter_header_current.matter_description									AS [Matter Description]
		, dim_matter_header_current.matter_owner_full_name								AS [Matter Owner]
		, dim_fed_hierarchy_history.hierarchylevel4hist									AS [Matter Owner Team]
		, dim_detail_core_details.track													AS [Track]
		, fact_finance_summary.total_reserve											AS [Total Reserve Current]
		, dim_detail_core_details.present_position										AS [Present Position]
		, dim_detail_core_details.proceedings_issued									AS [Proceedings Issued]
		, CAST(dim_detail_outcome.date_claim_concluded AS DATE)							AS [Date Claim Concluded]
		, RTRIM(dim_detail_outcome.outcome_of_case)										AS [Outcome of Case]
		, CAST(dim_detail_outcome.date_costs_settled AS DATE)							AS [Date Costs Settled]
		, dim_matter_header_current.billing_arrangement_description						AS [Billing Arrangement Description]
		, RTRIM(dim_detail_finance.output_wip_fee_arrangement)							AS [Fee Arrangement]
		, dim_client_involvement.insurerclient_reference								AS [Insurer Client Reference]
		, dim_client_involvement.insuredclient_reference								AS [Insured Client Reference]
		, dim_detail_core_details.clients_claims_handler_surname_forename				AS [Client Claims Handler]
		, fact_finance_summary.fixed_fee_amount											AS [Fixed Fee Amount]
		, dim_detail_core_details.delegated												AS [Delegated]
		, fact_finance_summary.wip														AS [WIP]
		, #internal_counsel.internal_counsel_time_value									AS [Internal Counsel WIP]
		, fact_finance_summary.client_account_balance_of_matter							AS [Client Balance]
		, fact_finance_summary.unpaid_bill_balance										AS [Unpaid Bills]
		, fact_finance_summary.disbursement_balance										AS [Disbs Balance]
		, CAST(fact_matter_summary_current.last_bill_date AS DATE)						AS [Date of Last Bill]
		, IIF(fact_matter_summary_current.disbursements_only_flag = 1, 'Yes', 'No')		AS [Was Last Bill Disbursement Only]
		, dim_detail_core_details.is_this_a_linked_file									AS [Is This a Linked File]
		, dim_detail_core_details.is_this_the_lead_file_c								AS [is This a Lead File]
		, dim_detail_core_details.coop_guid_reference_number							AS [Co-op GUID Reference Number]
		, ISNULL(costs_involved_detail.costs_involved, 'No')							AS [Costs Involved]
		, fact_finance_summary.defence_costs_billed										AS [Profit Costs]
		, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)		AS [Date Opened]
		, fact_finance_summary.portal_bill_total										AS [Portal Bill Total]
		, dim_matter_header_current.billing_portal_status								AS [Portal Status]
		, client_billing_sla.client_name												AS [Client Name]
		, #sla_billing.interim_final													AS [Interim or Final]
		, #sla_billing.bill_type														AS [Bill Type]
		, client_billing_sla.bill_rule_num												
		, client_billing_sla.fixed_fee_success_fee

		-- query reasons
		, CASE	
			WHEN dim_detail_finance.output_wip_fee_arrangement IS NULL THEN
				'Fee arrangement field is blank'
			ELSE
				NULL
			END																			AS [query_1]
		, CASE 
			WHEN dim_detail_core_details.present_position IS NULL THEN
				'Present position is  blank'
			ELSE
				NULL
			END																			AS [query_2]
		, CASE 
			WHEN RTRIM(dim_detail_finance.output_wip_fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee' AND fact_finance_summary.fixed_fee_amount IS NULL THEN
				'Fixed fee amount missing on fixed fee matter'
			ELSE
				NULL
			END																			AS [query_3]
		, CASE
			WHEN RTRIM(dim_detail_finance.output_wip_fee_arrangement) <> 'Fixed Fee/Fee Quote/Capped Fee' AND (fact_finance_summary.fixed_fee_amount > 0) THEN
				'Fixed fee amount entered on hourly rate matter'
			ELSE
				NULL
			END																			AS [query_4]
		, CASE 
			WHEN client_billing_sla.bill_type = 'hourly only' AND RTRIM(dim_detail_finance.output_wip_fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee' THEN
				'Client does not have a FF, data showing FF'
			ELSE
				NULL
			END																			AS [query_5]
		, CASE 
			WHEN client_billing_sla.bill_type = 'fixed fee only' AND RTRIM(dim_detail_finance.output_wip_fee_arrangement) <> 'Fixed Fee/Fee Quote/Capped Fee' THEN
				'Client does not have a HR, data showing HR'
			ELSE
				NULL
			END																			AS [query_6]
		, CASE	
			WHEN #sla_billing.interim_final = 'final'
			AND (dim_detail_outcome.date_claim_concluded IS NULL OR dim_detail_outcome.outcome_of_case IS NULL OR dim_detail_outcome.date_costs_settled IS NULL) THEN
				'Present position shows final bill option, settlement data blank'
			ELSE
				NULL
			END																			AS [query_7]
		, CASE	
			WHEN dim_detail_core_details.present_position IN ('Claim and costs outstanding', 'Claim concluded but costs outstanding')
			AND dim_detail_outcome.date_claim_concluded IS NOT NULL AND dim_detail_outcome.outcome_of_case IS NOT NULL AND dim_detail_outcome.date_costs_settled IS NOT NULL THEN
				'Settlement data completed, is present position correct'
			ELSE
				NULL
			END																			AS [query_8]
		, CASE 
			WHEN dim_detail_outcome.date_costs_settled IS NOT NULL AND (dim_detail_outcome.date_claim_concluded IS NULL OR dim_detail_outcome.outcome_of_case IS NULL) THEN
				'Date costs settled completed, claim concluded/outcome blank'
			ELSE
				NULL
			END																			AS [query_9]
		, CASE	--This checks if last bill was disb only before 3 months has passed, to make sure we don't miss the chance to raise a bill. Only an issue when billing every 3 months when not on a Ws quarter
			WHEN client_billing_sla.bill_frequency_months = 3 AND client_billing_sla.on_weightmans_quarter = 'No' AND 
				RTRIM(dim_detail_finance.output_wip_fee_arrangement) <> 'Fixed Fee/Fee Quote/Capped Fee' AND
					fact_matter_summary_current.disbursements_only_flag = 1 AND 
						GETDATE() < DATEADD(MONTH, 3, fact_matter_summary_current.last_bill_date) - DAY(fact_matter_summary_current.last_bill_date) THEN 
				'Previous bill disb only. Can we raise an hourly rate bill'
			ELSE
				NULL
			END																			AS [query_10]
	FROM red_dw.dbo.fact_dimension_main
		INNER JOIN red_dw.dbo.dim_matter_header_current
			ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
				AND dim_matter_header_current.date_closed_practice_management IS NULL
					AND dim_matter_header_current.client_code NOT IN ('00030645', '00453737', '00257251')
						AND dim_matter_header_current.reporting_exclusions = 0
		INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
			ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
		INNER JOIN #Team
			ON #Team.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.hierarchylevel4hist
		INNER JOIN #FeeEarner
			ON #FeeEarner.ListValue COLLATE DATABASE_DEFAULT = dim_matter_header_current.matter_owner_full_name
		LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
			ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
			ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
		LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
			ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
		LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
			ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
			ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
		LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
			ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
				AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
		LEFT OUTER JOIN #internal_counsel
			ON #internal_counsel.client_code = dim_matter_header_current.client_code
				AND #internal_counsel.matter_number = dim_matter_header_current.matter_number
		LEFT OUTER JOIN (
							SELECT DISTINCT
								fact_all_time_activity.client_code
								, fact_all_time_activity.matter_number
								, 'Yes' AS [costs_involved]
							FROM red_dw.[dbo].[fact_all_time_activity]
								INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
									ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
										AND dim_fed_hierarchy_history.hierarchylevel3hist = 'Motor'
											AND dim_fed_hierarchy_history.cost_handler = 1
						) AS costs_involved_detail
			ON costs_involved_detail.client_code = dim_matter_header_current.client_code
				AND costs_involved_detail.matter_number = dim_matter_header_current.matter_number
		LEFT OUTER JOIN dbo.client_billing_sla
			ON client_billing_sla.master_client_code COLLATE DATABASE_DEFAULT = dim_matter_header_current.master_client_code
		LEFT OUTER JOIN #sla_billing
			ON #sla_billing.master_client_code = dim_matter_header_current.master_client_code
				AND #sla_billing.master_matter_number = dim_matter_header_current.master_matter_number
	WHERE 1 = 1 
		AND dim_fed_hierarchy_history.hierarchylevel3hist = 'Motor'
	) AS all_data

END	



GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[NHSResolutionSteeringGroupDashboard_kpi_data]
(
@fin_period AS NVARCHAR(20)
)
AS


--DECLARE @fin_period AS NVARCHAR(18) = '2022-06 (Oct-2021)'
DECLARE @end_date AS DATE = (SELECT MAX(dim_date.calendar_date) FROM red_dw.dbo.dim_date WHERE dim_date.fin_period = @fin_period)
DECLARE @start_date	AS DATE = DATEADD(YEAR, -1, DATEADD(DAY, 1, @end_date))

DROP TABLE IF EXISTS #panel_averages
DROP TABLE IF EXISTS #nhs_kpi_data

--=====================================================================================================================================================
-- Panel averages - data kept up to date by data scientists 
--=====================================================================================================================================================
SELECT 
	pivot_data.tranche
	, pivot_data.matter_type
	, pivot_data.[claimant costs]
	, pivot_data.[damages]
	, pivot_data.[defence costs]
	, pivot_data.[settlement time]
INTO #panel_averages
FROM (
	SELECT 
		all_data.tranche
		, all_data.matter_type
		, all_data.type	AS kpi_type
		, SUM(all_data.total_panel_value) / SUM(all_data.no_of_cases_converted)		AS panel_average
	FROM ( 
		SELECT 
			*
			, IIF(p45_NHSR_data.scheme = 'CNST', 'Clinical', 'Non-Clinical')		AS matter_type
			, CAST(ROUND(CAST(p45_NHSR_data.no_cases AS FLOAT), 0) AS INT)	AS no_of_cases_converted
			, (CAST(ROUND(CAST(p45_NHSR_data.no_cases AS FLOAT), 0) AS INT) * CAST(p45_NHSR_data.average AS FLOAT))  AS total_panel_value
		FROM DataScience..p45_NHSR_data
		WHERE
			p45_NHSR_data.date = (SELECT MAX(dim_date.calendar_date) FROM red_dw.dbo.dim_date WHERE dim_date.fin_period = @fin_period)
			AND p45_NHSR_data.scheme <> 'ELS'
		) AS all_data
	GROUP BY
		all_data.tranche
		, all_data.matter_type
		, all_data.type
	) AS panel_average_data
PIVOT
	(
		SUM(panel_average)
		FOR kpi_type IN ([claimant costs], [damages], [defence costs], [settlement time])
	) AS pivot_data


--=====================================================================================================================================================
--=====================================================================================================================================================
SELECT *
	, CASE
		WHEN all_data.matter_type = 'Clinical' THEN
			CASE
				WHEN all_data.damages = 0 THEN
					'£0'
				WHEN all_data.damages BETWEEN 1 AND 50000 THEN 
					'£1-£50,000'
				WHEN all_data.damages BETWEEN 50001 AND 250000 THEN
					'£50,000-£250,000'
				WHEN all_data.damages BETWEEN 250001 AND 500000 THEN
					'£250,000-£500,000'
				WHEN all_data.damages BETWEEN 500001 AND 1000000 THEN
					'£500,000-£1,000,000'
				WHEN all_data.damages > 1000000 THEN
					'£1,000,000+'
			END  
		WHEN all_data.matter_type = 'Non-Clinical' THEN
			CASE
				WHEN all_data.damages = 0 THEN
					'£0'
				WHEN all_data.damages BETWEEN 1 AND 5000 THEN 
					'£1-£5,000'
				WHEN all_data.damages BETWEEN 5001 AND 10000 THEN
					'£5,000-£10,000'
				WHEN all_data.damages BETWEEN 10001 AND 25000 THEN
					'£10,000-£25,000'
				WHEN all_data.damages BETWEEN 25001 AND 50000 THEN
					'£25,000-£50,000'
				WHEN all_data.damages > 50000 THEN
					'£50,000+'
			END 
      END			AS damages_tranche
	, CASE
		WHEN all_data.matter_type = 'Clinical' THEN
			CASE
				WHEN all_data.is_this_a_ppo_matter = 'Yes' THEN
					'PPO'
				WHEN all_data.damages = 0 THEN
					'£0'
				WHEN all_data.damages BETWEEN 1 AND 50000 THEN 
					'£1-£50,000'
				WHEN all_data.damages BETWEEN 50001 AND 250000 THEN
					'£50,000-£250,000'
				WHEN all_data.damages BETWEEN 250001 AND 500000 THEN
					'£250,000-£500,000'
				WHEN all_data.damages BETWEEN 500001 AND 1000000 THEN
					'£500,000-£1,000,000'
				WHEN all_data.damages > 1000000 THEN
					'£1,000,000+'
			END  
		WHEN all_data.matter_type = 'Non-Clinical' THEN
			CASE
				WHEN all_data.damages = 0 THEN
					'£0'
				WHEN all_data.damages BETWEEN 1 AND 5000 THEN 
					'£1-£5,000'
				WHEN all_data.damages BETWEEN 5001 AND 10000 THEN
					'£5,000-£10,000'
				WHEN all_data.damages BETWEEN 10001 AND 25000 THEN
					'£10,000-£25,000'
				WHEN all_data.damages BETWEEN 25001 AND 50000 THEN
					'£25,000-£50,000'
				WHEN all_data.damages > 50000 THEN
					'£50,000+'
			END 
      END			AS defence_costs_tranche
	, CASE
		WHEN all_data.matter_type = 'Clinical' THEN
			CASE
				--WHEN all_data.is_this_a_ppo_matter = 'Yes' THEN
				--	7
				WHEN all_data.damages = 0 THEN
					1
				WHEN all_data.damages BETWEEN 1 AND 50000 THEN 
					2
				WHEN all_data.damages BETWEEN 50001 AND 250000 THEN
					3
				WHEN all_data.damages BETWEEN 250001 AND 500000 THEN
					4
				WHEN all_data.damages BETWEEN 500001 AND 1000000 THEN
					5
				WHEN all_data.damages > 1000000 THEN
					6
			END  
		WHEN all_data.matter_type = 'Non-Clinical' THEN
			CASE
				--WHEN all_data.is_this_a_ppo_matter = 'Yes' THEN
				--	7
				WHEN all_data.damages = 0 THEN
					1
				WHEN all_data.damages BETWEEN 1 AND 5000 THEN 
					2
				WHEN all_data.damages BETWEEN 5001 AND 10000 THEN
					3
				WHEN all_data.damages BETWEEN 10001 AND 25000 THEN
					4
				WHEN all_data.damages BETWEEN 25001 AND 50000 THEN
					5
				WHEN all_data.damages > 50000 THEN
					6
			END 
      END			AS tranche_order
INTO #nhs_kpi_data
FROM (
		SELECT 
			dim_matter_header_current.master_client_code
			, dim_matter_header_current.master_matter_number
			, dim_matter_header_current.matter_owner_full_name
			, dim_fed_hierarchy_history.name
			, dim_employee.locationidud
			, CASE 
				WHEN dim_employee.locationidud IN ('Manchester', 'Manchester PMC', 'Manchester Spinningfields', 'Manchester 3PP') THEN
					'Liverpool'
				WHEN dim_employee.locationidud = 'Leicester' THEN
					'Birmingham'
				ELSE	
					dim_employee.locationidud
			 END				AS office
			, COALESCE(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve)		AS damages
			, ISNULL(fact_finance_summary.defence_costs_billed, 0) + ISNULL(fact_finance_summary.disbursements_billed, 0) AS defence_costs
			, dim_detail_core_details.date_instructions_received
			, dim_detail_outcome.date_claim_concluded
			, dim_detail_health.is_this_a_ppo_matter
			, dim_detail_health.zurichnhs_date_final_bill_sent_to_client
			, CAST(DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_detail_outcome.date_claim_concluded)AS DECIMAL(7,2)) / 365 		AS shelf_life
			, CASE 
				WHEN dim_detail_health.nhs_scheme IN ( 
														'CNSGP',
														'CNST',
														'DH CL',
														'ELS',
														'ELSGP',
														'ELSGP (MDDUS)',
														'ELSGP (MPS)',
														'CNSC'
													) THEN
					'Clinical'
				WHEN dim_detail_health.nhs_scheme IN (
														'DH Liab',
														'LTPS',
														'PES'
													) THEN 
					'Non-Clinical'
				ELSE
					'Other'
			  END									AS matter_type
		FROM red_dw.dbo.dim_matter_header_current
			INNER JOIN red_dw.dbo.fact_dimension_main
				ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
				ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
			INNER JOIN red_dw.dbo.dim_employee
				ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key				
			INNER JOIN red_dw.dbo.dim_detail_health
				ON dim_detail_health.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
				ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
				ON fact_finance_summary.client_code = dim_matter_header_current.client_code
					AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
			LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
				ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
					AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
		WHERE	
			dim_matter_header_current.master_client_code = 'N1001'
			AND (dim_detail_outcome.date_claim_concluded BETWEEN @start_date AND @end_date
				OR
				dim_detail_health.zurichnhs_date_final_bill_sent_to_client BETWEEN @start_date AND @end_date	
			)
			AND dim_matter_header_current.reporting_exclusions = 0
			AND LOWER(dim_detail_core_details.referral_reason) LIKE 'dispute%'
) AS all_data
WHERE
	all_data.matter_type <> 'Other'

 
SELECT 
	#nhs_kpi_data.*
	, ROUND(#panel_averages.[claimant costs], 0)	AS claimant_cost_panel_average
	, ROUND(#panel_averages.damages, 0)			AS damages_panel_average
	, ROUND(#panel_averages.[defence costs], 0)	AS defence_costs_panel_average
	, ROUND(#panel_averages.[settlement time], 2) AS settlement_time_panel_average
FROM #nhs_kpi_data
	LEFT OUTER JOIN #panel_averages
		ON #nhs_kpi_data.matter_type = #panel_averages.matter_type
			AND #panel_averages.tranche = #nhs_kpi_data.defence_costs_tranche
UNION
SELECT 
	NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, #panel_averages.matter_type
	, #panel_averages.tranche
	, #panel_averages.tranche
	, NULL
	, ROUND(#panel_averages.[claimant costs], 0)
	, ROUND(#panel_averages.damages, 0)
	, ROUND(#panel_averages.[defence costs], 0)
	, ROUND(#panel_averages.[settlement time], 2)
FROM #panel_averages
WHERE
	#panel_averages.tranche = 'overall'
GO

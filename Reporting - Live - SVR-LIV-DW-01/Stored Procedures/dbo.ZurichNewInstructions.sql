SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2021-09-16
-- Description:	#114359 - New report to count no. of new instructions for Zurich
-- =============================================

CREATE PROCEDURE [dbo].[ZurichNewInstructions] --EXEC [dbo].[ZurichNewInstructions]
(
	@start_year AS INT 
)
AS

BEGIN

--For testing
--DECLARE @start_year AS INT = 2019

SELECT 
	dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number		AS [Mattersphere Reference]
	, CASE
		WHEN dim_instruction_type.instruction_type LIKE 'Outsource%' THEN
			'Outsource' 
		ELSE
			dim_detail_core_details.zurich_branch	
	  END											AS [Zurich Branch]
	, COALESCE(client_references.client_reference, dim_detail_client.zurich_insurer_ref)			AS [Zurich Reference]
	, dim_matter_header_current.matter_description				AS [Matter Description]
	, dim_detail_core_details.zurich_policy_holdername_of_insured			AS [Policyholder]
	, dim_matter_header_current.matter_owner_full_name					AS [File Handler]
	, CASE
		WHEN RTRIM(dim_matter_worktype.work_type_name) = 'Cross Border' THEN
			'Cross Border'
		ELSE
			dim_fed_hierarchy_history.hierarchylevel4hist
	  END																AS [Team]
	, dim_detail_core_details.zurich_track			AS [Zurich Track]
	, dim_detail_finance.output_wip_fee_arrangement			AS [Fee Structure]
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)			AS [Date Opened]
	, dim_date.fin_year			AS [Financial Year Opened]
	, dim_date.cal_year			AS [Calendar Year Opened]
	, dim_date.cal_month_name		AS [Month Opened]
	, dim_date.cal_month_no				AS month_order
	, 1					AS count_of_case
	, CASE
		WHEN dim_instruction_type.instruction_type LIKE 'Outsource%' THEN
			'Outsource'
		WHEN RTRIM(dim_matter_worktype.work_type_name) = 'Cross Border' THEN
			'Cross Border'
		WHEN dim_fed_hierarchy_history.hierarchylevel4hist = 'Niche Costs' THEN	
			'Niche Costs'
		WHEN dim_fed_hierarchy_history.hierarchylevel3hist = 'Large Loss' THEN 
			'Large Loss Excluding Cross Border'
		WHEN dim_fed_hierarchy_history.hierarchylevel3hist = 'Litigation' THEN
			'Litigation'
		WHEN dim_fed_hierarchy_history.hierarchylevel3hist = 'Regulatory' THEN 
			'Regulatory'
		WHEN dim_fed_hierarchy_history.hierarchylevel3hist = 'Motor' THEN 
			'Motor'
		WHEN dim_detail_core_details.injury_type_code LIKE 'D%' THEN
			'Disease'
		ELSE
			'Casualty'
	  END													AS [Claim Type]
	, CASE 
			WHEN (
					CASE 
						WHEN LOWER(work_type_name)='claims handling' THEN 
							COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve])  
						WHEN ISNULL(fact_finance_summary.[damages_reserve], 0) > 0 THEN
							fact_finance_summary.[damages_reserve]
						WHEN ISNULL(fact_detail_reserve_detail.initial_damages_reserve, 0) > 0 THEN
							fact_detail_reserve_detail.initial_damages_reserve
						ELSE
							fact_finance_summary.damages_paid
						END) <= 25000 THEN 
				'1. Fast Track'
			WHEN (
					CASE 
						WHEN LOWER(work_type_name)='claims handling' THEN 
							COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) 
						WHEN ISNULL(fact_finance_summary.[damages_reserve], 0) > 0 THEN
							fact_finance_summary.[damages_reserve]
						WHEN ISNULL(fact_detail_reserve_detail.initial_damages_reserve, 0) > 0 THEN
							fact_detail_reserve_detail.initial_damages_reserve
						ELSE
							fact_finance_summary.damages_paid
					END) <= 100000 THEN 
				'2. £25,000-£100,000'
			WHEN (
					CASE 
						WHEN LOWER(work_type_name)='claims handling' THEN 
							COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) 
						WHEN ISNULL(fact_finance_summary.[damages_reserve], 0) > 0 THEN
							fact_finance_summary.[damages_reserve]
						WHEN ISNULL(fact_detail_reserve_detail.initial_damages_reserve, 0) > 0 THEN
							fact_detail_reserve_detail.initial_damages_reserve
						ELSE
							fact_finance_summary.damages_paid
					END) <= 500000 THEN 
				'3. £100,001-£500,000'
			WHEN (
					CASE
						WHEN LOWER(work_type_name)='claims handling' THEN 
							COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) 
						WHEN ISNULL(fact_finance_summary.[damages_reserve], 0) > 0 THEN
							fact_finance_summary.[damages_reserve]
						WHEN ISNULL(fact_detail_reserve_detail.initial_damages_reserve, 0) > 0 THEN
							fact_detail_reserve_detail.initial_damages_reserve
						ELSE
							fact_finance_summary.damages_paid 
					END) <= 1000000 THEN 
				'4. £500,001-£1m'
			WHEN (
					CASE 
						WHEN LOWER(work_type_name)='claims handling' THEN 
							COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) 
						WHEN ISNULL(fact_finance_summary.[damages_reserve], 0) > 0 THEN
							fact_finance_summary.[damages_reserve]
						WHEN ISNULL(fact_detail_reserve_detail.initial_damages_reserve, 0) > 0 THEN
							fact_detail_reserve_detail.initial_damages_reserve
						ELSE
							fact_finance_summary.damages_paid 
					END) <= 3000000 THEN 
				'5. £1m-£3m'
			ELSE
				'6. No Reserve' 
		  END			AS [Damages Banding]
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.fact_dimension_main
		ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	INNER JOIN red_dw.dbo.dim_date
		ON CAST(dim_matter_header_current.date_opened_practice_management AS DATE)	= dim_date.calendar_date
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
			AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
			AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.client_code = dim_matter_header_current.client_code
			AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_instruction_type
		ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
		ON dim_detail_finance.client_code = dim_matter_header_current.client_code
			AND dim_detail_finance.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
			AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.client_code = dim_matter_header_current.client_code
			AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	
	LEFT OUTER JOIN ( --dim_client_involvement was slowing query down, replaced with below sub query					
						SELECT 
							dim_matter_header_current.dim_matter_header_curr_key
							, STRING_AGG(CAST(RTRIM(client_involvement.reference) AS NVARCHAR(MAX)), ', ')			AS client_reference
						FROM red_dw.dbo.dim_matter_header_current
							LEFT OUTER JOIN (
												SELECT DISTINCT
													dim_involvement_full.client_code
													, dim_involvement_full.matter_number
													, dim_involvement_full.reference
												FROM red_dw.dbo.dim_involvement_full
												WHERE
													dim_involvement_full.is_active = 1
													AND dim_involvement_full.capacity_code = 'INSURERCLIENT'
											) AS client_involvement 
								ON client_involvement.client_code = dim_matter_header_current.client_code
									AND client_involvement.matter_number = dim_matter_header_current.matter_number
						WHERE
							dim_matter_header_current.master_client_code = 'Z1001'
							--AND dim_matter_header_current.master_matter_number = '78163'
						GROUP BY
							dim_matter_header_current.dim_matter_header_curr_key
					) AS client_references
		ON client_references.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE
	dim_matter_header_current.master_client_code = 'Z1001'
	AND dim_matter_header_current.reporting_exclusions = 0
	AND ISNULL(LOWER(RTRIM(dim_detail_outcome.outcome_of_case)), '') <> 'exclude from reports'
	AND ISNULL(LOWER(RTRIM(dim_detail_client.zurich_data_admin_exclude_from_reports)), 'No') = 'No'
	AND dim_date.cal_year >= @start_year


END 




GO

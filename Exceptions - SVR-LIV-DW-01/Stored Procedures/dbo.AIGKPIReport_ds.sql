SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[AIGKPIReport_ds]
(
@year_type AS NVARCHAR(10), 
@year AS INT ,
@date_period  AS NVARCHAR(MAX),
@referral_reason AS NVARCHAR(MAX)
)
AS


--DECLARE @year_type AS NVARCHAR(10) = 'Financial'
--DECLARE @year AS INT = 2023
--DECLARE @date_period AS INT = '1'
--DECLARE @referral_reason AS NVARCHAR(MAX) = 'dispute on liability and quantum'

DROP TABLE IF EXISTS #DimDateData
DROP TABLE IF EXISTS #aig_last_bill_date
DROP TABLE IF EXISTS #aig_billed_hours

--========================================================================================================================================
-- Getting date keys from parameters selected in report
--========================================================================================================================================
CREATE TABLE #DimDateData(
dim_date_key INT
)

IF @year_type = 'Financial'

INSERT INTO #DimDateData
(
    dim_date_key
)
SELECT dim_date.dim_date_key
FROM red_dw.dbo.dim_date
WHERE
	dim_date.fin_year = @year
	AND (dim_date.fin_month IN (@date_period)
		OR dim_date.fin_quarter_no IN (@date_period)
		)

ELSE

INSERT INTO #DimDateData
(
    dim_date_key
)
SELECT dim_date.dim_date_key
FROM red_dw.dbo.dim_date
WHERE
	dim_date.cal_year = @year
	AND (dim_date.cal_month IN (@date_period)
		OR dim_date.cal_quarter_no IN (@date_period)
		)

--========================================================================================================================================
-- Last bill date
--========================================================================================================================================
SELECT *
INTO #aig_last_bill_date
FROM (
		SELECT 
			dim_matter_header_current.dim_matter_header_curr_key
			, MAX(fact_bill.dim_bill_date_key)		AS dim_bill_date_key	
		FROM red_dw.dbo.dim_bill
			INNER JOIN red_dw.dbo.fact_bill
				ON fact_bill.bill_sequence = dim_bill.bill_sequence
			INNER JOIN red_dw.dbo.dim_matter_header_current 
				ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill.dim_matter_header_curr_key
		WHERE
			dim_matter_header_current.master_client_code = 'A2002'
			AND dim_bill.bill_reversed = 0
		GROUP BY
			dim_matter_header_current.dim_matter_header_curr_key
	) AS last_bill
	INNER JOIN #DimDateData
		ON last_bill.dim_bill_date_key = #DimDateData.dim_date_key

--========================================================================================================================================
-- Billed hours
--========================================================================================================================================
SELECT 
	dim_matter_header_current.dim_matter_header_curr_key
	, SUM(fact_bill_billed_time_activity.invoiced_minutes)/60 AS billed_hours
	, SUM(fact_bill_billed_time_activity.minutes_recorded)/60		AS hours_recorded
INTO #aig_billed_hours
--select fact_bill_billed_time_activity.*
FROM red_dw.dbo.fact_bill_billed_time_activity WITH(NOLOCK)
	INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK) 
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
	INNER JOIN #aig_last_bill_date
		ON #aig_last_bill_date.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
--WHERE
--	dim_matter_header_current.master_client_code = 'A2002'
--	AND dim_matter_header_current.master_matter_number = '4426'
GROUP BY
	dim_matter_header_current.dim_matter_header_curr_key

--========================================================================================================================================
-- Main query
--========================================================================================================================================
SELECT 
	dim_matter_header_current.master_client_code		AS [Client Number]
	, dim_matter_header_current.master_matter_number		AS [Matter Number]
	, CAST(dim_matter_header_current.date_opened_case_management AS DATE)	AS [Date Case Opened]
	, CAST(dim_matter_header_current.date_closed_case_management AS DATE)	AS [Date Case Closed]
	, 'Q' + TRIM(STR(dim_date.cal_quarter_no))			AS [Quarter Concluded]
	, dim_matter_header_current.matter_description		AS [Matter Description]
	, dim_matter_header_current.matter_owner_full_name		AS [Matter Owner]
	, dim_fed_hierarchy_history.hierarchylevel4hist			AS [Team]
	, dim_matter_worktype.work_type_group				AS [Work Type Group]
	, dim_instruction_type.instruction_type				AS [Instruction Type]
	, dim_detail_core_details.aig_reference		AS [AIG Reference]
	, dim_detail_client.aig_litigation_number		AS [LIT Number]
	, dim_detail_core_details.clients_claims_handler_surname_forename		AS [Client Claim Handler]
	, dim_detail_core_details.aig_instructing_office		AS [AIG Instructing Office]
	, dim_detail_core_details.present_position		AS [Present Position]
	, CAST(dim_detail_core_details.date_instructions_received AS DATE)		AS [Date Instructions Received]
	, dim_detail_core_details.referral_reason		AS [Referral Reason]
	, dim_detail_core_details.proceedings_issued		AS [Proceedings Issued]
	, dim_detail_health.date_of_service_of_proceedings		AS [Date Proceedings Served]
	, dim_detail_core_details.track		AS [Track]
	, dim_detail_core_details.suspicion_of_fraud		AS [Suspicion of Fraud]
	, dim_detail_core_details.delegated		AS [Delegated]
	, dim_detail_core_details.aig_current_fee_scale		AS [AIG Current Fee Scale]
	, dim_detail_finance.output_wip_fee_arrangement		AS [Fee Arrangement]
	,ms_fileid
	,udClaimsA.cboWhatFeeArr
	,udMICoreGeneral.cboFeeArrang

	
	, CASE	
		WHEN dim_detail_finance.output_wip_fee_arrangement = 'Fixed Fee/Fee Quote/Capped Fee' THEN
			'Fixed Fee'
		WHEN dim_detail_finance.output_wip_fee_arrangement = 'Hourly rate' THEN	
			'Hourly Rate'
			WHEN udMICoreGeneral.cboFeeArrang = 'HOURLY' THEN 'Hourly Rate'
		ELSE	
			'Other'
	  END				AS [Mapped Fee Arrangement]
	, CAST(dim_detail_core_details.date_initial_report_sent AS DATE)		AS [Date Initial Report Sent]
	, fact_detail_reserve_detail.damages_reserve_initial		AS [Damages Reserve Initial]
	, fact_detail_reserve_detail.tp_costs_reserve_initial		AS [Claimant Costs Reserve Initial]
	, fact_detail_reserve_detail.defence_costs_reserve_initial		AS [Defence Costs Reserve Initial]
	, fact_detail_reserve_detail.damages_reserve			AS [Damages Reserve Current]
	, fact_detail_reserve_detail.current_indemnity_reserve		AS [Claimant Costs Reserve Current]
	, fact_detail_reserve_detail.defence_costs_reserve			AS [Defence Costs Reserve Current]
	, dim_detail_outcome.outcome_of_case		AS [Outcome of Case]
	--, IIF(ISNULL(fact_finance_summary.damages_paid, 0) = 0, 1, 0)		AS [Repudiated/Paid]
	, CASE WHEN (outcome_of_case LIKE 'Discontinued%') OR (outcome_of_case IN
															(
															'Rejected (MIB untraced only)                                ',
															'struck out                                                  ',
															'won at trial                                                ',
															'Struck Out                                                  ',
															'Struck out                                                  ',
															'Won At Trial                                                ',
															'Won at Trial                                                ',
															'Won at trial                                                '
															, 'Withdrawn'
															)) THEN 
		1


	WHEN ((LOWER(outcome_of_case) LIKE 'settled%' ) OR (outcome_of_case IN
														(
														'Assessment of damages',
														'Assessment of damages (damages exceed claimant''s P36 offer) ',
														'Lost at Trial                                               ',
														'Lost at trial                                               ',
														'Lost at trial (damages exceed claimant''s P36 offer)         ',
														'Settled',
														'Settled  - claimant accepts P36 offer out of time',
														'Settled - Infant Approval                                   ',
														'Settled - Infant approval                                   ',
														'Settled - JSM',
														'Settled - Mediation                                         ',
														'Settled - mediation                                         '
														))) THEN 
		0
	WHEN outcome_of_case IN
				(
				'Appeal',
				'Assessment of damages (claimant fails to beat P36 offer)    ',
				'Exclude from reports                                        ',
				'Returned to Client', 'Other', 'Exclude from Reports   ', 'Other'
				) THEN 
		0 
	END								AS [Repudiated/Paid]
	, IIF(ISNULL(RTRIM(dim_instruction_type.instruction_type), '') = 'Costs only', NULL, CAST(dim_detail_outcome.date_claim_concluded AS DATE))			AS [Date Claim Concluded]
	, IIF(ISNULL(RTRIM(dim_instruction_type.instruction_type), '') = 'Costs only', NULL, fact_finance_summary.damages_paid) AS [Damages Paid by Client]
	, CAST(dim_detail_outcome.date_claimants_costs_received AS DATE)	AS [Date Claimant's Costs Received]
	, CAST(dim_detail_outcome.date_costs_settled AS DATE)	AS [Date Costs Settled]
	, fact_finance_summary.claimants_total_costs_claimed			AS [Claimant's Total Costs Claimed Against Client]
	, fact_finance_summary.claimants_costs_paid			AS [Claimant's Costs Paid by Client - Disease]
	, fact_finance_summary.defence_costs_billed			AS [Revenue Costs Billed]
	, fact_finance_summary.disbursements_billed			AS [Disbursements Billed]
	, fact_finance_summary.vat_billed			AS [VAT Billed]
	, dim_date.calendar_date			AS [Last Bill Date]
	, dim_detail_finance.damages_banding				AS [Damages Banding]
	, ISNULL(fact_finance_summary.damages_paid, 0) + ISNULL(fact_finance_summary.claimants_costs_paid, 0)
		+ ISNULL(fact_finance_summary.defence_costs_billed, 0) + ISNULL(fact_finance_summary.disbursements_billed, 0)		AS [Total Case Costs]
	, ISNULL(#aig_billed_hours.billed_hours, 0)		AS [Billed Hours]
	, IIF(ISNULL(#aig_billed_hours.billed_hours, 0) = 0, 0, fact_finance_summary.defence_costs_billed / #aig_billed_hours.billed_hours)		AS [Recovery Rate]
	, DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_date.calendar_date)		AS [Elapsed Days Live Files]
	, DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_detail_outcome.date_costs_settled)		AS [Elapsed Days to Costs Settlement]
	, DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_detail_outcome.date_claim_concluded)		AS [Elapsed Days to Damages Concluded]
	, DATEDIFF(DAY, dim_detail_outcome.date_claim_concluded, dim_detail_outcome.date_costs_settled)			AS [Elapsed Days Damages Settled to Costs Settled]
	, IIF(dim_detail_core_details.date_initial_report_sent IS NULL, NULL, fact_detail_elapsed_days.days_to_first_report_lifecycle)		AS [Elapsed Days Initial Report]
	, DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_date.calendar_date)		AS [Elapsed Days to Last Bill]
	, 1 AS case_count
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN #aig_last_bill_date
		ON #aig_last_bill_date.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.fact_dimension_main
		ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_instruction_type
		ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
			AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.client_code = dim_matter_header_current.client_code
			AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_health
		ON dim_detail_health.client_code = dim_matter_header_current.client_code
			AND dim_detail_health.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
		ON dim_detail_finance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_matter_header_curr_key = dim_detail_core_details.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.client_code = dim_matter_header_current.client_code
			AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days
		ON fact_detail_elapsed_days.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN #aig_billed_hours
		ON #aig_billed_hours.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_date
		ON dim_date.dim_date_key = #aig_last_bill_date.dim_bill_date_key

		LEFT JOIN ms_prod.dbo.udClaimsA
		ON udClaimsA.fileID = ms_fileid

	LEFT JOIN ms_prod.dbo.udMICoreGeneral
	ON udMICoreGeneral.fileID = ms_fileid
WHERE 1 = 1
	AND RTRIM(dim_detail_core_details.present_position) IN ('Final bill sent - unpaid', 'To be closed/minor balances to be clear') 
	AND IIF(ISNULL(LOWER(RTRIM(dim_detail_core_details.referral_reason)), '') = '', 'missing', LOWER(RTRIM(dim_detail_core_details.referral_reason))) IN (@referral_reason)
	AND ISNULL(LOWER(RTRIM(dim_detail_outcome.outcome_of_case)), '') <> 'exclude from reports'
	--AND dim_matter_header_current.master_client_code +'-' + master_matter_number = 'A2002-10048'
ORDER BY	
	[Date Case Opened]
GO

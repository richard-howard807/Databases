SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2022-04-01
-- Description:	Ticket #140824 New Catalina report

-- JL 17/05/2022 added in new fields as per ticket #148197
-- JL 30/09/2022 added in new field as per ticke #17063
-- =============================================

CREATE PROCEDURE [dbo].[catalina_master_report]

AS
BEGIN

SET NOCOUNT ON

DROP TABLE IF EXISTS #last_bill_data
DROP TABLE IF EXISTS #revenue

--=================================================================================================================================
-- Last bill data
--=================================================================================================================================
SELECT *
INTO #last_bill_data
FROM (
		SELECT 
			fact_bill_matter_detail_summary.dim_matter_header_curr_key
			, UPPER(dim_bill.bill_flag)		AS bill_flag
			, dim_bill.bill_number
			, dim_bill.bill_reversed
			, CAST(dim_date.calendar_date AS DATE)	AS last_bill_date
			, ROW_NUMBER() OVER(PARTITION BY fact_bill_matter_detail_summary.dim_matter_header_curr_key ORDER BY CAST(dim_date.calendar_date AS DATE) DESC, dim_bill.bill_number DESC)		AS rw
		--INTO #last_bill
		FROM red_dw.dbo.fact_bill_matter_detail_summary
			INNER JOIN red_dw.dbo.dim_date
				ON fact_bill_matter_detail_summary.dim_bill_date_key = dim_date.dim_date_key
			INNER JOIN red_dw.dbo.dim_bill
				ON dim_bill.bill_sequence = fact_bill_matter_detail_summary.bill_sequence
			INNER JOIN red_dw.dbo.dim_matter_header_current
				ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_matter_detail_summary.dim_matter_header_curr_key
			LEFT OUTER JOIN red_dw.dbo.dim_detail_client
				ON dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
		WHERE 1 = 1
			AND (dim_matter_header_current.master_client_code = 'W25984'
				OR (dim_matter_header_current.master_client_code = 'Z1001' AND dim_detail_client.is_there_a_catalina_claim_number_on_this_claim = 'Yes'))
			AND dim_bill.bill_reversed = 0
	) AS all_data
WHERE
	all_data.rw = 1


--=================================================================================================================================
-- Revenue
--=================================================================================================================================
SELECT 
	fact_bill_activity.dim_matter_header_curr_key
	, SUM(fact_bill_activity.bill_amount) AS revenue
INTO #revenue
FROM red_dw.dbo.fact_bill_activity WITH(NOLOCK)
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_activity.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE 1 = 1
	AND (dim_matter_header_current.master_client_code = 'W25984'
		OR (dim_matter_header_current.master_client_code = 'Z1001' AND dim_detail_client.is_there_a_catalina_claim_number_on_this_claim = 'Yes'))
GROUP BY
	fact_bill_activity.dim_matter_header_curr_key

--=================================================================================================================================
-- Main query
--=================================================================================================================================
SELECT 
	CAST(dim_detail_core_details.date_instructions_received AS DATE)		AS [Receipt of Instruction]
	, CAST(dim_matter_header_current.date_opened_case_management AS DATE)	AS [Date Opened]
	, dim_client_involvement.insurerclient_reference				AS [Claim Number]
	, ISNULL(NULLIF(dim_claimant_thirdparty_involvement.claimant_name, ''), dim_detail_claim.zurich_data_admin_claimant_name)				AS [Claimant Name]
	, ISNULL(NULLIF(dim_client_involvement.insuredclient_name, ''), dim_detail_core_details.zurich_policy_holdername_of_insured)					AS [Policyholder]
	, dim_matter_header_current.master_client_code + '.' + dim_matter_header_current.master_matter_number		AS [MS Reference]
	, dim_matter_header_current.matter_owner_full_name			AS [Matter Owner]
	, dim_employee.locationidud					AS [Office]
	, dim_detail_core_details.present_position			AS [Present Position]
	, dim_detail_core_details.injury_type_code			AS [Injury Type]
	, CAST(dim_detail_core_details.date_initial_report_due AS DATE)		AS [Date Initial Report Due]
	, CAST(dim_detail_core_details.date_initial_report_sent AS DATE)		AS [Date Initial Report Sent]
	, dim_detail_outcome.outcome_of_case			AS [Outcome of Claim]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)		AS [Date Claim Concluded]
	, CAST(dim_matter_header_current.date_closed_case_management AS DATE)			AS [Date Matter Closed]
	, #last_bill_data.bill_flag		AS [Last Bill Marked Final or Interim]
	, dim_matter_header_current.billing_arrangement_description		AS [Billing Arrangement Description]
	, dim_matter_header_current.billing_arrangement		AS [Billing Arrangement Code]
	, fact_finance_summary.client_account_balance_of_matter		AS [Client Account Balance]
	, fact_finance_summary.total_amount_billed			AS [Total Amount Billed]
	, #revenue.revenue			AS [Revenue Costs Billed]
	, fact_finance_summary.disbursements_billed			AS [Disbursements Billed]
	, fact_finance_summary.vat_billed					AS [VAT Billed]
	, fact_finance_summary.wip							AS [WIP]
	, fact_finance_summary.disbursement_balance			AS [Unbilled Disbursements]
	, #last_bill_data.last_bill_date				AS [Last Bill Date]
	, CAST(fact_matter_summary_current.last_time_transaction_date AS DATE)				AS [Last Time Transaction Date]
	,dim_detail_claim.[lead_or_follow] AS [Lead/Follow]
	,dim_detail_core_details.referral_reason AS [Referral Reason]
	,dim_matter_worktype.[work_type_name] AS [work Type]
	,track AS [Track]
	,fact_finance_summary.damages_reserve AS[Damages Reserve]
	,claimant_costs_reserve_current AS [Claimants Costs Reserve]
	,fact_detail_claim.damages_paid_by_client AS [Damages Paid]
	,claimants_total_costs_paid_by_all_parties AS [Claimants Costs Paid]
	, [Defence cost reserve (current)] = udMICurrentReserves.curDefCostReCur 
	, dim_detail_health.date_of_service_of_proceedings

FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.fact_dimension_main
		ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	INNER JOIN red_dw.dbo.dim_employee
		ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
		ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.fact_matter_summary_current
		ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN #last_bill_data
		ON #last_bill_data.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN #revenue
		ON #revenue.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
   LEFT JOIN red_dw.dbo.dim_detail_claim
	ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_claim WITH(NOLOCK)
   ON  fact_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail WITH(NOLOCK)
  ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype WITH(NOLOCK)
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
 LEFT OUTER JOIN red_dw.dbo.dim_detail_health
ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key

 LEFT JOIN ms_prod.dbo.udMICurrentReserves
 ON fileID = ms_fileid
WHERE 1 = 1
	AND dim_matter_header_current.reporting_exclusions = 0
	AND (dim_matter_header_current.master_client_code = 'W25984'
		OR (dim_matter_header_current.master_client_code = 'Z1001' AND dim_detail_client.is_there_a_catalina_claim_number_on_this_claim = 'Yes'))
ORDER BY
	dim_matter_header_current.date_opened_case_management

END	
GO

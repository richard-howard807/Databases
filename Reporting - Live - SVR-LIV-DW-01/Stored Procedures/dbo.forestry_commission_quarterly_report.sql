SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2022-06-20
-- Description: #152648 New report for Forestry Commission client
-- =============================================
*/

CREATE PROCEDURE [dbo].[forestry_commission_quarterly_report] 
(
	@selected_quarter INT
)
AS

BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--testing
--DECLARE @selected_quarter AS INT = 202101


DECLARE @last_quarter AS INT = (SELECT q.last_quarter FROM (
									SELECT DISTINCT TOP 1 dim_date.cal_quarter, LAG(dim_date.cal_quarter) OVER(ORDER BY dim_date.cal_quarter) AS last_quarter
									FROM red_dw.dbo.dim_date
									WHERE
										dim_date.cal_quarter <= @selected_quarter
									ORDER BY
										dim_date.cal_quarter DESC) AS q
								)


DROP TABLE IF EXISTS #fc_revenue
DROP TABLE IF EXISTS #fee_balance

SELECT 
	fact_bill_activity.dim_matter_header_curr_key
	, SUM(fact_bill_activity.bill_amount)		AS fees_in_quarter
INTO #fc_revenue
FROM red_dw.dbo.fact_bill_activity
	INNER JOIN red_dw.dbo.dim_date
		ON dim_date.dim_date_key = fact_bill_activity.dim_bill_date_key
WHERE
	dim_date.cal_quarter = @last_quarter
	AND RTRIM(fact_bill_activity.client_code) = 'W24119'
GROUP BY
	fact_bill_activity.dim_matter_header_curr_key


SELECT 
	ds_sh_3e_matter.number
	, SUM(ds_sh_3e_invmaster.balfee)		AS outstanding_fees
INTO #fee_balance
FROM red_dw.dbo.ds_sh_3e_invmaster
	INNER JOIN red_dw.dbo.ds_sh_3e_matter
		ON ds_sh_3e_matter.mattindex = ds_sh_3e_invmaster.leadmatter
	INNER JOIN red_dw.dbo.ds_sh_3e_client
		ON ds_sh_3e_matter.client = ds_sh_3e_client.clientindex
WHERE
	ds_sh_3e_client.number = 'W24119'
GROUP BY
	ds_sh_3e_matter.number
HAVING
	SUM(ds_sh_3e_invmaster.balfee) > 0


SELECT
	dim_claimant_thirdparty_involvement.claimant_name		AS [Claimant Name]
	, dim_matter_header_current.matter_description			AS [Matter Description]
	, NULL					AS [Forest District]
	, dim_detail_core_details.clients_claims_handler_surname_forename		AS [FE Contact Client]
	, dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number		AS [Weightmans Reference]
	, dim_matter_header_current.matter_owner_full_name		AS [Fee Earner]
	, dim_matter_worktype.work_type_name			AS [Work Type]
	, dim_detail_core_details.referral_reason			AS [Referral Reason]
	, dim_detail_finance.output_wip_fee_arrangement		AS [Fee Basis]
	, CAST(dim_matter_header_current.date_opened_case_management AS DATE)			AS [Date Opened]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)			AS [Date Completed]
	, IIF(dim_matter_header_current.date_closed_case_management IS NULL, 'Open', 'Closed')		AS [File Status]
	, CAST(dim_detail_core_details.incident_date AS DATE)			AS [Accident Date]
	, dim_detail_core_details.brief_details_of_claim			AS [Accident Details]
	, NULL				AS [Current Status]
	, NULL				AS [Probability of Claim Succeeding]
	, fact_detail_reserve_detail.general_damages_non_pi_misc_reserve_current			AS [General Damages Reserve]
	, fact_detail_reserve_detail.special_damages_miscellaneous_reserve			AS [Special Damages Reserve]
	, fact_detail_reserve_detail.claimant_costs_reserve_current					AS [Claimant Costs Reserve]
	, fact_finance_summary.cru_reserve											AS [CRU Reserve]
	, fact_detail_reserve_detail.nhs_charges_reserve_current						AS [NHS Charges Reserve]
	, fact_finance_summary.defence_costs_reserve										AS [Defence Costs Estimate]
	,	ISNULL(fact_detail_reserve_detail.general_damages_non_pi_misc_reserve_current, 0)	
		+ ISNULL(fact_detail_reserve_detail.special_damages_miscellaneous_reserve, 0)		
		+ ISNULL(fact_detail_reserve_detail.claimant_costs_reserve_current, 0)				
		+ ISNULL(fact_finance_summary.cru_reserve, 0)										
		+ ISNULL(fact_detail_reserve_detail.nhs_charges_reserve_current, 0)					
		+ ISNULL(fact_finance_summary.defence_costs_reserve, 0)							AS [Total Reserve]		
	, ISNULL(fact_finance_summary.damages_interims, 0) + ISNULL(fact_detail_paid_detail.interim_costs_payments, 0)		AS [Payments Made]
	, fact_finance_summary.damages_paid			AS [Damages Paid]
	, fact_finance_summary.total_tp_costs_paid			AS [Costs Paid]
	, fact_finance_summary.defence_costs_billed				AS [Fees Paid to Date]
	, fact_finance_summary.disbursements_billed				AS [Disbursements Paid to Date]
	, #fc_revenue.fees_in_quarter							AS [Fees for Last Quarter]
	, fact_finance_summary.wip						AS [Fees to be Billed This Quarter]
	, fact_finance_summary.disbursement_balance			AS [Disbursements to be Billed This Quarter]
	, #fee_balance.outstanding_fees				AS [Fees Billed Awaiting Payment]
	, (ISNULL(fact_detail_reserve_detail.general_damages_non_pi_misc_reserve_current, 0)	
		+ ISNULL(fact_detail_reserve_detail.special_damages_miscellaneous_reserve, 0)		
		+ ISNULL(fact_detail_reserve_detail.claimant_costs_reserve_current, 0)				
		+ ISNULL(fact_finance_summary.cru_reserve, 0)										
		+ ISNULL(fact_detail_reserve_detail.nhs_charges_reserve_current, 0)					
		+ ISNULL(fact_finance_summary.defence_costs_reserve, 0))
	  - 
		(ISNULL(fact_finance_summary.damages_paid, 0)
		+ ISNULL(fact_finance_summary.total_tp_costs_paid, 0)
		+ ISNULL(fact_finance_summary.defence_costs_billed, 0))				AS [Outstanding Reserve]
	, CASE
		WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL THEN
			'Closed'
		WHEN TRIM(dim_fed_hierarchy_history.hierarchylevel3hist) = 'Regulatory' THEN
			'Regulatory'
		WHEN TRIM(dim_detail_core_details.referral_reason) = 'Advice only' THEN
			'Advice Only'
		WHEN dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims' THEN
			'Claims'
	  END										AS tab_split
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code
			AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
	INNER JOIN red_dw.dbo.dim_date
		ON dim_date.calendar_date = CAST(dim_matter_header_current.date_opened_case_management AS DATE)
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
		ON dim_detail_finance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
		ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
			AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
		ON fact_detail_paid_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN #fc_revenue
		ON #fc_revenue.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN #fee_balance
		ON #fee_balance.number = dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number
WHERE
	dim_matter_header_current.reporting_exclusions = 0
	AND dim_matter_header_current.master_client_code = 'W24119'
	AND dim_date.cal_quarter <= @selected_quarter
	AND RTRIM(LOWER(ISNULL(dim_detail_outcome.outcome_of_case, ''))) <> 'exclude from reports'

END



GO

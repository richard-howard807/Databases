SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--USE Visualisation

	-- =============================================
-- Author:		<Julie Loughlin >
-- Create date: <2021-09-10>
-- Description:	Data Set to drive the Real Estate Financial Dashboard>
  -- =============================================

  CREATE PROCEDURE  [dbo].[RealEstateDashboard]
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON 

IF OBJECT_ID('#billed_time') IS NOT NULL
        DROP TABLE #billed_time;
IF OBJECT_ID('#recorded_time') IS NOT NULL
        DROP TABLE #recorded_time



/*--------------------------------------------------------------------------------------
          get the value (£) of hours billed 
-----------------------------------------------------------------------------------*/
SELECT
	dim_matter_header_current.dim_matter_header_curr_key
	, SUM(fact_bill_billed_time_activity.invoiced_minutes) / 60		AS hours_billed
	, SUM(fact_bill_billed_time_activity.time_charge_value)			AS value_hours_billed
--SELECT fact_bill_billed_time_activity.*
INTO #billed_time
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.fact_bill_billed_time_activity ON fact_bill_billed_time_activity.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_date ON fact_bill_billed_time_activity.dim_bill_date_key = dim_date.dim_date_key
	INNER JOIN red_dw.dbo.fact_dimension_main ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
	AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
WHERE 1 = 1
	--AND dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number = 'W22678-1'  --IN ('W17049-10', '153838M-64')
	AND dim_fed_hierarchy_history.hierarchylevel3hist = 'Real Estate'
	AND dim_matter_header_current.date_opened_case_management >= '2019-05-01'
	AND (date_claim_concluded IS NULL 
	OR date_claim_concluded>='2019-05-01')
GROUP BY
	dim_matter_header_current.dim_matter_header_curr_key

	/*--------------------------------------------------------------------------------------
          get the value (£) of total hours recorded regardless if billed or not
-----------------------------------------------------------------------------------*/

SELECT 
	dim_matter_header_current.dim_matter_header_curr_key
	, SUM(fact_all_time_activity.wiphrs)		AS hours_recorded
	, SUM(fact_all_time_activity.wipamt)		AS value_hours_recorded
INTO #recorded_time
FROM red_dw.dbo.fact_all_time_activity		
	INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.fact_dimension_main ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
	AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
WHERE 1 = 1
	--AND dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number IN ('W22678-1')
	AND dim_fed_hierarchy_history.hierarchylevel3hist = 'Real Estate'
		AND dim_matter_header_current.date_opened_case_management >= '2019-05-01'
	AND (date_claim_concluded IS NULL 
	OR date_claim_concluded>='2019-05-01')
GROUP BY
	dim_matter_header_current.dim_matter_header_curr_key


	/*--------------------------------------------------------------------------------------
          main query 
-----------------------------------------------------------------------------------*/

SELECT
	dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number AS [3E Ref]
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)			AS [Date Opened]
	, CAST(dim_matter_header_current.date_closed_practice_management AS DATE)			AS [Date Closed]
	, dim_matter_header_current.client_name					AS [Client Name]
	, dim_matter_header_current.matter_description			AS [Matter Description]
	, dim_matter_header_current.matter_owner_full_name		AS [Matter Owner]
	, dim_fed_hierarchy_history.hierarchylevel4hist			AS [Team]
	, dim_fed_hierarchy_history.hierarchylevel3hist			AS [Department]
	, dim_matter_worktype.work_type_name				AS [Matter Type]
	, dim_detail_finance.output_wip_fee_arrangement			AS [Fee Arrangement]
	, fact_finance_summary.fixed_fee_amount				AS [Fixed Fee Amount]
	, CAST(fact_bill_matter.last_bill_date AS DATE)				AS [Last Bill Date (Non Comp)]
	, fact_finance_summary.defence_costs_billed			AS [Revenue Billed (Net of VAT]
	, fact_finance_summary.total_amount_billed			AS [Total Billed]
	, #recorded_time.hours_recorded					AS [Hours Recorded]
	, #recorded_time.value_hours_recorded			AS [Value of Hours Recorded]
	, #billed_time.value_hours_billed				AS [Value of Billed Hours]
	, #recorded_time.value_hours_recorded - #billed_time.value_hours_billed  				AS [Write Off Amount]
	,(
           SELECT fin_year
           FROM red_dw..dim_date WITH(NOLOCK)
           WHERE dim_date.calendar_date = CAST(dim_matter_header_current.date_opened_case_management AS DATE)
       ) [Fin Year Opened]
     
	   ,
       (
           SELECT fin_year
           FROM red_dw..dim_date WITH(NOLOCK)
           WHERE dim_date.calendar_date = CAST(dim_matter_header_current.date_closed_case_management AS DATE)
       ) [Fin Year Closed]

FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.fact_dimension_main ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.fact_bill_matter ON fact_bill_matter.client_code = dim_matter_header_current.client_code
	AND fact_bill_matter.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.client_code = dim_matter_header_current.client_code
	AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
	AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.client_code = dim_matter_header_current.client_code
	AND dim_detail_finance.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN #billed_time ON #billed_time.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN #recorded_time ON #recorded_time.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
	AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
WHERE
	dim_fed_hierarchy_history.hierarchylevel3hist = 'Real Estate'
	AND dim_matter_header_current.date_opened_case_management >= '2019-05-01'
	AND (date_claim_concluded IS NULL 
	OR date_claim_concluded>='2019-05-01')
	--AND dim_detail_finance.output_wip_fee_arrangement = 'Fixed Fee/Fee Quote/Capped Fee'
	--AND dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number IN ('W22678-1')


   END 
GO
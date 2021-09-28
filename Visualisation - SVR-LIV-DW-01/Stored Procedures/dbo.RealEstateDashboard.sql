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

Bill adjustment – where WIP is reduced in value at the point of bill, e.g. on a fixed fee where all the time gets put onto a bill, but the fee value is less than the WIP recorded, so everyone gets pro-rated down. 
WIP adjustment – this should be where something has been altered mid-matter. So perhaps the file was opened and everyone was set up to record at £500 per hour. Someone reviews the file and realises the mistake, changes it to £150 per hour. The value of WIP has been reduced, but it never really existed because it was a mistake.
Purged time – this is a true write off in the sense the time will never be billed. It is deleted from the system. Any value was completely lost. Probably most likely on aborted deals, or time recorded post completion. 

-----------------------------------------------------------------------------------*/
SELECT
	dim_matter_header_current.dim_matter_header_curr_key
	, SUM(fact_bill_billed_time_activity.invoiced_minutes) / 60		AS hours_billed
	, SUM(fact_bill_billed_time_activity.time_charge_value)			AS value_hours_billed
	,SUM(red_dw.dbo.fact_bill_billed_time_activity.minutes_recorded) /60 AS [Reported Billed Hours]
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
	,red_dw.dbo.dim_matter_header_current.fee_arrangement AS [Fee Arrangement v2]
	, fact_finance_summary.fixed_fee_amount				AS [Fixed Fee Amount]
	, CAST(fact_bill_matter.last_bill_date AS DATE)				AS [Last Bill Date (Non Comp)]
	, fact_finance_summary.defence_costs_billed			AS [Revenue Billed (Net of VAT]
	, fact_finance_summary.total_amount_billed			AS [Total Billed]
	
	--, #recorded_time.hours_recorded					AS [Hours Recorded]
	, #recorded_time.value_hours_recorded			AS [Value of Hours Recorded]
	, #billed_time.value_hours_billed				AS [Value of Billed Hours]
	--, #billed_time.[Reported Billed Hours] - #billed_time.value_hours_billed  				AS [Write Off Amount]
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
	   ,[WriteOfAmount (Billing Adjustment)]
	   ,[WriteOfAmount (Purged Time]
	   ,[WriteOfAmount (Chargeable Time]
	   ,[Total WriteOfAmount] 

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
 INNER JOIN (
    			SELECT 
			SUM(write_off_amt) AS [WriteOfAmount (Billing Adjustment)]
			,dim_matter_header_curr_key
			

			FROM red_dw.dbo.fact_write_off
			--INNER JOIN red_dw.dbo.dim_date on dim_date.dim_date_key=fact_write_off.dim_write_off_date_key
			WHERE client_code = 'W22678'  AND matter_number = '00000001'
			AND fact_write_off.write_off_type = 'BA'
			GROUP BY
		
			dim_matter_header_curr_key) AS writeoff 
ON writeoff.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

 INNER JOIN (
    			SELECT 
			SUM(write_off_amt) AS [WriteOfAmount (Purged Time]
					,dim_matter_header_curr_key
			

			FROM red_dw.dbo.fact_write_off
			--INNER JOIN red_dw.dbo.dim_date on dim_date.dim_date_key=fact_write_off.dim_write_off_date_key
			WHERE client_code = 'W22678'  AND matter_number = '00000001'
			AND fact_write_off.write_off_type = 'P'
			GROUP BY
		
			dim_matter_header_curr_key) AS writeoff_purg 
ON writeoff_purg .dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

INNER JOIN (
    			SELECT 
			SUM(write_off_amt) AS [Total WriteOfAmount] 
			,dim_matter_header_curr_key
			

			FROM red_dw.dbo.fact_write_off
			--INNER JOIN red_dw.dbo.dim_date on dim_date.dim_date_key=fact_write_off.dim_write_off_date_key
			WHERE client_code = 'W22678'  AND matter_number = '00000001'
			--AND fact_write_off.write_off_type = 'BA'
			GROUP BY
		
			dim_matter_header_curr_key) AS writeoff_Total 
ON writeoff_Total.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 INNER JOIN (
    			SELECT 
			SUM(write_off_amt) AS [WriteOfAmount (Chargeable Time]
			,dim_matter_header_curr_key
			

			FROM red_dw.dbo.fact_write_off
			--INNER JOIN red_dw.dbo.dim_date on dim_date.dim_date_key=fact_write_off.dim_write_off_date_key
			WHERE client_code = 'W22678'  AND matter_number = '00000001'
			AND fact_write_off.write_off_type = 'NC'
			GROUP BY
		
			dim_matter_header_curr_key) AS writeoff_CHT 
ON writeoff_CHT.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE
	dim_fed_hierarchy_history.hierarchylevel3hist = 'Real Estate'
	AND dim_matter_header_current.date_opened_case_management >= '2019-05-01'
	AND (date_claim_concluded IS NULL 
	OR date_claim_concluded>='2019-05-01')
	--AND dim_detail_finance.output_wip_fee_arrangement = 'Fixed Fee/Fee Quote/Capped Fee'
	AND  dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number IN ('W22678-1')


   END 
GO

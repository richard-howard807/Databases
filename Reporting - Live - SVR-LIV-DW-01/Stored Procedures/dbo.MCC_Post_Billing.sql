SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =========================================================================================
-- Author:		Emily Smith
-- Create date: 13/11/2020
-- Ticket:		79001
-- Description:	New post billing report for manchester city council
-- =========================================================================================

-- ==========================================================================================
CREATE PROCEDURE [dbo].[MCC_Post_Billing]
--(
--	@StartDate DATE
--	,@EndDate DATE 

--)	
AS
	-- For testing purposes
	--DECLARE @StartDate DATE = '20201001'
	--DECLARE @EndDate DATE = '20201031'

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT
            dim_matter_header_current.master_client_code + '-' +  dim_matter_header_current.master_matter_number AS [File Ref]
			,dim_matter_header_current.client_name AS [Council]
			,NULL AS [Social Worker]
			,dim_fed_hierarchy_history.name  AS [Case Handler]
			,dim_matter_header_current.matter_description	AS [Matter Description]
			,fact_finance_summary.defence_costs_billed AS [Fees Billed to Date]
			,SUM(bills.fees) AS [Fees]
			,SUM(bills.disbs) AS [Disbursements]
			,SUM(bills.disbs_vat + bills.fees_vat) AS [VAT Amount]
			,SUM(bills.fees+bills.disbs+bills.disbs_vat + bills.fees_vat)  [Total] 
			,bills.bill_number AS [Invoice]

	FROM red_dw.dbo.fact_dimension_main
	INNER JOIN	red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key

-- Date range financials
	INNER JOIN (
		SELECT client_code
				,matter_number
				,bill_number
				,SUM(CASE WHEN charge_type = 'time' THEN bill_total_excl_vat ELSE 0 END) fees
				,SUM(CASE WHEN charge_type = 'disbursements' THEN bill_total_excl_vat ELSE 0 END) [disbs]
				,SUM(CASE WHEN charge_type = 'disbursements' THEN vat_amount ELSE 0 END) disbs_vat
				,SUM(CASE WHEN charge_type = 'time' THEN vat_amount ELSE 0 END) fees_vat

		FROM red_dw.dbo.fact_bill_detail 
		INNER JOIN red_dw.dbo.dim_date billed_date ON fact_bill_detail.dim_bill_date_key = billed_date.dim_date_key
		WHERE client_code IN ('00704563','177862R')  
		AND fact_bill_detail.bill_number<>'PURGE'
		--AND billed_date.calendar_date >= @StartDate AND billed_date.calendar_date <= @EndDate
	
	GROUP BY client_code, matter_number, bill_number
	) bills ON bills.client_code = dim_matter_header_current.client_code AND bills.matter_number = dim_matter_header_current.matter_number 


	WHERE dim_matter_header_current.client_code IN ('00704563','177862R')  
	AND dim_matter_header_current.matter_number <> 'ML'
	AND dim_matter_header_current.date_closed_case_management IS NULL 
	AND dim_matter_header_current.reporting_exclusions=0
	
  
     GROUP BY dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number,
              dim_matter_header_current.client_name,
              dim_fed_hierarchy_history.name,
              dim_matter_header_current.matter_description,
              fact_finance_summary.defence_costs_billed,
              bills.bill_number
  
  ORDER BY [File Ref], Invoice


GO

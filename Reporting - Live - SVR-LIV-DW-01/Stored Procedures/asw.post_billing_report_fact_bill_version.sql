SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/*
	
*/
-- =========================================================================================
-- Author:		Lucy Dickinson
-- Create date: 22/02/2018
-- Ticket:		293398
-- Description:	Replacing the DAX version with a sql version to try and get rid of the complexity
-- =========================================================================================
CREATE PROCEDURE [asw].[post_billing_report_fact_bill_version]
(
	@StartDate DATE
	,@EndDate DATE 

)	
AS
	-- For testing purposes
	--DECLARE @StartDate DATE = '20170501'
	--DECLARE @EndDate DATE = '20180131'

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT
            dim_matter_header_current.client_code [client]
			,dim_matter_header_current.matter_number [matter]
			,dim_matter_header_current.client_code + '.' +  dim_matter_header_current.matter_number case_ref
			,RTRIM(dim_detail_property.store_number) store_number
			,RTRIM(dim_detail_property.store_name) store_name
			,RTRIM(dim_detail_property.case_type_asw) [case_type]
			,RTRIM(dim_detail_property.case_classification) case_classification 
            ,RTRIM(dim_detail_property.property_contact) property_contact
			,dim_fed_hierarchy_history.name  matter_owner_name
			,fact_detail_property.fee_estimate
			,fact_finance_summary.defence_costs_billed
       --     ,invoices.Invoices
			,bills.bill_total - bills.vat [bill_amount_ex_vat]
			,bills.fees_total
			,bills.disbs+ bills.unpaid_disbs [disbs]
			,bills.vat
			,bills.bill_total
	FROM red_dw.dbo.fact_dimension_main
	INNER JOIN	red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key 
	INNER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
	INNER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	INNER JOIN red_dw.dbo.fact_detail_property ON fact_detail_property.master_fact_key = fact_dimension_main.master_fact_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
-- Date range financials
	INNER JOIN (
		SELECT fact_bill.client_code
		,fact_bill.matter_number
		,SUM(fact_bill.fees_total) fees_total
		,SUM(fact_bill.vat_amount) vat	
		,SUM(fact_bill.paid_disbursements) disbs
		,SUM(fact_bill.bill_total) bill_total
		,SUM(fact_bill.unpaid_disbursements) unpaid_disbs
	FROM [red_dw].[dbo].[fact_bill] fact_bill
		INNER JOIN red_dw.dbo.dim_date billed_date ON fact_bill.dim_bill_date_key = billed_date.dim_date_key
	WHERE client_code IN ('00787558','00787559','00787560','00787561')  
		AND billed_date.calendar_date BETWEEN @StartDate AND @EndDate
	
	GROUP BY fact_bill.client_code, fact_bill.matter_number
	) bills ON bills.client_code = dim_matter_header_current.client_code AND bills.matter_number = dim_matter_header_current.matter_number 


	WHERE dim_matter_header_current.client_code IN ('00787558','00787559','00787560','00787561')  
	AND dim_matter_header_current.matter_number <> 'ML'
	AND dim_matter_header_current.date_closed_case_management IS NULL 
	-- 2018/02/22 Requested by Kate Fox 293398
	--AND fact_detail_property.fee_estimate <> fact_detail_property.third_party_pay	
	AND bills.bill_total <> 0
ORDER BY dim_matter_header_current.client_code, dim_matter_header_current.matter_number


GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





-- =========================================================================================
-- Author:		Lucy Dickinson
-- Create date: 22/02/2018
-- Ticket:		293398
-- Description:	Replacing the DAX version with a sql version to try and get rid of the complexity
-- =========================================================================================
-- 20180319 LD Webby 301576:  Kate requested that we exclude any negative invoices
-- ==========================================================================================
CREATE PROCEDURE [asw].[post_billing_report_v2]
(
	@StartDate DATE
	,@EndDate DATE 

)	
AS
	-- For testing purposes
	--DECLARE @StartDate DATE = '20171201'
	--DECLARE @EndDate DATE = '20171231'

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
			,bills.bill_number
			,SUM(bills.fees) fees_total
			,SUM(bills.disbs) [disbs]
			,SUM(bills.disbs_vat + bills.fees_vat) [vat]
			,SUM(bills.fees+bills.disbs+bills.disbs_vat + bills.fees_vat)  bill_total 
	FROM red_dw.dbo.fact_dimension_main
	INNER JOIN	red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key 
	INNER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
	INNER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	INNER JOIN red_dw.dbo.fact_detail_property ON fact_detail_property.master_fact_key = fact_dimension_main.master_fact_key
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
		WHERE client_code IN ('00787558','00787559','00787560','00787561')  
		AND billed_date.calendar_date >= @StartDate AND billed_date.calendar_date <= @EndDate
	
	GROUP BY client_code, matter_number, bill_number
	) bills ON bills.client_code = dim_matter_header_current.client_code AND bills.matter_number = dim_matter_header_current.matter_number 


	WHERE dim_matter_header_current.client_code IN ('00787558','00787559','00787560','00787561')  
	AND dim_matter_header_current.matter_number <> 'ML'
	AND dim_matter_header_current.date_closed_case_management IS NULL 
	-- 2018/02/22 Requested by Kate Fox 293398
	AND fact_detail_property.fee_estimate <> fact_detail_property.third_party_pay	
	-- 2018/03/19 Request by Kate Fox 301576 (changed <> 0 to > 0)
	AND (bills.fees+bills.disbs+bills.disbs_vat + bills.fees_vat) > 0
	
  
     GROUP BY       dim_matter_header_current.client_code 
			,dim_matter_header_current.matter_number 
			,RTRIM(dim_detail_property.store_number) 
			,RTRIM(dim_detail_property.store_name) 
			,RTRIM(dim_detail_property.case_type_asw) 
			,RTRIM(dim_detail_property.case_classification) 
            ,RTRIM(dim_detail_property.property_contact) 
			,dim_fed_hierarchy_history.name 
			,fact_detail_property.fee_estimate
			,fact_finance_summary.defence_costs_billed
			,bills.bill_number
  
  
  ORDER BY dim_matter_header_current.client_code, dim_matter_header_current.matter_number



GO

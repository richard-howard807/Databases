SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*
===================================================
===================================================
Author:				Lucy Dickinson
Created Date:		2018-09-26
Description:		Property Co-Op Billing Dashboard Query (Bill and Matter Level)
Current Version:	Initial Create
====================================================
====================================================
*/
 
CREATE PROCEDURE [dbo].[real_estate_coop_billing]
AS

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
				'Bill Level' [Source]
				 ,RTRIM(fact_bill.client_code)+'/'+fact_bill.matter_number AS [Weightmans Reference]
				,dim_matter_header_current.[matter_description] AS [Matter Description]
				,dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
				,dim_matter_header_current.date_closed_case_management AS [Date Case Closed]
				,fact_bill.bill_number AS [Bill Number]
				,fact_bill.bill_total AS [Bill Total]
				,fact_bill.fees_total AS [Revenue]
				,fact_bill.amount_paid AS [Bill Amount Paid]
				,ISNULL(fact_bill.bill_total,0) - ISNULL(fact_bill.amount_paid,0) AS [Left to Pay]
				,dim_bill_date.bill_date AS [Bill Date] --this has two different bill dates 
				,dim_bill_date.bill_cal_month_no AS [Month Billed]
				,dim_bill_date.bill_cal_month_name AS [Month Name Billed]
				,dim_bill_date.bill_cal_year [Year Billed]
				,dim_detail_property.[coop_purchase_order_1] AS [Co-op PO Ref]
				,dim_detail_property.[weightmans_po_reference] AS [Weightmans PO Reference]
				,dim_detail_property.[surveyor_dealing] AS [Surveyor Dealing]
				,dim_detail_property.[transaction_1] AS [Transaction Type]
				,dim_detail_property.[property_address] AS [Property Address]
				,0 AS [Current Costs Estimate]
	FROM
	red_dw.dbo.fact_bill AS fact_bill 
	LEFT OUTER JOIN red_dw.dbo.dim_bill_date ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.client_code=fact_bill.client_code AND dim_matter_header_current.matter_number=fact_bill.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_dimension_main ON fact_dimension_main.master_fact_key = fact_bill.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_property dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
	


	WHERE 


	((fact_bill.client_code  = '90735C'AND fact_bill.matter_number >= '00004570')
	OR (fact_bill.client_code  = '89471N'AND fact_bill.matter_number >= '00000125')
	OR (fact_bill.client_code  = '00568762'AND fact_bill.matter_number >= '00000106'))

	AND dim_bill_date.bill_date >'20140331' 
	AND dim_matter_header_current.reporting_exclusions=0
	AND dim_matter_header_current.date_closed_case_management IS NULL
	AND dim_matter_header_current.matter_description NOT LIKE 'test%'
	AND dim_matter_header_current.matter_description NOT LIKE '%GENERAL FILE%'
	
	

	UNION 


	SELECT 
				--SUM(fact_finance_summary.[total_amount_billed])
				
				'Matter Level' [Source]
				 ,RTRIM(main.client_code)+'/'+main.matter_number AS [Weightmans Reference]
				,dim_matter_header_current.[matter_description] AS [Matter Description]
				,dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
				,dim_matter_header_current.date_closed_case_management AS [Date Case Closed]
				,''  AS [Bill Number]
				,fact_finance_summary.[total_amount_billed] AS [Bill Total]
				,fact_finance_summary.[defence_costs_billed]  AS [Revenue]
				,fact_finance_summary.[total_paid] AS [Bill Amount Paid]
				,ISNULL(fact_finance_summary.[total_amount_billed],0) - ISNULL(fact_finance_summary.[total_paid],0) AS [Left to Pay]
				,dim_detail_client.[bill_date] AS [Bill Date] --this has two different bill dates 
				,'' AS [Month Billed]
				,'' AS [Month Name Billed]
				,YEAR(dim_detail_client.[bill_date]) [Year Billed]
				,dim_detail_property.[coop_purchase_order_1] AS [Co-op PO Ref]
				,dim_detail_property.[weightmans_po_reference] AS [Weightmans PO Reference]
				,dim_detail_property.[surveyor_dealing] AS [Surveyor Dealing]
				,dim_detail_property.[transaction_1] AS [Transaction Type]
				,dim_detail_property.[property_address] AS [Property Address]
				,fact_finance_summary.commercial_costs_estimate AS [Current Costs Estimate]

	FROM red_dw.dbo.fact_dimension_main main
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON  dim_matter_header_current.dim_matter_header_curr_key = main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_property dim_detail_property ON dim_detail_property.dim_detail_property_key = main.dim_detail_property_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key=main.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = main.dim_detail_client_key


	WHERE 


	((main.client_code  = '90735C'AND main.matter_number >= '00004570')
	OR (main.client_code  = '89471N'AND main.matter_number >= '00000125')
	OR (main.client_code  = '00568762'AND main.matter_number >= '00000106'))
	AND dim_matter_header_current.reporting_exclusions=0
	AND dim_matter_header_current.matter_description NOT LIKE 'test%'
	





GO

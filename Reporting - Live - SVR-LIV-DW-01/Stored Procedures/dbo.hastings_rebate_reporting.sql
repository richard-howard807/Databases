SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 27/08/2021
-- Description:	Ticket #110181 report on hastings bills
--JL 28-06-22 #154581 changed claim ref to pick up all claims, removed client/matter 19 as per ticket
-- =============================================

CREATE PROCEDURE [dbo].[hastings_rebate_reporting]
(
	@start_date AS DATE
	, @end_date AS DATE
)
AS

BEGIN


--testing
--DECLARE	@start_date AS DATE = DATEADD(MONTH, -1, GETDATE())
--	, @end_date AS DATE = GETDATE()
		


SELECT 
	
	 CAST(COALESCE(dim_client_involvement.insurerclient_reference, dim_client_involvement.client_reference) AS NVARCHAR(2000))	COLLATE Latin1_General_BIN	AS [Claim Reference] /*jl 28-06-22*/
	, dim_detail_core_details.clients_claims_handler_surname_forename			AS [Hastings Handler Name]
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number			AS [Supplier Reference]
	, dim_matter_header_current.matter_owner_full_name				AS [Matter Owner]
	, fact_bill.bill_number										AS [Supplier Invoice Number]
	, 'TBC'								AS [Date of Notification]
	, CAST(dim_date.calendar_date AS DATE)			AS [Date Involved]
	, fact_bill.fees_total + fact_bill.paid_disbursements 
		+ fact_bill.unpaid_disbursements + fact_bill.admin_charges_total			AS [Total Amount Net of VAT]
	, fact_bill.vat_amount				AS [Total VAT Amount]
	, fact_bill.bill_total			AS [Total Amount Due]
	, fact_bill.amount_outstanding	
	, DATEDIFF(DAY, dim_date.calendar_date, CAST(GETDATE() AS DATE))				AS [Any Overdue Invoices (90+ days)]
	, 'monthly_summary'			AS report_type
FROM red_dw.dbo.fact_bill
	INNER JOIN red_dw.dbo.dim_bill
		ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
	INNER JOIN red_dw.dbo.dim_date
		ON dim_date.dim_date_key = fact_bill.dim_bill_date_key
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.client_code = fact_bill.client_code
			AND dim_matter_header_current.matter_number = fact_bill.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
			AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.client_code = dim_matter_header_current.client_code
			AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
WHERE 1 = 1
	AND dim_matter_header_current.master_client_code = '4908'
	AND dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number	 <>'4908-19'
	AND dim_matter_header_current.reporting_exclusions = 0
	AND dim_bill.bill_reversed = 0
	AND dim_bill.bill_number <> 'PURGE'
	AND dim_date.calendar_date >= @start_date
	AND dim_date.calendar_date <= @end_date

UNION


SELECT 
	dim_client_involvement.insurerclient_reference			AS [Claim Number]
	, dim_detail_core_details.clients_claims_handler_surname_forename			AS [Hastings Handler Name]
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number			AS [Supplier Reference]
	, dim_matter_header_current.matter_owner_full_name				AS [Matter Owner]
	, fact_bill.bill_number										AS [Supplier Invoice Number]
	, 'TBC'								AS [Date of Notification]
	, CAST(dim_date.calendar_date AS DATE)			AS [Date Involved]
	, fact_bill.fees_total + fact_bill.paid_disbursements 
		+ fact_bill.unpaid_disbursements + fact_bill.admin_charges_total			AS [Total Amount Net of VAT]
	, fact_bill.vat_amount				AS [Total VAT Amount]
	, fact_bill.bill_total			AS [Total Amount Due]
	, fact_bill.amount_outstanding	
	, DATEDIFF(DAY, dim_date.calendar_date, CAST(GETDATE() AS DATE))				AS [Any Overdue Invoices (90+ days)]
	, 'overdue'			AS report_type
FROM red_dw.dbo.fact_bill
	INNER JOIN red_dw.dbo.dim_bill
		ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
	INNER JOIN red_dw.dbo.dim_date
		ON dim_date.dim_date_key = fact_bill.dim_bill_date_key
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.client_code = fact_bill.client_code
			AND dim_matter_header_current.matter_number = fact_bill.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
			AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.client_code = dim_matter_header_current.client_code
			AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
WHERE 1 = 1
	AND dim_matter_header_current.master_client_code = '4908'
	AND dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number	 <>'4908-19'  /*jl 28-06-22*/
	AND dim_matter_header_current.reporting_exclusions = 0
	AND dim_bill.bill_reversed = 0
	AND dim_bill.bill_number <> 'PURGE'
	AND dim_bill.outstanding_flag = 'Y'
	AND DATEDIFF(DAY, dim_date.calendar_date, CAST(GETDATE() AS DATE)) >= 90

END	
GO

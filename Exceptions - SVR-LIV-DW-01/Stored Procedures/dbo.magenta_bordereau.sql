SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 01-09-2022
-- Description:	Initial Create
-- =============================================
CREATE PROCEDURE [dbo].[magenta_bordereau]
(
	@start_date AS DATE
	, @end_date AS DATE
)

AS
BEGIN
	
SET NOCOUNT ON;


--DECLARE @start_date AS DATE = '2022-08-01'
--		, @end_date AS DATE = '2022-09-01'

SELECT 
	dim_matter_header_current.master_client_code		AS [Client Code]
	, dim_matter_header_current.master_matter_number		AS [Matter Number]
	, dim_detail_claim.gascomp_uprn			AS [UPRN]
	, dim_matter_header_current.matter_description			AS [Matter Desc]
	, dim_detail_claim.gascomp_current_status			AS [Current Status]
	, dim_bill.bill_number			AS [Bill Number]
	, CAST(dim_date.calendar_date AS DATE)			AS [Bill Date]
	, fact_bill.bill_total		AS [Bill Amount]
	, fact_bill.fees_total		AS [Revenue Total]
	, ISNULL(fact_bill.paid_disbursements, 0) + ISNULL(fact_bill.unpaid_disbursements, 0)			AS [Disbursements]
	, fact_bill.vat_amount		AS [VAT]
	, fact_bill.admin_charges_total
FROM red_dw.dbo.dim_matter_header_current
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.fact_bill
		ON fact_bill.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_bill
		ON dim_bill.bill_sequence = fact_bill.bill_sequence
	INNER JOIN red_dw.dbo.dim_date
		ON fact_bill.dim_bill_date_key = dim_date.dim_date_key
WHERE
	dim_matter_header_current.master_client_code = 'W15498'
	AND (dim_matter_header_current.matter_description LIKE 'GAS%'
		OR	dim_matter_header_current.matter_description LIKE 'ELEC%')
	AND dim_bill.bill_reversed = 0
	AND dim_bill.bill_number <> 'PURGE'
	AND dim_date.calendar_date BETWEEN @start_date AND @end_date	

END

GO

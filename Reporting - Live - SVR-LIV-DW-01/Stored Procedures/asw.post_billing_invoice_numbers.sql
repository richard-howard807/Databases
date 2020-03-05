SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =========================================================================================
-- Author:		Lucy Dickinson
-- Create date: 16/11/2017
-- Ticket:		274959
-- Description:	Louise Harvey has requested an invoice number column in her ASW Post Billing
--				Report which is a summary report.  This just concatenates multiple invoice numbers
--=========================================================================================
-- 20180327 LD Excluded Purge Bills
-- =========================================================================================
CREATE PROCEDURE [asw].[post_billing_invoice_numbers]
(
	@start_date DATE
	,@end_date DATE 

)	
AS
	---- For testing purposes
	--DECLARE @start_date DATE = '20180301'
	--	,@end_date DATE  = '20180331'

	DECLARE @st_date_int  INT = CAST(FORMAT(@start_date,'yyyyMMdd') AS INT)
			,@end_date_int INT = CAST(FORMAT(@end_date,'yyyyMMdd') AS INT)
		
		
	SELECT DISTINCT fact_bill.client_code
	,fact_bill.matter_number
	,SUBSTRING(
        (
            SELECT ','+RTRIM(fb1.bill_number)  AS [text()]
            FROM [red_dw].[dbo].[fact_bill] fb1
			INNER JOIN red_dw.dbo.dim_date bd1 ON fb1.dim_bill_date_key = bd1.dim_date_key
            WHERE fb1.client_code = fact_bill.client_code
			AND fb1.matter_number = fact_bill.matter_number
			AND bd1.calendar_date BETWEEN @start_date AND @end_date	
			-- ld 20180327 excluded purge bills
			AND fact_bill.bill_number <> 'PURGE'
			ORDER BY fb1.client_code,fb1.matter_number
            FOR XML PATH ('')
        ), 2, 1000) [Invoices]

FROM [red_dw].[dbo].[fact_bill] fact_bill
	INNER JOIN red_dw.dbo.dim_date billed_date ON fact_bill.dim_bill_date_key = billed_date.dim_date_key
WHERE fact_bill.client_code IN ('00787558','00787559','00787560','00787561')

AND billed_date.calendar_date BETWEEN @start_date AND @end_date

ORDER BY fact_bill.client_code, fact_bill.matter_number








GO

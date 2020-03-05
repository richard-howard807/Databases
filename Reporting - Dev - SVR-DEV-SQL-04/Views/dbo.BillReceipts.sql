SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[BillReceipts] as
SELECT        fact_bill.dim_matter_header_curr_key, fact_bill.dim_client_key, fact_bill.dim_bill_key, MAX(fact_bill.dim_bill_date_key) AS dim_bill_date_key, MAX(fact_bill_receipts.dim_receipt_date_key) 
                         AS dim_receipt_date_key, fact_bill_receipts.dim_matter_owner_key, SUM(fact_bill.bill_total) AS bill_total, SUM(fact_bill_receipts.receipt_total) AS receipt_total, DATEDIFF(dd, MAX(fact_bill_receipts.bill_date), 
                         MAX(fact_bill_receipts.receipt_date)) AS days_to_full_payment
FROM            red_dw.dbo.fact_bill LEFT OUTER JOIN
                         red_dw.dbo.fact_bill_receipts ON fact_bill.dim_bill_key = fact_bill_receipts.dim_bill_key INNER JOIN
                         red_dw.dbo.dim_bill ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
WHERE        (dim_bill.record_type = 'b')
GROUP BY fact_bill.dim_matter_header_curr_key, fact_bill.dim_client_key, fact_bill.dim_bill_key, fact_bill_receipts.dim_matter_owner_key
HAVING        (SUM(fact_bill.bill_total) = SUM(fact_bill_receipts.receipt_total))
GO

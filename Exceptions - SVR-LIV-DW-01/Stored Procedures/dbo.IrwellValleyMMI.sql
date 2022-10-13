SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[IrwellValleyMMI]
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS 

BEGIN

SELECT 'PFH' AS [Purchasing Group Code]
,'S201400044' AS [Supplier Code]
,master_client_code AS [Account Number]
,client_name AS [Account Description]
,fact_bill.bill_number AS [Invoice Number]
,bill_date AS [Invoice Date]
,NULL AS [Account Card Number]
,NULL AS [Product Code]
,matter_description AS [Product Description]
,1 AS [Quantity]
,ISNULL(bill_total ,0) - ISNULL(vat_amount,0) AS [Unit Price]
,ISNULL(bill_total ,0) - ISNULL(vat_amount,0) AS [Line Net]
,ISNULL(bill_total ,0) - ISNULL(vat_amount,0) AS [Invoice Net]
,vat_amount AS [Invoice Vat]
,bill_total AS [Invoice Gross]
,'20%' AS [VAT Rate]
,fileExternalNotes AS [Custom Field 1]
 FROM red_dw.dbo.dim_matter_header_current
 INNER JOIN red_dw.dbo.fact_bill
  ON fact_bill.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
LEFT OUTER JOIN ms_prod.config.dbFile
 ON ms_fileid=fileID
WHERE master_client_code='779674'
AND reporting_exclusions=0
AND bill_reversed=0
AND fact_bill.bill_number<>'PURGE'
AND bill_date BETWEEN @StartDate AND @EndDate

END 
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[CumbriaBilling]
AS
BEGIN
SELECT master_client_code + '-' + master_matter_number AS [Weightmans Ref]
,matter_description AS [Matter Description]
,matter_owner_full_name AS [Weightmans Handler]
,client_reference AS [Client Ref]
,bill_date AS [Bill Date]
,dim_bill.bill_number AS [Bill Number]
,bill_total AS [Total Bill]
,fees_total AS [Revenue]
,ISNULL(paid_disbursements,0) + ISNULL(unpaid_disbursements,0) AS [Disbursements]
,admin_charges_total AS [Admin Charges]
,vat_amount AS [VAT]
,contAddressee
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.fact_bill
 ON fact_bill.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
LEFT OUTER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key

LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN MS_Prod.config.dbAssociates
 ON fileID=ms_fileid AND assocType='CLIENT' AND assocOrder='0'
LEFT OUTER JOIN ms_prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE (master_client_code='243439'
OR (master_client_code='733225' AND master_matter_number='979'))
AND fact_bill.bill_number <>'PURGE'
AND bill_reversed=0
AND bill_date>='2020-08-01'
END
GO

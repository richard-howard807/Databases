SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[RiversideBillLevel]

AS 

BEGIN

SELECT master_client_code + '-'+master_matter_number AS [MS Client/Matter Number]
,matter_description AS [Matter Description]
,date_opened_case_management AS [Date Opened]
,work_type_name AS [Matter Type]
,matter_owner_full_name AS [Case Manager]
,fact_detail_property.[damages_tenant]
,fact_detail_property.[tenants_solicitors_costs]
,bill_total AS [Total Billed]
,fees_total AS [Revenue]
,ISNULL(paid_disbursements,0) + ISNULL(unpaid_disbursements,0) AS [Disbursements]
,ISNULL([Disbursements - Counsel's Fees],0) AS [Disbursements - Counsel's Fees]
,ISNULL(Disbursements.[Disbursements - Court Fees],0) AS [Disbursements - Court Fees]
,ISNULL(Disbursements.[Disbursements - Land Registry Fees],0) AS [Disbursements - Land Registry Fees]
,ISNULL(Disbursements.[Disbursements - Process Server Fees],0) AS [Disbursements - Process Server Fees]
,ISNULL(Disbursements.[Disbursements - Surveyor's Fees],0) AS [Disbursements - Surveyor's Fees]
,ISNULL(Disbursements.Amount,0) -
(
ISNULL([Disbursements - Counsel's Fees],0)
+ISNULL(Disbursements.[Disbursements - Court Fees],0)
+ISNULL(Disbursements.[Disbursements - Land Registry Fees],0)
+ISNULL(Disbursements.[Disbursements - Process Server Fees],0)
+ISNULL(Disbursements.[Disbursements - Surveyor's Fees],0)
) AS [Disbursements - Other]
,vat_amount AS [VAT]
,bill_date AS [Bill Date]
,red_dw.dbo.fact_bill.bill_number AS [Bill Number]


 FROM red_dw.dbo.dim_matter_header_current
 INNER JOIN red_dw.dbo.dim_matter_worktype
  ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.fact_bill
 ON fact_bill.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
LEFT OUTER JOIN 
(
SELECT fact_bill_detail.dim_bill_key
,SUM(workamt) AS [Amount]
,SUM(CASE WHEN LOWER(cost_type_description) LIKE '%counsel%'  OR LOWER(cost_type_description) LIKE '%brief%'THEN workamt ELSE 0 END) AS [Disbursements - Counsel's Fees]
,SUM(CASE WHEN LOWER(cost_type_description) LIKE '%court fee%'  THEN workamt ELSE 0 END) AS [Disbursements - Court Fees]
,SUM(CASE WHEN LOWER(cost_type_description) LIKE '%land registry%'  THEN workamt ELSE 0 END) AS [Disbursements - Land Registry Fees]
,SUM(CASE WHEN LOWER(cost_type_description) LIKE '%process serve%'  THEN workamt ELSE 0 END) AS [Disbursements - Process Server Fees]
,SUM(CASE WHEN LOWER(cost_type_description) LIKE '%inspect%'  OR LOWER(cost_type_description) LIKE '%survey%'THEN workamt ELSE 0 END) AS [Disbursements - Surveyor's Fees]

FROM red_dw.dbo.fact_bill_detail WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_bill WITH(NOLOCK)
 ON dim_bill.dim_bill_key = fact_bill_detail.dim_bill_key
INNER JOIN red_dw.dbo.fact_bill WITH(NOLOCK)
 ON fact_bill.dim_bill_key = fact_bill_detail.dim_bill_key
INNER JOIN red_dw.dbo.dim_matter_header_current  WITH(NOLOCK)
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_detail.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_bill_cost_type ON dim_bill_cost_type.dim_bill_cost_type_key = fact_bill_detail.dim_bill_cost_type_key
WHERE master_client_code='W15603'
AND  fact_bill_detail.charge_type='disbursements'
AND bill_reversed=0
GROUP BY fact_bill_detail.dim_bill_key
) AS Disbursements
 ON fact_bill.dim_bill_key=Disbursements.dim_bill_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_property
 ON fact_detail_property.client_code = dim_matter_header_current.client_code
 AND fact_detail_property.matter_number = dim_matter_header_current.matter_number
WHERE master_client_code='W15603'
AND bill_reversed=0
AND fact_bill.bill_number<>'PURGE'

END 
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[RiversideMatterLevel]

AS 

BEGIN

SELECT master_client_code + '-'+master_matter_number AS [MS Client/Matter Number]
,matter_description AS [Matter Description]
,red_dw.dbo.dim_matter_header_current.date_opened_case_management AS [Date Opened]
,work_type_name AS [Matter Type]
,matter_owner_full_name AS [Case Manager]
,fact_detail_property.[damages_tenant]
,fact_detail_property.[tenants_solicitors_costs]
,total_amount_billed AS [Total Billed]
,defence_costs_billed AS [Revenue]
,ISNULL(disbursements_billed,0) AS [Disbursements]
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
,vat_billed AS [VAT]
,last_bill_date AS [Last Bill Date]
,fact_finance_summary.fixed_fee_amount AS [Fixed Fee Amount]
,dim_detail_core_details.proceedings_issued AS [Proceedings Issued]
,dim_matter_header_current.date_closed_practice_management AS [Date Closed]


 FROM red_dw.dbo.dim_matter_header_current
 INNER JOIN red_dw.dbo.dim_matter_worktype
  ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_property
 ON fact_detail_property.client_code = dim_matter_header_current.client_code
 AND fact_detail_property.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key =dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN
(
SELECT dim_matter_header_current.dim_matter_header_curr_key
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
GROUP BY dim_matter_header_current.dim_matter_header_curr_key
) AS Disbursements
 ON Disbursements.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
 AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
  WHERE master_client_code='W15603'

END 
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GentooBills]
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS 
BEGIN

SELECT fact_bill.client_code AS [Client]
,fact_bill.matter_number AS [Matter]
,client_name AS [Client Name]
,matter_description AS [Description]
,branch_name AS [Office]
,work_type_name AS [Work Type]
,dim_bill.bill_number AS [Bill number]
,CASE WHEN bill_total=amount_paid THEN 'Paid' ELSE CAST(DATEDIFF(DAY,bill_date,GETDATE()) AS NVARCHAR(100)) END  AS [Bill Age]
,bill_date AS [Bill Date]
,matter_partner_full_name AS [Partner]
,fed_code AS [Fee Earner]
,matter_owner_full_name AS [Name]
,hierarchylevel4hist AS [Team]
,bill_total AS [Bill Total]
,fees_total AS [Revenue]
,paid_disbursements AS [Paid Disbs]
,unpaid_disbursements AS [Inpaid Disbs]
,admin_charges_total AS [Admin Charges]
,vat_amount AS [VAT Amount]
,amount_paid AS [Bill Amount Paid]
,last_pay_calendar_date AS [Last Payment]
,CASE WHEN final_bill_flag=1 THEN 'Final' ELSE 'Interim' END AS [Final or Interim]
FROM red_dw.dbo.fact_bill
INNER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_last_pay_date
 ON dim_last_pay_date.dim_last_pay_date_key = fact_bill.dim_last_pay_date_key
WHERE fact_bill.client_code IN ('W23626','W19299')
AND bill_date BETWEEN @StartDate AND @EndDate
AND dim_bill.bill_number <>'PURGE'
AND bill_reversed=0

END
GO

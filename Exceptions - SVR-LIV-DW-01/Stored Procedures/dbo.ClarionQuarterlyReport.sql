SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ClarionQuarterlyReport] 
(
@QTRStart AS DATE
,@QTREnd AS DATE
,@YearStart AS DATE
,@YearEnd AS DATE
)
AS
BEGIN

SELECT 
RTRIM(master_client_code) +'-'+RTRIM(master_matter_number) AS [Matter reference]
,dim_matter_header_current.date_opened_case_management AS [Date of instruction]
,dim_detail_client.[circle_authorised_person] AS [Instructing officer]
,matter_owner_full_name AS [Firm contact]
,matter_description AS [Matter description]
,CASE WHEN ISNULL(fact_finance_summary.[revenue_estimate_net_of_vat],0) +ISNULL(fact_finance_summary.[disbursements_estimate_net_of_vat] ,0)=0
THEN fact_finance_summary.fixed_fee_amount *1.2 
ELSE ISNULL(fact_finance_summary.[revenue_estimate_net_of_vat],0) +ISNULL(fact_finance_summary.[disbursements_estimate_net_of_vat] ,0) *1.2 END AS [Fee estimate or fixed fee (inclusive of VAT and disbursements)]
,QTRBilled AS [Amount billed in  quarter (inclusive of VAT and disbursements)]
,YearBilled AS [Amount billed financial year to date (inclusive of VAT and disbursements)]
,TotalBilled AS [Total amount billed to date (inclusive of VAT and disbursements)]
,wip AS [Work in Progress]
,CASE WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL THEN 'Closed'
WHEN dim_matter_header_current.date_closed_case_management IS NULL AND DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management,GETDATE())<=30 THEN 'New Instruction'
WHEN dim_matter_header_current.date_closed_case_management IS NULL AND CONVERT(DATE,last_time_transaction_date,103) BETWEEN @QTRStart AND @QTREnd THEN 'Ongoing'
WHEN dim_matter_header_current.date_closed_case_management IS NULL AND CONVERT(DATE,last_time_transaction_date,103) < @QTRStart AND ISNULL(wip,0)>0 THEN 'Dormant'
WHEN dim_matter_header_current.date_closed_case_management IS NULL AND CONVERT(DATE,last_time_transaction_date,103) < @QTRStart AND ISNULL(wip,0)=0 THEN 'Completed'
END AS [Status ]
,NULL AS [Comments]
,dim_matter_worktype.work_type_name AS [Matter Type]
,work_type_group AS [Matter Type Group]
,hierarchylevel4hist AS [Team]
,hierarchylevel3hist AS [Department]
 FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client
 ON dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN 
(
SELECT fact_bill.dim_matter_header_curr_key
,SUM(bill_total) AS TotalBilled
,SUM(CASE WHEN CONVERT(DATE,bill_date,103) BETWEEN @QTRStart AND @QTREnd THEN bill_total ELSE 0 END) AS QTRBilled
,SUM(CASE WHEN CONVERT(DATE,bill_date,103) BETWEEN @YearStart AND @YearEnd THEN bill_total ELSE 0 END) AS YearBilled
FROM red_dw.dbo.fact_bill
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill_date
ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
WHERE master_client_code='756630'
--AND master_matter_number='2760'
AND bill_reversed=0
GROUP BY fact_bill.dim_matter_header_curr_key


) AS Bills
 ON Bills.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE master_client_code='756630'
--AND master_matter_number='2760'
ORDER BY master_matter_number DESC
END 
GO

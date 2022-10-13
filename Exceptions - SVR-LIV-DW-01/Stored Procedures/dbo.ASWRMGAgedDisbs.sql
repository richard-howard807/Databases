SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ASWRMGAgedDisbs]
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN
SELECT dim_matter_header_current.client_code AS [Client]
,dim_matter_header_current.matter_number AS [Matter Number]
,matter_description AS [Matter Description]
,name AS [Fee Earner]
,fee_estimate AS [Fee Estimate]
,DisbAmount AS DisbAmount
,defence_costs_billed_composite AS [Fees Billed]
,CASE WHEN CAST(fee_estimate AS DECIMAL(10,2)) =0 THEN NULL ELSE CAST(defence_costs_billed_composite AS DECIMAL(10,2)) / CAST(fee_estimate AS DECIMAL(10,2)) END AS [%Billed]
,[fixed_feehourly_rate]
, fact_matter_summary_current.[last_time_transaction_date]  [Last time Worked]
 FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK) 
 ON fed_code=fee_earner_code collate database_default
 AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.fact_detail_property WITH(NOLOCK) 
 ON dim_matter_header_current.client_code=fact_detail_property.client_code
 AND dim_matter_header_current.matter_number=fact_detail_property.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary WITH(NOLOCK) 
 ON dim_matter_header_current.client_code=fact_finance_summary.client_code
 AND dim_matter_header_current.matter_number=fact_finance_summary.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_property WITH(NOLOCK) 
 ON dim_matter_header_current.client_code=dim_detail_property.client_code
 AND dim_matter_header_current.matter_number=dim_detail_property.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_detail_property.master_fact_key

LEFT OUTER JOIN 
(
SELECT fact_disbursements_detail.client_code AS client_code,fact_disbursements_detail.matter_number AS matter_number,SUM(ISNULL(unbilled_hard_disbursements,0)) + SUM(ISNULL(unbilled_soft_disbursements,0)) DisbAmount
FROM red_dw.dbo.fact_disbursements_detail WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON fact_disbursements_detail.client_code=dim_matter_header_current.client_code
 AND fact_disbursements_detail.matter_number=dim_matter_header_current.matter_number
WHERE (dim_matter_header_current.client_code IN ('00787558','00787559','00787560','00787561')
OR master_client_code='R1001')
AND workdate BETWEEN @StartDate AND @EndDate
AND dim_bill_key =0

GROUP BY fact_disbursements_detail.client_code,fact_disbursements_detail.matter_number
) AS WIPAmounts
 ON dim_matter_header_current.client_code=WIPAmounts.client_code
 AND dim_matter_header_current.matter_number=WIPAmounts.matter_number 
 
 
WHERE 

(
dim_matter_header_current.client_code IN ('00787558','00787559','00787560','00787561')
OR master_client_code='R1001'
)
AND red_dw.dbo.dim_matter_header_current.date_closed_practice_management IS NULL
AND hierarchylevel3hist='Real Estate'
AND dim_matter_header_current.client_code NOT IN ('P00016')
AND name <>'Property View'
AND DisbAmount>0

ORDER BY dim_matter_header_current.client_code
END
GO

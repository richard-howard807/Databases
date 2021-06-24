SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[PlotSalesWritoffReport]--EXEC  [dbo].[PlotSalesWritoffReport]'2021-06-20','2021-06-23'
(
@StartDate AS DATE
,@EndDate AS DATE
)

AS  

BEGIN

SELECT 
red_dw.dbo.dim_matter_header_current.dim_matter_header_curr_key
,CONVERT(DATE,GETDATE(),103) AS [DateRan]
,dim_matter_header_current.client_code AS [Client]
,dim_matter_header_current.matter_number AS [Matter]
,name AS [Fee Earner Name]
,completion_date AS [Completion Date]
,ISNULL(WIP,0) AS [Unbilled WIP Amount]
,LastBill.bill_date AS [Last Bill Date]
,LastBill.bill_number AS [Last Bill Number]
,LastBill.bill_total AS [Last Bill Total]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_detail_property
ON dim_detail_property.client_code = dim_matter_header_current.client_code
AND dim_detail_property.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN 
(
SELECT dim_matter_header_current_key AS dim_matter_header_current_key,SUM(wip_value) AS WIP FROM red_dw.dbo.fact_wip
GROUP BY dim_matter_header_current_key
) AS WIP
 ON  dim_matter_header_current.dim_matter_header_curr_key=WIP.dim_matter_header_current_key
LEFT OUTER JOIN 
(
SELECT fact_bill_matter_detail_summary.dim_matter_header_curr_key,bill_date,bill_total,bill_number
,ROW_NUMBER() OVER (PARTITION BY fact_bill_matter_detail_summary.dim_matter_header_curr_key ORDER BY dim_bill_date_key DESC) AS RecordN
FROM red_dw.dbo.fact_bill_matter_detail_summary
INNER JOIN red_dw.dbo.dim_detail_property
ON dim_detail_property.client_code = fact_bill_matter_detail_summary.client_code
AND dim_detail_property.matter_number = fact_bill_matter_detail_summary.matter_number
WHERE completion_date IS NOT NULL

) AS LastBill
ON LastBill.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
AND LastBill.RecordN=1
WHERE completion_date IS NOT NULL
AND CONVERT(DATE,completion_date,103) 
BETWEEN @StartDate AND @EndDate
--BETWEEN CONVERT(DATE,DATEADD(DAY,-1,GETDATE()),103) AND  CONVERT(DATE,GETDATE(),103)
AND fee_earner_code IN ('6228','3892','3891','3893','6246') -- added per reqiest
END
GO

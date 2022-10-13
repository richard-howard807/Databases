SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[MIBDemo]
(
@StartDate AS DATE
,@EndDate AS DATe
)
AS

BEGIN 
SELECT master_client_code 
,master_matter_number
,matter_description
,dim_detail_outcome.[date_costs_settled]
,service_category
,red_dw.dbo.fact_finance_summary.tp_total_costs_claimed

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_client
 ON dim_detail_client.client_code = dim_matter_header_current.client_code
 AND dim_detail_client.matter_number=dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
WHERE dim_detail_outcome.[date_costs_settled] BETWEEN  @StartDate AND @EndDate
AND master_client_code='M1001'

END 
GO

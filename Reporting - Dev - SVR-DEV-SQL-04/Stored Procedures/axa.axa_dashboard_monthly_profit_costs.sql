SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 01/03/2018
-- Ticket Number: 294178 & 294219
-- Description:	New datasource for the new AXA CS Dashboard 
-- =============================================
CREATE PROCEDURE [axa].[axa_dashboard_monthly_profit_costs]
	
AS
BEGIN

SELECT dim_detail_outcome.client_code
	,dim_detail_outcome.matter_number
	,bill_date
	,SUM(fees_total) profit_costs

FROM red_dw.dbo.dim_matter_header_current 
INNER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.client_code = dim_matter_header_current.client_code AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
INNER JOIN red_dw.dbo.fact_bill_matter_detail ON fact_bill_matter_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE 
	ISNULL(dim_detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
	AND dim_matter_header_current.matter_number<>'ML'
	AND dim_matter_header_current.master_client_code = 'A1001'
	AND dim_matter_header_current.reporting_exclusions=0
	AND dim_matter_header_current.date_opened_case_management >= '20170101'
	AND bill_date >= '20170101'
GROUP BY dim_detail_outcome.client_code
	,dim_detail_outcome.matter_number
	,bill_date

END
GO

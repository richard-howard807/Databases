SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2022-03-30
-- Description:	#141365 Wizz Air EC261 report and Wizz Air Listing report
-- =============================================
CREATE PROCEDURE [dbo].[WizzAirEC261]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT 
  ROW_NUMBER() OVER ( ORDER BY dim_matter_header_current.date_opened_case_management) AS [Nr.]
, NULL AS [Country]
, CAST([date_opened].cal_year AS VARCHAR(4)) +' Q'+ CAST([date_opened].cal_quarter_no AS VARCHAR(1)) AS [Year and Quarter]
, dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Claim number]
, NULL AS [Nr of PAX]
, NULL AS [AOC]
, NULL AS [Flight number]
, NULL AS [Operation (Original) day]
, NULL AS [Original Departure AP]
, NULL AS [Actual Departure AP]
, NULL AS [Original Arrival AP]
, NULL AS [Actual Arrival AP]
, NULL AS [DHC/DLC]
, NULL AS [Main Reason]
, NULL AS [Comments (if any)]
, NULL AS [OTA involved (1/0)]
, NULL AS [Claim farm (1/0)]
, NULL AS [Withdrawn (1/0)]
, NULL AS [Admitted/immediate payment (1/0)]
, NULL AS [Defended and Won (1/0)]
, NULL AS [Settled (1/0)]
, NULL AS [Defended and lost (1/0)]
, NULL AS [Default judgement]
, NULL AS [Appealed by Wizz]
, NULL AS [Appealed by Claimant]
, NULL AS [Reason for loosing]
, NULL AS [Comment (if any)]
, fact_finance_summary.defence_costs_billed AS [Own attorney fee (GBP)]
, fact_finance_summary.disbursements_billed AS [Other expenses (GBP)]
, NULL AS [Claimed amount (EUR)]
, NULL AS [Rendered amount (without interest, EUR)]
, NULL AS [EU261 (EUR)]
, NULL AS [Refund (EUR)]
, NULL AS [Other claims (EUR)]
, NULL AS [Litigation cost (EUR)]
, NULL AS [PNR]
, NULL AS [Claim for Article 9 Right to Care costs]
, NULL AS [Extraordinary Circumstances]
, NULL AS [Status]
, dim_detail_finance.output_wip_fee_arrangement AS [Fee Arrangement] 
, fact_finance_summary.fixed_fee_amount AS [Fixed fee amount]


FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_date AS [date_opened]
on CAST(dim_matter_header_current.date_opened_case_management AS DATE)=CAST([date_opened].calendar_date AS DATE) 
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
ON dim_detail_finance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
AND dim_matter_header_current.master_client_code='W21757'


END
GO

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
, wizz_country AS [Country]
, dim_matter_header_current.date_opened_case_management AS [Date Opened]
, CAST([date_opened].cal_year AS VARCHAR(4)) +' Q'+ CAST([date_opened].cal_quarter_no AS VARCHAR(1)) AS [Year and Quarter]
, [date_opened].cal_year AS [Year]
, [date_opened].cal_quarter_no AS [Quarter]
, dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Claim number]
, NULL AS [Nr of PAX]
, wizz_aoc AS [AOC]
, wizz_flight_number AS [Flight number]
, wizz_operation_original_day AS [Operation (Original) day]
, wizz_original_departure_airport AS [Original Departure AP]
, wizz_actual_departure_airport AS [Actual Departure AP]
, wizz_original_arrival_airport AS [Original Arrival AP]
, wizz_actual_arrival_airport AS [Actual Arrival AP]
, wizz_dhc_dlc AS [DHC/DLC]
, wizz_main_reason AS [Main Reason]
, wizz_reason_comments AS [Comments (if any)]
, wizz_ota_involved AS [OTA involved (1/0)]
, wizz_claim_form AS [Claim farm (1/0)]
, wizz_withdrawn AS [Withdrawn (1/0)]
, wizz_admitted_immediate_payment AS [Admitted/immediate payment (1/0)]
, wizz_defended_and_won AS [Defended and Won (1/0)]
, wizz_settled AS [Settled (1/0)]
, wizz_defended_and_lost AS [Defended and lost (1/0)]
, wizz_default_judgment AS [Default judgement]
, wizz_appealed_by_wizz AS [Appealed by Wizz]
, wizz_appealed_by_claimant AS [Appealed by Claimant]
, wizz_reason_for_losing AS [Reason for loosing]
, wizz_lose_comments AS [Comment (if any)]
, fact_finance_summary.defence_costs_billed AS [Own attorney fee (GBP)]
, fact_finance_summary.disbursements_billed AS [Other expenses (GBP)]
, NULL AS [Claimed amount (EUR)]
, NULL AS [Rendered amount (without interest, EUR)]
, NULL AS [EU261 (EUR)]
, NULL AS [Refund (EUR)]
, NULL AS [Other claims (EUR)]
, NULL AS [Litigation cost (EUR)]
, wizz_pnr AS [PNR]
, wizz_claim_for_article_nine AS [Claim for Article 9 Right to Care costs]
, wizz_extraordinary_circumstances AS [Extraordinary Circumstances]
, wizz_status AS [Status]
, dim_detail_finance.output_wip_fee_arrangement AS [Fee Arrangement] 
, fact_finance_summary.fixed_fee_amount AS [Fixed fee amount]
, 1 AS [Number of cases]


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
LEFT OUTER JOIN red_dw.dbo.dim_instruction_type
ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
LEFT OUTER JOIN red_dw.dbo.dim_file_notes
ON dim_file_notes.dim_file_notes_key = fact_dimension_main.dim_file_notes_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client
ON dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
AND dim_matter_header_current.master_client_code='W21757'
AND dim_instruction_type.instruction_type='EC261'

END
GO

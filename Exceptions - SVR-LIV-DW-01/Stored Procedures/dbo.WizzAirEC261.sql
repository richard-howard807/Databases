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
, dim_matter_header_current.date_closed_case_management AS [Date Closed]
, CAST([date_opened].cal_year AS VARCHAR(4)) +' Q'+ CAST([date_opened].cal_quarter_no AS VARCHAR(1)) AS [Year and Quarter]
, [date_opened].cal_year AS [Year]
, [date_opened].cal_quarter_no AS [Quarter]
, dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Claim number]
, dim_claimant_thirdparty_involvement.claimantsols_name AS [Claimant Solicitor]
, wizz_num_of_pax AS [Nr of PAX]
, wizz_aoc AS [AOC]
, wizz_flight_number AS [Flight number]
, wizz_operation_original_day AS [Operation (Original) day]
, wizz_original_departure_airport AS [Original Departure AP]
, wizz_actual_departure_airport AS [Actual Departure AP]
, wizz_original_arrival_airport AS [Original Arrival AP]
, wizz_actual_arrival_airport AS [Actual Arrival AP]
, ISNULL(wizz_dhc_dlc,'TBC') AS [DHC/DLC]
, wizz_main_reason AS [Main Reason]
, wizz_reason_comments AS [Comments (if any)]
, CASE WHEN wizz_ota_involved ='Yes' THEN 1 ELSE 0 END AS [OTA involved (1/0)]
, CASE WHEN wizz_claim_form ='Yes' THEN 1 ELSE 0 END AS [Claim farm (1/0)]
, CASE WHEN wizz_withdrawn ='Yes' THEN 1 ELSE 0 END AS [Withdrawn (1/0)]
, CASE WHEN wizz_admitted_immediate_payment ='Yes' THEN 1 ELSE 0 END AS [Admitted/immediate payment (1/0)]
, CASE WHEN wizz_defended_and_won ='Yes' THEN 1 ELSE 0 END AS [Defended and Won (1/0)]
, CASE WHEN wizz_settled ='Yes' THEN 1 ELSE 0 END AS [Settled (1/0)]
, CASE WHEN wizz_defended_and_lost ='Yes' THEN 1 ELSE 0 END AS [Defended and lost (1/0)]
, CASE WHEN wizz_default_judgment ='Yes' THEN 1 ELSE 0 END AS [Default judgement (1/0)]
, CASE WHEN wizz_appealed_by_wizz ='Yes' THEN 1 ELSE 0 END AS [Appealed by Wizz (1/0)]
, CASE WHEN wizz_appealed_by_claimant ='Yes' THEN 1 ELSE 0 END AS [Appealed by Claimant (1/0)]
, wizz_default_judgment AS [Default judgement]
, wizz_appealed_by_wizz AS [Appealed by Wizz]
, wizz_appealed_by_claimant AS [Appealed by Claimant]
, wizz_reason_for_losing AS [Reason for loosing]
, wizz_lose_comments AS [Comment (if any)]
, fact_finance_summary.defence_costs_billed AS [Own attorney fee (GBP)]
, fact_finance_summary.disbursements_billed AS [Other expenses (GBP)]
, wizz_claim_amount_eur AS [Claimed amount (EUR)]
, fact_detail_client.wizz_claim_amount_gbp AS [Claimed amount (GBP)]
, wizz_render_amount_eur AS [Rendered amount (without interest, EUR)]
, wizz_ec_two_six_one_eur AS [EC261 (EUR)]
, wizz_refund_eur AS [Refund (EUR)]
, wizz_other_claims_eur AS [Other claims (EUR)]
, wizz_lit_cost_eur AS [Litigation cost (EUR)]
, fact_detail_client.wizz_lit_cost_gbp AS [Litigation cost (GBP)]
, wizz_pnr AS [PNR]
, wizz_claim_for_article_nine AS [Claim for Article 9 Right to Care costs]
, wizz_extraordinary_circumstances AS [Extraordinary Circumstances]
, wizz_status AS [Status]
, dim_detail_finance.output_wip_fee_arrangement AS [Fee Arrangement] 
, fact_finance_summary.fixed_fee_amount AS [Fixed fee amount]
, 1 AS [Number of cases]
, [OriginalDeparture].Longitude AS [Original Departure Longitude]
, [OriginalDeparture].Latitude AS [Original Departure Latitude]



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
LEFT OUTER JOIN red_dw.dbo.fact_detail_client
ON fact_detail_client.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN Reporting.dbo.Airports AS [OriginalDeparture]
ON dim_detail_client.wizz_original_departure_airport=[OriginalDeparture].Airport COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
AND dim_matter_header_current.master_client_code='W21757'
AND dim_instruction_type.instruction_type='EC261'

END
GO

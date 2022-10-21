SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Julie Loughlin
-- Create date: 2022-09-20
-- Description:	New Report for Real Estate plot #168470
-- =============================================
-- #171078 - excluded Paul McGagh cases. Added matters opened since 2021. Only open matters

CREATE PROCEDURE [dbo].[RealEstatePlots]

AS
BEGIN

SET NOCOUNT ON;

SELECT 

[Client Matter] = fact_dimension_main.master_client_code +'-'+master_matter_number,
dim_client.client_name,
dim_client.client_code,
dim_matter_header_current.matter_number,
matter_description AS [Matter Description],
[Matter Owner] = dim_fed_hierarchy_history.name,
[Team] = hierarchylevel4hist,
[Department] = hierarchylevel3hist,
[Date Opened] = CAST(date_opened_case_management AS DATE),
[Date Instructions Received] = dim_detail_core_details.[date_instructions_received] 
,[Date Closed] = CAST(date_closed_case_management AS DATE),
exchange_date,
[Completion Date] = CAST(dim_detail_property.[completion_date] AS DATE) 
,dim_detail_core_details.[present_position]	AS [Present Position]
,chargeable_minutes_recorded/60 AS hours
,external_file_notes

--,DATEDIFF(DAY,CONVERT(DATE,date_instructions_received,103),CONVERT(DATE,COALESCE(dim_detail_plot_details.exchange_date, udPlotSalesExchange.dteExchangeDate, ExchangeDateCompleted, dim_detail_property.[exchange_date], dim_detail_plot_details.[date_of_exchange], dim_detail_property.[residential_date_of_exchange]),103)) AS [Elapsed Days to Exchange]
--,DATEDIFF(DAY,CONVERT(DATE,date_instructions_received,103),CONVERT(DATE,COALESCE(dim_detail_plot_details.pscompletion_date, udPlotSalesExchange.dteCompDate),103))  AS [Elapsed Days to Completion]
--,WorkedHours.HoursRecorded
--,WorkedHours.name AS [Fee earner who recorded the time]


FROM 
red_dw.dbo.fact_dimension_main
JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
LEFT JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_file_notes WITH (NOLOCK) ON dim_file_notes.dim_file_notes_key = fact_dimension_main.dim_file_notes_key

	----****HOURS WORKED (JL ADDED AS PER TICKET  57800 1.1)*****
	--LEFT OUTER JOIN (
	--	SELECT 
                
	--	SUM(minutes_recorded) / 60 AS [HoursRecorded]
	--	,SUM(minutes_recorded) AS [MinutesRecorded]
	--	,ct.master_fact_key
	--	,FeeEarners.name
	--	FROM red_dw.dbo.fact_chargeable_time_activity AS ct 

	--	LEFT OUTER JOIN(

	--			SELECT DISTINCT
	--			dim_fed_hierarchy_history_key,
	--			name
	--			FROM red_dw.dbo.dim_fed_hierarchy_history
	--		)AS FeeEarners
	--	ON FeeEarners.dim_fed_hierarchy_history_key = ct.dim_fed_hierarchy_history_key

	--	GROUP BY
	--	ct.master_fact_key,FeeEarners.name

	--	) AS WorkedHours
	--	ON WorkedHours.master_fact_key = fact_dimension_main.master_fact_key

WHERE 1 = 1 
AND dim_matter_header_current.client_code = 'W15353'
AND name IN ('Lisa Evans', 'Karen Hetherington', 'Anita Forshaw', 'Molly Heymans', 'Alex Howarth')
AND TRIM(hierarchylevel3hist) = 'Real Estate' 
AND CAST(date_opened_case_management AS DATE) >='20210101'
AND chargeable_minutes_recorded/60 >=4.5
AND reporting_exclusions = 0
AND dim_matter_header_current.date_closed_case_management IS NULL 
AND dim_detail_property.completion_date IS NULL
END
GO

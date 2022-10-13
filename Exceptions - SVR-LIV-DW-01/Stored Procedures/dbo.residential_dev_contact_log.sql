SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2020-06-29
-- Description:	#62643 Residential Development Contact Log 
-- =============================================
CREATE PROCEDURE [dbo].[residential_dev_contact_log]
(
-- client codes in report ('W15353', '848629', '190593P', '153838M')
@Client AS VARCHAR(7)
)

AS 

BEGIN
	
SET NOCOUNT ON;

SELECT DISTINCT
	dim_matter_header_current.master_client_code + '/' +
		dim_matter_header_current.master_matter_number									AS [Client/Matter Number]
	, dim_matter_header_current.matter_description										AS [Matter Description]
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)			AS [Date Opened]
	, dim_matter_header_current.matter_owner_full_name									AS [Case Manager]
	, [0002_figures].count_0002															AS [No. of Emails/Letters sent to Other Side]
	, [0002_figures].sum_0002															AS [Time Spent on Emails/Letters sent to Other Side]
	, [0009_figures].count_0009															AS [No. of Telephone Calls to Other Side]
	, [0009_figures].sum_0009															AS [Time Spent on Telephone Calls to Other Side]
	, SUM(fact_billable_time_activity.minutes_recorded)/60								AS [Total time recorded]
	, CAST(dim_matter_header_current.date_closed_practice_management AS DATE)			AS [Date Closed]
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN (
						SELECT 
							fact_billable_time_activity.dim_matter_header_curr_key
							, COUNT(*)				AS [count_0002]
							, SUM(fact_billable_time_activity.minutes_recorded)/60		AS [sum_0002]
						FROM red_dw.dbo.fact_billable_time_activity
							INNER JOIN red_dw.dbo.dim_matter_header_current	
								ON dim_matter_header_current.dim_matter_header_curr_key = fact_billable_time_activity.dim_matter_header_curr_key
							INNER JOIN red_dw.dbo.fact_dimension_main
								ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
							INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
								ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
						WHERE 
							dim_matter_header_current.master_client_code = @Client
							AND fact_billable_time_activity.time_activity_code = '0002'
							AND fact_billable_time_activity.minutes_recorded > 0
							AND fact_billable_time_activity.isactive = 1
							AND dim_fed_hierarchy_history.hierarchylevel4hist = 'Residential Development'
						GROUP BY
							fact_billable_time_activity.dim_matter_header_curr_key
					) AS [0002_figures]
		ON [0002_figures].dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN (
						SELECT 
							fact_billable_time_activity.dim_matter_header_curr_key
							, COUNT(*)				AS [count_0009]
							, SUM(fact_billable_time_activity.minutes_recorded)/60		AS [sum_0009]
						FROM red_dw.dbo.fact_billable_time_activity
							INNER JOIN red_dw.dbo.dim_matter_header_current	
								ON dim_matter_header_current.dim_matter_header_curr_key = fact_billable_time_activity.dim_matter_header_curr_key
							INNER JOIN red_dw.dbo.fact_dimension_main
								ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
							INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
								ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
						WHERE 
							dim_matter_header_current.master_client_code = @Client
							AND fact_billable_time_activity.time_activity_code = '0009'
							AND fact_billable_time_activity.minutes_recorded > 0
							AND fact_billable_time_activity.isactive = 1
							AND dim_fed_hierarchy_history.hierarchylevel4hist = 'Residential Development'
						GROUP BY
							fact_billable_time_activity.dim_matter_header_curr_key
					) AS [0009_figures]
		ON [0009_figures].dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_billable_time_activity
		ON fact_billable_time_activity.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
WHERE 
	dim_matter_header_current.master_client_code = @Client
	AND dim_matter_header_current.master_matter_number > '0'
	AND dim_matter_header_current.reporting_exclusions <> 1
	AND dim_fed_hierarchy_history.hierarchylevel4hist = 'Residential Development'
GROUP BY
	dim_matter_header_current.master_client_code + '/' +
		dim_matter_header_current.master_matter_number						
	, dim_matter_header_current.matter_description							
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)
	, dim_matter_header_current.matter_owner_full_name						
	, [0002_figures].count_0002												
	, [0002_figures].sum_0002												
	, [0009_figures].count_0009												
	, [0009_figures].sum_0009																
	, CAST(dim_matter_header_current.date_closed_practice_management AS DATE)

END 
GO

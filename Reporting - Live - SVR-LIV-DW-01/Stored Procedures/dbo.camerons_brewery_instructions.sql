SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2021-03-16
-- Description: #91950 New report request for Camerons Brewery. 
				Shows number of instructions received, split by Current Status
-- =============================================
*/

CREATE PROCEDURE [dbo].[camerons_brewery_instructions]

AS

BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
	dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number			AS [MatterSphere Client/Matter Number]
	, dim_matter_header_current.matter_description			AS [Matter Description]
	, dim_detail_claim.camerons_brewery_specific_legal_charge		AS [Specific Legal Charge]
	, dim_matter_header_current.matter_owner_full_name + ' & ' + dim_matter_header_current.matter_team_manager	AS [Weightmans Responsibility]
	, dim_detail_claim.camerons_brewery_current_status			AS [Current Status]
	, dim_detail_claim.camerons_brewery_next_weeks_steps		AS [Next Weeks Steps]
	, CONVERT(DATE, dim_detail_claim.camerons_brewery_anticipated_completion_date, 103)		AS [Anticipated Completion Date]
	, dim_detail_claim.camerons_brewery_last_updated			AS [Last Updated]
	, CONVERT(DATE, dim_matter_header_current.date_opened_practice_management, 103)		AS [Date Opened]
	, CASE
		WHEN dim_detail_claim.camerons_brewery_current_status IS NULL THEN
			0
		WHEN dim_detail_claim.camerons_brewery_current_status = 'Current' THEN
			1
		WHEN dim_detail_claim.camerons_brewery_current_status = 'Post Completion' THEN
			2
		WHEN dim_detail_claim.camerons_brewery_current_status = 'On Hold' THEN
			3
	  END					AS sort_order
	, CASE
		WHEN dim_detail_claim.camerons_brewery_current_status IS NULL THEN
			'Incomplete Current Status'
		WHEN dim_detail_claim.camerons_brewery_current_status = 'Current' THEN
			'Current Matters Instructed'
		WHEN dim_detail_claim.camerons_brewery_current_status = 'Post Completion' THEN
			'Post Completion Matters'
		WHEN dim_detail_claim.camerons_brewery_current_status = 'On Hold' THEN
			'On Hold Matters'
	  END					AS page_name
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
WHERE 1 = 1
	AND dim_matter_header_current.master_client_code = 'W22555'
	AND dim_matter_header_current.reporting_exclusions = 0

UNION

/*
Union is to create the blank "Potential Anticipated Matters" page that always needs to appear on the report as a blank sheet with the same column headers
*/

SELECT 
	''		AS [MatterSphere Client/Matter Number]
	, ''			AS [Matter Description]
	, ''		AS [Specific Legal Charge]
	, ''	AS [Weightmans Responsibility]
	, ''			AS [Current Status]
	, ''		AS [Next Weeks Steps]
	, NULL		AS [Anticipated Completion Date]
	, NULL			AS [Last Updated]
	, NULL		AS [Date Opened]
	, 99				AS sort_order --allows more sort_order categories to be added to above query
	, 'Potential Anticipated Matters'				AS page_name

ORDER BY
	sort_order
	, [Date Opened]


END	
GO

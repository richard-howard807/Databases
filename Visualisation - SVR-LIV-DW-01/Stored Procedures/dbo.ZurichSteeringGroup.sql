SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
/*
======================================================================
======================================================================
Author:				Jamie Bonner
Created Date:		2021-03-08
Description:		Zurich Steering Group new instructions dashboard
Current Version:	Initial Create
======================================================================
======================================================================
*/

CREATE PROCEDURE [dbo].[ZurichSteeringGroup]

AS

BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
SET NOCOUNT ON

DECLARE @start_date AS DATE = (SELECT DATEADD(YEAR, -3, MIN(dim_date.calendar_date)) FROM red_dw.dbo.dim_date WHERE dim_date.current_fin_year = 'Current') 
DECLARE @end_date AS DATE = DATEADD(DAY, -DAY(GETDATE()), GETDATE())


SELECT 
	dim_matter_header_current.master_client_code + '.' + dim_matter_header_current.master_matter_number		AS [MS Reference]
	, RTRIM(dim_matter_header_current.client_code) + '.' + SUBSTRING(dim_matter_header_current.matter_number, PATINDEX('%[^0]%', 
	dim_matter_header_current.matter_number), LEN(dim_matter_header_current.matter_number))		AS [fed ref]
	, dim_detail_core_details.zurich_referral_reason
	, LEFT(dim_detail_core_details.zurich_branch, 6)	AS [Zurich Branch]
	, dim_detail_core_details.zurich_line_of_business
	, dim_detail_core_details.injury_type_code
	, dim_detail_claim.cit_claim
	, dim_fed_hierarchy_history.name		AS [Fee Earners Name]
	, dim_fed_hierarchy_history.hierarchylevel4hist			AS [Handler team]
	, dim_employee.locationidud						AS [Handler Office]
	, dim_detail_core_details.date_instructions_received
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)		AS [Date opened]
	/*The dashboard refreshes each month on the 10th, needed to get the year to date based on the previous month being the end of the ytd for each financial year*/
	, CASE
		WHEN (MONTH(dim_matter_header_current.date_opened_practice_management) >= 5 AND MONTH(dim_matter_header_current.date_opened_practice_management) <= 12)
			OR
			(MONTH(dim_matter_header_current.date_opened_practice_management) >= 1 AND MONTH(dim_matter_header_current.date_opened_practice_management) < MONTH(GETDATE())) THEN
            'True'
		ELSE
			'False'
	  END									AS [YTD Filter]
	, dim_detail_client.zurich_instruction_type
	, CASE 
		WHEN ISNULL(dim_detail_client.zurich_instruction_type, '') NOT LIKE 'Outsource%' THEN
			'Litigated'
		ELSE
			'Outsource'
	  END						AS [Litigated/Outsource]
	, IIF(dim_detail_core_details.injury_type_code = 'D17', 'NIHL', 'Other')		AS [NIHL]
	, CASE
		WHEN ISNULL(RTRIM(dim_detail_claim.cit_claim), '') = 'Yes' THEN
			'CAT'
		WHEN ISNULL(RTRIM(dim_detail_core_details.zurich_line_of_business), '') = 'MOT' THEN
			'MOT'
		WHEN ISNULL(dim_detail_core_details.injury_type_code, '') LIKE 'D%' THEN
			'DDU'
		WHEN ISNULL(dim_detail_core_details.zurich_branch, '') LIKE 'ZM%' THEN
			'ZM'
		ELSE
			'ZC'
	  END									AS [ZM/ZC/DDU/MOT/CAT]
	, dim_matter_header_current.reporting_exclusions
	, dim_detail_client.zurich_data_admin_exclude_from_reports
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key_original_matter_owner_dopm
	INNER JOIN red_dw.dbo.dim_employee
		ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
WHERE 1 = 1
	AND dim_matter_header_current.master_client_code = 'Z1001'
	AND dim_matter_header_current.reporting_exclusions = 0
	AND ISNULL(RTRIM(dim_detail_client.zurich_data_admin_exclude_from_reports), 'No') <> 'Yes'
	AND CAST(dim_matter_header_current.date_opened_practice_management AS DATE) >= @start_date
	AND CAST(dim_matter_header_current.date_opened_practice_management AS DATE) <= @end_date
	--AND ISNULL(dim_detail_client.zurich_instruction_type, '') NOT LIKE 'Outsource%'
	--AND RTRIM(dim_matter_header_current.client_code) NOT IN ('Z00002', 'Z00004', 'Z00012', 'Z00014', 'Z00018', '00169487')

END	

GO

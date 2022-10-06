SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2022-06-23
-- Description: #153997 New report request for Northern Trust Company client report
-- =============================================
*/

CREATE PROCEDURE [dbo].[northern_trust_client_report] 

AS

BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
	dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number		AS [Weightmans Reference]
	, dim_matter_header_current.matter_owner_full_name			AS [Case Handler]
	, dim_matter_header_current.matter_description				AS [Matter Description]
	, dim_file_notes.external_file_notes					AS [Present Position]
	, dim_detail_finance.output_wip_percentage_complete		AS [Percentage Completion]
	, dim_matter_header_current.fixed_fee_amount				AS [Fixed Fee]
FROM red_dw.dbo.dim_matter_header_current
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details	
		ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
		ON dim_detail_finance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_property
		ON fact_detail_property.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_file_notes
		ON dim_file_notes.client_code = dim_matter_header_current.client_code
			AND dim_file_notes.matter_number = dim_matter_header_current.matter_number
WHERE
	dim_matter_header_current.reporting_exclusions = 0
	AND dim_matter_header_current.master_client_code = 'WB36668'
	AND dim_matter_header_current.date_closed_case_management IS NULL
ORDER BY
	dim_matter_header_current.date_opened_case_management DESC	
	

END 




GO

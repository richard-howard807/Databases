SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2022-09-22
-- Description:	Initial create
-- =============================================

CREATE PROCEDURE [dbo].[education_sector_claims_report] 
(
	@start_date AS DATE
	, @end_date AS DATE
)
AS

BEGIN

SET NOCOUNT ON

---- Testing dates, start of month to today
--DECLARE @start_date AS DATE = DATEADD(DAY, 1, EOMONTH(CAST(GETDATE() AS DATE), -1))
--		, @end_date AS DATE	= CAST(GETDATE() AS DATE)


SELECT 
	dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number AS [Client and Matter Number]
	, dim_matter_header_current.matter_description		AS [Matter Description]
	, dim_fed_hierarchy_history.name				AS [Matter Owner]
	, dim_fed_hierarchy_history.hierarchylevel4hist		AS [Team]
	, dim_fed_hierarchy_history.hierarchylevel3hist		AS [Department]
	, CAST(dim_matter_header_current.date_opened_case_management AS DATE)		AS [Date Opened]
	, dim_matter_worktype.work_type_name			AS [Matter Type]
	, dim_client.client_name			AS [Client Name]
	, dim_client_involvement.insuredclient_name		AS [Insured Name]
	, dim_client.segment		AS [Client Segment]
	, dim_client.sector		AS [Client Sector]
	, dim_client.sub_sector			AS [Client Sub-Sector]
	, dim_detail_core_details.insured_sector			AS [Insured Sector]
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.fact_dimension_main	
		ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	LEFT OUTER JOIN red_dw.dbo.dim_client
		ON dim_client.client_code = dim_matter_header_current.client_code
WHERE
	dim_matter_header_current.reporting_exclusions = 0
	AND dim_matter_header_current.date_opened_case_management BETWEEN @start_date AND @end_date
	AND dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims'
	AND dim_matter_header_current.master_client_code NOT IN ('N1001', '30645')
	AND (
		dim_client.sector = 'Education                               '
		OR dim_client.sub_sector = 'Education                               '
		OR dim_detail_core_details.insured_sector = 'Education'
		OR LOWER(dim_matter_header_current.matter_description) LIKE '%university%'
		OR LOWER(dim_matter_header_current.matter_description) LIKE '%college%'
		OR LOWER(dim_matter_header_current.matter_description) LIKE '%academy%'
		OR LOWER(dim_matter_header_current.matter_description) LIKE '%school%'
		OR LOWER(dim_client_involvement.insuredclient_name) LIKE '%university%'
		OR LOWER(dim_client_involvement.insuredclient_name) LIKE '%college%'
		OR LOWER(dim_client_involvement.insuredclient_name) LIKE '%academy%'
		OR LOWER(dim_client_involvement.insuredclient_name) LIKE '%school%'
		)

END
GO

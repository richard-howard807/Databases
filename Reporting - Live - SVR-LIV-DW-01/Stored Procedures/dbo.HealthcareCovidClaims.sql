SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[HealthcareCovidClaims]
	(
	
		@Team AS VARCHAR(MAX)
	)
AS 
BEGIN
SET NOCOUNT ON





DROP TABLE IF EXISTS #Team
CREATE TABLE #Team  (
ListValue NVARCHAR(MAX)  COLLATE Latin1_General_BIN
)

INSERT INTO #Team
SELECT ListValue
-- INTO #FedCodeList
FROM dbo.udt_TallySplit('|', @Team)




SELECT 
	dim_matter_header_current.master_client_code + '/'
		+ dim_matter_header_current.master_matter_number										AS [Client/Matter Number]
	, CASE 
		WHEN (dim_matter_header_current.client_group_name IS NULL OR dim_matter_header_current.client_group_name ='') THEN 
			dim_client.client_name 
		ELSE 
			dim_matter_header_current.client_group_name 
	  END																						AS [Client]
	, dim_matter_header_current.matter_description												AS [Matter Description]
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)					AS [Date Opened]
	, dim_matter_header_current.matter_owner_full_name											AS [Matter Owner]
	, dim_fed_hierarchy_history.hierarchylevel4hist												AS [Team]
	, dim_fed_hierarchy_history.hierarchylevel3hist												AS [Department]
	, dim_matter_worktype.work_type_name														AS [Worktype]
	, dim_detail_core_details.proceedings_issued												AS [Proceedings Issued]
	, dim_matter_header_current.present_position												AS [Present Position]
	, dim_detail_core_details.covid_reason_desc													AS [Covid 19 Reason]
	, dim_detail_core_details.covid_reason														AS [Covid 19 Reason - Other Only]
	,dim_detail_core_details.covid_reason_code_date_last_changed AS [Covid 19 Date Last Changed]
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_matter_worktype
	 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	INNER JOIN #Team ON #Team.ListValue = dim_fed_hierarchy_history.hierarchylevel4hist
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_client
		ON dim_client.dim_client_key = fact_dimension_main.dim_client_key

WHERE 
	dim_matter_header_current.reporting_exclusions <> 1
	AND dim_matter_header_current.master_client_code <> '30645'
	AND hierarchylevel3hist='Healthcare'
	AND (dim_detail_core_details.covid_reason_desc IS NOT NULL OR work_type_name='Disease - COVID-19')


END

GO

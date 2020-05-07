SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[TrackCovidClaims]
(
@Department AS VARCHAR(MAX),
@Team AS VARCHAR(MAX)
)
AS 
BEGIN
SET NOCOUNT ON

--DROP TABLE IF EXISTS #team_list

--CREATE TABLE #team_list  (
--ListValue  NVARCHAR(MAX)
--)
--BEGIN

--    INSERT into #team_list 
--	SELECT ListValue
--    FROM dbo.udt_TallySplit(',', @Team)
	
--END

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
	, SUBSTRING(CASE 
		WHEN dim_detail_core_details.covid_directions_extended = 1 THEN 
			', Directions extended'
		ELSE
			''
	  END 
	  +
	  CASE 
		WHEN dim_detail_core_details.covid_disclosure_delay_defendant = 1 THEN	
			', Disclosure delay - Defendant'
		ELSE
			''
	  END	
	  +
	  CASE 
		WHEN dim_detail_core_details.covid_disclosure_delay_claimant = 1 THEN 
			', Disclosure delay - Claimant'
		ELSE
			''
	  END
      +
	  CASE 
		WHEN dim_detail_core_details.covid_disclosure_delay_obtaining_docs = 1 THEN	 
			', Disclosure delay - Obtaining docs from third party'
		ELSE
			''
	  END
      +
	  CASE 
		WHEN dim_detail_core_details.covid_expert_unavailability_claimant_third_party = 1 THEN	
			', Expert unavailability - Claimant/third party'
		ELSE
			''
	  END
      +
	  CASE 
		WHEN dim_detail_core_details.covid_expert_unavailability_defendant = 1 THEN	
			', Expert unavailability - Defendant'
		ELSE
			''
	  END
      +
	  CASE	
		WHEN dim_detail_core_details.covid_hearing_vacated = 1 THEN	 
			', Hearing vacated'
		ELSE
			''
	  END
      +
	  CASE 
		WHEN dim_detail_core_details.covid_limitation_extension_or_moratorium = 1 THEN
			', Limitation extension/moratorium'
		ELSE 
			''
	  END
      +
	  CASE	
		WHEN dim_detail_core_details.covid_medical_exam_postponed = 1 THEN 
			', Medical exam postponed'
		ELSE
			''
	  END
      +
	  CASE 
		WHEN dim_detail_core_details.covid_witness_unavailablility_claimant = 1 THEN 
			', Witness unavailablility - Claimant'
		ELSE
			''
	  END
      +
	  CASE 
		WHEN dim_detail_core_details.covid_witness_unavailability_defendant = 1 THEN 
			', Witness unavailability - Defendant'
		ELSE
			''
	  END
      +
	  CASE 
		WHEN dim_detail_core_details.covid_contested_application_made = 1 THEN
			', Contested application made'
		ELSE
			''
	  END
	  +
	  CASE
		WHEN dim_detail_core_details.covid_other = 1 THEN
			', Other'
		ELSE
			''
	  END, 3, 400)																				AS [Covid 19 Reason]
	, dim_detail_core_details.covid_reason														AS [Covid 19 Reason - Other Only]
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_client
		ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
WHERE 
	dim_matter_header_current.reporting_exclusions <> 1
	AND dim_matter_header_current.master_client_code <> '30645'
	AND CONVERT(INT, dim_detail_core_details.covid_counsel_unavailability) +
		CONVERT(INT, dim_detail_core_details.covid_directions_extended) +
		CONVERT(INT, dim_detail_core_details.covid_disclosure_delay_defendant) +
		CONVERT(INT, dim_detail_core_details.covid_disclosure_delay_claimant) +
		CONVERT(INT, dim_detail_core_details.covid_disclosure_delay_obtaining_docs) +
		CONVERT(INT, dim_detail_core_details.covid_expert_unavailability_claimant_third_party) +
		CONVERT(INT, dim_detail_core_details.covid_expert_unavailability_defendant) +
		CONVERT(INT, dim_detail_core_details.covid_hearing_vacated) +
		CONVERT(INT, dim_detail_core_details.covid_limitation_extension_or_moratorium) +
		CONVERT(INT, dim_detail_core_details.covid_medical_exam_postponed) +
		CONVERT(INT, dim_detail_core_details.covid_other) +
		CONVERT(INT, dim_detail_core_details.covid_witness_unavailablility_claimant) +
		CONVERT(INT, dim_detail_core_details.covid_witness_unavailability_defendant) +
		CONVERT(INT, dim_detail_core_details.covid_contested_application_made) > 0
	AND dim_fed_hierarchy_history.hierarchylevel3hist IN (@Department)
	AND dim_fed_hierarchy_history.hierarchylevel4hist IN (@Team)

END
GO

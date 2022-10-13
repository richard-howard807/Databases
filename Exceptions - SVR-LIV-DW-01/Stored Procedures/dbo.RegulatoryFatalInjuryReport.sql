SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Max Taylor
-- Create date: 03/03/2021
-- Description:	Regulatory/Fatal Injury Report 90440
-- =============================================

-- =============================================

CREATE PROCEDURE [dbo].[RegulatoryFatalInjuryReport]

AS
BEGIN

	SET NOCOUNT ON;


SELECT 
	      dim_matter_header_current.master_client_code  AS [Client Number]
		 ,dim_matter_header_current.master_matter_number AS [Matter Number]
		, matter_description AS [Matter Description]
		, dim_matter_header_current.client_name AS [Client Name]
		, name AS [Matter Owner]
		, hierarchylevel4hist AS [Team]
		, dim_matter_header_current.date_opened_case_management AS [Date Opened]
		, dim_matter_header_current.date_closed_case_management AS [Date Closed]
		, work_type_name AS [Matter Type]
		, referral_reason AS [Referral Reason]
		, injury_type  AS  [Injury Type]
	

FROM red_dw.dbo.fact_dimension_main
LEFT JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_detail_core_details  ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key

WHERE 1 =1 
AND ( dim_matter_header_current.date_opened_case_management >='2019-05-01')
AND reporting_exclusions=0
AND LOWER(ISNULL(outcome_of_case,''))NOT IN ('exclude from reports','returned to client')
AND injury_type = 'Fatal injury'

ORDER BY  dim_matter_header_current.date_opened_case_management DESC
END




GO

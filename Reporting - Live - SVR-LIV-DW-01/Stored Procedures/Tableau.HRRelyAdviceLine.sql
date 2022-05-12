SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2022-05-11
-- Description:	#147125, HR Rely advice line dashboard
-- =============================================

CREATE PROCEDURE [Tableau].[HRRelyAdviceLine]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT dim_matter_header_current.client_name AS [Client]
	, dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Client/Matter Number]
	, dim_matter_header_current.matter_description AS [Matter Description]
	, dim_matter_header_current.date_opened_case_management AS [Date Opened]
	, dim_matter_header_current.date_closed_case_management AS [Date Closed]
	, dim_detail_core_details.date_instructions_received AS [Date Instructions Received]
	, dim_matter_worktype.work_type_name AS [Matter Type]
	, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
	, COALESCE(dim_detail_advice.issue, dim_detail_advice.emph_primary_issue,dim_detail_advice.issue_hr) AS [Issue]
	, dim_detail_advice.diversity_issue AS [Diversity Issue]
	, COALESCE(dim_detail_advice.secondary_issue, dim_detail_advice.secondary_issue_hr) AS [Secondary Issue]
	, dim_detail_advice.brief_description AS [Brief Description]
	, COALESCE(dim_detail_advice.tgif_classification, dim_detail_advice.case_classification) AS [Classification]
	, dim_detail_advice.risk AS [Risk]
	, COALESCE(dim_detail_advice.name_of_caller, dim_detail_advice.whitbread_name_of_caller, dim_detail_advice.swissport_name_of_caller) AS [Name of Caller]
	, COALESCE(dim_detail_advice.job_title_of_caller_pizza_hut, dim_detail_advice.whitbread_caller_job_title, dim_detail_advice.job_title_of_caller_emp, dim_detail_advice.job_title_of_caller_tgipe) AS [Job Title of Caller]
	, dim_detail_advice.geography AS [Geography]
	, dim_detail_advice.site AS [Site]
	, COALESCE(dim_detail_advice.region, dim_detail_advice.swissport_region) AS [Region]
	, dim_detail_advice.workplace_postcode AS [Workplace (postcode)]
	, dim_detail_advice.name_of_employee AS [Name of Employee]
	, dim_detail_advice.job_title_of_employee AS [Job Title of Employee]
	, dim_detail_advice.employment_start_date AS [Employment Start Date]
	, dim_detail_advice.lbs_employee_level AS [Employee Level]
	, dim_detail_advice.lbs_employee_department AS [Employee Department]
	, dim_detail_advice.outcome AS [Outcome]
	, dim_detail_advice.status AS [Status]
	, dim_detail_advice.date_last_call AS [Date of Last Call]
	, dim_detail_advice.category_of_advice AS [Category of Advice]
	, dim_detail_advice.policy_issue AS [Policy Issue]
	, dim_detail_advice.summary_of_advice AS [Summary of Advice]
	, dim_detail_advice.knowledge_gap AS [Knowledge Gap]
	, dim_detail_advice.units AS [Units]
	, TimeRecorded.[Hours Recorded]
	, fact_matter_summary_current.last_time_transaction_date AS [Date of Last Time Posting]
	
	
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_advice
ON dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN (SELECT fact_billable_time_activity.dim_matter_header_curr_key, SUM(fact_billable_time_activity.minutes_recorded)/60 AS [Hours Recorded] 
FROM red_dw.dbo.fact_billable_time_activity
GROUP BY fact_billable_time_activity.dim_matter_header_curr_key) AS [TimeRecorded]
ON TimeRecorded.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
AND dim_matter_worktype.work_type_name = 'Employment Advice Line'
AND (dim_matter_header_current.date_closed_case_management IS NULL OR dim_matter_header_current.date_closed_case_management>= '2019-01-01')


END
GO

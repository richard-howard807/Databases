SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2021-03-02
-- Description:	#90542, new lbs employment advice line report
-- =============================================
CREATE PROCEDURE [dbo].[lbs_employment_advice_line]

AS
BEGIN

	SET NOCOUNT ON;

SELECT 

   dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [MatterSphere Client/Matter Number]
	, dim_matter_header_current.matter_description AS [Matter Description]
	, dim_matter_header_current.matter_owner_full_name AS [Matter Owner]
	, dim_detail_core_details.[date_instructions_received] AS [Date Instructions Received]
	, dim_detail_advice.[lbs_issue] AS [Issue]
	, dim_detail_advice.[lbs_secondary_issue] AS [Secondary Issue]
	, dim_detail_advice.[risk] AS [Risk]
	, dim_detail_advice.[name_of_caller] AS [Name of Caller]
	, dim_detail_advice.[whitbread_caller_job_title] AS [Job Title of Caller]
	, dim_detail_advice.[lbs_caller_level] AS [Caller Level]
	, dim_detail_advice.[lbs_caller_department] AS [Caller Department]
	, dim_detail_advice.[name_of_employee] AS [Name of Employee]
	, dim_detail_advice.[whitbread_employee_job_title] AS [Job Title of Employee]
	, dim_detail_advice.[lbs_employee_level] AS [Employee Level]
	, dim_detail_advice.[lbs_employee_department] AS [Employee Department]
	, dim_detail_advice.[employment_start_date] AS [Employment Start Date]
	, dim_detail_advice.[lbs_outcome] AS [Outcome]
	, dim_detail_advice.[lbs_status] AS [Status]
	, dim_detail_advice.[date_last_call] AS [Date of Last Call]
	, SUM(fact_all_time_activity.minutes_recorded)/60 AS [Total Advice Hours]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_advice
ON dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_all_time_activity
ON fact_all_time_activity.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND LOWER(ISNULL(dim_detail_outcome.outcome_of_case,''))<>'exclude from reports'
AND dim_matter_header_current.master_client_code ='W23504'
AND dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number	 <>'W23504-86'
AND dim_matter_worktype.work_type_name ='Employment Advice Line'

GROUP BY 

  dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number 
	, dim_matter_header_current.matter_description 
	, dim_matter_header_current.matter_owner_full_name
	, dim_detail_core_details.[date_instructions_received] 
	, dim_detail_advice.[lbs_issue] 
	, dim_detail_advice.[lbs_secondary_issue] 
	, dim_detail_advice.[risk] 
	, dim_detail_advice.[name_of_caller] 
	, dim_detail_advice.[whitbread_caller_job_title]
	, dim_detail_advice.[lbs_caller_level] 
	, dim_detail_advice.[lbs_caller_department] 
	, dim_detail_advice.[name_of_employee] 
	, dim_detail_advice.[whitbread_employee_job_title] 
	, dim_detail_advice.[lbs_employee_level] 
	, dim_detail_advice.[lbs_employee_department]
	, dim_detail_advice.[employment_start_date] 
	, dim_detail_advice.[lbs_outcome] 
	, dim_detail_advice.[lbs_status] 
	, dim_detail_advice.[date_last_call] 

END
GO

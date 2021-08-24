SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
 

===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2021-08-23
Description:		Whitbread Call Log -  Tableau Vis
Current Version:	Initial Create
====================================================

*/
CREATE PROCEDURE [dbo].[WhitbreadCallLog]
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


SELECT
RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
,matter_description
,date_opened_case_management
,date_closed_case_management
,matter_owner_full_name
,dim_detail_property.client_code
,dim_detail_core_details.date_instructions_received AS [Date Instructions Received]
,dim_detail_advice.lbs_issue  	  AS [LBS/Whitbread) Issue]
,red_dw.dbo.dim_detail_advice.lbs_secondary_issue	 AS [LBS/Whitbread) Secondary Issue]
,red_dw.dbo.dim_detail_advice.risk
,red_dw.dbo.dim_detail_advice.name_of_caller AS [Name of Employee]
,red_dw.dbo.dim_detail_advice.job_title_of_employee AS [Job Title of Employee]
,red_dw.dbo.dim_detail_client.whitbread_brand AS[Whitbread) Brand]
,red_dw.dbo.dim_detail_advice.employment_start_date AS [Employment Start Date]
,red_dw.dbo.dim_detail_advice.lbs_outcome AS [LBS/Whitbread) Outcome]
,red_dw.dbo.dim_detail_advice.lbs_status AS [LBS/Whitbread) Status]
,red_dw.dbo.dim_detail_advice.date_last_call AS [Date of Last Call]
,red_dw.dbo.dim_detail_advice.units
,whitbread_name_of_caller



FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
LEFT OUTER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_department ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
LEFT OUTER JOIN red_dw..dim_instruction_type ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_advice WITH(NOLOCK) ON dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
LEFT OUTER JOIN red_dw..dim_detail_client ON dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH(NOLOCK) ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key 
WHERE dim_matter_header_current.client_code = 'W15630'
--AND dim_instruction_type.instruction_type IN ('Real Estate Transactional Work (Volume)','Real Estate Litigation Work (Volume)', 'Real Estate Advisory Work (Volume)','Real Estate Transactional Work (BAU)','Real Estate Litigation Work (BAU)','Real Estate Advisory Work (BAU)')))
AND dim_matter_header_current.matter_number <> 'ML'
AND dim_matter_worktype.work_type_name  = 'Employment Advice Line'

END 
GO

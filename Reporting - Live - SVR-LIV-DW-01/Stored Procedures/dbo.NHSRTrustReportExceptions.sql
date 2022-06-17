SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Author: Max Taylor
Date: 2022-06-17
Report: NHSR Trust Report Exceptions #152914


*/

CREATE PROCEDURE [dbo].[NHSRTrustReportExceptions]

AS 

SELECT DISTINCT 
[MatterSphere Ref] = dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number ,
[Matter Description] = dim_matter_header_current.matter_description,
[Case Manager] = name,
[Date Opened] = date_opened_case_management,
[Defendant Trust] = dim_detail_claim.[defendant_trust],
[Present Position] = dim_detail_core_details.[present_position],
[Exceptions] = REPLACE([Exceptions], '&amp;','&'),
fact_dimension_main.master_fact_key


FROM red_dw.dbo.dim_matter_header_current
JOIN red_dw.dbo.fact_dimension_main
	ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
JOIN red_dw.dbo.dim_fed_hierarchy_history 
	ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.dim_instruction_type
	ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
LEFT JOIN red_dw.dbo.dim_detail_core_details
	ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_claim
	ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
JOIN Exceptions.dbo.vwExceptions
	ON fact_dimension_main.master_fact_key = vwExceptions.master_fact_key
 
       WHERE dim_matter_header_current.master_client_code = 'N1001'
	   AND dim_detail_core_details.[present_position] = 'Claim and costs outstanding'
       AND reporting_exclusions = 0
	   AND datasetid = 247

 
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Author: Max Taylor
Date: 2022-06-20
Report: AIG Exceptions DWH #140619


*/

CREATE PROCEDURE [dbo].[AIGExceptionsDWH]

AS 

SELECT DISTINCT 
dim_matter_header_current.master_client_code ,
dim_matter_header_current.master_matter_number,
client_name,
[Description] = dim_matter_header_current.matter_description,
instruction_type,
[Case Manager] = name,
hierarchylevel2hist,
[Department] = hierarchylevel3hist,
[Team] = hierarchylevel4hist,
[Date Opened] = date_opened_case_management,
[Date Closed] = date_closed_case_management,
[Exceptions] = REPLACE([Exceptions], '&amp;','&'),
fact_dimension_main.master_fact_key,
vwExceptions.no_excptions,
COUNT(DISTINCT fact_dimension_main.master_fact_key) cases

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
 
       WHERE dim_matter_header_current.master_client_code = 'A2002'
       AND reporting_exclusions = 0
	   AND datasetid = 226
	 

	 GROUP BY
dim_matter_header_current.master_client_code ,
dim_matter_header_current.master_matter_number,
client_name,
dim_matter_header_current.matter_description,
instruction_type,
name,
hierarchylevel3hist,
hierarchylevel4hist,
date_opened_case_management,
date_closed_case_management,
 REPLACE([Exceptions], '&amp;','&'),
fact_dimension_main.master_fact_key,
vwExceptions.no_excptions, 
hierarchylevel2hist
 
GO

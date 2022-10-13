SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[AXAXLExceptions] 

AS


DROP TABLE IF EXISTS #FilterList

SELECT 
DISTINCT dim_matter_header_current.dim_matter_header_curr_key
INTO #FilterList
FROM red_dw.dbo.fact_dimension_main
JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
WHERE 1 =1 

AND client_group_name='AXA XL'
AND (dim_matter_header_current.date_closed_case_management IS NULL OR CONVERT(DATE,dim_matter_header_current.date_closed_case_management,103)>='2021-03-29')
AND (date_costs_settled  IS NULL OR CONVERT(DATE,date_costs_settled,103)>='2021-03-29')
AND (date_claim_concluded IS NULL OR CONVERT(DATE,date_claim_concluded,103)>='2021-03-29')
--just a quick one on this for the time being - can you restrict it to show files that are "live" - 
--so this will be where date claim concluded or date costs settled are null
AND TRIM(dim_matter_header_current.matter_number) <> 'ML'
AND reporting_exclusions = 0
AND dim_matter_header_current.master_client_code + '-' + master_matter_number NOT IN 
( 'A1001-6044','A1001-10784','A1001-10789','A1001-10798','A1001-10822','A1001-10877','A1001-10913','A1001-10992','A1001-11026','A1001-11140','A1001-11180','A1001-11237','A1001-11254','A1001-11329','A1001-11363','A1001-11375','A1001-11470','A1001-11547','A1001-11562','A1001-11566','A1001-11567','A1001-11586','A1001-11600','A1001-11616','A1001-11618','A1001-11624','A1001-11699','A1001-11749','A1001-11759','A1001-11832','A1001-11894','A1001-4822','A1001-9272', '207818-2'
)
--AND COALESCE(dim_detail_core_details.[date_instructions_received], dim_matter_header_current.date_opened_case_management) <= DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1)





SELECT 
name,
dim_fed_hierarchy_history.fed_code,
hierarchylevel2hist,
hierarchylevel3hist,
hierarchylevel4hist,
COUNT(*) no_excptions,
COUNT(DISTINCT case_id) cases
 FROM red_Dw.dbo.fact_exceptions_update
 LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_exceptions_update.dim_fed_hierarchy_history_key
 JOIN #FilterList ON #FilterList.dim_matter_header_curr_key = fact_exceptions_update.dim_matter_header_curr_key
WHERE datasetid = 243
AND duplicate_flag <> 1
AND miscellaneous_flag <> 1
GROUP BY name,
dim_fed_hierarchy_history.fed_code,
hierarchylevel2hist,
hierarchylevel3hist,
hierarchylevel4hist


GO

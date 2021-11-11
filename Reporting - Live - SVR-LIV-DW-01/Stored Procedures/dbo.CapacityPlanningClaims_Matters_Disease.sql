SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =========================================================================================
-- Author:		Max Taylor
-- Create date: 08/11/2021
-- Ticket:		119900
-- Description:	Initial Create SQL Matters
--=========================================================================================

-- =========================================================================================
CREATE PROCEDURE [dbo].[CapacityPlanningClaims_Matters_Disease]

AS

DROP TABLE IF EXISTS #t1
DROP TABLE IF EXISTS #pers
SELECT 
DatePeriod = REPLACE(RIGHT(fin_period,9),')',''), 
Department =  hierarchylevel3hist,
NewMatters = SUM(CASE WHEN REPLACE(RIGHT(fin_period,9),')','') = LEFT(DATENAME(MONTH, GETDATE()), 3) + '-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) THEN NULL  ELSE fact_matter_summary.open_practice_management_month end),
ClosedMatters = SUM(CASE WHEN REPLACE(RIGHT(fin_period,9),')','') = LEFT(DATENAME(MONTH, GETDATE()), 3) + '-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) THEN NULL  ELSE fact_matter_summary.closed_case_management_month end), 
Active = SUM(CASE WHEN REPLACE(RIGHT(fin_period,9),')','') = LEFT(DATENAME(MONTH, GETDATE()), 3) + '-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) THEN NULL  ELSE fact_matter_summary.open_case_management end)
,[Disease - Groupings] = CASE WHEN instruction_type LIKE '%Outsource%' THEN 'Disease Outsource' ELSE 'Disease exc Outsource' END
,Month = fin_period
INTO #t1 
FROM red_dw.dbo.fact_matter_summary
join red_dw.dbo.fact_dimension_main on fact_dimension_main.master_fact_key = fact_matter_summary.master_fact_key
JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key_original_matter_owner_dopm 
JOIN red_dw.dbo.dim_matter_header_history
ON dim_matter_header_history_key = dim_mat_head_history_key
JOIN  red_dw.dbo.dim_matter_header_current 
ON dim_matter_header_current.client_code = dim_matter_header_history.client_code AND dim_matter_header_current.matter_number = dim_matter_header_history.matter_number
JOIN red_dw.dbo.dim_date 
ON dim_date.dim_date_key = fact_matter_summary.dim_date_key
LEFT JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT JOIN red_dw.dbo.dim_instruction_type 
ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_history.dim_instruction_type_key

WHERE 1 = 1 
AND fin_period >= '2020-12 (Apr-2020)'
AND ISNULL(hierarchylevel3hist,'') IN ('Casualty','Disease', 'Healthcare', 'Large Loss','Motor' )
AND ISNULL(dim_matter_header_current.reporting_exclusions, 0)  = 0

/*Test */
AND ISNULL(hierarchylevel3hist,'') IN ('Disease' )
--AND fin_period = '2021-12 (Apr-2021)'

GROUP BY 

fin_period,
  hierarchylevel3hist, fact_matter_summary.fin_month
  ,CASE WHEN instruction_type LIKE '%Outsource%' THEN 'Disease Outsource' ELSE 'Disease exc Outsource' END
  ORDER BY  hierarchylevel3hist, CASE WHEN instruction_type LIKE '%Outsource%'  THEN 'Disease Outsource' ELSE 'Disease exc Outsource' END, fin_period


  
SELECT DISTINCT TOP 25  Month INTO #pers FROM #t1
ORDER BY Month DESC 


SELECT #t1.*
	   FROM #t1
WHERE Month IN (SELECT DISTINCT Month FROM #pers)
ORDER BY [Disease - Groupings], Month
GO

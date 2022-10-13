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
DROP TABLE IF EXISTS #ClosedMatters



SELECT   distinct
DatePeriod = REPLACE(RIGHT(fin_period,9),')',''), 
Department =  hierarchylevel3hist
,Month = fin_period
,ClosedMatters = COUNT(DISTINCT a.dim_matter_header_curr_key)
,[Disease - Groupings] = CASE WHEN dim_matter_worktype.dim_matter_worktype_key = 32 THEN 'Disease Outsource' ELSE 'Disease exc Outsource' END
INTO #ClosedMatters
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
JOIN red_dw.dbo.fact_all_time_activity a 
ON a.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_history.dim_matter_worktype_key
WHERE 1 = 1 
AND fin_period >= '2020-12 (Apr-2020)'
AND ISNULL(hierarchylevel3hist,'') IN ('Casualty','Disease', 'Healthcare', 'Large Loss','Motor' )
AND ISNULL(dim_matter_header_current.reporting_exclusions, 0)  = 0

/*Closed */
--AND ISNULL(hierarchylevel3hist,'') IN ('Casualty' )
--AND fin_period = '2021-12 (Apr-2021)'
AND ISNULL(hierarchylevel3hist,'') IN ('Disease' )
AND fact_matter_summary.closed_case_management_month = 1
AND outcome = 'closed'
AND time_billed IS NOT NULL
AND ISNULL(TRIM(outcome_of_case), 'Settled')
IN ('Settled  - claimant accepts P36 offer out of time','Settled','Settled - JSM','Won at trial','Settled - infant approval')
AND TRIM(dim_matter_header_history.present_position)
IN ('Final bill due - claim and costs concluded','Claim and costs outstanding','To be closed/minor balances to be clear','Claim concluded but costs outstanding')


GROUP BY 

 REPLACE(RIGHT(fin_period,9),')',''), 
 hierarchylevel3hist
 ,fin_period
 ,CASE WHEN dim_matter_worktype.dim_matter_worktype_key = 32 THEN 'Disease Outsource' ELSE 'Disease exc Outsource' END









SELECT 
DatePeriod = REPLACE(RIGHT(fin_period,9),')',''), 
Department =  hierarchylevel3hist,
NewMatters = SUM(CASE WHEN REPLACE(RIGHT(fin_period,9),')','') = LEFT(DATENAME(MONTH, GETDATE()), 3) + '-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) THEN NULL  ELSE fact_matter_summary.open_practice_management_month end),
ClosedMatters = CASE WHEN REPLACE(RIGHT(fin_period,9),')','') = LEFT(DATENAME(MONTH, GETDATE()), 3) + '-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) THEN NULL  ELSE ClosedMatters end, 
Active = CASE WHEN REPLACE(RIGHT(fin_period,9),')','') = LEFT(DATENAME(MONTH, GETDATE()), 3) + '-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) THEN NULL  ELSE Actuals.ActiveMatters end -- fact_matter_summary.open_case_management
,[Disease - Groupings] = CASE WHEN dim_matter_worktype.dim_matter_worktype_key = 32 THEN 'Disease Outsource' ELSE 'Disease exc Outsource' END
,Month = fin_period
,Actuals.[Actual Chargeable Hours]
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
LEFT JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_history.dim_matter_worktype_key
LEFT JOIN #ClosedMatters ON #ClosedMatters.Month = fin_period AND #ClosedMatters.Department = hierarchylevel3hist AND #ClosedMatters.[Disease - Groupings] = CASE WHEN dim_matter_worktype.dim_matter_worktype_key = 32 THEN 'Disease Outsource' ELSE 'Disease exc Outsource' END
LEFT JOIN (
SELECT
DatePeriod = REPLACE(RIGHT(fin_period,9),')',''),
Month = fin_period,
Department =  hierarchylevel3hist,
[Actual Chargeable Hours]  = 
SUM(
CASE WHEN REPLACE(RIGHT(fin_period,9),')','') = LEFT(DATENAME(MONTH, GETDATE()), 3) + '-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) THEN NULL 
     WHEN minutes_recorded/60  = 0 THEN NULL
ELSE minutes_recorded / 60 END) 
,[Disease - Groupings] = CASE WHEN dim_matter_worktype.dim_matter_worktype_key = 32 THEN 'Disease Outsource' ELSE 'Disease exc Outsource' END
,ActiveMatters = COUNT(DISTINCT fact_all_time_activity.dim_matter_header_curr_key)
FROM red_dw.dbo.fact_all_time_activity-- red_dw.dbo.fact_chargeable_time_activity
JOIN red_dw.dbo.fact_dimension_main ON fact_dimension_main.master_fact_key = fact_all_time_activity.master_fact_key
JOIN red_dw.dbo.dim_date
ON dim_date_key = dim_transaction_date_key
JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_instruction_type 
ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
LEFT JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key

WHERE 1 = 1 
AND fin_period >= '2020-12 (Apr-2020)'
AND ISNULL(hierarchylevel3hist,'') IN ('Disease' )


GROUP BY 
REPLACE(RIGHT(fin_period,9),')',''),
fin_period,
hierarchylevel3hist, CASE WHEN dim_matter_worktype.dim_matter_worktype_key = 32 THEN 'Disease Outsource' ELSE 'Disease exc Outsource' END

) Actuals ON Actuals.DatePeriod = REPLACE(RIGHT(fin_period,9),')','') AND Actuals.Department = hierarchylevel3hist
AND Actuals.[Disease - Groupings] = CASE WHEN dim_matter_worktype.dim_matter_worktype_key = 32 THEN 'Disease Outsource' ELSE 'Disease exc Outsource' END



WHERE 1 = 1 
AND fin_period >= '2020-12 (Apr-2020)'
AND ISNULL(dim_matter_header_current.reporting_exclusions, 0)  = 0
AND ISNULL(hierarchylevel3hist,'') IN ('Disease' )


GROUP BY 

fin_period,
  hierarchylevel3hist, fact_matter_summary.fin_month
  ,CASE WHEN dim_matter_worktype.dim_matter_worktype_key = 32 THEN 'Disease Outsource' ELSE 'Disease exc Outsource' END
  ,Actuals.[Actual Chargeable Hours]
  ,CASE WHEN REPLACE(RIGHT(fin_period,9),')','') = LEFT(DATENAME(MONTH, GETDATE()), 3) + '-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) THEN NULL  ELSE Actuals.ActiveMatters end
  ,CASE WHEN REPLACE(RIGHT(fin_period,9),')','') = LEFT(DATENAME(MONTH, GETDATE()), 3) + '-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) THEN NULL  ELSE ClosedMatters end
  
  ORDER BY  hierarchylevel3hist, CASE WHEN dim_matter_worktype.dim_matter_worktype_key = 32  THEN 'Disease Outsource' ELSE 'Disease exc Outsource' END, fin_period


  
SELECT DISTINCT TOP 25  Month INTO #pers FROM #t1
ORDER BY Month DESC 


SELECT #t1.DatePeriod,
       #t1.Department,
       #t1.NewMatters,
       #t1.ClosedMatters,
       #t1.Active ,
       #t1.[Disease - Groupings],
       #t1.Month,
       #t1.[Actual Chargeable Hours]
	   FROM #t1
WHERE Month IN (SELECT DISTINCT Month FROM #pers)
ORDER BY [Disease - Groupings], Month
GO

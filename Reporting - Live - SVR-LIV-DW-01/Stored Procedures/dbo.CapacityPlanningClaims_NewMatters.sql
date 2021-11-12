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
CREATE PROCEDURE [dbo].[CapacityPlanningClaims_NewMatters]

AS


DROP TABLE IF EXISTS #pers
SELECT DISTINCT fin_period
INTO #pers 
FROM red_dw.dbo.dim_date
WHERE REPLACE(RIGHT(fin_period,9),')','') =  LEFT(DATENAME(MONTH, DATEADD(MONTH, -1, GETDATE())), 3) +'-' +CAST(YEAR(DATEADD(MONTH, -1, GETDATE())) AS VARCHAR(4))


SELECT DISTINCT 
DatePeriod = REPLACE(RIGHT(fin_period,9),')',''),
Month = fin_period,
	 [Department] = 
	 CASE WHEN hierarchylevel3hist = 'Disease' AND instruction_type LIKE '%Outsource%' THEN 'Disease Outsource' 
	      WHEN hierarchylevel3hist = 'Disease' AND ISNULL(instruction_type, '') NOT LIKE '%Outsource%' THEN 'Disease exc Outsource' 
		  ELSE hierarchylevel3hist END

	, COUNT(DISTINCT master_fact_key) Matters 
	,SUM(minutes_recorded)/60 AS HoursRecorded
FROM red_dw.dbo.fact_billable_time_activity
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH (NOLOCK)
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = red_dw.dbo.fact_billable_time_activity.dim_fed_hierarchy_history_key
AND dim_fed_hierarchy_history.hierarchylevel2hist IN ( 'Legal Ops - Claims', 'Legal Ops - LTA' )
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current WITH (NOLOCK)
ON dim_matter_header_current.dim_matter_header_curr_key = fact_billable_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_date WITH (NOLOCK)
ON dim_date_key=fact_billable_time_activity.dim_orig_posting_date_key
LEFT OUTER JOIN red_dw.dbo.dim_time_activity_type WITH (NOLOCK)
ON dim_time_activity_type.time_activity_code = fact_billable_time_activity.time_activity_code
AND dim_time_activity_type.dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_billable_time_activity
ON dim_billable_time_activity.dim_chargeable_time_activity_key=fact_billable_time_activity.dim_billable_time_activity_key
LEFT OUTER JOIN red_dw.dbo.dim_instruction_type WITH (NOLOCK)
ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key


WHERE 1 =1 
AND dim_matter_header_current.reporting_exclusions=0
AND fin_period = (SELECT fin_period FROM #pers)
AND ISNULL(hierarchylevel3hist,'') IN ('Casualty','Disease', 'Healthcare', 'Large Loss','Motor' )


GROUP BY 
         dim_fed_hierarchy_history.hierarchylevel3hist,
  
		CASE WHEN hierarchylevel3hist = 'Disease' AND instruction_type LIKE '%Outsource%' THEN 'Disease Outsource' 
	      WHEN hierarchylevel3hist = 'Disease' AND ISNULL(instruction_type, '') NOT LIKE '%Outsource%' THEN 'Disease exc Outsource' 
		  ELSE hierarchylevel3hist END,

		  REPLACE(RIGHT(fin_period,9),')',''),fin_period

		  ORDER BY Department


GO

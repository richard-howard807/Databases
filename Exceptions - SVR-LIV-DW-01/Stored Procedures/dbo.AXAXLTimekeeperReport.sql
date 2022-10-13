SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[AXAXLTimekeeperReport]

AS

DROP TABLE IF EXISTS #t1

SELECT DISTINCT 
 [Email Distribution group]	= [Email Distribution group]
,[AXA Work Type]	= [AXA Work Type]
,[Fee Earner Name] =  forename + ' ' + surname
,[Email Address]	=workemail
,[AXA Billing Grade] = 
CASE 
WHEN dim_employee.jobtitle IN ('Paralegal','Trainee Solicitor','Costs Draftsperson','Intelligence Analyst','Legal Assistant','Litigation Executive (Non Qualified)','Consultant','Associate (Costs Draftsman)','Associate (unregistered barrister)','Intelligence Manager')   THEN 'Trainee/ Paralegal'
WHEN DATEDIFF(YEAR,admissiondateud,GETDATE()) >= 8 AND dim_employee.jobtitle IN ('Partner',  'Senior Partner') THEN 'Partner'
WHEN DATEDIFF(YEAR,admissiondateud,GETDATE()) >= 6 THEN 'Senior Associate'
WHEN DATEDIFF(YEAR,admissiondateud,GETDATE()) < 6 THEN 'Mid-Level Associate'
WHEN DATEDIFF(YEAR,admissiondateud,GETDATE()) <= 3 THEN 'Junior Associate'



END


,[Rate]	= CAST('' AS NVARCHAR(50))
,[Qualification date]	=admissiondateud
,[Todays Date]	= GETDATE()
,[PQE]	=  DATEDIFF(YEAR,admissiondateud,GETDATE()) 
,[Department] = CAST('' AS NVARCHAR(50))--hierarchylevel3hist	
,[Team]	= CAST('' AS NVARCHAR(50))  -- hierarchylevel4hist
,[Grade]	=dim_employee.jobtitle
,[In email group?] = CASE WHEN [Email Distribution group] = 'N/A' THEN 'No' WHEN [Email Distribution group] IS NOT NULL THEN 'Yes' END
,[Notes] = Notes
,leaver
,dim_employee.dim_employee_key
,[Time Recorded] = [Total Hrs]
,[Time Latest Recorded] = LatestRecorded
,[Time First Recorded] = FirstRecorded
,[WIP]
,[On original list] = CASE WHEN [Fee Earner Name] IS NOT NULL THEN 'Yes' ELSE 'No' END


INTO #t1
FROM red_dw.dbo.dim_matter_header_current
JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key 
LEFT JOIN red_dw.dbo.dim_employee 
ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key

LEFT JOIN SQLAdmin.[dbo].[AXA_Timekeepers]
ON [Fee Earner Name] COLLATE DATABASE_DEFAULT = forename + ' ' + surname



/*Time Recorded */
LEFT JOIN (
 SELECT DISTINCT forename + ' ' + surname AS Ref
,SUM(minutes_recorded) /60 AS [Total Hrs]
,MAX(transaction_calendar_date) AS LatestRecorded
,MIN(transaction_calendar_date) AS FirstRecorded
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.fact_all_time_activity
ON fact_all_time_activity.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_transaction_date
ON dim_transaction_date.dim_transaction_date_key = fact_all_time_activity.dim_transaction_date_key
JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.dim_employee 
ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
WHERE dim_matter_header_current.master_client_code = 'A1001'
and hierarchylevel2hist <> 'Unknown'
AND leaver = 0
AND employeestartdate IS NOT NULL

GROUP BY
 forename + ' ' + surname ) TimeRecorded ON TimeRecorded.Ref COLLATE DATABASE_DEFAULT = forename + ' ' + surname

 /* WIP */
LEFT JOIN (
 SELECT DISTINCT forename + ' ' + surname AS Ref
 ,SUM(fact_finance_summary.wip) AS [WIP]
FROM red_dw.dbo.dim_matter_header_current
JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.dim_employee 
ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
JOIN  red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
WHERE dim_matter_header_current.master_client_code = 'A1001'
and hierarchylevel2hist <> 'Unknown'
AND leaver = 0
AND employeestartdate IS NOT NULL

GROUP BY
 forename + ' ' + surname ) WIP ON WIP.Ref COLLATE DATABASE_DEFAULT = forename + ' ' + surname



WHERE dim_matter_header_current.master_client_code = 'A1001'
and hierarchylevel2hist <> 'Unknown'
AND leaver = 0
AND employeestartdate IS NOT NULL




UPDATE #t1

SET Department = hierarchylevel3hist, 
Team = hierarchylevel4hist

FROM #t1 
JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_employee_key = #t1.dim_employee_key
AND dim_fed_hierarchy_history.activeud = 1 
AND dim_fed_hierarchy_history.dss_current_flag = 'Y'

UPDATE #t1
SET Rate = [New Rates]
FROM #t1
JOIN SQLAdmin.[dbo].[AXA_Rates]
ON [Role] COLLATE DATABASE_DEFAULT = [AXA Billing Grade] AND [Products / Segments] = [AXA Work Type] COLLATE DATABASE_DEFAULT


SELECT DISTINCT *, 
LatestRecordedorWIPFlag = CASE WHEN [Time Latest Recorded] > GETDATE() -365 AND [Time Recorded] >1  THEN 'Yes'
WHEN WIP > 0 THEN 'Yes'END 
FROM #t1
ORDER BY [Fee Earner Name]


GO

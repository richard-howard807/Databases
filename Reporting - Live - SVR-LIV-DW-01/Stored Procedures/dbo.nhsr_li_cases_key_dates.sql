SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
===================================================
===================================================
Author:				Jamie Bonner
Created Date:		2022-06-08
Description:		NHSR matters overdue/future key dates report
Ticket:				151677
Current Version:	Initial Create
====================================================
====================================================
*/

CREATE PROCEDURE [dbo].[nhsr_li_cases_key_dates]  

AS

BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DROP TABLE IF EXISTS #key_dates

SELECT DISTINCT 
	dim_matter_header_current.dim_matter_header_curr_key
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number		AS [Reference]
	--, dbKeyDates.*
	, CAST([red_dw].[dbo].[datetimelocal](dbTasks.tskDue) AS DATE)			AS key_date_due_date
	, dbTasks.tskDesc			AS key_date_description
	, dbUser.usrFullName		AS key_date_owner
	, IIF([red_dw].[dbo].[datetimelocal](dbTasks.tskDue) < CAST(GETDATE() AS DATE), 'overdue', 'future')		AS overdue_future_date
INTO #key_dates
FROM MS_Prod..dbKeyDates
	INNER JOIN MS_Prod..dbTasks
		ON dbTasks.fileID = dbKeyDates.fileID
			AND dbTasks.tskRelatedID = dbKeyDates.kdRelatedID
	INNER JOIN MS_Prod..dbUser
		ON dbUser.usrID = dbTasks.feeusrID
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dbKeyDates.fileID = dim_matter_header_current.ms_fileid
	INNER JOIN red_dw.dbo.dim_detail_health
		ON dim_detail_health.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE
	dim_matter_header_current.master_client_code = 'N1001'
	AND dim_detail_health.nhs_instruction_type IN ('2022: LI250', '2022: LI100', '2022: LI250+') 
	AND dbTasks.tskComplete = 0
	AND dbKeyDates.kdActive = 1
	AND dbKeyDates.kdType <> 'REPORTCLIENT'
	AND dbTasks.tskDesc LIKE '%today%'
	AND CAST([red_dw].[dbo].[datetimelocal](dbTasks.tskDue) AS DATE) BETWEEN '2022-03-01' AND DATEADD(YEAR, 2, CAST(GETDATE() AS  DATE))



SELECT 
	dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number		AS [Reference]
	, CAST(fact_matter_summary_current.last_time_transaction_date AS DATE)		AS [Date of Last Time Posting]
	, IIF(DATEDIFF(DAY, CAST(fact_matter_summary_current.last_time_transaction_date AS DATE), CAST(GETDATE() AS DATE)) >= 14, 'Yes', '')  AS [Not Worked on in Over 2 Weeks]
	, dim_matter_header_current.matter_description			AS [Matter Description]
	, dim_fed_hierarchy_history.name			AS [Case Manager]
	, dim_fed_hierarchy_history.worksforname		AS [Team Manager]
	, dim_employee.locationidud			AS [Office]
	, dim_fed_hierarchy_history.hierarchylevel4hist			AS [Team]
	, dim_fed_hierarchy_history.hierarchylevel3hist			AS [Department]
	, dim_matter_worktype.work_type_name			AS [Matter Type]
	, dim_detail_health.nhs_scheme			AS [Scheme]
	, dim_detail_health.nhs_instruction_type		AS [NHS Instruction Type]
	, CAST(dim_matter_header_current.date_opened_case_management AS DATE)			AS [Date Case Opened]
	, CAST(dim_matter_header_current.date_closed_case_management AS DATE)			AS [Date Case Closed]
	, dim_detail_core_details.present_position			AS [Present Position]
	, #key_dates.key_date_description			AS [Key Date Reminder]
	, #key_dates.key_date_due_date				AS [Date Due]
	, #key_dates.key_date_owner					AS [Task Owner]
	, ISNULL(#key_dates.overdue_future_date, 'no_date') AS overdue_future_date
	, CASE 
		WHEN overdue_matters.dim_matter_header_curr_key IS NOT NULL THEN 
			'Red'
		WHEN future_matters.dim_matter_header_curr_key IS NULL THEN
			'Yellow'
		ELSE 
			'Transparent'
	  END						AS cell_colour_code
	, 1 AS row_count
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_matter_header_current.fee_earner_code = dim_fed_hierarchy_history.fed_code
			AND CAST(GETDATE() AS DATE) BETWEEN dim_fed_hierarchy_history.dss_start_date AND dim_fed_hierarchy_history.dss_end_date
	INNER JOIN red_dw.dbo.dim_employee
		ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_instruction_type
		ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_health
		ON dim_detail_health.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
		ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN #key_dates
		ON #key_dates.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN (
					SELECT DISTINCT 
						#key_dates.dim_matter_header_curr_key
					FROM #key_dates
					WHERE
						#key_dates.overdue_future_date = 'overdue'
					) AS overdue_matters
		ON overdue_matters.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN (
					SELECT DISTINCT 
						#key_dates.dim_matter_header_curr_key
					FROM #key_dates
					WHERE
						#key_dates.overdue_future_date = 'future'
					) AS future_matters
		ON future_matters.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE
	dim_matter_header_current.reporting_exclusions = 0
	AND dim_matter_header_current.master_client_code = 'N1001'
	AND dim_detail_health.nhs_instruction_type IN ('2022: LI250', '2022: LI100', '2022: LI250+')


END 


GO
